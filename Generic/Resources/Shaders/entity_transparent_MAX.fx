//--------------------------------------------------------------------------------------------------
// Transparent material (rev 4)
//--------------------------------------------------------------------------------------------------
#ifdef _3DSMAX_

//
//
//
#include "lib\lighting.fxh"

//
// Transformations parameters
//
float4x4 mWorld  				: WORLD					< string UIWidget = "None"; >;
float4x4 mWorldIT				: WORLDINVERSETRANSPOSE	< string UIWidget = "None"; >;
float4x4 mWorldViewProjection	: WORLDVIEWPROJECTION	< string UIWidget = "None"; >;
float4x4 mViewInv               : VIEWINVERSE           < string UIWidget = "None"; >;

//
// Material parameters
//
float3   AmbientColor 	        : Ambient               < > = {0.0f, 0.0f, 0.0f};

texture  DiffuseMap 	        : DiffuseMap            < string UIName = "Diffuse Map"; string name = "_nomap_white.tga"; string TextureType = "2D"; >;
texture  OpacityMap 	        : OpacityMap            < string UIName = "Opacity Map"; string name = "_nomap_white.tga"; string TextureType = "2D"; >;
texture  SelfIllumMap	        : SelfIllumMap          < string UIName = "Self-Illum Map"; string name = "_nomap_black.tga"; string TextureType = "2D"; >;

float3   DiffuseMapModulator 	: DiffuseMapModulator	< string UIName = "Diffuse map modulator";  > = {1.0f, 1.0f, 1.0f};
float3   SelfIllumMapModulator  : SelfIllumMapModulator	< string UIName = "Self-Illum map modulator"; > = {0.0f, 0.0f, 0.0f};
float3   SelfIllumColor         : SelfIllumColor        < string UIName = "Self-Illum color"; > = {0.0f, 0.0f, 0.0f};

float    TexCoordOffsetU		: TexCoordOffsetU		< string UIName = "Texture Coordinate Offset U"; > = 0.0f;
float    TexCoordOffsetV		: TexCoordOffsetV		< string UIName = "Texture Coordinate Offset V"; > = 0.0f;

static const float3   TESTLightBufferColor   : TESTLightBufferColor	< > = {0.5f, 0.5f, 0.5f};

//--------------------------------------------------------------------------------------------------
// Maps samplers
//--------------------------------------------------------------------------------------------------
sampler2D DiffuseMapSampler = sampler_state
{
	Texture   = <DiffuseMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP;
	AddressV  = WRAP;
};
sampler2D OpacityMapSampler = sampler_state
{
	Texture   = <OpacityMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP;
	AddressV  = WRAP;
};
sampler2D SelfIllumMapSampler = sampler_state
{
	Texture   = <SelfIllumMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
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
	float4 position         : POSITION;     // Vertex position
	float2 texcoord         : TEXCOORD0;	// Texture coordinates
	float3 vertexToEye      : TEXCOORD1;	// Vertex to eye vector (in world space)
	float3 worldPos         : TEXCOORD2;	// Vertex position (in world space)
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_INPUT vIn)
{
	//
	// Compute camera position in world space
	float4 cameraPosition = float4(mViewInv[3].xyz, 1);

	//
	// Output structure declaration
	VS_OUTPUT Out;

	//
	// Forward world position
	Out.worldPos = mul(vIn.position, mWorld).xyz;

	//
	// Forward texture coordinates
	Out.texcoord.xy = vIn.texcoord.xy + float2(TexCoordOffsetU, TexCoordOffsetV);

	//
	// Compute vector from vertex to eye in world space
	Out.vertexToEye = cameraPosition - vIn.position;

	//
	// Compute projected position
	Out.position = mul(float4(vIn.position.xyz,1.0f), mWorldViewProjection);

	return Out;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn, in float2 ScreenPos : VPOS) : COLOR
{
	//
	// Get the diffuse color from the diffuse map
	float3 diffuseMapTexel = tex2D(DiffuseMapSampler, vIn.texcoord.xy).rgb * DiffuseMapModulator;

	//
	// Get the opacity factor from the opacity map
	float1 opacityMapTexel = tex2D(OpacityMapSampler, vIn.texcoord.xy).r;

	//
	// Get the self illumination color from the self illumination map
	float3 selfIllumMapTexel = tex2D(SelfIllumMapSampler, vIn.texcoord.xy).rgb * SelfIllumMapModulator;

	//
	// Final color = Ambient + Diffuse + Specular
	float3 C = AmbientColor;

	//
	// Fake color
	float3 lightsparams = TESTLightBufferColor;
	const float diffuseFactor = 0.4f;
	const float lightingFactor = 0.8f;
	C += opacityMapTexel.r * diffuseMapTexel * (lightsparams * lightingFactor + diffuseFactor);

	//
	// Final color += self illumination term
	C += selfIllumMapTexel + SelfIllumColor;

	//
	// Final color opacity
	return float4(C, opacityMapTexel);
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique DefaultTechnique
{
	pass
	{
		ZWriteEnable            = FALSE;
		AlphaBlendEnable        = TRUE;
		SrcBlend                = SrcAlpha;
		DestBlend               = InvSrcAlpha;
		VertexShader            = compile vs_3_0 vs();
		PixelShader             = compile ps_3_0 ps();
	}
}

#else // _3DSMAX_

technique
{
    pass
    {
        VertexShader = null;
        PixelShader  = null;
    }
}

#endif // _3DSMAX_