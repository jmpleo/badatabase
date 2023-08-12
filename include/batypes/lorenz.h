#pragma once


#include <string>
#include <vector>

namespace batypes {

struct SweepLorenzResult
{
    struct LorenzParams;

    int sensorId;
    std::string sensorName;
    std::string sweepTime;
    float sensorLength;
    int sensorPointLength;
    int sensorStartPoint;
    int sensorEndPoint;
    std::vector<float> dataLorenz;
    std::vector<LorenzParams> dataLorenzParams;
    float shc;

    struct LorenzParams {
        float y0; // смещение
        float  w; // полуширина спектрального максимума
        float  a; // интегральная интенсивность
        float err; // ошибка
    };

};
}

