#ifndef __8081_LEVELLOADER_HPP
#define __8081_LEVELLOADER_HPP

#include <ShSDK/ShSDK.h>
#include <ShStd/ShStd.h>

class LevelLoader
{

public:

	struct GroundDef
	{
		struct GroundSpriteDef
		{
			CShString		library;
			CShString		identifier;
			unsigned int	probability;
		};
		
		int							seed;
		unsigned int				probabilitySum;
		CShArray<GroundSpriteDef>	sprites;
		
	};

									LevelLoader		(void);
									LevelLoader		(const CShString& level);
	virtual							~LevelLoader	(void);

	virtual bool					Load			(const CShString& level);
	virtual void					Release			(void);
	
	virtual	GroundDef*				GetGround		(void) const;
	virtual const CShString&		GetIdentifier	(void) const;

protected:

	GroundDef* 		m_ground;
	bool			m_loaded;
	CShString		m_id;

};

#endif // __8081_LEVELLOADER_HPP
