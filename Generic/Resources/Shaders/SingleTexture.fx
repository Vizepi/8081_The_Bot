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
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

sampler2D TileSetSampler = sampler_state
{
	Texture   = <TileSet>;
	MinFilter = POINT;
	MagFilter = POINT;
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
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_INPUT_COLOR
{
	float2	position	 : POSITION;		// Vertex position
	float2	texcoord	 : TEXCOORD0;		// Texture coordinates
	float4  color        : COLOR;       	// Vertex Color
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_INPUT_POSITION4
{
	float4	position	 : POSITION;		// Vertex position
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
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT_COLOR
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
	// Add half pixel offset
#if SH_PC || SH_X360
	vOut.position.x = vOut.position.x - SCREEN_SIZE.z;
	vOut.position.y = vOut.position.y + SCREEN_SIZE.w;
#endif // SH_PC || SH_X360

	return vOut;
}

//--------------------------------------------------------------------------------------------------
// 2D elements in screen-sapce [0,SCREENW/H] with position.xy and texcoord.xy
//--------------------------------------------------------------------------------------------------
VS_OUTPUT_COLOR vs_screenspace(VS_INPUT_COLOR vIn)
{
	//
	// Output structure declaration
	VS_OUTPUT_COLOR vOut;

	//
	// Forward texture coordinates
	vOut.texcoord = vIn.texcoord;
	
	//
	// Forward vertex color
	vOut.color = vIn.color;

	//
	// Compute clip space position from:
	// [0,SCREEN_SIZE.X] to [-1,+1] and [0,SCREEN_SIZE.Y] to [+1,-1] with SCREEN_SIZE.zw = 1.0f / SCREEN_SIZE.xy
	vOut.position.x = -1.0f + vIn.position.x * 2.0f * SCREEN_SIZE.z;
	vOut.position.y = +1.0f - vIn.position.y * 2.0f * SCREEN_SIZE.w;
	vOut.position.z = 0.0f;
	vOut.position.w = 1.0f;

	return vOut;
}

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT_COLOR vs_position4(VS_INPUT_POSITION4 vIn)
{
	//
	// Output structure declaration
	VS_OUTPUT_COLOR vOut;

	//
	// Forward texture coordinates
	vOut.texcoord = vIn.texcoord;
	
	//
	// Forward vertex color
	vOut.color = vIn.color;

	//
	// Compute projected position
	vOut.position = mul(vIn.position, WorldViewProjection);

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
	return textureColor * DiffuseColor;
}

float4 GetTiledPixel(float2 uv)
{
#if SH_DX11
	float4 tile = TextureMap.Sample(point_clamp_sampler, uv).bgra;
#else
	float4	tile = tex2D(TextureMapSampler, uv).bgra;			// load the tilemap value
#endif
	float2	tileIndex = (tile.xz * 255) + (tile.yw * 255 * 256);	// convert to integer tile X,Y
	tileIndex = round(tileIndex);									// *exact* integer, please!
	float2	tileSubUv = uv * TextureMapSize;				// convert UV to pixel index within tilemap; each pixel is a single tile
	tileIndex += frac(tileSubUv);							// the fractional part is added to the tile index to address the correct pixel in the tile
	tileIndex *= 8;									// now pixel index in the tileset
	tileIndex /= TileSetSize;							// now UV in the tileset
#if !SH_DX11
	return tex2D(TileSetSampler, tileIndex);
#else
	return TileSet.Sample(point_clamp_sampler, tileIndex);
#endif
}

float4 ps_tile(VS_OUTPUT vIn) : COLOR
{
	float4	textureColor = GetTiledPixel(vIn.texcoord);
	return textureColor * DiffuseColor;
}

float4 psSC(VS_OUTPUT_COLOR vIn) : COLOR
{
#if SH_DX11
	float4 textureColor = TextureMap.Sample(point_clamp_sampler, vIn.texcoord);
#else
	float4 textureColor = tex2D(TextureMapSampler, vIn.texcoord);
#endif

	return textureColor * vIn.color;
}

float4 psSC_tile(VS_OUTPUT_COLOR vIn) : COLOR
{
	float4	textureColor = GetTiledPixel(vIn.texcoord);
	return textureColor * vIn.color;
}

float4 ps3(VS_OUTPUT_COLOR vIn) : COLOR
{
#if !SH_DX11
	float4 textureColor = tex2D(TextureMapSampler, vIn.texcoord);
#else
	float4 textureColor = TextureMap.Sample(point_clamp_sampler, vIn.texcoord);
#endif
	return textureColor * vIn.color * DiffuseColor;
}

float4 ps3_tile(VS_OUTPUT_COLOR vIn) : COLOR
{
	float4 textureColor = GetTiledPixel(vIn.texcoord);
	return textureColor * vIn.color * DiffuseColor;
}

float4 psPickBuffer(VS_OUTPUT_COLOR vIn) : COLOR
{
#if !SH_DX11
	float4 textureColor = tex2D(TextureMapSampler, vIn.texcoord);
#else
	float4 textureColor = TextureMap.Sample(point_clamp_sampler, vIn.texcoord);
#endif

	clip(textureColor.a < 0.5f ? -1 : 1);
	return DiffuseColor;
}

float4 psPickBuffer_tile(VS_OUTPUT_COLOR vIn) : COLOR
{
	float4 textureColor = GetTiledPixel(vIn.texcoord);
	clip(textureColor.a < 0.5f ? -1 : 1);
	return DiffuseColor;
}

float4 psFrozen(VS_OUTPUT_COLOR vIn) : COLOR
{
#if !SH_DX11
	float4 textureColor = tex2D(TextureMapSampler, vIn.texcoord);
#else
	float4 textureColor = TextureMap.Sample(point_clamp_sampler, vIn.texcoord);
#endif

	float grayscale = 0.30 * textureColor.r + 0.59 * textureColor.g + 0.11 * textureColor.b;
	grayscale = 0.2 + grayscale * 0.2;
	return float4(grayscale, grayscale, grayscale, textureColor.a);
}

float4 psFrozen_tile(VS_OUTPUT_COLOR vIn) : COLOR
{
	float4 textureColor = GetTiledPixel(vIn.texcoord);
	float grayscale = 0.30 * textureColor.r + 0.59 * textureColor.g + 0.11 * textureColor.b;
	grayscale = 0.2 + grayscale * 0.2;
	return float4(grayscale, grayscale, grayscale, textureColor.a);
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

technique DefaultTechniqueSC
{ 
	pass
	{	
		VertexShader = compile vs_3_0 vs_screenspace();
		PixelShader  = compile ps_3_0 psSC();
	}
}

technique DefaultTechnique3
{ 
	pass
	{	
		VertexShader = compile vs_3_0 vs_position4();
		PixelShader  = compile ps_3_0 ps3();
	}
}

technique DefaultTechniquePickBuffer
{ 
	pass
	{	
		VertexShader = compile vs_3_0 vs_position4();
		PixelShader  = compile ps_3_0 psPickBuffer();
	}
}

technique DefaultTechniqueFrozen
{ 
	pass
	{	
		VertexShader = compile vs_3_0 vs_position4();
		PixelShader  = compile ps_3_0 psFrozen();
	}
}

technique DefaultTechnique_Tile
{ 
	pass
	{
		VertexShader = compile vs_3_0 vs();
		PixelShader  = compile ps_3_0 ps_tile();
	}
}

technique DefaultTechniqueSC_Tile
{ 
	pass
	{	
		VertexShader = compile vs_3_0 vs_screenspace();
		PixelShader  = compile ps_3_0 psSC_tile();
	}
}

technique DefaultTechnique3_Tile
{ 
	pass
	{	
		VertexShader = compile vs_3_0 vs_position4();
		PixelShader  = compile ps_3_0 ps3_tile();
	}
}

technique DefaultTechniquePickBuffer_Tile
{ 
	pass
	{	
		VertexShader = compile vs_3_0 vs_position4();
		PixelShader  = compile ps_3_0 psPickBuffer_tile();
	}
}

technique DefaultTechniqueFrozen_Tile
{ 
	pass
	{	
		VertexShader = compile vs_3_0 vs_position4();
		PixelShader  = compile ps_3_0 psFrozen_tile();
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

technique11 DefaultTechniqueSC
{ 
	pass
	{	
		SetVertexShader( CompileShader( vs_4_0, vs_screenspace() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, psSC() ) );
	}
}

technique11 DefaultTechnique3
{ 
	pass
	{	
		SetVertexShader( CompileShader( vs_4_0, vs_position4() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, ps3() ) );
	}
}

technique11 DefaultTechniquePickBuffer
{ 
	pass
	{	
		SetVertexShader( CompileShader( vs_4_0, vs_position4() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, psPickBuffer() ) );
	}
}

technique11 DefaultTechniqueFrozen
{ 
	pass
	{	
		SetVertexShader( CompileShader( vs_4_0, vs_position4() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, psFrozen() ) );
	}
}

technique11 DefaultTechnique_Tile
{ 
	pass
	{	
		SetVertexShader( CompileShader( vs_4_0, vs() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, ps_tile() ) );
	}
}

technique11 DefaultTechniqueSC_Tile
{ 
	pass
	{	
		SetVertexShader( CompileShader( vs_4_0, vs_screenspace() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, psSC_tile() ) );
	}
}

technique11 DefaultTechnique3_Tile
{ 
	pass
	{	
		SetVertexShader( CompileShader( vs_4_0, vs_position4() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, ps3_tile() ) );
	}
}

technique11 DefaultTechniquePickBuffer_Tile
{ 
	pass
	{	
		SetVertexShader( CompileShader( vs_4_0, vs_position4() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, psPickBuffer_tile() ) );
	}

}

technique11 DefaultTechniqueFrozen_Tile
{ 
	pass
	{	
		SetVertexShader( CompileShader( vs_4_0, vs_position4() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, psFrozen_tile() ) );
		
	}
}

#endif
