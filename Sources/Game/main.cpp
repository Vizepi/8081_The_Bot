#include "Game.hpp"

#include "../Plugins/Level/Level.hpp"

//
// Declare plugins
Level plugin_8081;

void RegisterGameCallbacks(void)
{
	ShApplication::SetOnPreInitialize(Game::OnPreInitialize);
	ShApplication::SetOnPostInitialize(Game::OnPostInitialize);
	ShApplication::SetOnPreUpdate(Game::OnPreUpdate);
	ShApplication::SetOnPostUpdate(Game::OnPostUpdate);
	ShApplication::SetOnPreRelease(Game::OnPreRelease);
	ShApplication::SetOnPostRelease(Game::OnPostRelease);

	ShInput::AddOnTouchDown(Game::OnTouchDown);
	ShInput::AddOnTouchUp(Game::OnTouchUp);
	ShInput::AddOnTouchMove(Game::OnTouchMove);

	//ShDisplay::SetFullScreen();
}

void RegisterPlugins(void)
{
	//
	// Initialize plugins
	plugin_8081.Initialize();

	// Register plugins here
	ShApplication::RegisterPlugin(&plugin_8081);
}

#if SH_PC
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE, LPSTR, int)
#else
int main(int argc, char ** argv)
#endif
{
	RegisterGameCallbacks();
	RegisterPlugins();

	ShDisplayProperties displayProperties;

	displayProperties.m_bLandscape			= true;
	displayProperties.m_width           	= 1366;
	displayProperties.m_height          	= 768;

	displayProperties.m_bEnable3d       	= false;
	displayProperties.m_bEnableZ        	= false;
	displayProperties.m_bUseSpecular    	= false;
	displayProperties.m_bUsePointLights 	= false;
	displayProperties.m_bUseShadows			= false;

#if SH_PC
	return(ShMain((void*)&hInstance, displayProperties));
#else
	return(ShMain(argc, argv, displayProperties));
#endif
}

