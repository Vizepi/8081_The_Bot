//--------------------------------------------------------------------------------------------------
// Mask material (rev 1)
//--------------------------------------------------------------------------------------------------
#include "lib\platform.fxh"
#include "lib\lighting.fxh"
#include "lib\skinning.fxh"

//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
float4x4 mWorld;
float4x4 mWorldViewProjection;
float fElapsedTime;

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
float3   	AmbientColor;
float3		SelfIllumColor2;

//--------------------------------------------------------------------------------------------------
// Material parameters
//--------------------------------------------------------------------------------------------------
texture DiffuseMap;
texture OpacityMap;
texture SelfIllumMap;
texture MaskMap;
float3 DiffuseMapModulator;
float3 SelfIllumMapModulator;
float3 SelfIllumColor;
float DiffuseSpeedU;
float DiffuseSpeedV;
float OpacitySpeedU;
float OpacitySpeedV;
float SelfIllumSpeedU;
float SelfIllumSpeedV;
float MaskSpeedU;
float MaskSpeedV;		

//--------------------------------------------------------------------------------------------------
// Constants
//--------------------------------------------------------------------------------------------------
static const float	UVSCROLL_SPEED_SCALE = 0.125f;

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
sampler2D MaskMapSampler = sampler_state
{
	Texture   = <MaskMap>;
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
	float3 worldPos 	 		: TEXCOORD0;	// Vertex position (in world space)
	float4 shadtexcoord	 		: TEXCOORD1;	// Shadow mapping texcoords
	
	float2 texcoord_diffuse 	: TEXCOORD2;	// Texture coordinates 0
	float2 texcoord_opacity 	: TEXCOORD3;	// Texture coordinates 1
	float2 texcoord_selfillum 	: TEXCOORD4;	// Texture coordinates 2
	float2 texcoord_mask 		: TEXCOORD5;	// Texture coordinates 3
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
	ISOLATE position = mul(vIn.position0, mWorldViewProjection);

	VS_OUTPUT Out;
	Out.worldPos = mul(vIn.position0,mWorld);
	Out.shadtexcoord = mul(vIn.position0, mShadowTexture);

	//
	// Forward texture coordinates
	Out.texcoord_diffuse.xy = vIn.texcoord.xy + float2(DiffuseSpeedU, DiffuseSpeedV) * fElapsedTime * UVSCROLL_SPEED_SCALE;
	Out.texcoord_opacity.xy = vIn.texcoord.xy + float2(OpacitySpeedU, OpacitySpeedV) * fElapsedTime * UVSCROLL_SPEED_SCALE;
	Out.texcoord_selfillum.xy = vIn.texcoord.xy + float2(SelfIllumSpeedU, SelfIllumSpeedV) * fElapsedTime * UVSCROLL_SPEED_SCALE;
	Out.texcoord_mask.xy = vIn.texcoord.xy + float2(MaskSpeedU, MaskSpeedV) * fElapsedTime * UVSCROLL_SPEED_SCALE;
	
	return Out;
}
VS_OUTPUT vs_skin(VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
	skin(vIn);
	ISOLATE position = mul(vIn.position0, mWorldViewProjection);

	VS_OUTPUT Out;
	Out.worldPos = mul(vIn.position0,mWorld);
	Out.shadtexcoord = mul(vIn.position0, mShadowTexture);

	//
	// Forward texture coordinates
	Out.texcoord_diffuse.xy = vIn.texcoord.xy + float2(DiffuseSpeedU, DiffuseSpeedV) * fElapsedTime * UVSCROLL_SPEED_SCALE;
	Out.texcoord_opacity.xy = vIn.texcoord.xy + float2(OpacitySpeedU, OpacitySpeedV) * fElapsedTime * UVSCROLL_SPEED_SCALE;
	Out.texcoord_selfillum.xy = vIn.texcoord.xy + float2(SelfIllumSpeedU, SelfIllumSpeedV) * fElapsedTime * UVSCROLL_SPEED_SCALE;
	Out.texcoord_mask.xy = vIn.texcoord.xy + float2(MaskSpeedU, MaskSpeedV) * fElapsedTime * UVSCROLL_SPEED_SCALE;
	
	return Out;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn, in float2 ScreenPos : VPOS) : COLOR
{
	//
	// Compute screen position
	ScreenPos = (ScreenPos + VPOS_offset) * SCREEN_SIZE.zw;

	//
	// Get the diffuse color from the diffuse map
	float3 diffuseMapTexel = tex2D(DiffuseMapSampler, vIn.texcoord_diffuse.xy).rgb * DiffuseMapModulator;

	//
	// Get the opacity factor from the opacity map
	float opacityMapTexel = tex2D(OpacityMapSampler, vIn.texcoord_opacity.xy).r;

	//
	// Get the self illumination color from the self illumination map
	float3 selfIllumMapTexel = tex2D(SelfIllumMapSampler, vIn.texcoord_selfillum.xy).rgb * SelfIllumMapModulator;

	//
	// Get the mask value from the mask map
	float maskMapTexel = tex2D(MaskMapSampler, vIn.texcoord_mask.xy).r;
	
	//
	// Final opacity value
	float opacityMask = opacityMapTexel * maskMapTexel;
	
	//
	// LightBuffer values
	float4 lightsparams = tex2D(LightBufferMapSampler, ScreenPos);

	//
	// Final color = Ambient + Diffuse + Specular
	float3 C = AmbientColor;

	//
	// Fake color
	const float diffuseFactor = 0.5f;
	const float lightingFactor = 0.7f;
	C += diffuseMapTexel * (lightsparams * lightingFactor + diffuseFactor);

	//
	// Final color += self illumination term
	C += selfIllumMapTexel + SelfIllumColor + SelfIllumColor2;

	//
    // Shadow
	C *= ComputeShadow(vIn.shadtexcoord, ShadowMapSampler);

	//
	// Fog
	C = ApplyVFog(C, vIn.worldPos.z, verticalFogColor, verticalFogStartEnd);
	
	//
	// Final color opacity
	return float4(C, opacityMask);
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
