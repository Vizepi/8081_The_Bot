#ifndef __8081_ANIMATION_HPP
#define __8081_ANIMATION_HPP

#include <ShSDK/ShSDK.h>
#include <ShStd/ShStd.h>

class Animation
{
	
private:
	
	class Manager
	{
		
	public:
		
		explicit 		Manager	(void);
		virtual 		~Manager(void);
		
		virtual void 	Add		(Animation* animation);
		virtual bool 	Remove	(Animation* animation);
		
		virtual void 	Update	(float deltaTime);

		virtual bool	Empty	(void) const;
		
	protected:
		
		CShArray<Animation*> m_animations;
		
	};

public:

	explicit			Animation	(void);
	virtual				~Animation	(void);

	virtual void		Initialize	(const CShIdentifier& level, const CShIdentifier& identifier, const CShIdentifier& spriteLibrary, const CShString& sprites, unsigned int frameCount);
	virtual void		Release		(void);

	virtual void		Update		(float deltaTime);
	virtual void		Play		(void);
	virtual void		Pause		(void);
	virtual void		Stop		(void);
	virtual bool		IsPlaying	(void) const;

	virtual void		SetFPS		(unsigned int fps);
	virtual int			GetFPS		(void) const;
	
	virtual ShEntity2* 	GetEntity	(void) const;

	static void			UpdateAll	(float deltaTime);

protected:

	void				SetSprite	(void);

	ShEntity2*				m_entity;

	CShIdentifier			m_spriteLibrary;
	CShArray<CShIdentifier>	m_sprites;
	
	bool					m_initialized;
	float					m_timer;
	bool					m_playing;
	int						m_currentFrame;
	float					m_secondsPerFrame;
	
	static Manager*			s_manager;
};

#endif // __8081_ANIMATION_HPP