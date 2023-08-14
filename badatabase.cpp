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

BADataBase::~BADataBase() {}

BADataBase::BADataBase(std::string connName)
    : connName_(connName)
    , conn_(nullptr)
{
}

//BADataBase BADataBase::operator=(BADataBase&& other) { return BADataBase(std::move(other)); }

bool BADataBase::tryConnect(std::string connectionName)
{
    try {
        connName_ = connectionName.empty() ? connName_ : connectionName;
        conn_ = std::make_unique<pqxx::connection>(ConnConfManager::getConnectionOptions(connName_));

        //if (checkScheme() || setScheme()) {
        if (setScheme()) {
            Logger::cout() << "Успешное подключение к " + connName_ << std::endl;
            return true;
        }
        else {
            return false;
        }
    }
    catch (const pqxx::broken_connection &e) {
        Logger::cout() << "Не удалось подключиться к " + connName_ << ": " << e.what() << std::endl;
        return false;
    }
    catch (...) {
        return false;
    }
}

bool BADataBase::checkScheme()
{
    try {
        pqxx::result
            tables = pqxx::nontransaction(*conn_).exec(
                " SELECT table_name FROM information_schema.tables"
                " WHERE table_schema = 'public'"
            ),
            functions = pqxx::nontransaction(*conn_).exec(
                " SELECT routine_name FROM information_schema.routines"
                " WHERE routine_schema = 'public'"
            );

        for (auto row : tables) {
            if (nt::checkTable(row["table_name"].c_str()) == false) {
                return false;
            }
        }
        //for (auto row : functions) {
        //    if (nt::checkFunc(row["routine_name"].c_str()) == false) {
        //        return false;
        //    }
        //}
        return true;
    }

    catch (const std::exception &e) {
        Logger::cout() << e.what() << std::endl;
        return false;
    }
}


bool BADataBase::setScheme()
{
    try {
        pqxx::work txn(*conn_);
        txn.exec(Query::mainSQL());
        txn.commit();
        Logger::cout() << "Схема базы данных была успешно обновлена" << std::endl;
        return true;
    }
    catch (const std::exception &e) {
        Logger::cout() << "Не удалось обновить схему соединения " + connName_ << e.what() << std::endl;
        return false;
    }
}


