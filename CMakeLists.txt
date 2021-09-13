# Copyright (c) 2021, Cyrille Favreau
# All rights reserved. Do not distribute without permission.
# Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
#
# This file is part of https://github.com/favreau/Brayns-UC-SDF

# ==============================================================================
# Project
# ==============================================================================
cmake_minimum_required(VERSION 3.1 FATAL_ERROR)
set(NAME SDF)
set(LIBRARY_NAME SDF)
project(${NAME} VERSION 0.1.0)
set(${NAME}_VERSION_ABI 1)

# ==============================================================================
# Packages and settings
# ==============================================================================
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/CMake)
set(BRAYNS_RESEARCH_MODULES_DIR ${PROJECT_SOURCE_DIR})
set(CMAKE_CXX_STANDARD 14) # C++ 14

find_package(Brayns REQUIRED SYSTEM)
find_package(ospray REQUIRED SYSTEM)

include(ispc)

include_directories(${PROJECT_SOURCE_DIR}/core)

# ==============================================================================
# Sources
# ==============================================================================
set(${NAME}_SOURCES
    core/module/ispc/renderer/SdfRenderer.cpp
    core/plugin/SDFPlugin.cpp
)

set(${NAME}_ISPC_SOURCES
    core/module/ispc/renderer/SdfRenderer.ispc
    core/module/ispc/renderer/Glsl.ispc
    core/module/ispc/renderer/Sdf.ispc
)

# ==============================================================================
# Compile ispc code
# ==============================================================================
list(APPEND CMAKE_MODULE_PATH ${OSPRAY_CMAKE_ROOT})
list(APPEND ALL_ISPC_INCLUDES ${${NAME}_MODULES_DIR})
list(APPEND ALL_ISPC_INCLUDES ${OSPRAY_INCLUDE_DIRS})
list(APPEND ALL_ISPC_INCLUDES ${GLM_INCLUDE_DIRS})
include_directories_ispc(${ALL_ISPC_INCLUDES})
ospray_ispc_compile(${${NAME}_ISPC_SOURCES})
list(APPEND ${NAME}_SOURCES ${ISPC_OBJECTS})

# ==============================================================================
# Compile C++ code
# ==============================================================================
include_directories(${BRAYNS_RESEARCH_MODULES_DIR} ${OSPRAY_INCLUDE_DIRS})
set(${NAME}_LINK_LIBRARIES
    PUBLIC ${OSPRAY_LIBRARIES}
    PRIVATE braynsOSPRayEngine braynsPluginAPI
)
add_library(${LIBRARY_NAME} SHARED ${${NAME}_SOURCES})
target_link_libraries(${LIBRARY_NAME} ${${NAME}_LINK_LIBRARIES})

# ==============================================================================
# Install binaries
# ==============================================================================
install(TARGETS ${LIBRARY_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)
