#include "Level.hpp"
#include <ctime>

BEGIN_DERIVED_CLASS(Level, CShPlugin)
	// ...
END_CLASS()

Level::Level(void)
: CShPlugin(CShIdentifier("Level"))
{
	
}

/*virtual*/ Level::~Level(void)
{
	
}

void Level::Initialize(void)
{
	
}

void Level::Release(void)
{
	
}

/*virtual*/ void Level::OnPlayStart(const CShIdentifier & levelIdentifier)
{

}

/*virtual*/ void Level::OnPlayStop(const CShIdentifier & levelIdentifier)
{
	
}

/*virtual*/ void Level::OnPlayPause(const CShIdentifier & levelIdentifier)
{
	
}

/*virtual*/ void Level::OnPlayResume(const CShIdentifier & levelIdentifier)
{
	
}

/*virtual*/ void Level::OnPreUpdate(void)
{

}

/*virtual*/ void Level::OnPostUpdate(float dt)
{
	
}
