cmake_minimum_required(VERSION 3.11)

find_library(babase_LIBRARY NAMES babase PATHS ${BABASE_PATH}/lib)

add_library(badatabase SHARED
    badatabase.cpp
    #query.cpp
    sensor.cpp
    )

target_compile_definitions(badatabase INTERFACE USING_BADATABASE_LIB)


