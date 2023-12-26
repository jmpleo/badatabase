#include "badatabase.h"
#include "batypes.h"
#include "connconfmanager.h"
#include "logger.h"
#include "namestranslator.h"

#include <algorithm>
#include <boost/container/container_fwd.hpp>
#include <boost/lexical_cast.hpp>
#include <cmath>
#include <cstddef>
#include <exception>
#include <memory>
#include <nlohmann/json_fwd.hpp>
#include <pqxx/array.hxx>
#include <pqxx/connection.hxx>
#include <pqxx/except.hxx>
#include <pqxx/nontransaction.hxx>
#include <pqxx/result.hxx>
#include <pqxx/strconv.hxx>
#include <pqxx/transaction.hxx>
#include <string>
#include <string_view>
#include <typeinfo>
#include <vector>


using namespace badatabase;
using namespace batypes;


/**
 * \brief Проверка соединения с БД.
 *
 * Для проверки соединения выполняется обращение к таблице badeviceinfo.
 *
 * \param
 * \return Статус соединения.
 */
bool BADataBase::isConnected()
{
    if (conn_ == nullptr) {
        return false;
    }
    try {
        return 0;
        //return not pqxx::nontransaction(*conn_).exec(
        //    "SELECT TRUE FROM badeviceinfo LIMIT 1"
        //).empty();
    }
    catch (const std::exception &e) {
        return false;
    }
}


/**
 * \brief Попытка выполнения скрипта main.sql.
 *
 * \return Статус успешности обновления схемы бд.
 */
bool BADataBase::setScheme()
{
    if (conn_ == nullptr) {
        Logger::cout() << "Cоединениe не установлено" << std::endl;
        return false;
    }

    try {
        //pqxx::work txn(*conn_);
        //txn.exec(Query::mainSQL);
        //txn.commit();
        return true;
    }
    catch (const std::exception &e) {
        Logger::cout() << "Не удалось обновить схему соединения " + connName_ << e.what() << std::endl;
        return false;
    }
}


/**
 * \brief Копирование данных таблицы из другого соединения.
 *
 * \param src Соединение откуда будет выполнен трансфер данных.
 * \param table Из какой таблицы осуществляется копирование.
 * \param mod Режим переноса. Force - перезапись данных по ограничению unique,
 * Quiet - данные не копируются при возникновении конфликта ограничения
 */
bool BADataBase::copyFrom(BADataBase &src, Table table, CopyMod mod)
{
    if (getBADeviceInfoId() != src.getBADeviceInfoId()) {
        Logger::cout() << "Устройства соединений не совпадают" << std::endl;
        return false;
    }

    if (conn_ == nullptr || src.conn_ == nullptr) {
        Logger::cout() << "Cоединениe не установлено" << std::endl;
        return false;
    }

    try {
        pqxx::work dstTxn(*conn_), srcTxn(*src.conn_);

        srcTxn.exec(Query::selectCursorOn(table));

        pqxx::result res;
        std::string record;

        while (res = srcTxn.exec(Query::fetchAsCompositeFromCurrentCursor(table)), !res.empty()) {
            record = res[0][0].c_str();
            dstTxn.exec(Query::insertInto(table, record, mod));
        }
        srcTxn.commit();
        dstTxn.commit();
        return true;
    }
    catch (const pqxx::sql_error &e) {
        Logger::cout() << e.what() << std::endl << e.query() << std::endl;
        return false;
    }
    catch (const std::exception &e) {
        Logger::cout() << e.what() << std::endl;
        return false;
    }
}


/**
 * \brief Удаление записи по первичному ключу.
 *
 * \param prKey Первичный ключ таблицы table.
 * \param table Таблица из которой выполняется удаление.
 *
 */
bool BADataBase::del(std::string prKey, Table table)
{
    if (conn_ == nullptr) {
        Logger::cout() << "Cоединениe не установлено" << std::endl;
        return false;
    }

    try {
        pqxx::work txn(*conn_);
        pqxx::result res = txn.exec(Query::deleteFrom(table, prKey));
        txn.commit();
        return !res.empty();
    }
    catch (const pqxx::sql_error &e) {
        Logger::cout() << e.what() << std::endl << e.query() << std::endl;
        return false;
    }
    catch (const std::exception &e) {
        Logger::cout() << e.what() << std::endl;
        return false;
    }
}


