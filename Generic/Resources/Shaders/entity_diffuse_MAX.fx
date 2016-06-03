//--------------------------------------------------------------------------------------------------
// diffuse material
//--------------------------------------------------------------------------------------------------
#ifdef _3DSMAX_

//
//
//
#include "lib\platform.fxh"
// 3DSMAX 2009 BUG: after including "lib\platform.fxh", MAX sets the current directory to "lib\"
#include "lighting.fxh"

//
// Transformations parameters
//
float4x4 	mWorldViewProjection  	: WORLDVIEWPROJ  		< string UIWidget = "None"; >;

//
// Material parameters
//
float3   DiffuseMapModulator 		: DiffuseMapModulator	< string UIName = "Diffuse map modulator";  > = { 1.0f, 1.0f, 1.0f };

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_INPUT
{
	float4 position		    : POSITION;		// Vertex position
	float2 texcoord		    : TEXCOORD0;	// Texture coordinates
	float3 tangent          : TANGENT;		// Tangent (in local space)
	float3 binormal		    : BINORMAL;		// Binormal (in local space)
	float3 normal           : NORMAL;		// Normal (in local space)
	float3 color            : COLOR;		// Vertex color
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
void vs(in VS_INPUT vIn, out float4 position : POSITION)
{
	//
	// Compute projected position
	position = mul(float4(vIn.position.xyz,1.0f), mWorldViewProjection);
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(void) : COLOR
{
	return(float4(DiffuseMapModulator,1.0f));
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique DefaultTechnique
{
    pass
    {
        VertexShader 	= compile vs_3_0 vs();
        PixelShader  	= compile ps_3_0 ps();
    }
}

#else // _3DSMAX_

technique
{
    pass
    {
        VertexShader 	= null;
        PixelShader  	= null;
    }
}

#endif // _3DSMAX_0,4