cmake_minimum_required(VERSION 3.16)
project(ray_tracer)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(OpenGL REQUIRED)
find_package(glfw3 REQUIRED)
find_package(assimp REQUIRED)

# ---- GLAD library ----
add_library(glad external/glad/src/glad.c)
target_include_directories(glad PUBLIC external/glad/include)

# ---- Your executable ----
add_executable(ray_tracer
    src/main.cpp
    src/MetalRenderer.mm
)

target_include_directories(ray_tracer PRIVATE 
    external/include
    src
)

target_link_libraries(ray_tracer PRIVATE
    glad
    glfw
    OpenGL::GL
    assimp::assimp
    "-framework Metal"
    "-framework Foundation"
    "-framework Cocoa"
    "-framework IOKit"
)

set_source_files_properties(
    src/MetalRenderer.mm
    PROPERTIES
    COMPILE_FLAGS "-x objective-c++"
)