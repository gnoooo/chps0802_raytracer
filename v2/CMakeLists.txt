cmake_minimum_required(VERSION 3.10)
project(raytracer_cpu)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(${PROJECT_SOURCE_DIR}/include)

add_executable(raytracer_cpu 
    src/main.cpp
    src/vec3.cpp
    src/ray.cpp
    src/sphere.cpp
    src/hittable_list.cpp
    src/camera.cpp)
