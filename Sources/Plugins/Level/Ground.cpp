#include "Ground.hpp"
#include "LevelLoader.hpp"
#include "Level.hpp"

Ground::Ground()
	: m_tiles(shNULL)
	, m_width(0)
	, m_height(0)
	, m_initialized(false)
{
	
}

/*virtual*/ Ground::~Ground()
{
	if(m_initialized)
	{
		Release();
	}
}

/*virtual*/ void Ground::Initialize(const LevelLoader& level, unsigned int width, unsigned int height, float originX, float originY)
{
	m_tiles = shNULL;
	m_width = width;
	m_height = height;

	if(0 == width || 0 == height)
	{
		ShLog(e_log_level_error, e_log_type_game, 0, "Unable to create a Ground of size %dx%d", width, height);
		return;
	}

	m_tiles = new ShEntity2*[width * height];
	if(shNULL == m_tiles)
	{
		ShLog(e_log_level_error, e_log_type_game, 0, "Unable to allocate memory for Ground of size %dx%d", width, height);
		return;
	}

	unsigned int size = width * height;

	LevelLoader::GroundDef* groundDef = level.GetGround();
	CShRandomValue random(groundDef->seed);
	CShIdentifier layer_default("layer_default");

	for(register unsigned int i = 0; i < width; ++i)
	{
		for(register unsigned int j = 0; j < height; ++j)
		{

			unsigned int randSum = random.GetNextInt() % groundDef->probabilitySum;
			unsigned int sum = 0;
			unsigned int index = 0;

			do
			{
				index++;
				sum += groundDef->sprites[index-1].probability;
			} while(sum  <= randSum);
			index--;

			unsigned int tileIndex = j * width + i;
			m_tiles[tileIndex] = ShEntity2::Create(
				CShIdentifier(level.GetIdentifier()), 
				CShIdentifier(CShString("ground_tile_") + CShString::FromInt(tileIndex)),
				layer_default, 
				CShIdentifier(groundDef->sprites[index].library), 
				CShIdentifier(groundDef->sprites[index].identifier),
				CShVector3(1024.0f * i - originX, 1024.0f * j - originY, -100.0f), 
				CShEulerAngles_ZERO, 
				CShVector3(1.0f, 1.0f, 1.0f));

			if(shNULL == m_tiles[tileIndex])
			{
				ShLog(e_log_level_error, e_log_type_game, 0, "Unable to create tile \"%s\" with sprite \"%s.%s\"",
					(CShString("ground_tile_") + CShString::FromInt(tileIndex)).Get(),
					groundDef->sprites[index].library.Get(),
					groundDef->sprites[index].identifier.Get());
				continue;
			}
			ShEntity2::SetPivotBottomLeft(m_tiles[tileIndex]);

		}
	}

	m_initialized = true;
}

/*virtual*/ void Ground::Release()
{
	if(!m_initialized)
	{
		ShLog(e_log_level_error, e_log_type_game, 0, "Trying to release Ground that is not initialized or already released");
		return;
	}
	unsigned int size = m_width * m_height;
	for(register unsigned int i = 0; i < size; ++i)
	{
		if(Level::IsRealeseEnabled())
		{
			ShEntity2::Destroy(m_tiles[i]);
		}
	}

	SH_SAFE_DELETE_ARRAY(m_tiles);

	m_width = 0;
	m_height = 0;
	m_initialized = false;
}

/*virtual*/ void Ground::Log(ELogLevel level)
{
	if(!m_initialized)
	{
		return;
	}
	unsigned int size = m_width * m_height;
	for(register unsigned int i = 0; i < size; ++i)
	{
		ShLog(level, e_log_type_game, 0, "Sprite : %f %f %f", 
			ShEntity2::GetPosition(m_tiles[i]).m_x,
			ShEntity2::GetPosition(m_tiles[i]).m_y,
			ShEntity2::GetPosition(m_tiles[i]).m_z);
	}
}