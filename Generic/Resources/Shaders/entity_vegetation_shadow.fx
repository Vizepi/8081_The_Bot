//--------------------------------------------------------------------------------------------------
// Shadow shader for vegetation material (rev 1)
//--------------------------------------------------------------------------------------------------
#include "lib\platform.fxh"
#include "lib\skinning.fxh"

//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
float4x4 mWorldViewProjection;

//--------------------------------------------------------------------------------------------------
// Material Parameters
//--------------------------------------------------------------------------------------------------

float    TexCoordOffsetU;
float    TexCoordOffsetV;

//--------------------------------------------------------------------------------------------------
// Wind Parameters
//--------------------------------------------------------------------------------------------------
float4 WindParams = float4(0.0f, 0.0f, 1.0f, 0.0f);

//--------------------------------------------------------------------------------------------------
// Maps Samplers
//--------------------------------------------------------------------------------------------------
#if !SH_DX11
texture  OpacityMap;
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
Texture2D  OpacityMap;
SamplerState OpacityMapSampler 
{
	Filter = Min_Mag_Linear_Mip_Point;
	AddressU  = WRAP;
	AddressV  = WRAP;
	MipLODBias = DEFAULT_TEXTURELODBIAS;
};
#endif

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4	position		: POSITION;		// Vertex position
	float4	texcoord_depth  : TEXCOORD0;	// Texture coordinates and Depth value
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(in VS_SKIN_INPUT vIn)
{
	//
	// Output structure declaration
	VS_OUTPUT Out;
	
	//
	// Compute projected position
	Out.position = mul(vIn.position0, mWorldViewProjection);
	Out.texcoord_depth.xy = vIn.texcoord + float2(TexCoordOffsetU,TexCoordOffsetV);
	Out.texcoord_depth.zw = Out.position.zw;

	return Out;
}
VS_OUTPUT vs_noskin(in VS_SKIN_INPUT vIn)
{
	wind(vIn.position0.xyz, WindParams.xy, WindParams.z);
	return(vs(vIn));
}
VS_OUTPUT vs_skin(in VS_SKIN_INPUT vIn)
{
	skin(vIn);
	wind(vIn.position0.xyz, WindParams.xy, WindParams.z);
	return(vs(vIn));
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn) : COLOR
{
#if SH_DX11
	float opacityMapTexel = OpacityMap.Sample(OpacityMapSampler, vIn.texcoord_depth.xy).r;
#else
	float opacityMapTexel = tex2D(OpacityMapSampler, vIn.texcoord_depth.xy).r;
#endif
	clip(opacityMapTexel - FLOAT_ALPHA_REF);
#if !SH_PS3
	return(vIn.texcoord_depth.z/vIn.texcoord_depth.w);
#else
	return float4(0,0,0,0);
#endif
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