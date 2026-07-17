cmake_minimum_required(VERSION 3.10)
project(compositor_helper VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Define shared library output
add_library(compositor_helper SHARED compositor_helper.cpp)

# Enable positioning code for shared library
set_target_properties(compositor_helper PROPERTIES POSITION_INDEPENDENT_CODE ON)

# Add compiler optimization flags for system math helper
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    target_compile_options(compositor_helper PRIVATE -O3 -ffast-math)
endif()
