//--------------------------------------------------------------------------------------------------
// Normal depth for water material (rev 1)
//--------------------------------------------------------------------------------------------------
#include "lib\platform.fxh"
#include "lib\lighting.fxh"
#include "lib\skinning.fxh"

//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
float4x4 	mWorldIT;
float4x4 	mWorldViewProjection;
float 		fElapsedTime;

//--------------------------------------------------------------------------------------------------
// Material Parameters
//--------------------------------------------------------------------------------------------------
texture 	Wave0Map;
texture 	Wave1Map;
float2 		WaveMapOffset0;
float2 		WaveMapOffset1;
float 		WaveScale;
float 		Shininess;
bool 		FlipNormalMapY;

//--------------------------------------------------------------------------------------------------
// Constants
//--------------------------------------------------------------------------------------------------
static const float	  TEXSCALE = 5.0f;
static const float	  TIMESCALE = 4.0f;
static const float	  WAVESPEED = 0.1f;

//--------------------------------------------------------------------------------------------------
// Maps Samplers
//--------------------------------------------------------------------------------------------------
sampler2D Wave0MapSampler = sampler_state
{
	Texture = <Wave0Map>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};
sampler2D Wave1MapSampler = sampler_state
{
	Texture = <Wave1Map>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};

//--------------------------------------------------------------------------------------------------
// Vertex shader output structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4	texcoord1_depth  : TEXCOORD0;	// Texture coordinates 1 / Depth zw
	float2  texcoord2		 : TEXCOORD1;	// Texture coordinates 2
	float4	worldNormal		 : TEXCOORD2;	// Normal (in world space)
	float3	worldTangent	 : TEXCOORD3;	// Tangent (in world space)
	float3	worldBinormal	 : TEXCOORD4;	// Binormal (in world space)
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(in VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
	ISOLATE position = mul(vIn.position0, mWorldViewProjection);

	//
	// Output structure declaration
	VS_OUTPUT Out;

	//
	// Compute normal in world space
	Out.worldNormal.xyz = normalize(mul(vIn.normal0, (float3x3)mWorldIT).xyz);

	//
	// Compute tangent in world space
	Out.worldTangent = normalize(mul(vIn.tangent0, (float3x3)mWorldIT).xyz);
	if (FlipNormalMapY == true)
	{
		Out.worldTangent = -Out.worldTangent;
	}

	//
	// Compute binormal in world space
	Out.worldBinormal = normalize(mul(vIn.binormal0, (float3x3)mWorldIT).xyz);

	//
	// Forward texture coordinates
	Out.texcoord1_depth.zw = position.zw;
	Out.texcoord1_depth.xy 	= (vIn.texcoord.xy * WaveScale) + WaveMapOffset0 * fElapsedTime * WAVESPEED * TIMESCALE;
	Out.texcoord2 			= (vIn.texcoord.xy * WaveScale) + WaveMapOffset1 * fElapsedTime * WAVESPEED * TIMESCALE;
	Out.worldNormal.w = Shininess / 128.0f;
	
	return Out;
}


//--------------------------------------------------------------------------------------------------
// Pixel shader output structure
//--------------------------------------------------------------------------------------------------
struct PS_OUTPUT
{
	float4 Normal_Shininess : COLOR0;
#if SH_PC
	float4 Depth  : COLOR1;
#endif
};

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
PS_OUTPUT ps(VS_OUTPUT vIn)
{
	PS_OUTPUT Out;

	//
	// Get the normal from the normal map
	float3 normalT0 = UnpackNormalMap(Wave0MapSampler, vIn.texcoord1_depth.xy);
	float3 normalT1 = UnpackNormalMap(Wave1MapSampler, vIn.texcoord2.xy);

	//
	// Compute normal map
	float3 N = ApplyNormalMapping((normalT0+normalT1)/2.0, vIn.worldTangent, vIn.worldBinormal, vIn.worldNormal);

	//
	// Pack the outputs into RGBA8
	Out.Normal_Shininess.xyz = N * 0.5f + 0.5f;
	Out.Normal_Shininess.w   = vIn.worldNormal.w;
#if SH_PC
	Out.Depth                = vIn.texcoord1_depth.z / vIn.texcoord1_depth.w;
#endif

	return Out;
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique Solid
{
    pass
    {
        VertexShader 	= compile vs_3_0 vs();
        PixelShader  	= compile ps_3_0 ps();
    }
}
technique SolidSkinning
{
    pass
    {
        VertexShader 	= compile vs_3_0 vs();
        PixelShader  	= compile ps_3_0 ps();
    }
}
