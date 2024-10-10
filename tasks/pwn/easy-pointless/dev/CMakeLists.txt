cmake_minimum_required(VERSION 3.15)
project(pointless C)


set(CMAKE_C_FLAGS "-no-pie")


add_executable(${PROJECT_NAME} src/pointless.c)
set_property(TARGET ${PROJECT_NAME} PROPERTY POSITION_INDEPENDENT_CODE FALSE)

