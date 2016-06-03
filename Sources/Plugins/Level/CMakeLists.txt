
include_directories(${SHSDK_INCLUDE_DIRS})

set(SOURCES_PLUGIN_IMPL Level.cpp Level.hpp)
source_group("" FILES ${SOURCES_PLUGIN_IMPL})

set(SOURCES ${SOURCES_PLUGIN_IMPL}
)

# Compile to use it on Runtime
add_library(PluginLevel STATIC ${SOURCES})

set_property(TARGET PluginLevel PROPERTY FOLDER "Runtime")
set_property(TARGET PluginLevel APPEND PROPERTY COMPILE_DEFINITIONS "SH_DEV=1")
set_property(TARGET PluginLevel APPEND PROPERTY COMPILE_DEFINITIONS "SH_MASTER=1")

# Compile to use it in the Shine Editor
add_library(PluginLevel_Editor OBJECT ${SOURCES})
set_property(TARGET PluginLevel_Editor PROPERTY FOLDER "Editor")
set_property(TARGET PluginLevel_Editor APPEND PROPERTY COMPILE_DEFINITIONS "SH_DEV=1")
set_property(TARGET PluginLevel_Editor APPEND PROPERTY COMPILE_DEFINITIONS "SH_MASTER=1" )
set_property(TARGET PluginLevel_Editor APPEND PROPERTY COMPILE_DEFINITIONS "SH_EDITOR=1")
set_property(TARGET PluginLevel_Editor APPEND PROPERTY COMPILE_DEFINITIONS "_INTERNAL_DLL")
set_property(TARGET PluginLevel_Editor APPEND PROPERTY POSITION_INDEPENDENT_CODE True)

