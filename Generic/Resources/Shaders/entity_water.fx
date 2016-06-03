//--------------------------------------------------------------------------------------------------
// Final pass for water material (rev 1)
//--------------------------------------------------------------------------------------------------
#include "lib\platform.fxh"
#include "lib\lighting.fxh"
#include "lib\skinning.fxh"

//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
float4x4 	mWorld;
float4x4 	mWorldViewProjection;
float3		vCameraPosition;
float		fElapsedTime;

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
// Material Parameters
//--------------------------------------------------------------------------------------------------
texture 	Wave0Map;
texture 	Wave1Map;
texture 	ReflectMap;
texture 	RefractMap;
float2 		WaveMapOffset0;
float2 		WaveMapOffset1;
float 		WaveScale;
float3 		WaterColor;
float3 		SelfIllumColor;
float 		SpecularLevel;

//--------------------------------------------------------------------------------------------------
// Constants
//--------------------------------------------------------------------------------------------------
static const float R0 = 0.02037f; // Fresnel reflection term
static const float TEXSCALE = 5.0f;
static const float TIMESCALE = 4.0f;
static const float WAVESPEED = 0.1f;

//--------------------------------------------------------------------------------------------------
// Maps Samplers
//--------------------------------------------------------------------------------------------------
sampler2D Wave0MapSampler = sampler_state
{
	Texture = <Wave0Map>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};
sampler2D Wave1MapSampler = sampler_state
{
	Texture = <Wave1Map>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};
sampler2D ReflectMapSampler = sampler_state
{
	Texture = <ReflectMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};
sampler2D RefractMapSampler = sampler_state
{
	Texture = <RefractMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};

//--------------------------------------------------------------------------------------------------
// NormalShininess map sampler
//--------------------------------------------------------------------------------------------------
texture         NormalShininessMap;
sampler2D       NormalShininessMapSampler = sampler_state
{
    Texture   = <NormalShininessMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
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
// Vertex shader output structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4 texcoord		 : TEXCOORD0;	// Texture coordinates
	float3 worldPos 	 : TEXCOORD1;	// Vertex position (in world space)
	float4 shadtexcoord	 : TEXCOORD2;	// Shadow mapping texcoords
    float3 toEyeW		 : TEXCOORD3;
    float4 clipPos		 : TEXCOORD4;
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
    ISOLATE position = mul(vIn.position0, mWorldViewProjection);

	VS_OUTPUT Out;
	Out.texcoord.xy = (vIn.texcoord.xy * WaveScale) + WaveMapOffset0 * fElapsedTime * WAVESPEED * TIMESCALE;
	Out.texcoord.zw = (vIn.texcoord.xy * WaveScale) + WaveMapOffset1 * fElapsedTime * WAVESPEED * TIMESCALE;
	Out.worldPos = mul(vIn.position0, mWorld).xyz;
	Out.shadtexcoord = mul(vIn.position0, mShadowTexture);
	Out.toEyeW = Out.worldPos - vCameraPosition;
	Out.clipPos = position;
	return(Out);
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn, in float2 ScreenPos : VPOS) : COLOR
{
	// transform the projective texcoords to NDC space and
	// scale and offset xy to correctly sample a DX texture
	vIn.clipPos.xyz = vIn.clipPos.xyz / vIn.clipPos.w;
	vIn.clipPos.x = 0.5f * vIn.clipPos.x + 0.5f;
	vIn.clipPos.y = -0.5f * vIn.clipPos.y + 0.5f;
	vIn.clipPos.z = .1f / vIn.clipPos.z; //refract more based on distance from the camera

	//
	// Create lighting and view vectors
	float3 V = normalize(vIn.toEyeW);

	//
	// Compute screen position
	ScreenPos = (ScreenPos + VPOS_offset) * SCREEN_SIZE.zw;

	//
	// Get normal value
	float3 N = normalize(tex2D(NormalShininessMapSampler, ScreenPos) * 2.0f - 1.0f);
	float3 M = float3(0,0,1);

	//
	// Compute the fresnel term to blend reflection and refraction maps
	float ang = saturate(dot(V,M));
	float f = R0 + (1.0f-R0) * pow(1.0f-ang,5.0f);

	//
	// Compute the diffuse color using reflection and refraction map
	float3 refl = tex2D(ReflectMapSampler, (vIn.clipPos.xy + vIn.clipPos.z * N.xz)*TEXSCALE);
	float3 refr = tex2D(RefractMapSampler, (vIn.clipPos.xy - vIn.clipPos.z * N.xz)*TEXSCALE);
	float3 diffuseMapTexel = WaterColor * lerp(refr, refl, f);

	//
	// Default specular color and level
	float3 specularMapTexel = diffuseMapTexel;

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
	C += SelfIllumColor + SelfIllumColor2;

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
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps();
	}
}
