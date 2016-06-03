//--------------------------------------------------------------------------------------------------
// Normal depth for vegetation material (rev 1)
//--------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
float4x4 mWorldIT;
float4x4 mWorldViewProjection;


//--------------------------------------------------------------------------------------------------
// Material Parameters
//--------------------------------------------------------------------------------------------------

float    Shininess;
bool 	 FlipNormalMapY;


//--------------------------------------------------------------------------------------------------
// Wind Parameters
//--------------------------------------------------------------------------------------------------
float4 WindParams = float4(0.0f, 0.0f, 1.0f, 0.0f);

#include "lib\platform.fxh"
#include "lib\lighting.fxh"
#include "lib\skinning.fxh"
//--------------------------------------------------------------------------------------------------
// Maps Samplers
//--------------------------------------------------------------------------------------------------
#if !SH_DX11
texture  NormalMap;
texture  OpacityMap;
sampler2D NormalMapSampler = sampler_state
{
	Texture   = <NormalMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
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
#else 
Texture2D  NormalMap;
Texture2D  OpacityMap;

SamplerState NormalMapSampler 
{
	Filter = Min_Mag_Mip_Linear;
	AddressU  = WRAP;
	AddressV  = WRAP;
	MipLODBias = DEFAULT_TEXTURELODBIAS;
};
SamplerState OpacityMapSampler 
{
	Filter = Min_Mag_Linear_Mip_Point;
	AddressU  = WRAP;
	AddressV  = WRAP;
	MipLODBias = DEFAULT_TEXTURELODBIAS;
};
#endif

//--------------------------------------------------------------------------------------------------
// Vertex shader output structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4	texcoord_depth   : TEXCOORD0;	// Texture coordinates / Depth zw
	float4	worldNormal		 : TEXCOORD1;	// Normal (in world space)
	float3	worldTangent	 : TEXCOORD2;	// Tangent (in world space)
	float3	worldBinormal	 : TEXCOORD3;	// Binormal (in world space)
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
	Out.texcoord_depth.xy = vIn.texcoord;
	Out.texcoord_depth.zw = depth;
	Out.worldNormal.w = Shininess / 128.0f;

	return Out;
}
VS_OUTPUT vs_noskin(VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
	wind(vIn.position0.xyz, WindParams.xy, WindParams.z);
	ISOLATE position = mul(vIn.position0, mWorldViewProjection);
	return vs(vIn, position.zw);
}
VS_OUTPUT vs_skin(VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
	skin(vIn);
	wind(vIn.position0.xyz, WindParams.xy, WindParams.z);
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
	// Alpha test
#if SH_DX11
	float opacityMapTexel = OpacityMap.Sample(OpacityMapSampler, vIn.texcoord_depth.xy).r;
#else
	float opacityMapTexel = tex2D(OpacityMapSampler, vIn.texcoord_depth.xy).r;
#endif
	clip(opacityMapTexel - FLOAT_ALPHA_REF);

	//
	// Get the normal from the normal map
#if SH_DX11
	float3 normalMapTexel = UnpackNormalMap(NormalMap, NormalMapSampler, vIn.texcoord_depth.xy);
#else
	float3 normalMapTexel = UnpackNormalMap(NormalMapSampler, vIn.texcoord_depth.xy);
#endif

	//
	// Compute normal map
	float3 N = ApplyNormalMapping(normalMapTexel, vIn.worldTangent, vIn.worldBinormal, vIn.worldNormal);

	//
	// Pack the outputs into RGBA8
	Out.Normal_Shininess.xyz = N * 0.5f + 0.5f;
	Out.Normal_Shininess.w   = vIn.worldNormal.w;
#if SH_PC
	Out.Depth                = vIn.texcoord_depth.z / vIn.texcoord_depth.w;
#endif

	return Out;
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
#if !SH_DX11
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
#else
technique11 Solid
{
	pass
	{
		SetVertexShader( CompileShader( vs_4_0, vs_noskin() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, ps() ) );
	}
}

technique11 SolidSkinning
{
	pass
	{
		SetVertexShader( CompileShader( vs_4_0, vs_skin() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, ps() ) );
	}
}
#endif