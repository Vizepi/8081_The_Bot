//--------------------------------------------------------------------------------------------------
// Water shader for MAX (rev 1)
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
float4x4	mWorld          		: WORLD          		< string UIWidget = "None"; >;
float4x4 	mWorldIT				: WORLDINVERSETRANSPOSE	< string UIWidget = "None"; >;
float4x4 	mWorldViewProjection  	: WORLDVIEWPROJ  		< string UIWidget = "None"; >;
float4x4	mViewInv       			: VIEWINVERSE    		< string UIWidget = "None"; >;
float		fElapsedTime			: TIME    				< string UIWidget = "None"; >;

//
// Material parameters
//
float3   	AmbientColor    		: Ambient        	< > = {0.0f, 0.0f, 0.0f};

texture 	Wave0Map       			: Wave0Map       	< string UIName = "Wave Map 0"; string name = "_nomap_nrm.tga"; string TextureType = "2D"; >;
texture 	Wave1Map       			: Wave1Map       	< string UIName = "Wave Map 1"; string name = "_nomap_nrm.tga"; string TextureType = "2D"; >;
texture 	ReflectMap     			: ReflectMap     	< string UIName = "Reflection Map"; string name = "_nomap_white.tga"; string TextureType = "2D"; >;
texture 	RefractMap     			: RefractMap     	< string UIName = "Refraction Map"; string name = "_nomap_white.tga"; string TextureType = "2D"; >;

float3   	WaterColor 				: WaterColor		< string UIName = "Diffuse map modulator";  > = { 1.0f, 1.0f, 1.0f };
float3   	SelfIllumColor			: SelfIllumColor 	< string UIName = "Self-Illum"; > = { 0.0f, 0.0f, 0.0f };

float2  	WaveMapOffset0 			: WaveMapOffset0 	< string UIName = "Wave Map Offset 0"; > = { 0.0f, 0.0f };
float2  	WaveMapOffset1 			: WaveMapOffset1 	< string UIName = "Wave Map Offset 1"; > = { 0.0f, 0.0f };
float   	WaveScale       		: TexScale       	< string UIName = "Wave Textures Scale"; > = 1.0f;

float    Shininess              	: Shininess         < string UIName = "Shininess"; string UIWidget = "slider"; float UIMin = 1; float UIMax = 128; > = 40;
float    SpecularLevel          	: SpecularLevel     < string UIName = "Specular level"; string UIWidget = "slider"; float UIMin = 0; float UIMax = 16; > = 1;
bool 	 FlipNormalMapY				: FlipNormalMapY	< string UIName = "Flip Normal Map Green Channel"; string gui = "slider"; > = false;

//
// Constants
//
static const float	  R0 = 0.02037f;
static const float	  TEXSCALE = 5.0f;
static const float	  WAVESPEED = 0.1f;

//
// Lights parameters
//
float3 Light1Pos                : POSITION              < string UIName = "Light 1 Position"; string Object = "PointLight"; string Space = "World"; int refID = 0; > = {0.0f, 0.0f, 0.0f};
float3 Light2Pos                : POSITION              < string UIName = "Light 2 Position"; string Object = "PointLight"; string Space = "World"; int refID = 1; > = {0.0f, 0.0f, 0.0f};
float3 Light3Pos                : POSITION              < string UIName = "Light 3 Position"; string Object = "PointLight"; string Space = "World"; int refID = 2; > = {0.0f, 0.0f, 0.0f};
float3 Light4Pos                : POSITION              < string UIName = "Light 4 Position"; string Object = "PointLight"; string Space = "World"; int refID = 3; > = {0.0f, 0.0f, 0.0f};

float3 Light1Color              : LIGHTCOLOR            < int LightRef = 0; > = {1.0f, 1.0f, 1.0f};
float3 Light2Color              : LIGHTCOLOR            < int LightRef = 1; > = {1.0f, 1.0f, 1.0f};
float3 Light3Color              : LIGHTCOLOR            < int LightRef = 2; > = {1.0f, 1.0f, 1.0f};
float3 Light4Color              : LIGHTCOLOR            < int LightRef = 3; > = {1.0f, 1.0f, 1.0f};

float2 Light1Attenuation        : LIGHTATTENUATION      < int LightRef = 0; > = {1.0f, 2.0f};
float2 Light2Attenuation        : LIGHTATTENUATION      < int LightRef = 1; > = {1.0f, 2.0f};
float2 Light3Attenuation        : LIGHTATTENUATION      < int LightRef = 2; > = {1.0f, 2.0f};
float2 Light4Attenuation        : LIGHTATTENUATION      < int LightRef = 3; > = {1.0f, 2.0f};

