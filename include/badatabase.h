#pragma once

#include "babase.h"
#include "batypes.h"
#include "logger.h"
#include "namestranslator.h"
#include "query.h"

#include <exception>
#include <pqxx/connection.hxx>
#include <pqxx/pqxx>
#include <string>
#include <charconv>

namespace badatabase {

using namespace babase;
using namespace batypes;

using nt = NamesTranslator;
using CopyMod = InsertMod;


/**
 * \brief Класс взаимодействия с базой данных типа ba.
 *
 * База данных состоит из таблиц: sensors, sensorslines, zones, sweepdatalorenz,
 * badeviceinfo. Объект BADataBase реализует необходимые для работы с
 * соединением методы базового класса BABase: setScheme(), isConnected().
 *
 */
class BADataBase : public BABase
{
public:
    BADataBase() : BABase() {}
    BADataBase(std::string connName) : BABase(connName) {}

    bool isConnected() override;

    //std::string setDevice(BADeviceInfo& d) { return add(d, InsertMod::Force); }

    int addZone  (Zone& z,               InsertMod mod = InsertMod::Quiet) { return add(z, mod); } // { try { return std::stoi(add(z, mod));  } catch (...) { return 0; } }
    int addSensor(Sensor& s,             InsertMod mod = InsertMod::Quiet) { return add(s, mod); } // { try { return std::stoi(add(s, mod));  } catch (...) { return 0; } }
    int addLine  (SensorLine& l,         InsertMod mod = InsertMod::Quiet) { return add(l, mod); } // { try { return std::stoi(add(l, mod));  } catch (...) { return 0; } }
    int addSweep (SweepLorenzResult& sw, InsertMod mod = InsertMod::Quiet) { return add(sw, mod); } // { try { return std::stoi(add(sw, mod)); } catch (...) { return 0; } }


    bool delLine  (int lineId)   { return del(std::to_string(lineId),   Table::Line);   }
    bool delZone  (int zoneId)   { return del(std::to_string(zoneId),   Table::Zone);   }
    bool delSweep (int sweepId)  { return del(std::to_string(sweepId),  Table::Sweep);  }
    bool delSensor(int sensorId) { return del(std::to_string(sensorId), Table::Sensor); }

    bool copyFrom   (BADataBase &src, Table, CopyMod);

    std::vector <SensorLine> getSensorLines(int sensorId);
    std::vector <Zone>       getSensorZones(int sensorId);
    std::vector <SensorDB>   getSensorsDB();
    BADeviceInfo             getBADeviceInfo();
    std::string              getBADeviceInfoId();
    SweepLorenzResult        getSweepLorenzResult(int sensorId, std::string time);


    std::vector <std::pair <int, std::string>>
    getAllSweepByTime(std::string startTime = "" , const bool includes = true);


    std::vector <std::pair <int, std::string>>
    sensorListTime(int sensorId, std::string startTime="");


    //bool JsonFileToSensors(const char* jsonFileName);
    //bool JsonFileToBAInfo(const char* jsonFileName);


private:
    template <typename Entity> int add(Entity&, InsertMod);
    bool del(std::string id, Table);
    bool setScheme() override;
};

/**
 *  \brief Метод добавления абстрактной сущности.
 *
 *  Поддерживаются только сущности типа Sensor, SensorLine, Zone, BADeviceInfo.
 *
 * \param entity Одна из описанных сущностей, добавляемая в таблицу.
 * \param mod Режим вставки: Force - обновить, если существует, Quiet - доавить
 * только если отсутствует (по первичному ключу и ограничениям).
 */
template <typename T>
int BADataBase::add(T &entity, InsertMod mod)
{
    int id = 0;

    if (conn_ == nullptr) {
        Logger::cout() << "Cоединениe не установлено" << std::endl;
        return id;
    }

    try {
        pqxx::work txn(*conn_);
        pqxx::result res = txn.exec(Query::insertInto(entity, mod));
        txn.commit();

        id = std::stoi(res[0][0].as<std::string>());
    }
    catch (const pqxx::sql_error &e) {
        Logger::cout() << e.what() << std::endl << e.query() << std::endl;
    }
    catch (const std::exception &e) {
        Logger::cout() << e.what() << std::endl;
    }

    return id;
}

} // end namespace badatabase
