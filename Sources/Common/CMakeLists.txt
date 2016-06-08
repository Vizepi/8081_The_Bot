cmake_minimum_required(VERSION 2.6)

include_directories(${SHSDK_INCLUDE_DIRS})

project(Common)

set(SOURCES_ANIMATION Animation.hpp Animation.cpp)
source_group("Animation" FILES ${SOURCES_ANIMATION})

set(SOURCES_TOOLS Tools.hpp Tools.cpp)
source_group("Tools" FILES ${SOURCES_TOOLS})

set(SOURCES_INPUT Input.hpp Input.cpp)
source_group("Input" FILES ${SOURCES_INPUT})

set(SOURCES 
	${SOURCES_ANIMATION} 
	${SOURCES_TOOLS}
	${SOURCES_INPUT}
)

add_library(Common STATIC ${SOURCES})
set_property(TARGET Common APPEND PROPERTY COMPILE_DEFINITIONS "SH_DEV=1")
set_property(TARGET Common APPEND PROPERTY COMPILE_DEFINITIONS "SH_MASTER=1")
