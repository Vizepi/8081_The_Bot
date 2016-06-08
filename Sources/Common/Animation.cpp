#include "Animation.hpp"
#include "Tools.hpp"

/*static*/ const char* CShString::EMPTY = "";

/*explicit*/ Animation::Manager::Manager()
	: m_animations()
{

}

/*virtual*/ Animation::Manager::~Manager()
{

}

/*virtual*/ void Animation::Manager::Add(Animation* animation)
{
	m_animations.Add(animation);
}

/*virtual*/ bool Animation::Manager::Remove(Animation* animation)
{
	int size = m_animations.GetCount();
	for(int i = 0; i < size; ++i)
	{
		if(m_animations[i] == animation)
		{
			m_animations.Remove(i);
			return true;
		}
	}
	return false;
}

/*virtual*/ void Animation::Manager::Update(float deltaTime)
{
	int size = m_animations.GetCount();
	for(int i = 0; i < size; ++i)
	{
		m_animations[i]->Update(deltaTime);
	}
}

/*virtual*/ bool Animation::Manager::Empty() const
{
	return 0 == m_animations.GetCount();
}

/*explicit*/ Animation::Animation()
	: m_entity(shNULL)
	, m_spriteLibrary("")
	, m_sprites()
	, m_initialized(false)
	, m_timer(0.0f)
	, m_playing(false)
	, m_currentFrame(0)
	, m_secondsPerFrame(1.0f / 24.0f)
{
	if(shNULL == s_manager)
	{
		s_manager = new Animation::Manager();
		s_manager->Add(this);
	}
}

/*virtual*/ Animation::~Animation()
{
	if(m_initialized)
	{
		Release();
	}
	s_manager->Remove(this);
	if(s_manager->Empty())
	{
		SH_SAFE_DELETE(s_manager);
	}
}

/*virtual*/ void Animation::Initialize(const CShIdentifier& level, const CShIdentifier& identifier, const CShIdentifier& spriteLibrary, const CShString& sprites, unsigned int frameCount)
{
	for(unsigned int i = 0; i < frameCount; ++i)
	{
		m_sprites.Add(CShIdentifier(sprites + CShString("_") + CShString::FromInt((int)i)));
	}
	m_entity = ShEntity2::Create(
		level, 
		identifier,
		CShIdentifier("layer_default"),
		spriteLibrary,
		m_sprites[0], 
		CShVector3_ZERO,
		CShEulerAngles_ZERO,
		CShVector3(1.0f, 1.0f, 1.0f));
	if(shNULL == m_entity)
	{
		ShLog(e_log_level_error, e_log_type_game, 0, "Unable to create animation starting with sprites \"%s\"", sprites.Get());
		return;
	}
	m_initialized = true;
}

/*virtual*/ void Animation::Release()
{
	if(!m_initialized)
	{
		ShLog(e_log_level_error, e_log_type_game, 0, "The animation is already released or not initialized yet");
		return;
	}
	Stop();
	m_playing = false;
	m_secondsPerFrame = 1.0f / 24.0f;
	m_sprites.Empty();
	if(Tools::IsReleaseEnabled())
	{
		ShEntity2::Destroy(m_entity);
	}
	m_initialized = false;
}

/*virtual*/ void Animation::Update(float deltaTime)
{
	if(m_initialized && m_playing)
	{
		m_timer += deltaTime;
		while(m_timer > m_secondsPerFrame)
		{
			m_timer -= m_secondsPerFrame;
			m_currentFrame++;
		}
		m_currentFrame %= m_sprites.GetCount();
		SetSprite();
	}
}

/*virtual*/ void Animation::Play()
{
	m_playing = true;
}

/*virtual*/ void Animation::Pause()
{
	m_playing = false;
}

/*virtual*/ void Animation::Stop()
{
	m_playing = false;
	m_currentFrame = 0;
	m_timer = 0.0f;
	if(m_initialized)
	{
		SetSprite();
	}
}

/*virtual*/ bool Animation::IsPlaying() const
{
	return  m_playing;
}

/*virtual*/ void Animation::SetFPS(unsigned int fps)
{
	if(fps != 0)
	{
		m_secondsPerFrame = 1.0f / fps;
	}
}

/*virtual*/ int Animation::GetFPS() const
{
	return (int)(1.0f / m_secondsPerFrame);
}

/*virtual*/ ShEntity2* Animation::GetEntity() const
{
	return m_entity;
}

/*static*/ void Animation::UpdateAll(float deltaTime)
{
	if(shNULL != s_manager)
	{
		s_manager->Update(deltaTime);
	}
}

/*virtual*/ void Animation::SetSprite()
{
	if(0 < m_sprites.GetCount())
	{
		ShEntity2::SetSprite(m_entity, m_spriteLibrary, m_sprites[m_currentFrame]);
	}
}

/*static*/ Animation::Manager* Animation::s_manager = shNULL;
