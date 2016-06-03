//--------------------------------------------------------------------------------------------------
// Water shader (rev 1)
//--------------------------------------------------------------------------------------------------
#include "lib\platform.fxh"
#include "lib\lighting.fxh"

//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
float4x4 			mWorld;
float4x4 			mWorldViewProjection;

//--------------------------------------------------------------------------------------------------
// Automatic Fog Parameters
//--------------------------------------------------------------------------------------------------
float3  			verticalFogColor;
float2   			verticalFogStartEnd;

//--------------------------------------------------------------------------------------------------
// Automatic Params
//--------------------------------------------------------------------------------------------------
uniform float 	 	fElapsedTime;
uniform float3	 	vCameraPosition;
uniform float3		SunDirection;
uniform float4	 	vZNearFarAB;


//--------------------------------------------------------------------------------------------------
// Material Params
//--------------------------------------------------------------------------------------------------
uniform float  		vDetailTile1 		= 0.0005;
uniform float  		vDetailTile2 		= 0.0002;
uniform float  		vNormalTile  		= 0.0001;
uniform float  		vDetailSpeed1 		= 0.03;
uniform float  		vDetailSpeed2 		= 0.02;
uniform float  		vNormalSpeed  		= 0.01;
uniform float  		fWaterVisualRange	= 600.0;
uniform float  		fScaleOffsetU		= 1.0;
uniform float  		fScaleOffsetV		= 0.84;
uniform float 		fFresnelBias		= 0.3;
uniform float 		fFresnelPower		= 0.7;
uniform float		fSpecularPower 		= 190.0;
uniform float4 		vWaterColor			= float4(0.70999998,0.62333333,0.34000000,1.0);
uniform float4 		vSpecularColor		= float4(0.70999998,0.62333333,0.34000000,1.0);
uniform float4 		vWaterDeepColor		= float4(0.30980393,0.34117648,0.23137258,1.0);


//--------------------------------------------------------------------------------------------------
// Textures
//--------------------------------------------------------------------------------------------------
texture Water1DetailMap;
sampler2D Water1DetailMapSampler = sampler_state
{
	Texture = <Water1DetailMap>;
	MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR;
	AddressU  = WRAP; AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;	
};

texture Water2DetailMap;
sampler2D Water2DetailMapSampler = sampler_state
{
	Texture = <Water2DetailMap>;
	MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR;
	AddressU  = WRAP; AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;	
};

texture NormalMap;
sampler2D NormalMapSampler = sampler_state
{
	Texture = <NormalMap>;
	MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR;
	AddressU  = WRAP; AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;	
};

texture SpecularMap;
sampler2D SpecularMapSampler = sampler_state
{
	Texture = <SpecularMap>;
	MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR;
	AddressU  = WRAP; AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;	
};

texture WaterDeepNoiseMap;
sampler2D WaterDeepNoiseMapSampler = sampler_state
{
	Texture = <WaterDeepNoiseMap>;
	MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR;
	AddressU  = WRAP; AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;	
};

texture FrameBufferMap;
sampler2D FrameBufferMapSampler = sampler_state
{
	Texture = <FrameBufferMap>;
	MinFilter = POINT; MagFilter = POINT; MipFilter = NONE;
	AddressU  = CLAMP; AddressV  = CLAMP;
};

texture DepthMap;
sampler2D DepthMapSampler = sampler_state
{
	Texture = <DepthMap>;
	MinFilter = POINT; MagFilter = POINT; MipFilter = NONE;
	AddressU  = CLAMP; AddressV  = CLAMP;
};


//--------------------------------------------------------------------------------------------------
// Helper functions
//--------------------------------------------------------------------------------------------------
float Fresnel(float NdotL, float fBias, float fPow)
{
   float fFacing = 1 - NdotL;
   return max(fBias + (1 - fBias) * pow(fFacing, fPow), 0);
}

//--------------------------------------------------------------------------------------------------
// Shader input/output structures
//--------------------------------------------------------------------------------------------------
struct WaterVertex
{
  float4 f4Position 	: POSITION;
};

struct WaterPixel
{
  float4 f4Position    			: POSITION;
  float4 f4UV          			: TEXCOORD0;
  float3 f3ViewDir     			: TEXCOORD1;
  float4 f4NormalDeepNoiseUV    : TEXCOORD2;
  float3 f3Depth				: TEXCOORD4;
};


