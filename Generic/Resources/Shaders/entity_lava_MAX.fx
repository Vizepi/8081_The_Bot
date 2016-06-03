//--------------------------------------------------------------------------------------------------
// Extended material for MAX (rev 1)
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
float4x4 mWorld  				: WORLD					< string UIWidget = "None"; >;
float4x4 mWorldIT				: WORLDINVERSETRANSPOSE	< string UIWidget = "None"; >;
float4x4 mWorldViewProjection	: WORLDVIEWPROJECTION	< string UIWidget = "None"; >;
float4x4 mView                  : VIEW                  < string UIWidget = "None"; >;
float4x4 mViewInv               : VIEWINVERSE           < string UIWidget = "None"; >;
float	 fElapsedTime			: TIME    				< string UIWidget = "None"; >;

//
// Material parameters
//
float3   AmbientColor 	        : Ambient               < > = {0.0f, 0.0f, 0.0f};

texture  DiffuseMap 	        : DiffuseMap            < string UIName = "Diffuse Map"; string name = "_nomap_white.tga"; string TextureType = "2D"; >;
texture  NormalFusionMap        : NormalFusionMap       < string UIName = "Fusion Normal"; string name = "_nomap_nrm.tga"; string TextureType = "2D"; >;
texture  NormalFusion2Map       : NormalFusion2Map      < string UIName = "Fusion Normal 2"; string name = "_nomap_nrm.tga"; string TextureType = "2D"; >;
texture  NormalRockMap          : NormalRockMap         < string UIName = "Rock Normal"; string name = "_nomap_nrm.tga"; string TextureType = "2D"; >;
texture  NormalMaskMap 	        : NormalMaskMap         < string UIName = "Normal Mask"; string name = "_nomap_white.tga"; string TextureType = "2D"; >;
texture  SpecularMap            : SpecularMap           < string UIName = "Specular Map"; string name = "_nomap_white.tga"; string TextureType = "2D"; >;
texture  SelfIllumMap	        : SelfIllumMap          < string UIName = "Self-Illum Map"; string name = "_nomap_black.tga"; string TextureType = "2D"; >;

float3   RockDiffuseColor 	    : RockDiffuseColor		< string UIName = "Rock Diffuse";  > = {1.0f, 1.0f, 1.0f};
float3   LavaDiffuseColor 		: LavaDiffuseColor		< string UIName = "Lava Diffuse";  > = {1.0f, 1.0f, 1.0f};
float3   SpecularMapModulator	: SpecularMapModulator	< string UIName = "Specular map modulator"; > = {1.0f, 1.0f, 1.0f};
float3   SelfIllumMapModulator  : SelfIllumMapModulator	< string UIName = "Self-Illum map modulator"; > = {0.0f, 0.0f, 0.0f};
float3   SelfIllumColor         : SelfIllumColor        < string UIName = "Self-Illum color"; > = {0.0f, 0.0f, 0.0f};

float    Shininess              : Shininess             < string UIName = "Shininess"; string UIWidget = "slider"; float UIMin = 1; float UIMax = 128; > = 40;
float    SpecularLevel          : SpecularLevel         < string UIName = "Specular level"; string UIWidget = "slider"; float UIMin = 0; float UIMax = 16; > = 1;
float    TexCoordOffsetU		: TexCoordOffsetU		< string UIName = "Texture Coordinate Offset U"; > = 0.0f;
float    TexCoordOffsetV		: TexCoordOffsetV		< string UIName = "Texture Coordinate Offset V"; > = 0.0f;
bool 	 FlipNormalMapY			: FlipNormalMapY		< string UIName = "Flip Normal Map Green Channel"; string gui = "slider"; > = false;

//
// Lights parameters
//
float3 Light1Pos                : POSITION              < string UIName = "Light 1 Position"; string Object = "PointLight"; string Space = "World"; int refID = 0; > = {0.0f, 0.0f, 0.0f};
float3 Light2Pos                : POSITION              < string UIName = "Light 2 Position"; string Object = "PointLight"; string Space = "World"; int refID = 1; > = {0.0f, 0.0f, 0.0f};
float3 Light3Pos                : POSITION              < string UIName = "Light 3 Position"; string Object = "PointLight"; string Space = "World"; int refID = 2; > = {0.0f, 0.0f, 0.0f};
float3 Light4Pos                : POSITION              < string UIName = "Light 4 Position"; string Object = "PointLight"; string Space = "World"; int refID = 3; > = {0.0f, 0.0f, 0.0f};

