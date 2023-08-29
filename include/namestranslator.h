#pragma once

#include "batypes.h"
#include "batypes/badeviceinfo.h"
#include "batypes/sensor.h"
#include "batypes/zone.h"
#include <pqxx/pqxx>
#include <boost/lexical_cast.hpp>
#include <string>
#include <typeinfo>

namespace badatabase {

enum class Table      { None, Sensor, Line, Zone, Sweep, Device };
enum class InsertMod  { None, Force, Quiet };


/**
 *
 * \brief Класс транслирования сочетаний Table, InsertMod в названия сущностей,
 * первичных ключей, функций БД.
 *
 */
class NamesTranslator
{
using str = std::string;

public:
    inline static str name(Table);
    inline static str primaryKeyOf(Table);

    inline static str cursorName(Table t) { return "cursor_on_"  + name(t); }
    inline static str cursorFunc(Table t) { return "cur_select_" + name(t); }
    inline static str fetchFunc (Table t) { return "fetch_"      + name(t); }

    inline static str insertFunc(Table, InsertMod);

    inline static bool checkTable(str name);

    template <typename T> inline static Table whatEnity(T &enity);
};


template <typename T>
inline Table NamesTranslator::whatEnity(T &entity)
{
    if (typeid(batypes::Zone) == typeid(T))              return Table::Zone;
    if (typeid(batypes::Sensor) == typeid(T))            return Table::Sensor;
    if (typeid(batypes::SensorLine) == typeid(T))        return Table::Line;
    if (typeid(batypes::BADeviceInfo) == typeid(T))      return Table::Device;
    if (typeid(batypes::SweepLorenzResult) == typeid(T)) return Table::Sweep;
    return Table::None;
}


inline bool NamesTranslator::checkTable(str name)
{
    if (name == "sweepdatalorenz") return true;
    if (name == "sensorslines")    return true;
    if (name == "badeviceinfo")    return true;
    if (name == "sensors")         return true;
    if (name == "zones")           return true;
    return false;
}


inline std::string NamesTranslator::insertFunc(Table table, InsertMod mod)
{
    switch (mod) {
        case InsertMod::Force: return "insert_" + name(table) + "_with_update";
        case InsertMod::Quiet: return "insert_" + name(table) + "_without_update";
        default:               return "";
    }
}


inline std::string NamesTranslator::name(Table table)
{
    switch (table) {
        case Table::Line:   return "sensorslines";
        case Table::Sensor: return "sensors";
        case Table::Sweep:  return "sweepdatalorenz";
        case Table::Zone:   return "zones";
        case Table::Device: return "badeviceinfo";
        default:            return "";
    }
}


inline std::string NamesTranslator::primaryKeyOf(Table table)
{
    switch (table) {
        case Table::Line:   return "lineid";
        case Table::Sensor: return "sensorid";
        case Table::Sweep:  return "sweepid";
        case Table::Zone:   return "zoneid";
        case Table::Device: return "deviceid";
        default:            return "";
    }
}

} // end namespace badatabase::namestranslator

