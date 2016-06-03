//--------------------------------------------------------------------------------------------------
// Standard material
//--------------------------------------------------------------------------------------------------

//
// Includes
//
#include "lib\platform.fxh"

//
// Transformations parameters
//
float4x4 WorldViewProjection : WORLDVIEWPROJECTION   < string UIWidget = "None"; >;

//
// DiffuseColor Color
//
float4 DiffuseColor;

#if !SH_DX11
//
// Textures
//
texture TextureMap;
texture TileSet;

//
// Samplers
//
sampler2D TextureMapSampler = sampler_state
{
	Texture   = <TextureMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

sampler2D TileSetSampler = sampler_state
{
	Texture   = <TileSet>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};
#else
Texture2D TextureMap;
Texture2D TileSet;

SamplerState point_clamp_sampler
{
	Filter = Min_Mag_Linear_Mip_Point;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

#endif

uniform float2	TextureMapSize;
uniform float2	TileSetSize;

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_INPUT
{
	float2	position	 : POSITION;		// Vertex position
	float2	texcoord	 : TEXCOORD0;		// Texture coordinates
	float4  color        : COLOR;       	// Vertex Color
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4  position        : POSITION;		// Vertex position
	float2  texcoord        : TEXCOORD0;	// Texture coordinates
	float4  color           : COLOR;        // Vertex Color
};

//--------------------------------------------------------------------------------------------------
// 2D elements in clip-space [-1,+1] with position.xy and texcoord.xy
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
	vOut.position = mul(float4(vIn.position,0,1), WorldViewProjection);
	
	//
	// Pass color to the pixel shader
	vOut.color = vIn.color;
	
	//
	// Add half pixel offset
#if SH_PC || SH_X360
	vOut.position.x = vOut.position.x - SCREEN_SIZE.z;
	vOut.position.y = vOut.position.y + SCREEN_SIZE.w;
#endif // SH_PC || SH_X360

	return vOut;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn) : COLOR
{
#if SH_DX11
	float4 textureColor = TextureMap.Sample(point_clamp_sampler, vIn.texcoord);
#else
	float4 textureColor = tex2D(TextureMapSampler, vIn.texcoord);
#endif
	return float4(1.0f, 1.0f, 1.0f, textureColor.w) * vIn.color * DiffuseColor;
}

#if !SH_DX11
//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique DefaultTechnique
{ 
	pass
	{
		VertexShader = compile vs_3_0 vs();
		PixelShader  = compile ps_3_0 ps();
	}
}
#else
//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique11 DefaultTechnique
{ 
	pass
	{		
		SetVertexShader( CompileShader( vs_4_0, vs() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, ps() ) );
	}
}
#endif
