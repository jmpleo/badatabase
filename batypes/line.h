#pragma once


#include <string>
#include <vector>

namespace batypes {

struct Zone;

struct SensorLine
{
    enum linetype { notdet, temp, def };
    enum direct   { forward, reverse  };

    int             lineId;         // ID линии в базе
    int             sensorId;       // ID сенсора в базе
    std::string     lineName;       // имя линии
    std::string     lineFullName;   // описание линии
    int             lineType;       // тип линии enum linetype
    int             direct;         // направление линии enum direct
    int             startPoint;     // дискрет начала
    int             endPoint;       // дискрет конца
    int             lengthPoint;    // длина в дискретах
    float           lengthMeters;   // длина в метрах
    double          mhzTemp20;      // значение в Mhz при 20C
    double          tempCoeff;      // температурный коэффициент
    double          defCoeff;       // деформационный коэффициент
    int             auxLineId;      // если 0, то вспомогательная линия не определена
    std::vector<Zone>   zones;      // вектор зон линии

};
}