/**
 * \brief Получение ID устройства с которым поддерживается соединение.
 *
 * Сначала производится попытка просмотра в файл конфигурации - куда кэшируется
 * id устройства.
 *
 */
std::string BADataBase::getBADeviceInfoId()
{
    std::string id = config.getDevice(connName_);
    return id.empty() ? getBADeviceInfo().deviceId : id;
}


/**
 * \brief Получение устройства для для текщего соединения.
 *
 * \return Пустую структуру при неуспешном выполнении запроса к таблице
 * badeviceinfo.
 */
BADeviceInfo BADataBase::getBADeviceInfo()
{
    BADeviceInfo device;

    if (conn_ == nullptr) {
        Logger::cout() << "Cоединениe не установлено" << std::endl;
        return device;
    }

    try {
        pqxx::result res = pqxx::nontransaction(*conn_).exec(Query::selectFrom(Table::Device));

        if (not res.empty()) {
            device.deviceId = res[0]["deviceid"].c_str();
            device.deviceName = res[0]["devicename"].c_str();
            device.adcFreq = res[0]["adcfreq"].as<long>(0);
            device.startDiscret = res[0]["startdiscret"].as<int>(0);
        }

        config.setDevice(connName_, device.deviceId);

        return device;
    }
    catch (const pqxx::sql_error &e) {
        Logger::cout() << e.what() << std::endl << e.query() << std::endl;
        return device;
    }
    catch (const std::exception &e) {
        Logger::cout() << e.what() << std::endl;
        return device;
    }
}


/**
 * \brief Получение списка линий для сенсора.
 *
 * \param sensorId Первичный ключ сенсора в таблице.
 */
std::vector <SensorLine> BADataBase::getSensorLines(int sensorId)
{
    std::vector <SensorLine> lines;

    if (conn_ == nullptr) {
        Logger::cout() << "Cоединениe не установлено" << std::endl;
        return lines;
    }

    try {
        pqxx::work txn(*conn_);
        pqxx::result res = txn.exec(Query::selectCursorOnLines(sensorId));

        pqxx::row row;

        while (res = txn.exec(Query::fetchFromCurrentCursor(Table::Line)), !res.empty()) {

            row = res[0];
            SensorLine l;

            l.direct = row["direct"].as<int>(0);
            l.lineId = row["lineid"].as<int>(0);
            l.lineName = row["linename"].c_str();
            l.sensorId = row["sensorid"].as<int>(0);
            l.lineType = row["linetype"].as<int>(0);
            l.defCoeff = row["defcoeff"].as<float>(0.);
            l.endPoint = row["endpoint"].as<int>(0);
            l.mhzTemp20 = row["mhztemp20"].as<float>(0.);
            l.tempCoeff = row["tempcoeff"].as<float>(0.);
            l.auxLineId = row["auxlineid"].as<int>(0);
            l.startPoint = row["startpoint"].as<int>(0);
            l.lengthPoint = row["lengthpoints"].as<int>(0);
            l.lengthMeters = row["lengthmeters"].as<float>(0.);
            l.lineFullName = row["linefullname"].c_str();

            lines.push_back(l);
        }

        return lines;
    }
    catch (const std::exception &e) {
        Logger::cout() << e.what() << std::endl;
        return lines = {};
    }
}


/**
 * \brief Получение списка зон для сенсора.
 *
 * \param sensorId Первичный ключ сенсора.
 *
 */