float3 Light1Color 		: LIGHTCOLOR <int LightRef = 0; string UIWidget = "None"; > = float3(1.0f, 1.0f, 1.0f);
float3 Light2Color 		: LIGHTCOLOR <int LightRef = 1; string UIWidget = "None"; > = float3(0.0f, 0.0f, 0.0f);
float3 Light3Color 		: LIGHTCOLOR <int LightRef = 2; string UIWidget = "None"; > = float3(0.0f, 0.0f, 0.0f);
float3 Light4Color 		: LIGHTCOLOR <int LightRef = 3; string UIWidget = "None"; > = float3(0.0f, 0.0f, 0.0f);

float4 Light1Attenuation        : LIGHTATTENUATION      < int LightRef = 0; string UIWidget = "None"; > = float4(1.0f, 2000.0f, 3.0f, 4.0f);
float4 Light2Attenuation        : LIGHTATTENUATION      < int LightRef = 1; string UIWidget = "None"; > = float4(1.0f, 2000.0f, 3.0f, 4.0f);
float4 Light3Attenuation        : LIGHTATTENUATION      < int LightRef = 2; string UIWidget = "None"; > = float4(1.0f, 2000.0f, 3.0f, 4.0f);
float4 Light4Attenuation        : LIGHTATTENUATION      < int LightRef = 3; string UIWidget = "None"; > = float4(1.0f, 2000.0f, 3.0f, 4.0f);

