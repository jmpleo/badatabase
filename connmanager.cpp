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

bool ConnManager::touch(std::string connName, size_t attempt)
{
    // Текущее соединение все еще доступно
    if (connName.empty() && available()) {
        return true;
    }
    connName = (connName.empty() ? instance().name() : connName);

    while (attempt--) {
        Logger::cout() << "Попытка соединения к " + connName << std::endl;
        if (instance().curConn_.tryConnect(connName)) {
            instance().curDevice_ = instance().curConn_.getBADeviceInfo();
            return true;
        }
    }
    return false;
}

bool ConnManager::touch(BADataBase& conn, size_t attempt)
{
    while (attempt--) {
        Logger::cout() << "Попытка соединения к " + conn.getConnectionName() << std::endl;
        if (conn.tryConnect()) {
            return true;
        }
    }
    return false;
}
