#pragma once

#include "config.h"
#include "logger.h"
#include "namestranslator.h"
#include <boost/lexical_cast.hpp>
#include <pqxx/strconv.hxx>
#include <string>

namespace badatabase {

class Query
{
using str = std::string;
using nt = NamesTranslator;

public:
    static inline str mainSQL() { return instance().mainSQL_; }

    static inline str selectFrom(Table table) { return "SELECT * FROM " + nt::name(table); }

    static inline str deleteFrom(Table, str prKey);
    static inline str selectCursorOn(Table);
    static inline str fetchFromCurrentCursor(Table);
    static inline str fetchAsCompositeFromCurrentCursor(Table);

    template <typename Entity>
    static inline str insertInto(Entity&, InsertMod);
    static inline str insertInto(Table, str record, InsertMod);
    static inline str selectCursorOnZones(int sensorId);
    static inline str selectCursorOnLines(int sensorId);

    static inline str to_quoted (str s) { return "'" + s + "'"; }

    Query(const Query&) = delete;
    Query& operator=(const Query&) = delete;

    static inline void setMainSQLPath(std::string newMaiSQLPath = _DEFAULT_MAINSQL_PATH ) { instance().mainSQL_ = readMainSQL(newMaiSQLPath); }

private:
    template <typename Entity>
    static inline str prepareQueryParam(Entity&)    { return ""; }
    static inline str exec(str func, str paramLine) { return "SELECT " + func + "(" + paramLine + ")"; }

private:
    inline static Query& instance() { static Query instance; return instance; }

    static std::string readMainSQL(std::string pathToMainSQL = _DEFAULT_MAINSQL_PATH);

    Query();
    ~Query();

