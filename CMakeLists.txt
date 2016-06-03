cmake_minimum_required(VERSION 3.2.1)

project(Bobi_The_Bot)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# Enable C++11
set(CMAKE_CXX_STANDARD 11)

# Disable exceptions
if (MSVC)
	string(REPLACE "/EHsc" "/EHs-c-" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
else (MSVC)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-exceptions")
endif (MSVC)

# Disable RTTI
if (MSVC)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /GR-")
else (MSVC)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-rtti")
endif (MSVC)

# Set Warning levels
if (MSVC)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_CRT_SECURE_NO_WARNINGS /wd4800")
else (MSVC)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")
endif (MSVC)

# Find the Shine Engine SDK
set(SHSDK_INCLUDE_DIR "../../Include" CACHE PATH "Shine include directory")
set(SHSDK_LIB_DIR "../../Lib" CACHE PATH "Shine libraries directory")
find_package(ShSDK)

# recurse into subdirectory
add_subdirectory(Sources)