//
// Maps samplers
//
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
sampler2D NormalFusionMapSampler = sampler_state
{
	Texture   = <NormalFusionMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP;
	AddressV  = WRAP;
};
sampler2D NormalFusion2MapSampler = sampler_state
{
	Texture   = <NormalFusion2Map>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP;
	AddressV  = WRAP;
};
sampler2D NormalRockMapSampler = sampler_state
{
	Texture   = <NormalRockMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP;
	AddressV  = WRAP;
};
sampler2D SpecularMapSampler = sampler_state
{
	Texture   = <SpecularMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP;
	AddressV  = WRAP;
};
sampler2D NormalMaskMapSampler = sampler_state
{
	Texture   = <NormalMaskMap>;
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

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4 texcoord		    : TEXCOORD0;	// Texture coordinates
	float3 vertexToEye		: TEXCOORD1;	// Vertex to eye vector (in world space)
	float3 worldPos 		: TEXCOORD2;	// Vertex position (in world space)
	float3 worldNormal		: TEXCOORD3;	// Normal (in world space)
	float3 worldTangent	    : TEXCOORD4;	// Tangent (in world space)
	float3 worldBinormal	: TEXCOORD5;	// Binormal (in world space)
	float3 viewNormal		: TEXCOORD6; 	// Normal (in view space)
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(in VS_INPUT vIn, out float4 position : POSITION)
{
	//
	// Compute camera position in world space
	float4 cameraPosition = float4(mViewInv[3].xyz, 1);

	//
	// Output structure declaration
	VS_OUTPUT Out;

	//
	// Compute normal in world space
	Out.worldNormal = normalize(mul(vIn.normal, (float3x3)mWorldIT).xyz);
	Out.viewNormal = mul(normalize(mul(vIn.normal, (float3x3)mWorldIT).xyz), (float3x3)mView).xyz;

	//
	// Compute tangent in world space
	Out.worldTangent = normalize(mul(vIn.tangent, (float3x3)mWorldIT).xyz);

	//
	// Compute binormal in world space
	Out.worldBinormal = normalize(mul(vIn.binormal, (float3x3)mWorldIT).xyz);

	//
	// Both positive and negative y format normal maps supported
	if (FlipNormalMapY == true)
	{
		Out.worldTangent = -Out.worldTangent;
	}

	//
	// Forward world position
	Out.worldPos = mul(vIn.position, mWorld).xyz;

	//
	// Forward texture coordinates
	Out.texcoord.xy = vIn.texcoord.xy + float2(TexCoordOffsetU, TexCoordOffsetV) * fElapsedTime;
	Out.texcoord.wz = vIn.texcoord.xy + float2(TexCoordOffsetU, TexCoordOffsetV * -0.33f) * fElapsedTime;

	//
	// Compute vector from vertex to eye in world space
	Out.vertexToEye = cameraPosition - vIn.position;

	//
	// Compute projected position
	position = mul(float4(vIn.position.xyz,1.0f), mWorldViewProjection);

	return Out;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn) : COLOR
{
	//
	// Get UVs
	float2 uv1 = vIn.texcoord.xy;
	float2 uv2 = vIn.texcoord.wz;

	//
	// Get mask between lava and rocks
	float a = tex2D(NormalMaskMapSampler, uv1).r;
	
	//
	// Compute normal map texel
	float3 normalMapFusionTexel = normalize(tex2D(NormalFusionMapSampler, uv1).xyz * 2.0 - 1.0)
								* normalize(tex2D(NormalFusionMapSampler, uv2).xyz * 2.0 - 1.0)
								* normalize(tex2D(NormalFusion2MapSampler, uv1).xyz * 2.0 - 1.0);
	float3 normalMapRockTexel	= normalize(tex2D(NormalRockMapSampler, uv1).xyz * 2.0 - 1.0);
    float3 normalMapTexel = a * normalMapRockTexel + (1 - a) * normalMapFusionTexel;
    float3 N = ApplyNormalMapping(normalMapTexel, vIn.worldTangent, vIn.worldBinormal, vIn.worldNormal);

	//
	// Get the diffuse color from the diffuse map
	float3 diffuseMapTexel = tex2D(DiffuseMapSampler, uv1).xyz * a * RockDiffuseColor
	                       + /*tex2D(DiffuseMapSampler, uv1).xyz **/ (1-a) * LavaDiffuseColor;
	
	//
	// Get the specular color from the specular map
	float3 specularMapTexel = tex2D(SpecularMapSampler, uv1).rgb * SpecularMapModulator;

	//
	// Get the self illumination color from the self illumination map
	float3 selfIllumMapTexel = tex2D(SelfIllumMapSampler, uv1).rgb * SelfIllumMapModulator;

	//
	// Create lighting and view vectors
	float3 V = normalize(vIn.vertexToEye);

	//
	// Final color = Ambient + Diffuse + Specular
	float3 C = AmbientColor;

	//
	// Final color += 4 localized lights terms
	{
		//
		// Compute attenuation
		float Light1Att         = AttenutaionPointLight(vIn.worldPos, Light1Pos, Light1Attenuation.xy).x;
		float Light2Att         = AttenutaionPointLight(vIn.worldPos, Light2Pos, Light2Attenuation.xy).x;
		float Light3Att         = AttenutaionPointLight(vIn.worldPos, Light3Pos, Light3Attenuation.xy).x;
		float Light4Att         = AttenutaionPointLight(vIn.worldPos, Light4Pos, Light4Attenuation.xy).x;

		//
		// Compute diffuse and specular Phong-Blinn factor
		float2 Light1Factor     = BlinnFactor(N, normalize(Light1Pos - vIn.worldPos), V, Shininess) /** Light1Att*/;
		float2 Light2Factor     = BlinnFactor(N, normalize(Light2Pos - vIn.worldPos), V, Shininess) /** Light2Att*/;
		float2 Light3Factor     = BlinnFactor(N, normalize(Light3Pos - vIn.worldPos), V, Shininess) /** Light3Att*/;
		float2 Light4Factor     = BlinnFactor(N, normalize(Light4Pos - vIn.worldPos), V, Shininess) /** Light4Att*/;

		//
        // Compute final color contribution
	  	C += Blinn(diffuseMapTexel, Light1Color * Light1Factor.x, specularMapTexel, SpecularLevel, float2(1, Light1Factor.y));
	  	C += Blinn(diffuseMapTexel, Light2Color * Light2Factor.x, specularMapTexel, SpecularLevel, float2(1, Light2Factor.y));
	  	C += Blinn(diffuseMapTexel, Light3Color * Light3Factor.x, specularMapTexel, SpecularLevel, float2(1, Light3Factor.y));
	  	C += Blinn(diffuseMapTexel, Light4Color * Light4Factor.x, specularMapTexel, SpecularLevel, float2(1, Light4Factor.y));
	}

	//
	// Final color += self illumination term
	C += (selfIllumMapTexel + SelfIllumColor) * (1-a) ;

	//
	// Alpha channel is unused
	return float4(C, 1.0f);
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique DefaultTechnique
{
	pass
	{
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps();
	}
}

#else // _3DSMAX_

technique
{
    pass
    {
        vertexShader = null;
        pixelShader  = null;
    }
}

#endif // _3DSMAX_