//
// Maps samplers
//
sampler2D Wave0MapSampler = sampler_state
{
	Texture = <Wave0Map>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

sampler2D Wave1MapSampler = sampler_state
{
	Texture = <Wave1Map>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

sampler2D ReflectMapSampler = sampler_state
{
	Texture = <ReflectMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

sampler2D RefractMapSampler = sampler_state
{
	Texture = <RefractMap>;
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
// Vertex shader output structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4 texcoord		    : TEXCOORD0;	// Texture coordinates
	float3 vertexToEye		: TEXCOORD1;	// Vertex to eye vector (in world space)
	float3 worldPos 		: TEXCOORD2;	// Vertex position (in world space)
	float3 worldNormal		: TEXCOORD3;	// Normal (in world space)
	float3 worldTangent	    : TEXCOORD4;	// Tangent (in world space)
	float3 worldBinormal	: TEXCOORD5;	// Binormal (in world space)
    float4 clipPos			: TEXCOORD6;	// Position in clip space
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
	Out.texcoord.xy = (vIn.texcoord.xy * WaveScale) + WaveMapOffset0 * fElapsedTime * WAVESPEED;
	Out.texcoord.zw = (vIn.texcoord.xy * WaveScale) + WaveMapOffset1 * fElapsedTime * WAVESPEED;

	//
	// Compute vector from vertex to eye in world space
	Out.vertexToEye = cameraPosition - vIn.position;

	//
	// Compute projected position
	position = Out.clipPos = mul(float4(vIn.position.xyz,1.0f), mWorldViewProjection);

	return Out;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn) : COLOR
{
	//transform the projective texcoords to NDC space
	//and scale and offset xy to correctly sample a DX texture
	vIn.clipPos.xyz /= vIn.clipPos.w;
	vIn.clipPos.x =  0.5f*vIn.clipPos.x + 0.5f;
	vIn.clipPos.y = -0.5f*vIn.clipPos.y + 0.5f;
	vIn.clipPos.z = .1f / vIn.clipPos.z; //refract more based on distance from the camerA

	//
	// Create lighting and view vectors
	float3 V = normalize(vIn.vertexToEye);

	//
	// Get normal from both wave maps
	float3 normalT0 = normalize(tex2D(Wave0MapSampler, vIn.texcoord.xy).xyz * 2.0 - 1.0);
	float3 normalT1 = normalize(tex2D(Wave1MapSampler, vIn.texcoord.zw).xyz * 2.0 - 1.0);
    float3 N = ApplyNormalMapping((normalT0+normalT1)/2.0, vIn.worldTangent, vIn.worldBinormal, vIn.worldNormal);
	float3 M = float3(0,0,1);

	//
	// Compute the fresnel term to blend reflection and refraction maps
	float ang = saturate(dot(V,M));
	float f = R0 + (1.0f-R0) * pow(1.0f-ang,5.0f);

	//
	// Compute the diffuse color using reflection and refraction map
	float3 refl = tex2D(ReflectMapSampler, (vIn.clipPos.xy + vIn.clipPos.z * N.xz) * TEXSCALE);
	float3 refr = tex2D(RefractMapSampler, (vIn.clipPos.xy - vIn.clipPos.z * N.xz) * TEXSCALE);
	float3 diffuseMapTexel = WaterColor * lerp(refr, refl, f);

	//
	// Default specular color
	float3 specularMapTexel = diffuseMapTexel;

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
		float2 Light1Factor     = BlinnFactor(N, normalize(Light1Pos - vIn.worldPos), V, Shininess) * Light1Att;
		float2 Light2Factor     = BlinnFactor(N, normalize(Light2Pos - vIn.worldPos), V, Shininess) * Light2Att;
		float2 Light3Factor     = BlinnFactor(N, normalize(Light3Pos - vIn.worldPos), V, Shininess) * Light3Att;
		float2 Light4Factor     = BlinnFactor(N, normalize(Light4Pos - vIn.worldPos), V, Shininess) * Light4Att;

		//
        // Compute final color contribution
	  	C += Blinn(diffuseMapTexel, Light1Color * Light1Factor.x, specularMapTexel, SpecularLevel, float2(1, Light1Factor.y));
	  	C += Blinn(diffuseMapTexel, Light2Color * Light2Factor.x, specularMapTexel, SpecularLevel, float2(1, Light2Factor.y));
	  	C += Blinn(diffuseMapTexel, Light3Color * Light3Factor.x, specularMapTexel, SpecularLevel, float2(1, Light3Factor.y));
	  	C += Blinn(diffuseMapTexel, Light4Color * Light4Factor.x, specularMapTexel, SpecularLevel, float2(1, Light4Factor.y));
	}

	//interpolate the reflection and refraction maps based on the fresnel term and add the sunlight
	C += SelfIllumColor;

	return float4(C, 1.0f);
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