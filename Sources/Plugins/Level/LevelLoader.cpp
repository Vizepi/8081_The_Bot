#include "LevelLoader.hpp"

LevelLoader::LevelLoader()
	: m_ground(shNULL)
	, m_loaded(false)
{
	
}

LevelLoader::LevelLoader(const CShString& level)
	: m_ground(shNULL)
	, m_loaded(false)
{
	m_loaded = Load(level);
}

/*virtual*/ LevelLoader::~LevelLoader()
{

}

/*virtual*/ bool LevelLoader::Load(const CShString& level)
{
	if(m_loaded)
	{
		ShLog(e_log_level_error, e_log_type_game, 0, "Unable to load : Level is already loaded");
		return true;
	}
	m_ground = new GroundDef();
	m_ground->probabilitySum = 2;
	m_ground->seed = 1234;
	GroundDef::GroundSpriteDef gsd;
	gsd.identifier = CShString("ground_0");
	gsd.library = CShString("bobi");
	gsd.probability = 1;
	m_ground->sprites.Add(gsd);
	gsd.identifier = CShString("ground_1");
	m_ground->sprites.Add(gsd);

	m_id = level;
	m_loaded = true;

	return true;
}

/*virtual*/ void LevelLoader::Release()
{
	if(!m_loaded)
	{
		ShLog(e_log_level_error, e_log_type_game, 0, "Unable to release LevelLoader : Level not loaded or already released");
		return;
	}
	delete m_ground;
	m_loaded = false;
}

/*virtual*/ LevelLoader::GroundDef* LevelLoader::GetGround() const
{
	return m_ground;
}

/*virtual*/ const CShString& LevelLoader::GetIdentifier() const
{
	return m_id;
}
