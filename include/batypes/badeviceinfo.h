#pragma once


#include <string>

namespace batypes {

struct BADeviceInfo
{
    std::string     deviceId;// = "3001";
    std::string   deviceName;// = "БА 3001";
    long             adcFreq;// = 250000000;
    int         startDiscret;// = 876;
};
}