//--------------------------------------------------------------------------------------------------
// Vertex shader
//--------------------------------------------------------------------------------------------------
WaterPixel WaterVS( WaterVertex Input )
{
  WaterPixel Output;

  float4 f4WorldPosition = mul( Input.f4Position.xyzw, mWorld );
  float2 f2TerrainUV     = f4WorldPosition.xy;

  Output.f4Position      = mul( Input.f4Position.xyzw, mWorldViewProjection );
  Output.f4UV.xy         = f2TerrainUV * vDetailTile1 + float2( +vDetailSpeed1, +vDetailSpeed2 ) * fElapsedTime;
  Output.f4UV.zw         = f2TerrainUV * vDetailTile2 + float2( -vDetailSpeed1, +vDetailSpeed2 ) * 0.7 * fElapsedTime;
  Output.f3ViewDir       = vCameraPosition - f4WorldPosition.xyz;
  Output.f4NormalDeepNoiseUV.xy = f2TerrainUV * vNormalTile + float2( +vNormalSpeed * 0.7, -vNormalSpeed * 1.0 ) * fElapsedTime;
  Output.f4NormalDeepNoiseUV.zw = f2TerrainUV;
  Output.f3Depth.xy      = Output.f4Position.zw;
  Output.f3Depth.z		 = f4WorldPosition.z;
  
  return Output;
}


//--------------------------------------------------------------------------------------------------
// Pixel shader
//--------------------------------------------------------------------------------------------------
float4 WaterPS( WaterPixel Input, float2 f2ScreenPosition : VPOS ) : COLOR0
{
  float2 f2NormalUV = Input.f4NormalDeepNoiseUV.xy;
  float2 f2DeepNoiseUV = Input.f4NormalDeepNoiseUV.zw;

  float fWaterDestination = vZNearFarAB.w / (Input.f3Depth.x / Input.f3Depth.y - vZNearFarAB.z);
  Input.f3ViewDir = normalize( Input.f3ViewDir );

  // Detail normal kiszamolasa
  float3 f3NormalDetail1    = UnpackNormalMap( Water1DetailMapSampler, Input.f4UV.xy );
  float3 f3NormalDetail2    = UnpackNormalMap( Water2DetailMapSampler, Input.f4UV.zw );
  float3 f3ReflectionNormal = f3NormalDetail1 + f3NormalDetail2;
  f3ReflectionNormal.z     *= fScaleOffsetU * 2;

  // Fo normal kiszamolasa
  float fWavePower = tex2D( NormalMapSampler, f2NormalUV ).r;
  f3ReflectionNormal.xy *= fWavePower * fScaleOffsetV;
  f3ReflectionNormal = normalize( f3ReflectionNormal );
  
  float fNdotL = saturate( dot( -SunDirection, f3ReflectionNormal ) );
  float fNdotV = saturate( dot( Input.f3ViewDir, float3( 0, 0, 1 ) ) );

  float fSceneDepth = vZNearFarAB.w / (GetZ(DepthMapSampler, ( f2ScreenPosition + 0.5 ) * SCREEN_SIZE.zw) - vZNearFarAB.z);

  float fFresnel = Fresnel( fNdotV, fFresnelBias, fFresnelPower );
  float fOpacity = saturate((fSceneDepth - fWaterDestination) / 4);
    
  float2 fBorderFactor = abs((f2ScreenPosition * SCREEN_SIZE.zw - 0.5) * 2.0);
  fBorderFactor = float2(1.0,1.0) - fBorderFactor * fBorderFactor;
  
  static float rScale   = 256;
  float2 f2RefractionUV = ( f2ScreenPosition + f3ReflectionNormal.xy * fOpacity * fBorderFactor * 32) * SCREEN_SIZE.zw;
  float3 f3Refraction   = tex2D( FrameBufferMapSampler, f2RefractionUV ).rgb;
  float  fDepthRange    = saturate( ( fSceneDepth - fWaterDestination ) / fWaterVisualRange );
  float3 f3DeepColor    = tex2D( WaterDeepNoiseMapSampler, f2DeepNoiseUV * 0.005 + f3ReflectionNormal.xy * SCREEN_SIZE.zw ) * vWaterDeepColor;
  f3Refraction          = lerp( f3Refraction, f3DeepColor, fDepthRange );

  float3 f3Reflection   = tex2D( SpecularMapSampler, reflect( -Input.f3ViewDir, f3ReflectionNormal ).xy * 2 ).rgb;

  float4 cColor;
  cColor.rgb  = lerp( f3Refraction, f3Reflection, ( 1 - fFresnel ) * fOpacity ) * vWaterColor.rgb;

  float f3Specular = pow( max( 1e-6, dot( reflect( -Input.f3ViewDir, f3ReflectionNormal ), -SunDirection )) * 0.999, fSpecularPower );
  cColor.rgb += f3Specular * fOpacity * vSpecularColor.rgb;
  cColor.a = fOpacity;
  
  cColor.rgb = ApplyVFog(cColor.rgb, Input.f3Depth.z, verticalFogColor, verticalFogStartEnd);
  
  return cColor;
 }


//--------------------------------------------------------------------------------------------------
// Technique definition
//--------------------------------------------------------------------------------------------------
technique Solid
{
    pass	
    {
		AlphaBlendEnable	= true;
		SrcBlend			= SrcAlpha;
		DestBlend			= InvSrcAlpha;
        vertexShader 		= compile vs_3_0 WaterVS();
        pixelShader  		= compile ps_3_0 WaterPS();
    }    
}
