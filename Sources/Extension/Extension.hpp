#ifndef __8081_EXTENSION_HPP
#define __8081_EXTENSION_HPP

#if defined(_WIN32)
#	if defined(Ext8081_EXPORTS)
#		define EXTENSION_8081_EXPORT __declspec(dllexport)
#	else
#		define EXTENSION_8081_EXPORT __declspec(dllimport)
#	endif // Ext8081_EXPORTS
#else // defined(_WIN32)
#	define EXTENSION_8081_EXPORT
#endif

extern "C"
{
	EXTENSION_8081_EXPORT void	ExtensionInitialize		(void);
	EXTENSION_8081_EXPORT void	ExtensionRelease		(void);
}

#endif // __8081_EXTENSION_HPP
