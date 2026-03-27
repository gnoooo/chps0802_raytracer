cmake_minimum_required(VERSION 3.18)
project(raytracer_v3_cuda LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# Architecture GPU — GH200 = sm_90 ; adaptez si besoin (A100 → 80, V100 → 70)
set(CMAKE_CUDA_ARCHITECTURES 90)

set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -O3 --use_fast_math")

include_directories(${PROJECT_SOURCE_DIR}/include)

# GPU : seul main.cu (vec3/ray/camera sont maintenant header-only)
# sphere.cpp et hittable_list.cpp ne sont pas nécessaires pour le rendu GPU
add_executable(raytracer_gpu src/main.cu)
