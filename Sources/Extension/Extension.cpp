#include "Extension.hpp"

#include <ShSDK/ShSDK.h>

//
// Include plugins
#include "../Plugins/Level/Level.hpp"

//
// Declare plugins
static Level plugin_8081;

extern "C"
{
	EXTENSION_8081_EXPORT void ExtensionInitialize(void)
	{
		//
		// Initialize plugins
		plugin_8081.Initialize();

		// Register plugins here
		ShApplication::RegisterPlugin(&plugin_8081);
	}

	EXTENSION_8081_EXPORT void ExtensionRelease(void)
	{
		// Release plugins here
		plugin_8081.Release();
	}
}