std::vector <Zone> BADataBase::getSensorZones(int sensorId)
{
    std::vector <Zone> zones;

    if (conn_ == nullptr) {
        Logger::cout() << "Cоединениe не установлено" << std::endl;
        return zones;
    }

    try {
        pqxx::work txn(*conn_);
        pqxx::result res = txn.exec(Query::selectCursorOnZones(sensorId));

        pqxx::row row;

        while (res = txn.exec(Query::fetchFromCurrentCursor(Table::Zone)), !res.empty()) {

            row = res[0];
            Zone z;

            z.direct = row["direct"].as<int>(0);
            z.zoneId = row["zoneid"].as<int>(0);
            z.extZoneId = row["extzoneid"].as<int>(0);
            z.lineId = row["lineid"].as<int>(0);
            z.sensorId = row["sensorid"].as<int>(0);
            z.zoneType = row["zonetype"].as<int>(0);
            z.deviceId = row["deviceid"].c_str();
            z.zoneName = row["zonename"].c_str();

            z.startInArea = Zone::PointArea{
                row["startinareax"].as<float>(0.),
                row["startinareay"].as<float>(0.)
            };

            z.endInArea = Zone::PointArea{
                row["endinareax"].as<float>(0.),
                row["endinareay"].as<float>(0.)
            };

            z.endInLine = row["endinline"].as<float>(0.);
            z.zoneFullName = row["zonefullname"].c_str();
            z.startInLine = row["startinline"].as<float>(0.);
            z.lengthInLine = row["lengthinline"].as<float>(0.);
            z.lengthZoneInArea = row["lengthzoneinarea"].as<float>(0.);

            zones.push_back(z);
        }

        return zones;
    }
    catch (const std::exception &e) {
        Logger::cout() << e.what() << std::endl;
        return zones = {};
    }
}


/**
 * \brief Получение списка сенсоров с линиями и зонами.
 */
std::vector <SensorDB> BADataBase::getSensorsDB()
{
    std::vector <SensorDB> sensors;

    if (conn_ == nullptr) {
        Logger::cout() << "Cоединениe не установлено" << std::endl;
        return sensors;
    }

    try {
        pqxx::work txn(*conn_);
        pqxx::result res = txn.exec(Query::selectCursorOn(Table::Sensor));
        pqxx::row row;

        while (res = txn.exec(Query::fetchFromCurrentCursor(Table::Sensor)), !res.empty()) {
            row = res[0];
            SensorDB s;

            s.name = row["sensorname"].c_str();
            s.comment = row["comment"].c_str();
            s.Average = row["average"].as<int>(0);
            s.sensorId = row["sensorid"].as<int>(0);
            s.freqStart = row["freqstart"].as<float>(0.);
            s.fname = row["sensorfname"].c_str();
            s.flagSensorOn = row["flagsensoron"].as<bool>(false);
            s.extraCmdScript = row["extracmdscript"].c_str();
            s.flagUsingSwitch = row["flagusingswith"].as<bool>(false);
            s.swithSensorName = row["switchsensorname"].c_str();
            s.freqStep = row["freqstep"].as<float>(0.);
            s.freqStop = row["freqstop"].as<float>(0.);
            s.sensorLength = row["sensorlength"].as<int>(0);
            s.sensorPointLength = row["sensorpointlength"].as<int>(0);
            //sensorstartpoint
            //sensorendpoint
            s.cwAtt = row["cwatt"].as<int>(0);
            s.apdGain = row["adpgain"].as<int>(0);
            s.pulseGain = row["pulsegain"].as<int>(0);
            s.pulseLength = row["pulselength"].as<int>(0);

            sensors.push_back(s);
        }
        txn.commit();

        std::for_each(sensors.begin(), sensors.end(), [&](SensorDB& s) {
            s.snrLines = getSensorLines(s.sensorId);
            s.snrZones = getSensorZones(s.sensorId);
        });

        return sensors;
    }
    catch (const std::exception &e) {
        Logger::cout() << e.what() << std::endl;
        return sensors = {};
    }
}


/**
 * \brief Получение Свипа сенсора по времени.
 */
