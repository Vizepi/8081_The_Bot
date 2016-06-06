#ifndef __8081_GROUND_HPP
#define __8081_GROUND_HPP

#include <ShSDK/ShSDK.h>
#include <ShStd/ShStd.h>

class LevelLoader;

class Ground
{

public:

					Ground		(void);
	virtual			~Ground		(void);

	virtual void	Initialize	(const LevelLoader& level, unsigned int width, unsigned int height, float originX, float originY);
	virtual void	Release		(void);
	virtual void	Log			(ELogLevel level);

protected:

	ShEntity2**		m_tiles;

	unsigned int	m_width;
	unsigned int	m_height;
	bool			m_initialized;

};

#endif // __8081_GROUND_HPP
