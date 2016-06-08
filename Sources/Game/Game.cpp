#include "Game.hpp"
#include <ShSDK\ShSDK.h>
#include "../Plugins/Level/Level.hpp"
#include "../Common/Tools.hpp"

void Game::OnPreInitialize()
{
	//
	// Create camera
	ShCamera * pCamera = ShCamera::Create(GID(global), GID(camera), false);
	SH_ASSERT(NULL != pCamera);

	ShCamera::SetPosition			(pCamera, CShVector3(0.0f, 0.0f, 1000.0f));
	ShCamera::SetTarget				(pCamera, CShVector3(0.0f, 0.0f, 0.0f));
	ShCamera::SetUp					(pCamera, CShVector3(0.0f, 1.0f, 0.0f));
	ShCamera::SetProjectionOrtho	(pCamera);
	ShCamera::SetNearPlaneDistance	(pCamera, 1.0f);
	ShCamera::SetFarPlaneDistance	(pCamera, 2000.0f);

	ShCamera::SetCurrent2D(pCamera);
	Level::SetReleaseEnabled(false);
	Tools::SetReleaseEnabled(false);
}

void Game::OnPostInitialize()
{
	ShLevel::Load(CShIdentifier("test"));
}

void Game::OnPreUpdate(float dts)
{
	
}

void Game::OnPostUpdate(float dts)
{

}

void Game::OnPreRelease()
{
	ShLevel::Release();
}

void Game::OnPostRelease()
{

}

void Game::OnTouchDown(int iTouch, float positionX, float positionY)
{

}

void Game::OnTouchUp(int iTouch, float positionX, float positionY)
{

}

void Game::OnTouchMove(int iTouch, float positionX, float positionY)
{
	// TODO : Comment when fix released
	Level::OnTouchMove(iTouch, positionX, positionY);
}
