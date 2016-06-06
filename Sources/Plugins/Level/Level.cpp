#include "Level.hpp"

BEGIN_DERIVED_CLASS(Level, CShPlugin)
	// ...
END_CLASS()

Level::Level(void)
	: CShPlugin(CShIdentifier("Level"))
	, m_loader(new LevelLoader())
	, m_ground(new Ground())
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
	delete m_loader;
	delete m_ground;
}

/*virtual*/ void Level::OnPlayStart(const CShIdentifier & levelIdentifier)
{
	m_loader->Load(CShString("test"));
	m_ground->Initialize(*m_loader, 20, 20, 10*1024, 10*1024);
}

/*virtual*/ void Level::OnPlayStop(const CShIdentifier & levelIdentifier)
{
	m_ground->Release();
	m_loader->Release();
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

/*static*/ void Level::SetReleaseEnabled(bool state)
{
	s_releaseEnabled = state;
}

/*static*/ bool Level::IsRealeseEnabled()
{
	return s_releaseEnabled;
}

/*static*/ bool Level::s_releaseEnabled = true;
