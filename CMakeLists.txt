cmake_minimum_required(VERSION 3.11)
project(badatabase)

list(APPEND CMAKE_PREFIX_PATH "/usr")
list(APPEND CMAKE_PREFIX_PATH "/usr/lib")
list(APPEND CMAKE_PREFIX_PATH "/usr/lib/x86_64-linux-gnu/")

set(CMAKE_CXX_FLAGS "-std=gnu++20")

set(Boost_USE_STATIC_LIBS OFF)
set(Boost_USE_MULTITHREADED ON)
set(Boost_USE_STATIC_RUNTIME OFF)

set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/lib)

find_package(Boost COMPONENTS system log)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/config.h.in ${CMAKE_CURRENT_SOURCE_DIR}/config.h)

add_library(badatabase SHARED
    badatabase.cpp
    connconfmanager.cpp
    connmanager.cpp
    query.cpp
    batypes/sensor.cpp
    )

include_directories("/usr/include/modbus/")
include_directories(${CMAKE_SOURCE_DIR})

#target_link_libraries(baviewer PRIVATE pthread rt pqxx pq)
