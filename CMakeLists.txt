cmake_minimum_required(VERSION 3.11)
project(badatabase)

list(APPEND CMAKE_PREFIX_PATH "/usr")
list(APPEND CMAKE_PREFIX_PATH "/usr/lib")
list(APPEND CMAKE_PREFIX_PATH "/usr/lib/x86_64-linux-gnu/")

set(CMAKE_CXX_FLAGS "-std=gnu++20")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(__MAINSQL_PATH ${CMAKE_CURRENT_SOURCE_DIR}/sql/main.sql)

set(Boost_USE_STATIC_LIBS OFF)
set(Boost_USE_MULTITHREADED ON)
set(Boost_USE_STATIC_RUNTIME OFF)

set(LIBRARY_OUTPUT_PATH ${CMAKE_CURRENT_SOURCE_DIR}/lib)

find_package(Boost COMPONENTS system log)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/config.h.in
    ${CMAKE_CURRENT_SOURCE_DIR}/include/config.h)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/babase)

add_subdirectory(src)
add_subdirectory(babase)
