#ifndef __8081_8081_HPP
#define __8081_8081_HPP

#include <ShSDK/ShSDK.h>
#include <ShEngineExt/ShEngineExt.h>

class Level : public CShPlugin
{

public:

							Level			(void);
	virtual					~Level			(void);

	void					Initialize					(void);
	void					Release						(void);

	virtual	void			OnPlayStart					(const CShIdentifier & levelIdentifier);
	virtual	void			OnPlayStop					(const CShIdentifier & levelIdentifier);
	virtual	void			OnPlayPause					(const CShIdentifier & levelIdentifier);
	virtual	void			OnPlayResume				(const CShIdentifier & levelIdentifier);

	virtual	void			OnPreUpdate					(void);
	virtual	void			OnPostUpdate				(float dt);

	DECLARE_VARIABLES();

protected:

};

#endif // __8081_8081_HPP
