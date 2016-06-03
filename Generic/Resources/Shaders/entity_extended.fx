//--------------------------------------------------------------------------------------------------
// Final pass for standard material (rev 1)
//--------------------------------------------------------------------------------------------------
#include "lib\platform.fxh"
#include "lib\lighting.fxh"
#include "lib\skinning.fxh"

//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
float4x4 	mWorld;
float4x4 	mWorldIT;
float4x4	mView;
float4x4 	mWorldViewProjection;

//--------------------------------------------------------------------------------------------------
// Automatic Shadow Parameters
//--------------------------------------------------------------------------------------------------
float4x4 	mShadowTexture;

//--------------------------------------------------------------------------------------------------
// Automatic Fog Parameters
//--------------------------------------------------------------------------------------------------
float3  	verticalFogColor;
float2   	verticalFogStartEnd;

//--------------------------------------------------------------------------------------------------
// Automatic Colors Parameters
//--------------------------------------------------------------------------------------------------
float3   	AmbientColor = {0.0f, 0.0f, 0.0f};
float3		SelfIllumColor2 = {0.0f, 0.0f, 0.0f};

float		RenderIfOccluded = 0.0f;
float4		ModulateColor = {1.0f, 1.0f, 1.0f, 1.0f};
float4		SaturateColor = {0.0f, 0.0f, 0.0f, 0.0f};

//--------------------------------------------------------------------------------------------------
// Material Parameters
//--------------------------------------------------------------------------------------------------
texture  	DiffuseMap;
texture  	SpecularMap;
texture  	OpacityMap;
texture  	EnvMap;
texture  	EnvMapMask;
texture  	SelfIllumMap;

float3   	DiffuseMapModulator;
float3   	SpecularMapModulator;
float3   	SelfIllumMapModulator;
float3   	SelfIllumColor;

float    	Shininess;
float    	SpecularLevel;
float    	EnvMapFactor;
float    	TexCoordOffsetU;
float    	TexCoordOffsetV;
bool 	 	FlipNormalMapY;


//--------------------------------------------------------------------------------------------------
// Maps Samplers
//--------------------------------------------------------------------------------------------------
sampler2D DiffuseMapSampler = sampler_state
{
	Texture   = <DiffuseMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};
sampler2D SpecularMapSampler = sampler_state
{
	Texture   = <SpecularMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};
sampler2D OpacityMapSampler = sampler_state
{
	Texture   = <OpacityMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};
sampler2D EnvMapMaskSampler = sampler_state
{
	Texture   = <EnvMapMask>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;	
};
sampler2D EnvMapSampler = sampler_state
{
	Texture   = <EnvMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};
sampler2D SelfIllumMapSampler = sampler_state
{
	Texture   = <SelfIllumMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};

//--------------------------------------------------------------------------------------------------
// LightBuffer map sampler
//--------------------------------------------------------------------------------------------------
texture LightBufferMap;
sampler2D LightBufferMapSampler = sampler_state
{
	Texture   = <LightBufferMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};
//--------------------------------------------------------------------------------------------------
// Shadow map sampler
//--------------------------------------------------------------------------------------------------
texture ShadowMap;
sampler2D ShadowMapSampler = sampler_state
{
	Texture   = <ShadowMap>;
#if !SH_PS3
    MinFilter = POINT;
    MagFilter = POINT;
#else
    MinFilter = LINEAR;
    MagFilter = LINEAR;
#endif
    MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float2 texcoord		 : TEXCOORD0;	// Texture coordinates
	float3 worldPos 	 : TEXCOORD1;	// Vertex position (in world space)
	float4 shadtexcoord	 : TEXCOORD2;	// Shadow mapping texcoords
	float3 viewNormal	 : TEXCOORD3;  // Normal (in view space)
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
	ISOLATE position = mul(vIn.position0, mWorldViewProjection);

	VS_OUTPUT Out;
	Out.texcoord.xy = vIn.texcoord;
	Out.worldPos = mul(vIn.position0, mWorld);
	Out.shadtexcoord = mul(vIn.position0, mShadowTexture);
	Out.viewNormal = mul(normalize(mul(vIn.normal0, (float3x3)mWorldIT).xyz), (float3x3)mView).xyz;

	return Out;
}
VS_OUTPUT vs_skin(VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
	skin(vIn);
	ISOLATE position = mul(vIn.position0, mWorldViewProjection);

	VS_OUTPUT Out;
	Out.texcoord.xy = vIn.texcoord;
	Out.worldPos = mul(vIn.position0,mWorld);
	Out.shadtexcoord = mul(vIn.position0, mShadowTexture);
	Out.viewNormal = mul(normalize(mul(vIn.normal0, (float3x3)mWorldIT).xyz), (float3x3)mView).xyz;

	return Out;
}

