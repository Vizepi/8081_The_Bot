#include "Tools.hpp"

/*static*/ void Tools::SetReleaseEnabled(bool state)
{
	s_releaseEnabled = state;
}

/*static*/ bool Tools::IsReleaseEnabled()
{
	return s_releaseEnabled;
}

/*static*/ bool Tools::s_releaseEnabled = true;
