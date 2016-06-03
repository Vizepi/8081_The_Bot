//-----------------------------------------------------------------------------
// Global variables
//-----------------------------------------------------------------------------
#include "lib\platform.fxh"

float FadeValue;

//--------------------------------------------------------------------------------------------------
// Transformations
//--------------------------------------------------------------------------------------------------
float4x4 WorldViewProj : WORLDVIEWPROJECTION   < string UIWidget = "None"; >;


//-----------------------------------------------------------------------------
// Texture samplers
//-----------------------------------------------------------------------------

texture 	DiffuseMap   : DiffuseMap       < string UIName = "Diffuse Map ";
                                            string name   = "default.tga";
                                            string TextureType = "2D"; >;
                                           
                                            
                                                                                       
sampler2D DiffuseMapSampler = sampler_state
{
	Texture = <DiffuseMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
};


//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4 position		: POSITION;		// Vertex position
	float2 texcoord		: TEXCOORD0;	// Texture coordinates
};

struct PS_INPUT
{
#if SH_DX11
	float4 position		: POSITION;		// Vertex position
#endif
	float2 texcoord		: TEXCOORD0;	// Texture coordinates
};

//--------------------------------------------------------------------------------------------------
// Vertex shader 
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(float3 position : POSITION, 
             float2 texcoord : TEXCOORD0)
{
  // Zero out our output.
	VS_OUTPUT outVS = (VS_OUTPUT)0;
	
	outVS.position = mul(float4(position, 1.0), WorldViewProj);
	outVS.texcoord = texcoord;
	
		
  return outVS;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader
//--------------------------------------------------------------------------------------------------
float4 ps(PS_INPUT vIn) : COLOR
{
	float4 texcolor = tex2D(DiffuseMapSampler, vIn.texcoord);
	texcolor.a *= FadeValue;
	return texcolor;
}

#if !SH_DX11
//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique DefaultTechnique
{ 
	pass one 
	{		
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps();
	}
}
#else
//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique11 DefaultTechnique
{ 
	pass one 
	{			
		SetVertexShader( CompileShader( vs_4_0, vs() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, ps() ) );
	}
}
#endif