#define FEATURE_FLAGS	0
#define PS_NAME		ps0
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	1
#define PS_NAME		ps1
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	2
#define PS_NAME		ps2
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	3
#define PS_NAME		ps3
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	4
#define PS_NAME		ps4
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	5
#define PS_NAME		ps5
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	6
#define PS_NAME		ps6
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	7
#define PS_NAME		ps7
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	8
#define PS_NAME		ps8
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	9
#define PS_NAME		ps9
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	10
#define PS_NAME		ps10
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	11
#define PS_NAME		ps11
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	12
#define PS_NAME		ps12
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	13
#define PS_NAME		ps13
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	14
#define PS_NAME		ps14
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	15
#define PS_NAME		ps15
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	16
#define PS_NAME		ps16
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	17
#define PS_NAME		ps17
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	18
#define PS_NAME		ps18
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	19
#define PS_NAME		ps19
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	20
#define PS_NAME		ps20
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	21
#define PS_NAME		ps21
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	22
#define PS_NAME		ps22
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	23
#define PS_NAME		ps23
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	24
#define PS_NAME		ps24
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	25
#define PS_NAME		ps25
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	26
#define PS_NAME		ps26
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	27
#define PS_NAME		ps27
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	28
#define PS_NAME		ps28
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	29
#define PS_NAME		ps29
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	30
#define PS_NAME		ps30
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

#define FEATURE_FLAGS	31
#define PS_NAME		ps31
#include "entity_extended_macrops.fxh"
#undef PS_NAME
#undef FEATURE_FLAGS

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique Solid
{
	pass
	{
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps15();
	}
}

technique SolidSkinning
{
	pass
	{
		VertexShader     = compile vs_3_0 vs_skin();
		PixelShader      = compile ps_3_0 ps15();
	}
}

technique SolidSilhouette
{
	pass
	{
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps31();
	}
}

technique SolidSkinningSilhouette
{
	pass
	{
		VertexShader     = compile vs_3_0 vs_skin();
		PixelShader      = compile ps_3_0 ps31();
	}
}

technique Solid0 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps0(); } }
technique Solid1 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps1(); } }
technique Solid2 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps2(); } }
technique Solid3 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps3(); } }
technique Solid4 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps4(); } }
technique Solid5 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps5(); } }
technique Solid6 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps6(); } }
technique Solid7 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps7(); } }
technique Solid8 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps8(); } }
technique Solid9 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps9(); } }
technique Solid10 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps10(); } }
technique Solid11 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps11(); } }
technique Solid12 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps12(); } }
technique Solid13 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps13(); } }
technique Solid14 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps14(); } }
technique Solid15 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps15(); } }
technique Solid16 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps16(); } }
technique Solid17 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps17(); } }
technique Solid18 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps18(); } }
technique Solid19 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps19(); } }
technique Solid20 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps20(); } }
technique Solid21 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps21(); } }
technique Solid22 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps22(); } }
technique Solid23 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps23(); } }
technique Solid24 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps24(); } }
technique Solid25 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps25(); } }
technique Solid26 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps26(); } }
technique Solid27 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps27(); } }
technique Solid28 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps28(); } }
technique Solid29 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps29(); } }
technique Solid30 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps30(); } }
technique Solid31 { pass { VertexShader = compile vs_3_0 vs(); PixelShader = compile ps_3_0 ps31(); } }

technique SolidSkinning0 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps0(); } }
technique SolidSkinning1 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps1(); } }
technique SolidSkinning2 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps2(); } }
technique SolidSkinning3 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps3(); } }
technique SolidSkinning4 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps4(); } }
technique SolidSkinning5 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps5(); } }
technique SolidSkinning6 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps6(); } }
technique SolidSkinning7 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps7(); } }
technique SolidSkinning8 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps8(); } }
technique SolidSkinning9 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps9(); } }
technique SolidSkinning10 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps10(); } }
technique SolidSkinning11 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps11(); } }
technique SolidSkinning12 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps12(); } }
technique SolidSkinning13 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps13(); } }
technique SolidSkinning14 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps14(); } }
technique SolidSkinning15 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps15(); } }
technique SolidSkinning16 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps16(); } }
technique SolidSkinning17 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps17(); } }
technique SolidSkinning18 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps18(); } }
technique SolidSkinning19 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps19(); } }
technique SolidSkinning20 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps20(); } }
technique SolidSkinning21 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps21(); } }
technique SolidSkinning22 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps22(); } }
technique SolidSkinning23 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps23(); } }
technique SolidSkinning24 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps24(); } }
technique SolidSkinning25 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps25(); } }
technique SolidSkinning26 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps26(); } }
technique SolidSkinning27 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps27(); } }
technique SolidSkinning28 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps28(); } }
technique SolidSkinning29 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps29(); } }
technique SolidSkinning30 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps30(); } }
technique SolidSkinning31 { pass { VertexShader = compile vs_3_0 vs_skin(); PixelShader = compile ps_3_0 ps31(); } }
