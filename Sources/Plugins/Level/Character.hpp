#ifndef __8081_CHARACTER_HPP
#define __8081_CHARACTER_HPP

#include <ShSDK/ShSDK.h>
#include "../../Common/Animation.hpp"

class Character
{

public:

	explicit		Character	(void);
	virtual			~Character	(void);

	virtual void	Initialize	(const CShIdentifier& level, const CShVector2& position = CShVector2_ZERO);
	virtual void	Release		(void);

	virtual void	SetPosition	(const CShVector2& position = CShVector2_ZERO);
	virtual void	Update		(float deltaTime);
	virtual void	OnTouchMove	(int iTouch, float positionX, float positionY);

	virtual void	HandleInputs(void);

protected:

	ShCharacterController*	m_controller;
	Animation*				m_animation;

	ShInput*				m_inputs[4];

	float					m_mouseX;
	float					m_mouseY;
	float					m_axisX;
	float					m_axisY;
	float					m_idle;

	bool					m_initialized;
};

#endif // __8081_CHARACTER_HPP