bool BADataBase::copyFrom(BADataBase &src, Table table, CopyMod mod)
{
    if (getBADeviceInfoId() != src.getBADeviceInfoId()) {
        Logger::cout() << "Устройства соединений не совпадают" << std::endl;
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


bool BADataBase::del(std::string prKey, Table table)
{
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

std::string BADataBase::getBADeviceInfoId()
{
    std::string id = ConnConfManager::getDevice(connName_);
    if (id.empty()) { return getBADeviceInfo().deviceId; }
    return id;
}


BADeviceInfo BADataBase::getBADeviceInfo()
{
    BADeviceInfo device;

    try {
        pqxx::result res = pqxx::nontransaction(*conn_).exec(Query::selectFrom(Table::Device));

        device.deviceId = res[0]["deviceid"].c_str();
        device.deviceName = res[0]["devicename"].c_str();
        device.adcFreq = res[0]["adcfreq"].as<long>();
        device.startDiscret = res[0]["startdiscret"].as<int>();

        ConnConfManager::setDevice(connName_, device.deviceId);

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


std::vector <SensorLine> BADataBase::getSensorLines(int sensorId)
{
    std::vector <SensorLine> lines;

    try {
        pqxx::work txn(*conn_);
        pqxx::result res = txn.exec(Query::selectCursorOnLines(sensorId));

        pqxx::row row;

        while (res = txn.exec(Query::fetchFromCurrentCursor(Table::Line)), !res.empty()) {

            row = res[0];
            SensorLine l;

            l.direct = row["direct"].as<int>();
            l.lineId = row["lineid"].as<int>();
            l.lineName = row["linename"].c_str();
            l.sensorId = row["sensorid"].as<int>();
            l.lineType = row["linetype"].as<int>();
            l.defCoeff = row["defcoeff"].as<float>();
            l.endPoint = row["endpoint"].as<int>();
            l.mhzTemp20 = row["mhztemp20"].as<float>();
            l.tempCoeff = row["tempcoeff"].as<float>();
            l.auxLineId = row["auxlineid"].as<int>();
            l.startPoint = row["startpoint"].as<int>();
            l.lengthPoint = row["lengthpoints"].as<int>();
            l.lengthMeters = row["lengthmeters"].as<float>();
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


std::vector <Zone> BADataBase::getSensorZones(int sensorId)
{
    std::vector <Zone> zones;

    try {
        pqxx::work txn(*conn_);
        pqxx::result res = txn.exec(Query::selectCursorOnZones(sensorId));

        pqxx::row row;

        while (res = txn.exec(Query::fetchFromCurrentCursor(Table::Zone)), !res.empty()) {

            row = res[0];
            Zone z;

            z.direct = row["direct"].as<int>();
            z.zoneId = row["zoneid"].as<int>();
            z.lineId = row["lineid"].as<int>();
            z.sensorId = row["sensorid"].as<int>();
            z.zoneType = row["zonetype"].as<int>();
            z.deviceId = row["deviceid"].c_str();
            z.zoneName = row["zonename"].c_str();

            z.startInArea = Zone::PointArea{
                row["startinareax"].as<float>(),
                row["startinareay"].as<float>()
            };

            z.endInArea = Zone::PointArea{
                row["endinareax"].as<float>(),
                row["endinareay"].as<float>()
            };

            z.endInLine = row["endinline"].as<float>();
            z.zoneFullName = row["zonefullname"].c_str();
            z.startInLine = row["startinline"].as<float>();
            z.lengthInLine = row["lengthinline"].as<float>();
            z.lengthZoneInArea = row["lengthzoneinarea"].as<float>();

            zones.push_back(z);
        }

        return zones;
    }
    catch (const std::exception &e) {
        Logger::cout() << e.what() << std::endl;
        return zones = {};
    }
}


std::vector <SensorDB> BADataBase::getSensorsDB()
{
    std::vector <SensorDB> sensors;

    try {
        pqxx::work txn(*conn_);
        pqxx::result res = txn.exec(Query::selectCursorOn(Table::Sensor));
        pqxx::row row;

        while (res = txn.exec(Query::fetchFromCurrentCursor(Table::Sensor)), !res.empty()) {
            row = res[0];
            SensorDB s;

            s.name = row["sensorname"].c_str();
            s.comment = row["comment"].c_str();
            s.Average = row["average"].as<int>();
            s.sensorId = row["sensorid"].as<int>();
            s.freqStart = row["freqstart"].as<float>();
            s.fname = row["sensorfname"].c_str();
            s.flagSensorOn = row["flagsensoron"].as<bool>();
            s.extraCmdScript = row["extracmdscript"].c_str();
            s.flagUsingSwitch = row["flagusingswith"].as<bool>();
            s.swithSensorName = row["switchsensorname"].c_str();
            s.freqStep = row["freqstep"].as<float>();
            s.freqStop = row["freqstop"].as<float>();
            s.sensorLength = row["sensorlength"].as<int>();
            s.sensorPointLength = row["sensorpointlength"].as<int>();
            //sensorstartpoint
            //sensorendpoint
            s.cwAtt = row["cwatt"].as<int>();
            s.apdGain = row["adpgain"].as<int>();
            s.pulseGain = row["pulsegain"].as<int>();
            s.pulseLength = row["pulselength"].as<int>();

            s.snrLines = getSensorLines(s.sensorId);
            s.snrZones = getSensorZones(s.sensorId);

            sensors.push_back(s);
        }

        return sensors;
    }
    catch (const std::exception &e) {
        Logger::cout() << e.what() << std::endl;
        return sensors = {};
    }
}


SweepLorenzResult BADataBase::getSweepLorenzResult(int sensorId, std::string time)
{
    SweepLorenzResult sw;

    try {
        pqxx::result res = pqxx::nontransaction(*conn_).exec(Query::selectFrom(Table::Sweep)
            + " WHERE sensorid = "+ pqxx::to_string(sensorId)
            + " AND sweeptime = "+ Query::to_quoted(time)
        );

        pqxx::row row;

        if (!res.empty()) {

            row = res[0];

            sw.sensorId = row["sensorid"].as<int>();
            sw.sensorName = row["sensorname"].as<std::string>();
            sw.sweepTime = row["sweeptime"].as<std::string>();
            sw.shc = row["shc"].as<float>();

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


std::vector <std::pair <int, std::string>>
BADataBase::getAllSweepByTime(std::string startTime, const bool includes)
{
    std::vector<std::pair<int, std::string>> ptime;

    try {
        pqxx::result res = pqxx::nontransaction(*conn_).exec(
            "SELECT sensorid, sweeptime FROM " + nt::name(Table::Sweep) + (
                startTime.empty()
                ? ""
                : " WHERE sweeptime " + ((includes ? ">=" : ">") + Query::to_quoted(startTime))
            ) + " ORDER BY sweeptime DESC"
        );

        for (auto row : res) {

            int id = row["sensorId"].as<int>();
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

std::vector <std::pair <int, std::string>>
BADataBase::sensorListTime(int sensorId, std::string startTime)
{
    std::vector<std::pair<int, std::string>> ptime;

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
            int id = row["sensorId"].as<int>();
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

////////////////////////////////////////////////////////////////////////////////////////
/// @brief Сосчитать из JSON файла информацию о сенсорах и актуализировать ее в БД
/// @param jsonFileName - имя json файла
/// @return успешно - true иначе false
/*
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