SweepLorenzResult BADataBase::getSweepLorenzResult(int sensorId, std::string time)
{
    SweepLorenzResult sw;

    if (conn_ == nullptr) {
        Logger::cout() << "Cоединениe не установлено" << std::endl;
        return sw;
    }

    try {
        pqxx::result res = pqxx::nontransaction(*conn_).exec(Query::selectFrom(Table::Sweep)
            + " WHERE sensorid = "+ pqxx::to_string(sensorId)
            + " AND sweeptime = "+ Query::to_quoted(time)
        );

        pqxx::row row;

        if (!res.empty()) {

            row = res[0];

            sw.sensorId = row["sensorid"].as<int>(0);
            sw.sensorName = row["sensorname"].as<std::string>();
            sw.sweepTime = row["sweeptime"].as<std::string>();
            sw.shc = row["shc"].as<float>(0.);

            pqxx::array_parser parser = row["datalorenz"].as_array();

            std::pair <pqxx::array_parser::juncture, std::string> val;

            while (val = parser.get_next(), val.first != pqxx::array_parser::juncture::done) {
                if (val.first == pqxx::array_parser::juncture::string_value) {
                    sw.dataLorenz.push_back(boost::lexical_cast<double>(val.second));
                }
            }
        }

        return sw;
    }
    catch (const std::exception &e) {
        Logger::cout() << e.what() << std::endl;
        return sw = {};
    }

}


/**
 * \brief Получение списка свипов упорядоченных по времени.
 *
 * \param startTime С какого периода рассматриваются свипы.
 * \param includes Включение свипов с startTime.
 *
 * \return Список из пар (sensorid, timeStamp)
 */
std::vector <std::pair <int, std::string>>
BADataBase::getAllSweepByTime(std::string startTime, const bool includes)
{
    std::vector<std::pair<int, std::string>> ptime;

    if (conn_ == nullptr) {
        Logger::cout() << "Cоединениe не установлено" << std::endl;
        return ptime;
    }

    try {
        pqxx::result res = pqxx::nontransaction(*conn_).exec(
            "SELECT sensorid, sweeptime FROM " + nt::name(Table::Sweep) + (
                startTime.empty()
                ? ""
                : " WHERE sweeptime " + ((includes ? ">=" : ">") + Query::to_quoted(startTime))
            ) + " ORDER BY sweeptime DESC"
        );

        for (auto row : res) {

            int id = row["sensorId"].as<int>(0);
            std::string time = row["sweepTime"].as<std::string>();

            ptime.push_back({ id, time });
        }

        return ptime;
    }
    catch (const std::exception &e) {
        Logger::cout() << e.what() << std::endl;
        return ptime = {};
    }
}


/**
 * \brief Получение списка свипов для конкретного сенсора.
 *
 * \param sensorId Первичный ключ сенсора.
 * \param startTime Время начиная с которого рассматриваются свипы.
 *
 * \return Список пар (sensorid, sweeptime).
 */
std::vector <std::pair <int, std::string>>
BADataBase::sensorListTime(int sensorId, std::string startTime)
{
    std::vector<std::pair<int, std::string>> ptime;

    if (conn_ == nullptr) {
        Logger::cout() << "Cоединениe не установлено" << std::endl;
        return ptime;
    }

    try {
        pqxx::result res = pqxx::nontransaction(*conn_).exec(
            " SELECT sensorid, sweeptime FROM " + nt::name(Table::Sweep)
            + " WHERE sensorid = " + pqxx::to_string(sensorId) + (
                startTime.empty()
                ? ""
                : " AND sweeptime > " + Query::to_quoted(startTime)
            ) + " ORDER BY sweeptime DESC"
        );

        for (auto row : res) {
            int id = row["sensorId"].as<int>(0);
            std::string time = row["sweepTime"].as<std::string>();
            ptime.push_back({ id, time });
        }

        return ptime;
    }
    catch (const std::exception &e) {
        Logger::cout() << e.what() << std::endl;
        return ptime = {};
    }
}

