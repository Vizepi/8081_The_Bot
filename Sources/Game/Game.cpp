#include "Game.hpp"
#include <ShSDK\ShSDK.h>
#include "../Plugins/Level/Level.hpp"

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
}
ShEntity2* character = shNULL;
ShInput* up = shNULL, *down = shNULL, *left = shNULL, *right = shNULL;
ShCharacterController* controller = shNULL;
void Game::OnPostInitialize()
{
	ShLevel::Load(CShIdentifier("test"));
	character = ShEntity2::Create(
		CShIdentifier("test"), 
		CShIdentifier("character"), 
		CShIdentifier("layer_default"), 
		CShIdentifier("bobi"), 
		CShIdentifier("character_top_0"),
		CShVector3_ZERO, 
		CShEulerAngles(0.0f, 0.0f, 3.1416f), 
		CShVector3(1.0f, 1.0f, 1.0f));
	SH_ASSERT(shNULL != character);
	up = ShInput::CreateInputPressed(
		ShInput::e_input_device_keyboard, 
		ShInput::e_input_device_control_pc_key_z, 
		0.5f);
	down = ShInput::CreateInputPressed(
		ShInput::e_input_device_keyboard, 
		ShInput::e_input_device_control_pc_key_s, 
		0.5f);
	left = ShInput::CreateInputPressed(ShInput::e_input_device_keyboard, 
		ShInput::e_input_device_control_pc_key_q, 
		0.5f);
	right = ShInput::CreateInputPressed(ShInput::e_input_device_keyboard, 
		ShInput::e_input_device_control_pc_key_d, 
		0.5f);
	controller = ShCharacterController::Create(
		CShIdentifier("test"), 
		CShIdentifier("character_controller"),
		CShVector2_ZERO, 
		70.0f, 
		CShVector2(0.0f, 1.0f), 
		128.0f);
}

void Game::OnPreUpdate(float dts)
{
	CShVector2 direction(
		(ShInput::IsTrue(left)?-1.0f:0.0f) + (ShInput::IsTrue(right)?1.0f:0.0f), 
		(ShInput::IsTrue(up)?1.0f:0.0f) + (ShInput::IsTrue(down)?-1.0f:0.0f));
	ShCharacterController::SetWalkDirection(
		controller,
		CShVector2(direction));
	ShCharacterController::Update(controller);
	ShEntity2::SetPosition(
		character, 
		CShVector3(
			ShCharacterController::GetPosition(controller).m_x,
			ShCharacterController::GetPosition(controller).m_y,
			1.0f));
	if(0 != direction.m_x || 0 != direction.m_y)
	{
		ShEntity2::SetRotation(
			character,
			0.0f, 0.0f, 3.1416 - atan2(direction.m_x, direction.m_y));
	}
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

}
