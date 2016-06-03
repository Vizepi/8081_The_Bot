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
float4x4 	mWorldViewProjection;
float	 	fElapsedTime;

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

//--------------------------------------------------------------------------------------------------
// Material Parameters
//--------------------------------------------------------------------------------------------------
texture  	DiffuseMap;
texture  	NormalMaskMap;
texture  	SpecularMap;
texture  	SelfIllumMap;
float3   	RockDiffuseColor;	  
float3   	LavaDiffuseColor;	
float3   	SpecularMapModulator;
float3   	SelfIllumMapModulator;
float3   	SelfIllumColor;
float    	TexCoordOffsetU;
float    	TexCoordOffsetV;
float    	SpecularLevel;

//--------------------------------------------------------------------------------------------------
// Constants
//--------------------------------------------------------------------------------------------------
static const float TIMESCALE = 4.0f;

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
sampler2D NormalMaskMapSampler = sampler_state
{
	Texture   = <NormalMaskMap>;
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
	float4 texcoord		 : TEXCOORD0;	// Texture coordinates
	float3 worldPos 	 : TEXCOORD1;	// Vertex position (in world space)
	float4 shadtexcoord	 : TEXCOORD2;	// Shadow mapping texcoords
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
	ISOLATE position = mul(vIn.position0, mWorldViewProjection);

	VS_OUTPUT Out;
	Out.texcoord.xy = vIn.texcoord.xy + float2(TexCoordOffsetU, TexCoordOffsetV) * fElapsedTime * TIMESCALE;
	Out.texcoord.zw = vIn.texcoord.xy + float2(TexCoordOffsetU, TexCoordOffsetV * -0.33f) * fElapsedTime * TIMESCALE;
	Out.worldPos = mul(vIn.position0,mWorld);
	Out.shadtexcoord = mul(vIn.position0, mShadowTexture);

	return Out;
}
VS_OUTPUT vs_skin(VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
	skin(vIn);
	ISOLATE position = mul(vIn.position0, mWorldViewProjection);

	VS_OUTPUT Out;
	Out.texcoord.xy = vIn.texcoord.xy + float2(TexCoordOffsetU, TexCoordOffsetV) * fElapsedTime;
	Out.texcoord.zw = vIn.texcoord.xy + float2(TexCoordOffsetU, TexCoordOffsetV * -0.33f) * fElapsedTime;
	Out.worldPos = mul(vIn.position0,mWorld);
	Out.shadtexcoord = mul(vIn.position0, mShadowTexture);

	return Out;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn, in float2 ScreenPos : VPOS) : COLOR
{
	//
	// Get mask between lava and rocks
	float a = tex2D(NormalMaskMapSampler, vIn.texcoord.xy+ float2(TexCoordOffsetU, TexCoordOffsetV) ).r;

	//
	// Get the diffuse color from the diffuse map
	float3 diffuseMapTexel = tex2D(DiffuseMapSampler, vIn.texcoord.xy + float2(TexCoordOffsetU, TexCoordOffsetV)).xyz * a * RockDiffuseColor
	                       + tex2D(DiffuseMapSampler, vIn.texcoord.xy + float2(TexCoordOffsetU, TexCoordOffsetV)).xyz * (1-a) * LavaDiffuseColor;

	//
	// Get the self illumination color from the self illumination map
	float3 selfIllumMapTexel = tex2D(SelfIllumMapSampler, vIn.texcoord.xy).rgb * SelfIllumMapModulator;

	//
	// Get the specular color from the specular map
	float3 specularMapTexel = tex2D(SpecularMapSampler, vIn.texcoord.xy).rgb * SpecularMapModulator;

	//
	// Compute screen position
	ScreenPos = (ScreenPos + VPOS_offset) * SCREEN_SIZE.zw;

	//
	// LightBuffer values
	float4 lightsparams     = tex2D(LightBufferMapSampler, ScreenPos);
	float3 diffuse_color    = lightsparams.xyz;
	float  specular_factor  = lightsparams.w;

	//
	// Final color
	float3 C = AmbientColor;

	//
	// Compute Blinn
	C += Blinn(diffuseMapTexel, diffuse_color, specularMapTexel, SpecularLevel, float2(1,specular_factor));

	//
	// Final color += self illumination term
	C += (selfIllumMapTexel + SelfIllumColor) * (1-a);

    //
    // Shadow
	C *= ComputeShadow(vIn.shadtexcoord, ShadowMapSampler);

	//
	// Fog
	C = ApplyVFog(C, vIn.worldPos.z, verticalFogColor, verticalFogStartEnd);

	//
	// Alpha channel is used by FXAA
	return FXAALuminance(C);
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique Solid
{
	pass
	{
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps();
	}
}

technique SolidSkinning
{
	pass
	{
		VertexShader     = compile vs_3_0 vs_skin();
		PixelShader      = compile ps_3_0 ps();
	}
}
