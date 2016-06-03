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
texture TextureMap : TextureMap < string UIName = "Diffuse Map"; string name = "_nomap_white.tga"; string TextureType = "2D"; >;

//
// Samplers
//
sampler2D TextureMapSampler = sampler_state
{
	Texture   = <TextureMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

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

struct VS_OUTPUT
{
	float4  position        : POSITION;		// Vertex position
	float2  texcoord        : TEXCOORD0;	// Texture coordinates
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_INPUT vIn)
{
	//
	// Output structure declaration
	VS_OUTPUT vOut;

	//
	// Forward texture coordinates
	vOut.texcoord = vIn.texcoord;

	//
	// Compute projected position
	vOut.position = mul(float4(vIn.position), mWorldViewProjection);

	return vOut;}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn) : COLOR
{
	float4 textureColor = tex2D(TextureMapSampler, vIn.texcoord);
	return(textureColor);
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