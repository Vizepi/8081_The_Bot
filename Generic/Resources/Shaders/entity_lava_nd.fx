//--------------------------------------------------------------------------------------------------
// Normal depth for standard material (rev 1)
//--------------------------------------------------------------------------------------------------
#include "lib\platform.fxh"
#include "lib\lighting.fxh"
#include "lib\skinning.fxh"

//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
float4x4 mWorldIT;
float4x4 mWorldViewProjection;
float	 fElapsedTime;

//--------------------------------------------------------------------------------------------------
// Material Parameters
//--------------------------------------------------------------------------------------------------
texture  NormalFusionMap;
texture  NormalFusion2Map;
texture  NormalRockMap;
texture  NormalMaskMap;
float    Shininess;
float    TexCoordOffsetU;
float    TexCoordOffsetV;
bool 	 FlipNormalMapY;

//--------------------------------------------------------------------------------------------------
// Constants
//--------------------------------------------------------------------------------------------------
static const float TIMESCALE = 4.0f;

//--------------------------------------------------------------------------------------------------
// Maps Samplers
//--------------------------------------------------------------------------------------------------
sampler2D NormalFusionMapSampler = sampler_state
{
	Texture   = <NormalFusionMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};
sampler2D NormalFusion2MapSampler = sampler_state
{
	Texture   = <NormalFusion2Map>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};
sampler2D NormalRockMapSampler = sampler_state
{
	Texture   = <NormalRockMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};
sampler2D NormalMaskMapSampler = sampler_state
{
	Texture   = <NormalMaskMap>;
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
VS_OUTPUT vs(in VS_SKIN_INPUT vIn, in float2 depth)
{
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
	Out.texcoord1_depth.zw 	= depth;
	Out.texcoord1_depth.xy 	= vIn.texcoord.xy + float2(TexCoordOffsetU, TexCoordOffsetV) * fElapsedTime * TIMESCALE;
	Out.texcoord2 			= vIn.texcoord.xy + float2(TexCoordOffsetU, TexCoordOffsetV * -0.33f) * fElapsedTime * TIMESCALE;
	Out.worldNormal.w = Shininess / 128.0f;

	return Out;
}
VS_OUTPUT vs_noskin(VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
	ISOLATE position = mul(vIn.position0, mWorldViewProjection);
	return vs(vIn, position.zw);
}
VS_OUTPUT vs_skin(VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
	skin(vIn);
	ISOLATE position = mul(vIn.position0, mWorldViewProjection);
	return vs(vIn, position.zw);
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
	// Get UVs
	float2 uv1 = vIn.texcoord1_depth.xy;
	float2 uv2 = vIn.texcoord2;
	
	//
	// Get mask between lava and rocks
	float a = tex2D(NormalMaskMapSampler, uv1).r;
	
	//
	// Compute normal map texel
	float3 normalMapFusionTexel = UnpackNormalMap(NormalFusionMapSampler, uv1)
								* UnpackNormalMap(NormalFusionMapSampler, uv2)
								* UnpackNormalMap(NormalFusion2MapSampler, uv1);
	float3 normalMapRockTexel	= UnpackNormalMap(NormalRockMapSampler, uv1);
    float3 normalMapTexel = a * normalMapRockTexel + (1 - a) * normalMapFusionTexel;
	float3 N = ApplyNormalMapping(normalMapTexel, vIn.worldTangent, vIn.worldBinormal, vIn.worldNormal);

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
		VertexShader     = compile vs_3_0 vs_noskin();
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
