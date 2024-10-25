cmake_minimum_required(VERSION 3.15)
project(weird_crypter CXX ASM)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_FLAGS "-no-pie -s")


set_source_files_properties(src/encrypt.s PROPERTIES COMPILE_FLAGS "-x assembler-with-cpp")
add_executable(${PROJECT_NAME} src/main.cc src/encrypt.s)
set_property(TARGET ${PROJECT_NAME} PROPERTY POSITION_INDEPENDENT_CODE FALSE)
