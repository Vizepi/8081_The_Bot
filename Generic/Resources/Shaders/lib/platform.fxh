//--------------------------------------------------------------------------------------------------
// Platform specific constants and defines (rev 2)
//--------------------------------------------------------------------------------------------------

//
// Define MipMap LOD Bias
// 0: default, <0: crispier textures, >0: smoother textures
#if SH_X360
#define ISOLATE [isolate]
#define TEXTURELODBIAS MipMapLodBias 
#else
#define ISOLATE 
#define TEXTURELODBIAS MipLODBias
#endif
#define DEFAULT_TEXTURELODBIAS 0.0f

//
// Define value above which pixel are discarded in alpha test
static const int 	INT_ALPHA_REF 		= 150;
static const float 	FLOAT_ALPHA_REF 	= (float)INT_ALPHA_REF / 255.0f;

//
// Remove half on PC
#if SH_PC
#define half float
#define half1 float1
#define half2 float2
#define half3 float3
#define half4 float4
#endif

//
// Isolate keyword force same outputs of different vertex shaders
#if SH_X360
#define ISOLATE [isolate]
#else
#define ISOLATE 
#endif

//
// Loop keyword
#if SH_PS3
#define LOOP
#else
#define LOOP [loop]
#endif

//
// Needed for support of VPOS and predicated tiling on Xbox 360 (see 'PredicatedTilingVPos' sample in XDK)
#if SH_X360
float4 VPOS_offset         : register(c128) = { +0.5f, +0.5f, 0.0f, 0.0f };
float4 VPOS_offset_dummy_1 : register(c129);
float4 VPOS_offset_dummy_2 : register(c130);
float4 VPOS_offset_dummy_3 : register(c131);
#else
static const float2 VPOS_offset = { +0.5f, +0.5f };
#endif

//
// VPOS is called WPOS on PS3
#if SH_PS3
#define VPOS				WPOS
#endif

//
// Disable FXAA on console for now
float4 FXAALuminance(float3 color)
{
        static const float3 RGB_TO_LUMA = { 0.299, 0.587, 0.114 };
        return(float4(color, dot(RGB_TO_LUMA, sqrt(saturate(color)))));
}

#if !SH_PS3
// Screen resolution is hardcoded
// if you change this make sure you also change
// 'Generic\Resources\Shaders\lib\platform.fxh'
uniform float	SCREENW		= 1280.0f;
uniform float	SCREENH		= 720.0f;
uniform float	HALFSCREENW	= 1280.0f / 2.0f;
uniform float	HALFSCREENH	= 720.0f / 2.0f;
uniform float4	SCREEN_SIZE	= { 1280.0f, 720.0f, 1.0f / 1280.0f, 1.0f / 720.0f };
#else
static const float	SCREENW		= 1280.0f;
static const float	SCREENH		= 720.0f;
static const float	HALFSCREENW	= 1280.0f / 2.0f;
static const float	HALFSCREENH	= 720.0f / 2.0f;
static const float4	SCREEN_SIZE	= { 1280.0f, 720.0f, 1.0f / 1280.0f, 1.0f / 720.0f };
#endif