/*
////////////////////////////////////////////////////////////////////////////////////////
/// @brief Сосчитать из JSON файла информацию о сенсорах и актуализировать ее в БД
/// @param jsonFileName - имя json файла
/// @return успешно - true иначе false
bool BADataBase::JsonFileToSensors(const char *jsonFileName)
{
    nlohmann::json snrConf; // создаем пустой документ

    std::ifstream fs;
    fs.open(jsonFileName);

    if (!(fs.is_open())) {
        Logger::cout() << "Don't open: " << jsonFileName << std::endl;
        return false;
    }

    try {
        snrConf = nlohmann::json::parse(fs);
    }
    catch (nlohmann::json::parse_error &ex) {
        Logger::cout() << "parse jsonFile: " << jsonFileName << "Error byte " << ex.byte << std::endl;
        return false;
    }

    fs.close();

    if (snrConf["Sensors"].is_null()) {
        Logger::cout() << "Don't jbject Sensors" << std::endl;
        return false;
    }

    for (auto &jsnr : snrConf["Sensors"]) {

        SensorDB snr = {};
        snr.name = jsnr.value("name", "sensor");               //	короткое имя сенсора
        snr.fname = jsnr.value("fname", "sensor");             // полное имя сенсора
        snr.extraCmdScript = jsnr.value("extraCmdScript", ""); // скрипт для установки дополнительных параметров сенсора
        snr.comment = jsnr.value("comment", "");
        snr.swithSensorName = jsnr.value("swithSensorName", "");
        snr.flagUsingSwitch = jsnr.value<bool>("flagUsingSwitch", 0);
        snr.flagSensorOn = jsnr.value<bool>("flagSensorOn", 0);
        snr.sensorLength = jsnr.value<float>("sensorLength", 0);
        snr.sensorPointLength = jsnr.value<int>("sensorPointLength", 0); // длина сенсора в дискретах
        snr.centralFreq = jsnr.value<float>("centralFreq", 0);           // основная частота
        snr.freqStart = jsnr.value<float>("freqStart", 0);               // начальная частота SWEEP
        snr.freqStop = jsnr.value<float>("freqStop", 0);                 // конечная частота SWEEP
        snr.freqStep = jsnr.value<float>("freqStep", 1);                 // шаг частоты SWEEP
        snr.Average = jsnr.value<int>("Average", 1);                     // колличество усреднений

        snr.pulseLength = jsnr.value<int>("pulseLength", 1);
        snr.pulseGain = jsnr.value<int>("pulseGain", 1);
        snr.cwAtt = jsnr.value<int>("cwAtt", 1);
        snr.apdGain = jsnr.value<int>("apdGain", 1);

        // Logger::cout() << snr.name << std::endl;
        // Logger::cout() << snr.fname << std::endl;
        // Logger::cout() << snr.extraCmdScript << std::endl;
        // Logger::cout() << snr.comment << std::endl;
        // Logger::cout() << snr.sensorLength << " " << jsnr.value<float>("sensorLength",0) << std::endl;

        add(snr);
    }

    return true;
}

////////////////////////////////////////////////////////////////////////////////////////
/// @brief Сосчитать из JSON файла информацию об устройстве и актуализировать ее в БД
/// @param jsonFileName - имя json файла
/// @return успешно - true иначе false
bool BADataBase::JsonFileToBAInfo(const char *jsonFileName)
{

    nlohmann::json jbainfo; // создаем пустой документ

    std::ifstream fs;
    fs.open(jsonFileName);
    if (!(fs.is_open())) {
        Logger::cout() << "Don't open: " << jsonFileName << std::endl;
        return false;
    }

    try {
        jbainfo = nlohmann::json::parse(fs);
    }
    catch (nlohmann::json::parse_error &ex) {
        Logger::cout() << "parse jsonFile: " << jsonFileName << "Error byte " << ex.byte << std::endl;
        return false;
    }

    fs.close();

    BADeviceInfo bainfo;

    bainfo.deviceId = jbainfo.value("deviceId", "3001");
    bainfo.deviceName = jbainfo.value("deviceName", "BA 3001");
    bainfo.adcFreq = jbainfo.value<long>("adcFreq", 250000000L);
    bainfo.startDiscret = jbainfo.value<int>("startDiscret", 100);

    return setDevice(bainfo);
}

*/
