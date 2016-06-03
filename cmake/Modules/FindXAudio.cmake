#-------------------------------------------------------------------
# This file is part of the CMake build system for OGRE
#     (Object-oriented Graphics Rendering Engine)
# For the latest info, see http://www.ogre3d.org/
#
# The contents of this file are placed in the public domain. Feel
# free to make use of it in any way you like.
#-------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Find XAudio SDK
# Define:
# XAudio_FOUND
# XAudio_INCLUDE_DIR
# XAudio_LIBRARY
# XAudio_ROOT_DIR

if(WIN32) # The only platform it makes sense to check for XAudio SDK
  include(FindPkgMacros)
  findpkg_begin(XAudio)
  
  # Get path, convert backslashes as ${ENV_DXSDK_DIR}
  getenv_path(DXSDK_DIR)
  getenv_path(DirectX_HOME)
  getenv_path(DirectX_ROOT)
  getenv_path(DirectX_BASE)
  
  # construct search paths
  set(XAudio_PREFIX_PATH 
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

  create_search_paths(XAudio)
  # redo search if prefix path changed
  clear_if_changed(XAudio_PREFIX_PATH
    XAudio_LIBRARY
	XAudio_INCLUDE_DIR
  )
  
  # lib files are in XAudio_ROOT_DIR/Lib/x64|x86
  if(CMAKE_CL_64)
    set(XAudio_LIBPATH_SUFFIX "x64")
  else(CMAKE_CL_64)
    set(XAudio_LIBPATH_SUFFIX "x86")
  endif(CMAKE_CL_64)
  find_path(XAudio_INCLUDE_DIR NAMES xaudio2.h HINTS ${XAudio_INC_SEARCH_PATH})
  find_library(XAudio_LIBRARY NAMES X3DAudio HINTS ${XAudio_LIB_SEARCH_PATH} PATH_SUFFIXES ${XAudio_LIBPATH_SUFFIX})

  findpkg_finish(XAudio)
    
endif(WIN32)
