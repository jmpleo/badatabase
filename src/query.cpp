//#include "query.h"
//#include "config.h"


//using namespace badatabase;

//std::string Query::mainSQL = Query::readMainSQL(_DEFAULT_MAINSQL_PATH);


/*
 * \brief Чтение файла содержащего по большей степени определения серверных
 * процедур.
 *
 * \param pathToMainSQL путь до скрипта.
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
*/

