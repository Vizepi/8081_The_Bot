//--------------------------------------------------------------------------------------------------
// Shadow shader for extented material (rev 1)
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
texture  OpacityMap;
float    TexCoordOffsetU;
float    TexCoordOffsetV;

//--------------------------------------------------------------------------------------------------
// Maps Samplers
//--------------------------------------------------------------------------------------------------
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
	Out.texcoord_depth.xy = vIn.texcoord;
	Out.texcoord_depth.zw = Out.position.zw;

	return Out;
}
VS_OUTPUT vs_noskin(in VS_SKIN_INPUT vIn)
{
	return(vs(vIn));
}
VS_OUTPUT vs_skin(in VS_SKIN_INPUT vIn)
{
	skin(vIn);
	return(vs(vIn));
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn) : COLOR
{
	float opacityMapTexel = tex2D(OpacityMapSampler, vIn.texcoord_depth.xy).r;
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