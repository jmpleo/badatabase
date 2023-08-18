#pragma once


#include <string>

namespace batypes {

struct Zone
{
    struct PointArea { float x; float y; };

    int                 zoneId; // идентификатор зоны в БД
    int              extZoneId; // внешний идентификатор зоны в БД
    int                 lineId; // идентификатор линии
    int               sensorId; // идентификатор сенсора
    std::string       deviceId; // идентификатор устройства

    std::string       zoneName; // наименоывнине зоны
    std::string   zoneFullName; // полное наименоывнине зоны
    int               zoneType; // тип зоны
    int                 direct; // направление

    PointArea      startInArea; // Точка начала зоны в области
    PointArea        endInArea; // Точка окончания зоны в области
    float     lengthZoneInArea; // длина зоны в метрах в области


    float          startInLine; // начало зоны в основной линии
    float            endInLine; // конец зоны в основной линии
    float         lengthInLine; // длина зоны в линии

};
}


