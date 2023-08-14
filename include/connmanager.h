#pragma once


#include "badatabase.h"
#include "batypes/badeviceinfo.h"
#include "logger.h"
#include <cstddef>
#include <memory>


namespace badatabase {

class ConnManager
{
public:
    ConnManager(const ConnManager&) = delete;
    ConnManager& operator=(const ConnManager&) = delete;

    static inline std::string name() { return instance().curConn_.getConnectionName(); }
    static inline bool available()   { return instance().curConn_.isConnected(); }

    static bool connect(BADataBase&, size_t attempt = 1);

    static inline bool touch(                      size_t attempt = 1) { return        available() ? true           : connect(name(),   attempt); }
    static inline bool touch(std::string connName, size_t attempt = 1) { return connName == name() ? touch(attempt) : connect(connName, attempt); }

    static inline BADataBase&     conn() { return instance().curConn_;   }
    static inline BADeviceInfo& device() { return instance().curDevice_; }

private:
    static ConnManager& instance() { static ConnManager instance; return instance; }
    static bool connect(std::string, size_t);

    ConnManager();
    ~ConnManager();

    BADataBase curConn_;
    BADeviceInfo curDevice_;
};

}