    std::string mainSQL_;
};


inline std::string Query::selectCursorOnZones(int sensorId)
{
    return exec(nt::cursorFunc(Table::Zone),
        "p_sensorid =>" + std::to_string(sensorId) +
        ",cur_name =>" + to_quoted(nt::cursorName(Table::Zone))
    );
}

inline std::string Query::selectCursorOnLines(int sensorId)
{
    return exec(nt::cursorFunc(Table::Line),
        "p_sensorid =>" + std::to_string(sensorId) +
        ",cur_name =>" + to_quoted(nt::cursorName(Table::Line))
    );
}

inline std::string Query::deleteFrom(Table table, str prKey)
{
    return " DELETE FROM " + nt::name(table) + " WHERE " + nt::primaryKeyOf(table) + "=" + prKey;
}

inline std::string Query::selectCursorOn(Table table)
{
    return exec(nt::cursorFunc(table), to_quoted(nt::cursorName(table)));
}

inline std::string Query::fetchAsCompositeFromCurrentCursor(Table table)
{
    return exec(nt::fetchFunc(table), to_quoted(nt::cursorName(table)));
}

inline std::string Query::fetchFromCurrentCursor(Table table)
{
    return "SELECT * FROM " + nt::fetchFunc(table) + "(" + to_quoted(nt::cursorName(table)) + ")";
}

template <typename T>
inline std::string Query::insertInto(T &entity, InsertMod mod)
{
    return exec(nt::insertFunc(nt::whatEnity(entity), mod), prepareQueryParam(entity));
}

inline std::string Query::insertInto(Table t, str composite, InsertMod mod)
{
    return exec(nt::insertFunc(t, mod), to_quoted(composite));
}

template <>
inline std::string Query::prepareQueryParam<batypes::Sensor>(batypes::Sensor& sensor)
{
    using boost::lexical_cast;
    using pqxx::to_string;

    return
        "p_sensorname =>" + to_quoted( sensor.name ) +
        ",p_sensorfname =>" + to_quoted( sensor.fname ) +
        ",p_flagsensoron =>" + to_string( sensor.flagSensorOn ) +
        ",p_flagusingswith =>" + to_string( sensor.flagUsingSwitch ) +
        ",p_extracmdscript =>" + to_quoted( sensor.extraCmdScript ) +
        ",p_switchsensorname =>" + to_quoted( sensor.swithSensorName ) +
        ",p_average =>" + to_string( sensor.Average ) +
        ",p_freqstart =>" + to_string( sensor.freqStart ) +
        ",p_freqstep =>" + to_string( sensor.freqStep ) +
        ",p_freqstop =>" + to_string( sensor.freqStop ) +
        ",p_sensorlength =>" + lexical_cast<std::string>( sensor.sensorLength )+
        ",p_sensorpointlength =>" + to_string( sensor.sensorPointLength ) +
        ",p_sensorstartpoint =>" + "0" +
        ",p_sensorendpoint =>" + to_string( sensor.sensorPointLength - 1 ) +
        ",p_cwatt =>" + to_string( sensor.cwAtt ) +
        ",p_adpgain =>" + to_string( sensor.apdGain ) +
        ",p_pulsegain =>" + to_string( sensor.pulseGain ) +
        ",p_pulselength =>" + to_string( sensor.pulseLength );
}

template <>
inline std::string Query::prepareQueryParam<batypes::SensorLine>(batypes::SensorLine& line)
{
    using boost::lexical_cast;
    using pqxx::to_string;

    return
        "p_sensorid =>" + to_string( line.sensorId ) +
        ",p_linename =>" + to_quoted( line.lineName ) +
        ",p_linefullname =>" + to_quoted( line.lineFullName ) +
        ",p_linetype =>" + to_string( line.lineType ) +
        ",p_startpoint =>" + to_string( line.startPoint ) +
        ",p_endpoint =>" + to_string( line.endPoint ) +
        ",p_direct =>" + to_string ( line.direct ) +
        ",p_lengthpoints =>" + to_string( line.lengthPoint ) +
        ",p_lengthmeters =>" + to_string( line.lengthMeters ) +
        ",p_mhztemp20 =>" + to_string( line.mhzTemp20 ) +
        ",p_tempcoeff =>" + to_string( line.tempCoeff ) +
        ",p_defcoeff =>" + to_string( line.defCoeff ) +
        ",p_auxlineid =>" + to_string( line.auxLineId );

}

template <>
inline std::string Query::prepareQueryParam<batypes::Zone>(batypes::Zone& zone)
{
    using boost::lexical_cast;
    using pqxx::to_string;

    return
        "p_lineid   =>" + to_string( zone.lineId ) +
        ",p_sensorid =>" + to_string( zone.sensorId ) +
        ",p_deviceid =>" + to_quoted( zone.deviceId ) +
        ",p_zonename =>" + to_quoted( zone.zoneName ) +
        ",p_zonefullname =>" + to_quoted( zone.zoneFullName ) +
        ",p_zonetype =>" + to_string( zone.zoneType ) +
        ",p_direct   =>"   + to_string( zone.direct ) +
        ",p_startinareax =>" + to_string( zone.startInArea.x ) +
        ",p_startinareay =>" + to_string( zone.startInArea.y ) +
        ",p_endinareax =>" + to_string( zone.endInArea.x ) +
        ",p_endinareay =>" + to_string( zone.endInArea.y ) +
        ",p_lengthzoneinarea =>" + to_string( zone.lengthZoneInArea ) +
        ",p_startinline  =>" + to_string( zone.startInLine ) +
        ",p_endinline    =>" + to_string( zone.endInLine ) +
        ",p_lengthinline =>" + to_string( zone.lengthInLine );
}

template <>
inline std::string Query::prepareQueryParam<batypes::BADeviceInfo>(batypes::BADeviceInfo& device)
{
    using boost::lexical_cast;
    using pqxx::to_string;

    return
        "p_deviceid =>" + to_quoted( device.deviceId ) +
        ",p_devicename =>" + to_quoted( device.deviceName ) +
        ",p_adcfreq =>" + to_string( device.adcFreq ) +
        ",p_startdiscret =>" + to_string( device.startDiscret );
}

}
