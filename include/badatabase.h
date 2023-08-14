#pragma once

#include "batypes.h"
#include "connconfmanager.h"
#include "logger.h"
#include "namestranslator.h"
#include "query.h"

#include <exception>
#include <pqxx/connection.hxx>
#include <pqxx/pqxx>
#include <string>

namespace badatabase {

using namespace batypes;
using nt = NamesTranslator;
using CopyMod = InsertMod;


class BADataBase
{
public:
    BADataBase() = delete;
    BADataBase(std::string);
    BADataBase(BADataBase&&) = delete;
    BADataBase(BADataBase const&) = delete;
    BADataBase operator = (BADataBase const&) = delete;
    BADataBase operator = (BADataBase&&);
    ~BADataBase();

    inline std::string getConnectionName() const { return connName_; }

    inline std::string setDevice(BADeviceInfo& d) { return add(d, InsertMod::Force); }

    inline int addZone  (Zone& z,               InsertMod mod = InsertMod::Quiet) { return std::stoi(add(z, mod)); }
    inline int addSensor(Sensor& s,             InsertMod mod = InsertMod::Quiet) { return std::stoi(add(s, mod)); }
    inline int addLine  (SensorLine& l,         InsertMod mod = InsertMod::Quiet) { return std::stoi(add(l, mod)); }
    inline int addSweep (SweepLorenzResult& sw, InsertMod mod = InsertMod::Quiet) { return std::stoi(add(sw, mod)); }

    inline bool delLine  (int lineId)   { return del(std::to_string(lineId),   Table::Line);   }
    inline bool delZone  (int zoneId)   { return del(std::to_string(zoneId),   Table::Zone);   }
    inline bool delSweep (int sweepId)  { return del(std::to_string(sweepId),  Table::Sweep);  }
    inline bool delSensor(int sensorId) { return del(std::to_string(sensorId), Table::Sensor); }

    bool tryConnect (std::string connectionName = "");
    bool copyFrom   (BADataBase &src, Table, CopyMod);

    inline bool isConnected() { return checkScheme(); }

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


//private:
    template <typename Entity> std::string add(Entity&, InsertMod);
    bool del(std::string id, Table);

    bool checkScheme();
    bool setScheme();

//private:
    std::string connName_;
    std::unique_ptr<pqxx::connection> conn_;
};


template <typename T>
std::string BADataBase::add(T &entity, InsertMod mod)
{
    std::string insertedId = "0";

    try {
        pqxx::work txn(*conn_);
        pqxx::result res = txn.exec(Query::insertInto(entity, mod));
        txn.commit();

        insertedId = res[0][0].c_str();

        return insertedId;
    }
    catch (const pqxx::sql_error &e) {
        Logger::cout() << e.what() << std::endl << e.query() << std::endl;
        return insertedId;
    }
    catch (const std::exception &e) {
        Logger::cout() << e.what() << std::endl;
        return insertedId;
    }
}

} // end namespace badatabase
