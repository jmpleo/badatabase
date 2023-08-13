#include "connmanager.h"
#include "badatabase.h"
#include "logger.h"

using namespace badatabase;

ConnManager::ConnManager()
    : curConn_("")
    , curDevice_()
{

}

ConnManager::~ConnManager() {}

bool ConnManager::connect(std::string connName, size_t attempt)
{
    while (attempt--) {
        Logger::cout() << "Попытка соединения к " + name() << std::endl;
        if (conn().tryConnect(connName)) {
            device() = conn().getBADeviceInfo();
            return true;
        }
    }
    return false;
}

bool ConnManager::connect(BADataBase& conn, size_t attempt)
{
    while (attempt--) {
        Logger::cout() << "Попытка соединения к " + conn.getConnectionName() << std::endl;
        if (conn.tryConnect()) {
            return true;
        }
    }
    return false;
}
