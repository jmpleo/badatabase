#include "connconfmanager.h"
#include "logger.h"
#include "config.h"
#include <fstream>
#include <nlohmann/json_fwd.hpp>
#include <sstream>
#include <string>
#include <regex>
#include <vector>

using namespace badatabase;

ConnConfManager::ConnConfManager()
    : jconfigState_()
    , configPath_(_DEFAULT_DB_CONFIG_PATH)
{
    updateState();
}

ConnConfManager::~ConnConfManager()
{

}

void ConnConfManager::updateState()
{
    std::ifstream f(configPath_);
    if (f.is_open() == false) {
        Logger::cout() << "Не удалось открыть файл конфигурации: " << configPath_ << std::endl;
        return;
    }

    try {
        f >> jconfigState_;
    }
    catch (nlohmann::json::parse_error &ex) {
        Logger::cout() << "parse json: " << configPath_ << " error byte " << ex.byte << std::endl;
    }
    f.close();
}

void ConnConfManager::updateConfig()
{
    std::ofstream f(configPath_);
    if (f.is_open() == false) {
        Logger::cout() << "Не удалось открыть файл конфигурации: " << configPath_ << std::endl;
        return;
    }

    f << jconfigState_.dump(4);
    f.close();
}

void ConnConfManager::removeConnection(std::string connName)
{
    try {
        instance().jconfigState_.at("connections").erase(connName);
        instance().updateConfig();
    }
    catch (nlohmann::json::type_error &ex) {
        Logger::cout() << ex.what() << std::endl;
    }
    catch (nlohmann::json::out_of_range &ex) {
        Logger::cout() << ex.what() << std::endl;
    }
}


void ConnConfManager::setConnectionOptions(std::string connName, std::string paramsLine)
{
    instance().jconfigState_["connections"][connName]["options"] = paramsLine;
    instance().updateConfig();
}

void ConnConfManager::setDevice(std::string connName, std::string id)
{
    instance().jconfigState_["connections"][connName]["device"] = id;
    instance().updateConfig();
}

std::string ConnConfManager::getDevice(std::string connName)
{
    //instance().updateState();
    std::string id;
    try {
        id = instance().jconfigState_
            .at("connections")
            .at(connName)
            .at("device")
            .get<std::string>();
    }
    catch (nlohmann::json::type_error &ex) {
        Logger::cout() << ex.what() << std::endl;
    }
    catch (nlohmann::json::out_of_range &ex) {
        Logger::cout() << ex.what() << std::endl;
    }
    return id;
}


std::string ConnConfManager::getConnectionOptions(std::string connName)
{
    //instance().updateState();
    std::string paramLine;
    try {
        paramLine = instance().jconfigState_
            .at("connections")
            .at(connName)
            .at("options")
            .get<std::string>();
    }
    catch (nlohmann::json::type_error &ex) {
        Logger::cout() << ex.what() << std::endl;
    }
    catch (nlohmann::json::out_of_range &ex) {
        Logger::cout() << ex.what() << std::endl;
    }
    return paramLine;
}

std::vector<std::string> ConnConfManager::getConnectionsList()
{
    //instance().updateState();
    std::vector<std::string> connectionList;
    try {
        for (auto &conn : instance().jconfigState_.at("connections").items()) {
            Logger::cout() << "Нашлось соединение: " << conn.key() << std::endl;
            connectionList.push_back(conn.key());
        }
    }
    catch (nlohmann::json::type_error &ex) {
        Logger::cout() << ex.what() << std::endl;
    }
    catch (nlohmann::json::out_of_range &ex) {
        Logger::cout() << ex.what() << std::endl;
    }
    return connectionList;
}


std::map <std::string, std::string> ConnConfManager::splitOptions(std::string paramsLine)
{
    std::map<std::string, std::string> params;

    std::istringstream iss(paramsLine);
    std::string key, param, value;
    std::regex pattern("\\s*(\\w+)\\s*=\\s*(\\S+)\\s*");

    std::smatch match;
    std::string::const_iterator searchStart(paramsLine.cbegin());
    while (std::regex_search(searchStart, paramsLine.cend(), match, pattern)) {
        params[match[1]] = match[2];
        //std::cout << match[1] << " = " << match[2] << std::endl;
        searchStart = match.suffix().first;
    }
    return params;
}
