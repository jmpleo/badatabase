#pragma once


#include "logger.h"
#include "config.h"
#include <map>
#include <nlohmann/detail/iterators/iteration_proxy.hpp>
#include <nlohmann/detail/meta/type_traits.hpp>
#include <nlohmann/json.hpp>
#include <nlohmann/json_fwd.hpp>
#include <string>
#include <vector>

namespace badatabase {

class ConnConfManager
{
    using mapped_param = std::map <std::string, std::string>;

public:
    ConnConfManager(const ConnConfManager&) = delete;
    ConnConfManager& operator=(const ConnConfManager&) = delete;

    static void        setConnectionOptions(std::string connName, std::string paramsLine);
    static void        setDevice           (std::string connName, std::string id);
    static void        removeConnection    (std::string connName);
    static inline bool connectionExists    (std::string connName) { return !getConnectionOptions(connName).empty(); }
    static std::string getConnectionOptions(std::string connName);
    static std::string getDevice           (std::string connName);
    static std::string rollupOptions       (mapped_param);

    static inline mapped_param getSplitedConnectionOptions(std::string connName) { return splitOptions(getConnectionOptions(connName)); }
    static        mapped_param splitOptions               (std::string optionsLine);

    static std::vector<std::string> getConnectionsList();

    static inline void setConfigPath(std::string newConfigPath = _DEFAULT_DB_CONFIG_PATH) { instance().configPath_ = newConfigPath; }

private:
    inline static ConnConfManager& instance() { static ConnConfManager instance; return instance; }

    void updateState();
    void updateConfig();

    ConnConfManager();
    ~ConnConfManager();

private:
    nlohmann::json jconfigState_;
    std::string configPath_;
};

inline std::string ConnConfManager::rollupOptions(std::map<std::string, std::string> splitedOpt)
{
    std::string paramLine;
    for (auto &opt : splitedOpt) { paramLine += (" " + opt.first + "=" + opt.second); }
    return paramLine;
}

}
