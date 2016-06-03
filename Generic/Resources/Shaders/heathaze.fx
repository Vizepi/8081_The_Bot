#include "lib\platform.fxh"

//--------------------------------------------------------------------------------------------------
// Parameters
//--------------------------------------------------------------------------------------------------
#if !SH_DX11
texture DiffuseMap    : DiffuseMap    < string UIName = "Diffuse Map"; string name = "default.tga"; string TextureType = "2D"; >;
texture DistortMap    : DistortMap    < string UIName = "Distort Map"; string name = "default.tga"; string TextureType = "2D"; >;
#else
Texture2D DiffuseMap;
Texture2D DistortMap;
#endif

static const float4 vDistortScrollScale = { -0.5, +1.0, +8.0, +4.5 };  // xy = scroll, zw = scale
float fTime;

//--------------------------------------------------------------------------------------------------
// Maps samplers
//--------------------------------------------------------------------------------------------------
#if !SH_DX11
sampler2D DiffuseMapSampler = sampler_state
{
	Texture   = <DiffuseMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

sampler2D DistortMapSampler = sampler_state
{
	Texture   = <DistortMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
};
#else
SamplerState DiffuseMapSampler
{
	Filter 		= Min_Mag_Mip_Point;
	AddressU  	= CLAMP;
	AddressV  	= CLAMP;
};

SamplerState DistortMapSampler
{
	Filter 		= Min_Mag_Mip_Linear;
	AddressU  	= WRAP;
	AddressV  	= WRAP;
};

#endif

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_INPUT
{
	float4	position					: POSITION;
	float3	texcoord_attenuation		: TEXCOORD0;
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4	position					: POSITION;
	float3  texcoord_attenuation		: TEXCOORD0;
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_INPUT vIn)
{
	VS_OUTPUT vOut;
	vOut.position = vIn.position;
	vOut.texcoord_attenuation = vIn.texcoord_attenuation;
	return vOut;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
#if SH_DX11
float4 ps(VS_OUTPUT vIn) : COLOR
{
	float2 ScreenPos = vIn.position.xy;
#else
float4 ps(VS_OUTPUT vIn, float2 ScreenPos : VPOS) : COLOR
{
#endif

	// compute screen texture coord
	ScreenPos = (ScreenPos + 0.5f) * SCREEN_SIZE.zw;

	// fecht sample from distort location that will be blended with the scene
	float2 uv = (ScreenPos.xy * vDistortScrollScale.zw) + vDistortScrollScale.xy * fTime;

#if !SH_DX11
	float3 distort = tex2D( DistortMapSampler, uv ).xyz;
#else
	float3 distort = DistortMap.Sample( DistortMapSampler, uv ).xyz;
#endif

	// part of attenuation is in alpha channel of distort map
#if SH_DX11
	float attenuation = vIn.texcoord_attenuation.z * DistortMap.Sample( DistortMapSampler, vIn.texcoord_attenuation.xy ).a;
#else
	float attenuation = vIn.texcoord_attenuation.z * tex2D( DistortMapSampler, vIn.texcoord_attenuation.xy ).a;
#endif

	// modulate normal vector length with attenuation
	float3 normal  = attenuation * normalize((distort - 0.5f) * 2.0f);
#if SH_DX11
	float3 diffuse = DiffuseMap.Sample( DiffuseMapSampler, ScreenPos + normal.xy );
#else
	float3 diffuse = tex2D( DiffuseMapSampler, ScreenPos + normal.xy );
#endif
	// return full opaque pixel
	return float4(diffuse, 1.0f);
}


//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
#if !SH_DX11
technique
{ 
	pass
	{		
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps();
	}
}

#else
//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique11
{ 
	pass
	{		
		SetVertexShader( CompileShader( vs_4_0, vs() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, ps() ) );
	}
}
#endif

