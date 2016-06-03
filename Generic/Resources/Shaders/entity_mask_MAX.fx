//--------------------------------------------------------------------------------------------------
// Mask material (rev 4)
//--------------------------------------------------------------------------------------------------
#ifdef _3DSMAX_

//
//
//
#include "lib\lighting.fxh"

//
// Transformations parameters
//
float4x4 mWorldViewProjection	: WORLDVIEWPROJECTION	< string UIWidget = "None"; >;
float	 fElapsedTime			: TIME    				< string UIWidget = "None"; >;

//
// Material parameters
//
float3   AmbientColor 	        : Ambient               < > = {0.0f, 0.0f, 0.0f};

texture  DiffuseMap 	        : DiffuseMap            < string UIName = "Diffuse Map"; string name = "_nomap_white.tga"; string TextureType = "2D"; >;
texture  OpacityMap 	        : OpacityMap            < string UIName = "Opacity Map"; string name = "_nomap_white.tga"; string TextureType = "2D"; >;
texture  SelfIllumMap	        : SelfIllumMap          < string UIName = "Self-Illum Map"; string name = "_nomap_black.tga"; string TextureType = "2D"; >;
texture  MaskMap	        	: MaskMap          		< string UIName = "Mask Map"; string name = "_nomap_white.tga"; string TextureType = "2D"; >;

float3   DiffuseMapModulator 	: DiffuseMapModulator	< string UIName = "Diffuse map modulator";  > = {1.0f, 1.0f, 1.0f};
float3   SelfIllumMapModulator  : SelfIllumMapModulator	< string UIName = "Self-Illum map modulator"; > = {0.0f, 0.0f, 0.0f};
float3   SelfIllumColor         : SelfIllumColor        < string UIName = "Self-Illum color"; > = {0.0f, 0.0f, 0.0f};

float    DiffuseSpeedU			: DiffuseSpeedU			< string UIName = "Diffuse Map Scrolling Speed U"; 	float UIMin = -100; float UIMax = +100; > = 0.0f;
float    DiffuseSpeedV			: DiffuseSpeedV			< string UIName = "Diffuse Map Scrolling SpeedV"; 	float UIMin = -100; float UIMax = +100; > = 0.0f;
float    OpacitySpeedU			: OpacitySpeedU			< string UIName = "Opacity Map Scrolling SpeedU"; 	float UIMin = -100; float UIMax = +100; > = 0.0f;
float    OpacitySpeedV			: OpacitySpeedV			< string UIName = "Opacity Map Scrolling SpeedV"; 	float UIMin = -100; float UIMax = +100; > = 0.0f;
float    SelfIllumSpeedU		: SelfIllumSpeedU		< string UIName = "SelfIllum Map Scrolling SpeedU"; float UIMin = -100; float UIMax = +100; > = 0.0f;
float    SelfIllumSpeedV		: SelfIllumSpeedV		< string UIName = "SelfIllum Map Scrolling SpeedV"; float UIMin = -100; float UIMax = +100; > = 0.0f;
float    MaskSpeedU				: MaskSpeedU			< string UIName = "Mask Map Scrolling SpeedU"; 		float UIMin = -100; float UIMax = +100; > = 0.0f;
float    MaskSpeedV				: MaskSpeedV			< string UIName = "Mask Map Scrolling SpeedV"; 		float UIMin = -100; float UIMax = +100; > = 0.0f;

//--------------------------------------------------------------------------------------------------
// Constants
//--------------------------------------------------------------------------------------------------
static const float		UVSCROLL_SPEED_SCALE = 0.03125f;
static const float3   	TESTLightBufferColor   : TESTLightBufferColor	< > = {0.5f, 0.5f, 0.5f};

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
sampler2D MaskMapSampler = sampler_state
{
	Texture   = <MaskMap>;
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
	float4 position         	: POSITION;     // Vertex position
	float2 texcoord_diffuse 	: TEXCOORD0;	// Texture coordinates 0
	float2 texcoord_opacity 	: TEXCOORD1;	// Texture coordinates 1
	float2 texcoord_selfillum 	: TEXCOORD2;	// Texture coordinates 2
	float2 texcoord_mask 		: TEXCOORD3;	// Texture coordinates 3
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_INPUT vIn)
{
	//
	// Output structure declaration
	VS_OUTPUT Out;

	//
	// Forward texture coordinates
	Out.texcoord_diffuse.xy = vIn.texcoord.xy + float2(DiffuseSpeedU, DiffuseSpeedV) * fElapsedTime * UVSCROLL_SPEED_SCALE;
	Out.texcoord_opacity.xy = vIn.texcoord.xy + float2(OpacitySpeedU, OpacitySpeedV) * fElapsedTime * UVSCROLL_SPEED_SCALE;
	Out.texcoord_selfillum.xy = vIn.texcoord.xy + float2(SelfIllumSpeedU, SelfIllumSpeedV) * fElapsedTime * UVSCROLL_SPEED_SCALE;
	Out.texcoord_mask.xy = vIn.texcoord.xy + float2(MaskSpeedU, MaskSpeedV) * fElapsedTime * UVSCROLL_SPEED_SCALE;
	
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
	float3 diffuseMapTexel = tex2D(DiffuseMapSampler, vIn.texcoord_diffuse.xy).rgb * DiffuseMapModulator;

	//
	// Get the opacity factor from the opacity map
	float opacityMapTexel = tex2D(OpacityMapSampler, vIn.texcoord_opacity.xy).r;

	//
	// Get the self illumination color from the self illumination map
	float3 selfIllumMapTexel = tex2D(SelfIllumMapSampler, vIn.texcoord_selfillum.xy).rgb * SelfIllumMapModulator;
	
	//
	// Get the mask value from the mask map
	float maskMapTexel = tex2D(MaskMapSampler, vIn.texcoord_mask.xy).r;
	
	//
	// Final opacity value
	float opacityMask = opacityMapTexel * maskMapTexel;

	//
	// Final color = Ambient + Diffuse + Specular
	float3 C = AmbientColor;

	//
	// Fake color
	float3 lightsparams = TESTLightBufferColor;
	const float diffuseFactor = 0.4f;
	const float lightingFactor = 0.8f;
	C += diffuseMapTexel * (lightsparams * lightingFactor + diffuseFactor);

	//
	// Final color += self illumination term
	C += selfIllumMapTexel + SelfIllumColor;

	//
	// Final color opacity
	return float4(C, opacityMask);
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