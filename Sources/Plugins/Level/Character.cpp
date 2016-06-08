#include "Character.hpp"
#include "Level.hpp"

/*explicit*/ Character::Character()
	: m_controller(shNULL)
	, m_animation(shNULL)
	, m_mouseX(0.0f)
	, m_mouseY(0.0f)
	, m_axisX(0.0f)
	, m_axisY(0.0f)
	, m_idle(0.0f)
	, m_initialized(false)
{
	m_inputs[0] = m_inputs[1] = m_inputs[2] = m_inputs[3] = shNULL;
}

/*virtual*/ Character::~Character()
{
	if(m_initialized)
	{
		Release();
	}
}

/*virtual*/ void Character::Initialize(const CShIdentifier& level, const CShVector2& position)
{
	if(m_initialized)
	{
		ShLog(e_log_level_error, e_log_type_game, 0, "The character is already initialized");
		return;
	}
	m_controller = ShCharacterController::Create(
		level, 
		CShIdentifier("character_controller"), 
		position, 
		70.0f, 
		CShVector2(0.0f, -1.0f), 
		600.0f);
	m_animation = new Animation();
	m_animation->Initialize(level, CShIdentifier("character_animation"), CShIdentifier("bobi"), CShString("character_top"), 8);
	m_inputs[0] = ShInput::CreateInputPressed(
		ShInput::e_input_device_keyboard, 
		ShInput::e_input_device_control_pc_key_z, 
		0.5f);
	m_inputs[1] = ShInput::CreateInputPressed(
		ShInput::e_input_device_keyboard, 
		ShInput::e_input_device_control_pc_key_s, 
		0.5f);
	m_inputs[2] = ShInput::CreateInputPressed(
		ShInput::e_input_device_keyboard, 
		ShInput::e_input_device_control_pc_key_q, 
		0.5f);
	m_inputs[3] = ShInput::CreateInputPressed(
		ShInput::e_input_device_keyboard, 
		ShInput::e_input_device_control_pc_key_d, 
		0.5f);
	m_initialized = true;
}

/*virtual*/ void Character::Release()
{
	if(!m_initialized)
	{
		ShLog(e_log_level_error, e_log_type_game, 0, "The character is already released or not initialized yet");
		return;
	}
	delete m_animation;
	if(Level::IsRealeseEnabled())
	{
		ShCharacterController::Disable(m_controller);
		//SH_SAFE_DELETE(m_controller);
	}
}

/*virtual*/ void Character::SetPosition(const CShVector2& position)
{
	ShCharacterController::SetPosition(m_controller, position);
}

/*virtual*/ void Character::Update(float deltaTime)
{
	HandleInputs();
	ShCharacterController::UpdateFromInputs(
		m_controller,
		m_axisX,
		m_axisY,
		false);
	if(0.0f == m_axisX && 0.0f == m_axisY)
	{
		m_animation->Stop();
	}
	else
	{
		m_animation->Play();
	}
	CShVector2 controllerPosition = ShCharacterController::GetPosition(m_controller);
	ShEntity2::SetPosition(
		m_animation->GetEntity(),
		controllerPosition.m_x,
		controllerPosition.m_y,
		1.0f);
	ShCamera::SetPosition(
		ShCamera::GetCamera2D(),
		CShVector3(
			controllerPosition.m_x,
			controllerPosition.m_y,
			1000.0f));
	ShCamera::SetTarget(
		ShCamera::GetCamera2D(),
		CShVector3(
			controllerPosition.m_x,
			controllerPosition.m_y,
			0.0f));
	if(0.0f != m_axisX || 0.0f != m_axisY)
	{
		ShEntity2::SetRotation(
			m_animation->GetEntity(),
			0.0f, 0.0f, 3.1416f - atan2f(m_axisX, m_axisY));
	}
	CShVector2 deltaPosition(m_mouseX - controllerPosition.m_x, m_mouseY - controllerPosition.m_y);
	ShEntity2::SetRotation(
		m_animation->GetEntity(), 
		CShEulerAngles(0.0f, 0.0f, 3.1416f - atan2f(deltaPosition.m_x, deltaPosition.m_y) + sinf(m_idle * 5.0f)* 0.05f));
	m_idle += deltaTime;
}

/*virtual*/ void Character::OnTouchMove(int iTouch, float positionX, float positionY)
{
	m_mouseX = positionX;
	m_mouseY = positionY;
}

/*virtual*/ void Character::HandleInputs()
{
	m_axisX = 0.0f;
	m_axisY = 0.0f;
	if(ShInput::IsTrue(m_inputs[0]))
	{
		m_axisY += 1.0f;
	}
	if(ShInput::IsTrue(m_inputs[1]))
	{
		m_axisY -= 1.0f;
	}
	if(ShInput::IsTrue(m_inputs[2]))
	{
		m_axisX -= 1.0f;
	}
	if(ShInput::IsTrue(m_inputs[3]))
	{
		m_axisX += 1.0f;
	}
}
