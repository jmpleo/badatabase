#include "query.h"

using namespace badatabase;

Query::Query()
    : mainSQL_(readMainSQL())
{
}

Query::~Query() {}

std::string Query::readMainSQL(std::string pathToMainSQL)
{
    std::ifstream scheme(pathToMainSQL);

    if (!scheme) {
        Logger::cout() << "Не удалось открыть файл со схемой sql: " << pathToMainSQL << std::endl;
        return "";
    }

    std::stringstream buffer;
    buffer << scheme.rdbuf();
    return buffer.str();
}

