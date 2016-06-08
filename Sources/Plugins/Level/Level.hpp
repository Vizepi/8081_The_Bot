#ifndef __8081_LEVEL_HPP
#define __8081_LEVEL_HPP

#include <ShSDK/ShSDK.h>
#include <ShEngineExt/ShEngineExt.h>
#include "Ground.hpp"
#include "LevelLoader.hpp"
#include "Character.hpp"

class Level : public CShPlugin
{

public:

					Level				(void);
	virtual			~Level				(void);
	
	void			Initialize			(void);
	void			Release				(void);

	virtual	void	OnPlayStart			(const CShIdentifier & levelIdentifier);
	virtual	void	OnPlayStop			(const CShIdentifier & levelIdentifier);
	virtual	void	OnPlayPause			(const CShIdentifier & levelIdentifier);
	virtual	void	OnPlayResume		(const CShIdentifier & levelIdentifier);

	virtual	void	OnPreUpdate			(void);
	virtual	void	OnPostUpdate		(float dt);

	static void		OnTouchMove			(int iTouch, float positionX, float positionY);

	static void		SetReleaseEnabled	(bool state);
	static bool		IsRealeseEnabled	(void);

	DECLARE_VARIABLES();

protected:

	Ground*				m_ground;
	LevelLoader*		m_loader;
	Character*			m_character;

	static bool			s_releaseEnabled;
	static CShArray<Character*>	s_character;

};

#endif // __8081_LEVEL_HPP
