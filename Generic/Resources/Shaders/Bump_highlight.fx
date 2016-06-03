//--------------------------------------------------------------------------------------------------
// Diffuse + Specular bump mapping
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
// Parameters
//--------------------------------------------------------------------------------------------------
float4   AmbientColor  : Ambient    < string UIName      = "Ambient Color"; > = {0.25f, 0.25f, 0.25f, 1.0f};

float4   DiffuseColor  : Diffuse    < string UIName      = "Diffuse Color"; > = {1.0f, 1.0f, 1.0f, 1.0f};

texture DiffuseMap    : DiffuseMap < string UIName      = "Diffuse Texture";
                                     string name        = "default.tga";
                                     string TextureType = "2D"; >;

float4   SpecularColor : Specular   < string UIName      = "Specular Color"; > = { 0.2f, 0.2f, 0.2f, 1.0f };

float    Shininess                  < string UIName      = "Shininess";
                                     string UIWidget    = "slider";
                                     float  UIMin       = 1;
                                     float  UIMax       = 128; > = 40;

texture NormalMap     : NormalMap  < string UIName      = "Normal Map";
                                     string name        = "default.tga";
                                     string TextureType = "2D"; >;

bool    direction                  < string UIName      = "Flip Normal Map Green Channel";
                                     string gui         = "slider"; > = false;

float4   SelfIllumColor						 < string UIName      = "Self illumination color"; > = {0.0f, 0.0f, 0.0f, 0.0f};

//--------------------------------------------------------------------------------------------------
// Diffuse map sampler
//--------------------------------------------------------------------------------------------------
sampler2D DiffuseMapSampler = sampler_state
{
	Texture   = <DiffuseMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

//--------------------------------------------------------------------------------------------------
// Normal map sampler
//--------------------------------------------------------------------------------------------------
sampler2D NormalMapSampler = sampler_state
{
	Texture   = <NormalMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

//--------------------------------------------------------------------------------------------------
// Transformations
//--------------------------------------------------------------------------------------------------
float4x4	mWorld					: WORLD					< string UIWidget = "None"; >;
float4x4	mView					: VIEW					< string UIWidget = "None"; >;
float4x4	mWorldViewProjection	: WORLDVIEWPROJECTION	< string UIWidget = "None"; >;
float4x4	mWorldIT				: WORLDINVERSETRANSPOSE	< string UIWidget = "None"; >;
float4x4	mViewInv				: VIEWINVERSE			< string UIWidget = "None"; >;

//--------------------------------------------------------------------------------------------------
// Compute blinn lighting using lit function
//--------------------------------------------------------------------------------------------------
float4 ComputeBlinn(float3 N, float3 L, float3 V, uniform float4 diffuseColor, uniform float4 SpecularColor, uniform float Shininess)
{
	float3 H = normalize(V + L);
	float4 lighting = lit(dot(L, N), dot(H, N), Shininess);
	return diffuseColor * lighting.y + SpecularColor * lighting.z;
}

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_INPUT
{
	float4	position		: POSITION;		// Vertex position
	float2	texcoord		: TEXCOORD0;	// Texture coordinates
	float3	tangent			: TANGENT;		// Tangent (in local space)
	float3	binormal		: BINORMAL;		// Binormal (in local space)
	float3	normal			: NORMAL;		// Normal (in local space)
	float3	color			: COLOR;		// Vertex color
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4	position		: POSITION;		// Vertex position
	float2	texcoord		: TEXCOORD0;	// Texture coordinates
	float3	vertexToEye		: TEXCOORD1;	// Vertex to eye vector (in world space)
	float3	vertexToLight	: TEXCOORD2;	// Vertex to light vector (in world space)
	float3	worldNormal		: TEXCOORD3;	// Normal (in world space)
	float3	worldTangent	: TEXCOORD4;	// Tangent (in world space)
	float3	worldBinormal	: TEXCOORD5;	// Binormal (in world space)
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
	// Make light position match the camera position in world space
	float4 lightPosition = cameraPosition;

	//
	// Output structure declaration
	VS_OUTPUT Out;

	//
	// Compute normal in world space
	Out.worldNormal = mul(vIn.normal, mWorldIT).xyz;

	//
	// Compute tangent in world space
	Out.worldTangent = mul(vIn.tangent, mWorldIT).xyz;

	//
	// Compute binormal in world space
	Out.worldBinormal = mul(vIn.binormal, mWorldIT).xyz;

	//
	// Both positive and negative y format normal maps supported
	if (direction == true)
	{
		Out.worldTangent = -Out.worldTangent;
	}

	//
	// Compute position in world space
	float3 worldSpacePos = mul(vIn.position, mWorld);

	//
	// Compute vector from vertex to light in world space
	Out.vertexToLight = lightPosition - worldSpacePos;

	//
	// Forward texture coordinates
	Out.texcoord.xy = vIn.texcoord;

	//
	// Compute vector from vertex to eye in world space
	Out.vertexToEye = mViewInv[3].xyz - worldSpacePos;

	//
	// Compute projected position
	Out.position = mul(vIn.position, mWorldViewProjection);

	return Out;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn) : COLOR
{
	//
	// Get the diffuse color from the diffuse map
	float4 diffuseMapTexel = tex2D(DiffuseMapSampler, vIn.texcoord.xy);

	float4 C;
	
	C.r = 1.0f;
	C.g = 0.0f;
	C.b = 0.0f;
	C.a = 0.5f;

	C *= diffuseMapTexel;

	return C;
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique DefaultTechnique
{ 
	pass one 
	{		
		VertexShader		= compile vs_1_1 vs();
			
		ZEnable				= true;
		ZWriteEnable		= true;
		CullMode			= NONE;
		AlphaBlendEnable	= true;
			
		PixelShader			= compile ps_2_0 ps();
	}
}

