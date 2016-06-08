
include_directories(${SHSDK_INCLUDE_DIRS})

set(SOURCES_LEVEL Level.cpp Level.hpp)
source_group("Level" FILES ${SOURCES_LEVEL})

set(SOURCES_GROUND Ground.cpp Ground.hpp)
source_group("Ground" FILES ${SOURCES_GROUND})

set(SOURCES_LEVELLOADER LevelLoader.cpp LevelLoader.hpp)
source_group("LevelLoader" FILES ${SOURCES_LEVELLOADER})

set(SOURCES_CHARACTER Character.cpp Character.hpp)
source_group("Character" FILES ${SOURCES_CHARACTER})

set(SOURCES 
	${SOURCES_LEVEL}
	${SOURCES_GROUND}
	${SOURCES_LEVELLOADER}
	${SOURCES_CHARACTER}
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

