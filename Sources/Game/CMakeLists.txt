
# Enable Address Sanitizer
if (UNIX)
	option(ENABLE_ASAN "Enable address sanitizer" ON)

	if (ENABLE_ASAN)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address")
	endif (ENABLE_ASAN)
endif(UNIX)

include_directories(${SHSDK_INCLUDE_DIRS})

set(SOURCES_MAIN main.cpp)
source_group("" FILES ${SOURCES_MAIN})

set(SOURCES_GAME Game.cpp Game.hpp)
source_group("Game" FILES ${SOURCES_GAME})

add_executable(8081 WIN32 ${SOURCES_MAIN} ${SOURCES_GAME})
set_property(TARGET 8081 APPEND PROPERTY COMPILE_DEFINITIONS "SH_DEV=1")
set_property(TARGET 8081 APPEND PROPERTY COMPILE_DEFINITIONS "SH_MASTER=1")

target_link_libraries(8081 PluginLevel) # link with plugins

target_link_libraries(8081 ${SHSDK_LIBRARIES} ${SHSDK_LIB_DIR}/StubUserSystem.lib)


