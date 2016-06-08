#ifndef __8081_TOOLS_HPP
#define __8081_TOOLS_HPP

class Tools
{

public:

	static void		SetReleaseEnabled	(bool state);
	static bool		IsReleaseEnabled	(void);

protected:

	static bool s_releaseEnabled;

};

#endif // __8081_TOOLS_HPP