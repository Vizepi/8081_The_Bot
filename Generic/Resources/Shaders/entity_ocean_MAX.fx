//--------------------------------------------------------------------------------------------------
// Ocean shader for MAX (rev 1)
//--------------------------------------------------------------------------------------------------
#ifdef _3DSMAX_

//
//
//
#include "lib\lighting.fxh"

//--------------------------------------------------------------------------------------------------
// Constants Params
//--------------------------------------------------------------------------------------------------
#if SH_X360
#define ISOLATE [isolate]
#define TEXTURELODBIAS MipMapLodBias
#else
#define ISOLATE
#define TEXTURELODBIAS MipLODBias
#endif
#define DEFAULT_TEXTURELODBIAS -0.5f

//--------------------------------------------------------------------------------------------------
// Automatic Params
//--------------------------------------------------------------------------------------------------
uniform float4x4	mWorld 					: WORLD;
uniform float4x4 	mWorldViewProjection 	: WORLDVIEWPROJECTION;
uniform float 	 	fElapsedTime 			: TIME;
uniform float3	 	vCameraPosition;
uniform float3		SunDirection;
uniform float4	 	vZNearFarAB;


//--------------------------------------------------------------------------------------------------
// Material Params
//--------------------------------------------------------------------------------------------------
uniform float  		vDetailTile1 		< string UIName = "vDetailTile1"; 		float UIMin = -100; float UIMax = +100; > 	= 0.0005;
uniform float  		vDetailTile2 		< string UIName = "vDetailTile2"; 		float UIMin = -100; float UIMax = +100; > 	= 0.0002;
uniform float  		vNormalTile  		< string UIName = "vNormalTile"; 		float UIMin = -100; float UIMax = +100; > 	= 0.0001;
uniform float  		vDetailSpeed1 		< string UIName = "vDetailSpeed1"; 		float UIMin = -100; float UIMax = +100; > 	= 0.03;
uniform float  		vDetailSpeed2 		< string UIName = "vDetailSpeed2"; 		float UIMin = -100; float UIMax = +100; > 	= 0.02;
uniform float  		vNormalSpeed  		< string UIName = "vNormalSpeed"; 		float UIMin = -100; float UIMax = +100; > 	= 0.01;
uniform float  		fWaterVisualRange	< string UIName = "fWaterVisualRange"; 	float UIMin = 0; float UIMax = 10000; > 	= 600.0;
uniform float  		fScaleOffsetU		< string UIName = "fScaleOffsetU"; 		float UIMin = 0; float UIMax = 100; > 		= 1.0;
uniform float  		fScaleOffsetV		< string UIName = "fScaleOffsetV"; 		float UIMin = 0; float UIMax = 100; > 		= 0.84;
uniform float 		fFresnelBias		< string UIName = "fFresnelBias"; 		float UIMin = 0; float UIMax = 1; > 		= 0.3;
uniform float 		fFresnelPower		< string UIName = "fFresnelPower"; 		float UIMin = 0; float UIMax = 1; > 		= 0.7;
uniform float		fSpecularPower 		< string UIName = "fSpecularPower"; 	float UIMin = 0; float UIMax = 255;> 		= 190.0;
uniform float4 		vWaterColor			< string UIName = "vWaterColor"; > 													= float4(0.70999998,0.62333333,0.34000000,1.0);
uniform float4 		vSpecularColor		< string UIName = "vSpecularColor"; > 												= float4(0.70999998,0.62333333,0.34000000,1.0);
uniform float4 		vWaterDeepColor		< string UIName = "vWaterDeepColor"; > 												= float4(0.30980393,0.34117648,0.23137258,1.0);


//--------------------------------------------------------------------------------------------------
// Textures
//--------------------------------------------------------------------------------------------------
texture Water1DetailMap < string UIName = "Water1DetailMap"; string name = "water_2_detail1_nrm.tga"; string TextureType = "2D"; >;
sampler2D Water1DetailMapSampler = sampler_state
{
	Texture = <Water1DetailMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP; AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};

texture Water2DetailMap < string UIName = "Water2DetailMap"; string name = "water_2_detail2_nrm.tga"; string TextureType = "2D"; >;
sampler2D Water2DetailMapSampler = sampler_state
{
	Texture = <Water2DetailMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP; AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};

texture NormalMap < string UIName = "NormalMap"; string name = "water_2_color.tga"; string TextureType = "2D"; >;
sampler2D NormalMapSampler = sampler_state
{
	Texture = <NormalMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP; AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};

texture SpecularMap < string UIName = "SpecularMap"; string name = "water_2_reflect_color.tga"; string TextureType = "2D"; >;
sampler2D SpecularMapSampler = sampler_state
{
	Texture = <SpecularMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP; AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};

texture WaterDeepNoiseMap < string UIName = "WaterDeepNoiseMap"; string name = "water_2_noise_color.tga"; string TextureType = "2D"; >;
sampler2D WaterDeepNoiseMapSampler = sampler_state
{
	Texture = <WaterDeepNoiseMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP; AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};


//--------------------------------------------------------------------------------------------------
// Shader input/output structures
//--------------------------------------------------------------------------------------------------
struct WaterVertex
{
  float4 f4Position 	: POSITION;
};

struct WaterPixel
{
  float4 f4Position    	: POSITION;
};


//--------------------------------------------------------------------------------------------------
// Vertex shader
//--------------------------------------------------------------------------------------------------
WaterPixel WaterVS( WaterVertex Input )
{
  WaterPixel Output;
  Output.f4Position      = mul( Input.f4Position.xyzw, mWorldViewProjection );
  return Output;
}


//--------------------------------------------------------------------------------------------------
// Pixel shader
//--------------------------------------------------------------------------------------------------
float4 WaterPS( WaterPixel Input ) : COLOR0
{
	return float4(0.1098f, 0.2274f, 0.5333f, 1.0f);
}


//--------------------------------------------------------------------------------------------------
// Technique definition
//--------------------------------------------------------------------------------------------------
technique DefaultTechnique
{
    pass
    {
        VertexShader 		= compile vs_3_0 WaterVS();
        PixelShader  		= compile ps_3_0 WaterPS();
    }
}

#else // _3DSMAX_

technique
{
    pass
    {
        VertexShader = null;
        PixelShader  = null;
    }
}

#endif // _3DSMAX_