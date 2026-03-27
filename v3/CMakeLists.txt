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

# ── Tests unitaires ───────────────────────────────────────────────────────────
enable_testing()

add_executable(test_cpu
    tests/test_cpu.cpp
    src/vec3.cpp
    src/ray.cpp
    src/sphere.cpp
    src/hittable_list.cpp
    src/camera.cpp)

target_compile_options(test_cpu PRIVATE -O2)

add_test(NAME test_cpu COMMAND test_cpu)

# make run_tests (depuis v3/build)
add_custom_target(run_tests
    COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
    DEPENDS test_cpu
    COMMENT "Lancement des tests unitaires v3 CPU")

