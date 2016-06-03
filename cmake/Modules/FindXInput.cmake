#-------------------------------------------------------------------
# This file is part of the CMake build system for OGRE
#     (Object-oriented Graphics Rendering Engine)
# For the latest info, see http://www.ogre3d.org/
#
# The contents of this file are placed in the public domain. Feel
# free to make use of it in any way you like.
#-------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Find XInput SDK
# Define:
# XInput_FOUND
# XInput_INCLUDE_DIR
# XInput_LIBRARY
# XInput_ROOT_DIR

if(WIN32) # The only platform it makes sense to check for XInput SDK
  include(FindPkgMacros)
  findpkg_begin(XInput)
  
  # Get path, convert backslashes as ${ENV_DXSDK_DIR}
  getenv_path(DXSDK_DIR)
  getenv_path(DirectX_HOME)
  getenv_path(DirectX_ROOT)
  getenv_path(DirectX_BASE)
  
  # construct search paths
  set(XInput_PREFIX_PATH 
    "${DXSDK_DIR}" "${ENV_DXSDK_DIR}"
    "${DIRECTX_HOME}" "${ENV_DIRECTX_HOME}"
    "${DIRECTX_ROOT}" "${ENV_DIRECTX_ROOT}"
    "${DIRECTX_BASE}" "${ENV_DIRECTX_BASE}"
    "C:/apps_x86/Microsoft DirectX SDK*"
    "C:/Program Files (x86)/Microsoft DirectX SDK*"
    "C:/apps/Microsoft DirectX SDK*"
    "C:/Program Files/Microsoft DirectX SDK*"
	"$ENV{ProgramFiles}/Microsoft DirectX SDK*"
  )

  create_search_paths(XInput)
  # redo search if prefix path changed
  clear_if_changed(XInput_PREFIX_PATH
    XInput_LIBRARY
	XInput_INCLUDE_DIR
  )
  
  # lib files are in XInput_ROOT_DIR/Lib/x64|x86
  if(CMAKE_CL_64)
    set(XInput_LIBPATH_SUFFIX "x64")
  else(CMAKE_CL_64)
    set(XInput_LIBPATH_SUFFIX "x86")
  endif(CMAKE_CL_64)
  find_path(XInput_INCLUDE_DIR NAMES XInput.h HINTS ${XInput_INC_SEARCH_PATH})
  find_library(XInput_LIBRARY NAMES XInput HINTS ${XInput_LIB_SEARCH_PATH} PATH_SUFFIXES ${XInput_LIBPATH_SUFFIX})
  find_library(XInput_DINPUT8_LIBRARY NAMES dinput8 HINTS ${XInput_LIB_SEARCH_PATH} PATH_SUFFIXES ${XInput_LIBPATH_SUFFIX})
  find_library(XInput_DXGUID_LIBRARY NAMES dxguid HINTS ${XInput_LIB_SEARCH_PATH} PATH_SUFFIXES ${XInput_LIBPATH_SUFFIX})

  findpkg_finish(XInput)
  set(XInput_LIBRARIES ${XInput_LIBRARIES} 
    ${XInput_DINPUT8_LIBRARY}
	${XInput_DXGUID_LIBRARY}
  )
  
  mark_as_advanced(XInput_DINPUT8_LIBRARY XInput_DXGUID_LIBRARY) 
  
endif(WIN32)
