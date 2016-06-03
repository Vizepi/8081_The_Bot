//--------------------------------------------------------------------------------------------------
// Standard material
//--------------------------------------------------------------------------------------------------

//
// Transformations parameters
//

float4x4 mWorld               : WORLD                 < string UIWidget = "None"; >;
float4x4 mView                : VIEW                  < string UIWidget = "None"; >;
float4x4 mWorldViewProjection : WORLDVIEWPROJECTION   < string UIWidget = "None"; >;
float4x4 mWorldIT             : WORLDINVERSETRANSPOSE < string UIWidget = "None"; >;
float4x4 mViewInv             : VIEWINVERSE           < string UIWidget = "None"; >;

//
// Lights parameter
//

float4	DefaultLightColor : DefaultLightColor < string UIName = "Default Light Color";  					 > = {0.5f, 0.5f, 0.5f, 1.0f};

float4 Light1Pos : POSITION < string UIName = "Light 1 Position"; string Object = "PointLight"; string Space = "World"; int refID = 0; > = {0.0f, 0.0f, 0.0f, 0.0f};
float4 Light2Pos : POSITION < string UIName = "Light 2 Position"; string Object = "PointLight"; string Space = "World"; int refID = 1; > = {0.0f, 0.0f, 0.0f, 0.0f};
float4 Light3Pos : POSITION < string UIName = "Light 3 Position"; string Object = "PointLight"; string Space = "World"; int refID = 2; > = {0.0f, 0.0f, 0.0f, 0.0f};
float4 Light4Pos : POSITION < string UIName = "Light 4 Position"; string Object = "PointLight"; string Space = "World"; int refID = 3; > = {0.0f, 0.0f, 0.0f, 0.0f};
float4 Light5Pos : POSITION < string UIName = "Light 5 Position"; string Object = "PointLight"; string Space = "World"; int refID = 4; > = {0.0f, 0.0f, 0.0f, 0.0f};
float4 Light6Pos : POSITION < string UIName = "Light 6 Position"; string Object = "PointLight"; string Space = "World"; int refID = 5; > = {0.0f, 0.0f, 0.0f, 0.0f};
float4 Light7Pos : POSITION < string UIName = "Light 7 Position"; string Object = "PointLight"; string Space = "World"; int refID = 6; > = {0.0f, 0.0f, 0.0f, 0.0f};
float4 Light8Pos : POSITION < string UIName = "Light 8 Position"; string Object = "PointLight"; string Space = "World"; int refID = 7; > = {0.0f, 0.0f, 0.0f, 0.0f};

float4 Light1Color : LIGHTCOLOR < int LightRef = 0;																	 > = { 1.0f, 1.0f, 1.0f, 0.0f };
float4 Light2Color : LIGHTCOLOR < int LightRef = 1;																	 > = { 1.0f, 1.0f, 1.0f, 0.0f };
float4 Light3Color : LIGHTCOLOR < int LightRef = 2;																	 > = { 1.0f, 1.0f, 1.0f, 0.0f };
float4 Light4Color : LIGHTCOLOR < int LightRef = 3;																	 > = { 1.0f, 1.0f, 1.0f, 0.0f };
float4 Light5Color : LIGHTCOLOR < int LightRef = 4;																	 > = { 1.0f, 1.0f, 1.0f, 0.0f };
float4 Light6Color : LIGHTCOLOR < int LightRef = 5;																	 > = { 1.0f, 1.0f, 1.0f, 0.0f };
float4 Light7Color : LIGHTCOLOR < int LightRef = 6;																	 > = { 1.0f, 1.0f, 1.0f, 0.0f };
float4 Light8Color : LIGHTCOLOR < int LightRef = 7;																	 > = { 1.0f, 1.0f, 1.0f, 0.0f };

float Light1Attenuation : LIGHTATTENUATION	< int LightRef = 0;																	 > = 0.0f;
float Light2Attenuation : LIGHTATTENUATION	< int LightRef = 1;																	 > = 0.0f;
float Light3Attenuation : LIGHTATTENUATION	< int LightRef = 2;																	 > = 0.0f;
float Light4Attenuation : LIGHTATTENUATION	< int LightRef = 3;																	 > = 0.0f;
float Light5Attenuation : LIGHTATTENUATION	< int LightRef = 4;																	 > = 0.0f;
float Light6Attenuation : LIGHTATTENUATION	< int LightRef = 5;																	 > = 0.0f;
float Light7Attenuation : LIGHTATTENUATION	< int LightRef = 6;																	 > = 0.0f;
float Light8Attenuation : LIGHTATTENUATION	< int LightRef = 7;																	 > = 0.0f;

//
// Material parameters
//

float4    AmbientColor 	      : Ambient     	      	< string UIName = "Ambient Color";  > = {0.25f, 0.25f, 0.25f, 1.0f};

texture  AOMap                : AOMap									< string UIName = "AO Map";  string name = "default.tga"; string TextureType = "2D"; >;

float4    SelfIllumColor       : SelfIllumColor      	< string UIName = "Self Illumination color"; > = {0.0f, 0.0f, 0.0f, 0.0f};
texture  SelfIllumMap	        : SelfIllumMap					< string UIName = "SelfIllum Map";  string name = "default.tga"; string TextureType = "2D"; >;
float    SelfIllumMapScrollU  : SelfIllumMapScrollU   < string UIName = "SelfIllum Map Scroll U"; > = 0.0f;
float    SelfIllumMapScrollV  : SelfIllumMapScrollV   < string UIName = "SelfIllum Map Scroll V"; > = 0.0f;

float4    DiffuseColor 	      : DiffuseColor          < string UIName = "Diffuse Color";  > = {1.0f, 1.0f, 1.0f, 1.0f};
texture  DiffuseMap 	        : DiffuseMap            < string UIName = "Diffuse Map";  string name = "default.tga"; string TextureType = "2D"; >;
float    DiffuseMapScrollU    : DiffuseMapScrollU     < string UIName = "Diffuse Map Scroll U"; > = 0.0f;
float    DiffuseMapScrollV    : DiffuseMapScrollV     < string UIName = "Diffuse Map Scroll V"; > = 0.0f;

float4    SpecularColor        : SpecularColor       	< string UIName = "Specular Color"; > = { 0.2f, 0.2f, 0.2f, 1.0f };
texture  SpecularMap          : SpecularMap           < string UIName = "Specular Map";	string name = "default.tga"; string TextureType = "2D"; >;
float    SpecularMapScrollU   : SpecularMapScrollU    < string UIName = "Specular Map Scroll U"; > = 0.0f;
float    SpecularMapScrollV   : SpecularMapScrollV    < string UIName = "Specular Map Scroll V"; > = 0.0f;
float     Shininess 		        : Shininess   		      < string UIName = "Shininess"; string UIWidget = "slider"; float UIMin = 1; float UIMax = 128; > = 40;
float    SpecularLevel        : SpecularLevel                   < string UIName = "SpecularLevel"; string UIWidget = "slider"; float UIMin = 0; float UIMax = 16; > = 1;

texture  OpacityMap 	        : OpacityMap            < string UIName = "Opacity Map"; 	string name = "default.tga"; string TextureType = "2D"; >;
float    OpacityMapScrollU    : OpacityMapScrollU     < string UIName = "Opacity Map Scroll U"; > = 0.0f;
float    OpacityMapScrollV    : OpacityMapScrollV     < string UIName = "Opacity Map Scroll V"; > = 0.0f;

texture  NormalMap            : NormalMap             < string UIName = "Normal Map";   string name = "default.tga"; string TextureType = "2D"; >;
float    NormalMapScrollU     : NormalMapScrollU      < string UIName = "Normal Map Scroll U"; > = 0.0f;
float    NormalMapScrollV     : NormalMapScrollV      < string UIName = "Normal Map Scroll V"; > = 0.0f;
bool 	   direction 		        : direction   		      < string UIName = "Flip Normal Map Green Channel"; string gui = "slider"; > = false;

//
// Maps samplers
//
sampler2D AOMapSampler = sampler_state
{
	Texture   = <AOMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

sampler2D DiffuseMapSampler = sampler_state
{
	Texture   = <DiffuseMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

sampler2D SelfIllumMapSampler = sampler_state
{
	Texture   = <SelfIllumMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

sampler2D SpecularMapSampler = sampler_state
{
	Texture   = <SpecularMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

sampler2D NormalMapSampler = sampler_state
{
	Texture   = <NormalMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

sampler2D OpacityMapSampler = sampler_state
{
	Texture   = <OpacityMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

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
	// stream 0
	float3	position		: POSITION;		// Vertex position
	float2	texcoord		: TEXCOORD0;	// Texture coordinates
	float3	tangent			: TANGENT;		// Tangent (in local space)
	float3	binormal		: BINORMAL;		// Binormal (in local space)
	float3	normal			: NORMAL;		// Normal (in local space)
		
    float4 matrixrow0 : TEXCOORD1;
    float4 matrixrow1 : TEXCOORD2;
    float4 matrixrow2 : TEXCOORD3;
    float4 matrixrow3 : TEXCOORD4;
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4	position		: POSITION;		// Vertex position
	float2	texcoord		: TEXCOORD0;	// Texture coordinates
	float3	vertexToEye		: TEXCOORD1;	// Vertex to eye vector (in world space)
	float3	worldPos 		: TEXCOORD2;	// Vertex position (in world space)
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
	// Output structure declaration
	VS_OUTPUT Out;
	
	float4x4 mLocal = float4x4(vIn.matrixrow0,
														 vIn.matrixrow1,
														 vIn.matrixrow2,
														 vIn.matrixrow3);
														 
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
	Out.worldPos = worldSpacePos;

	//
	// Forward texture coordinates
	Out.texcoord.xy = vIn.texcoord;

	//
	// Compute vector from vertex to eye in world space
	Out.vertexToEye = mViewInv[3].xyz; - worldSpacePos;
	
	float4x4 mWVP = mul(mLocal, mWorldViewProjection);

	//
	// Compute projected position
	Out.position = mul(float4(vIn.position/* + vIn.vShift*/, 1.0f), mWVP/*mWorldViewProjection*/);

	return Out;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn) : COLOR
{
	//
	// Get the ambient occlusion factor from the ambient occlusion map
	float4 aoFactor = tex2D(AOMapSampler, vIn.texcoord.xy);

	//
	// Get the diffuse color from the diffuse map
	float4 diffuseMapTexel = tex2D(DiffuseMapSampler, vIn.texcoord.xy + float2(DiffuseMapScrollU, DiffuseMapScrollV));

	//
	// Get the self illumination color from the self illumination map
	float4 selfIllumMapTexel = tex2D(SelfIllumMapSampler, vIn.texcoord.xy + float2(SelfIllumMapScrollU, SelfIllumMapScrollV));

	//
	// Get the opacity factor from the opacity map
	float4 opacityMapTexel = tex2D(OpacityMapSampler, vIn.texcoord.xy + float2(OpacityMapScrollU, OpacityMapScrollV));

	//
	// Get the specular color from the specular map
	float4 specularMapTexel = tex2D(SpecularMapSampler, vIn.texcoord.xy + float2(SpecularMapScrollU, SpecularMapScrollV));

	//
	// Get the normal from the normal map
	float3 normalMapTexel = tex2D(NormalMapSampler, vIn.texcoord.xy + float2(NormalMapScrollU, NormalMapScrollV)).xyz * 2.0 - 1.0;

	//
	// Offset world space normal with normal map values
	float3 N = (vIn.worldNormal * normalMapTexel.z) + (normalMapTexel.x * vIn.worldBinormal + normalMapTexel.y * - vIn.worldTangent);
	N = normalize(N);

	//
	// Create lighting and view vectors
	float3 V = normalize(vIn.vertexToEye);
	//float3 L = normalize(vIn.vertexToLight.xyz);

	//
	// Final color = Ambient * Diffuse
	float4 C = AmbientColor * diffuseMapTexel;

	//
	// Final color += Default light term
	{
		float3 L = normalize(vIn.vertexToEye.xyz);
  	C += ComputeBlinn(N, L, V, diffuseMapTexel * DefaultLightColor, SpecularColor, Shininess);
	}

	//
	// Final color += 8 localized lights terms
	{
		float3 L = normalize(Light1Pos - vIn.worldPos);
	  C += ComputeBlinn(N, L, V, diffuseMapTexel * Light1Color, SpecularColor, Shininess) * saturate(1 - (length(Light1Pos - vIn.worldPos) / Light1Attenuation));
	
		L = normalize(Light2Pos - vIn.worldPos);
		C += ComputeBlinn(N, L, V, diffuseMapTexel * Light2Color, SpecularColor, Shininess) * saturate(1 - (length(Light2Pos - vIn.worldPos) / Light2Attenuation));
	
		L = normalize(Light3Pos - vIn.worldPos);
		C += ComputeBlinn(N, L, V, diffuseMapTexel * Light3Color, SpecularColor, Shininess) * saturate(1 - (length(Light3Pos - vIn.worldPos) / Light3Attenuation));
	
		L = normalize(Light4Pos - vIn.worldPos);
		C += ComputeBlinn(N, L, V, diffuseMapTexel * Light4Color, SpecularColor, Shininess) * saturate(1 - (length(Light4Pos - vIn.worldPos) / Light4Attenuation));
	
		L = normalize(Light5Pos - vIn.worldPos);
		C += ComputeBlinn(N, L, V, diffuseMapTexel * Light5Color, SpecularColor, Shininess) * saturate(1 - (length(Light5Pos - vIn.worldPos) / Light5Attenuation));
	
		L = normalize(Light6Pos - vIn.worldPos);
		C += ComputeBlinn(N, L, V, diffuseMapTexel * Light6Color, SpecularColor, Shininess) * saturate(1 - (length(Light6Pos - vIn.worldPos) / Light6Attenuation));
	
		L = normalize(Light7Pos - vIn.worldPos);
		C += ComputeBlinn(N, L, V, diffuseMapTexel * Light7Color, SpecularColor, Shininess) * saturate(1 - (length(Light7Pos - vIn.worldPos) / Light7Attenuation));
	
		L = normalize(Light8Pos - vIn.worldPos);
		C += ComputeBlinn(N, L, V, diffuseMapTexel * Light8Color, SpecularColor, Shininess) * saturate(1 - (length(Light8Pos - vIn.worldPos) / Light8Attenuation));
	}

	//
	// Final color *= ambient occlusion factor
	{
		C *= aoFactor;
	}
	
	//
	// Final color += self illumination term
	//C += selfIllumMapTexel * SelfIllumColor;

	//
	// Final color opacity
	C.a = opacityMapTexel.r;
	
	return C;
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique BlendModeNone
{ 
	pass one 
	{		
		CullMode         = None;
		AlphaTestEnable  = false;
		AlphaBlendEnable = true;
		ZEnable = true;
		ZWriteEnable = false;
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps();
	}
}

technique BlendModeAlpha
{ 
	pass one 
	{		
		CullMode         = None;
		AlphaTestEnable  = false;
		ZEnable = true;
		ZWriteEnable = false;
		AlphaBlendEnable = true;
		SrcBlend = SrcAlpha;
		DestBlend = InvSrcAlpha;
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps();
	}
}

technique BlendModeAlphaAdd
{ 
	pass one 
	{		
		CullMode         = None;
		AlphaTestEnable  = false;
		ZEnable = true;
		ZWriteEnable = false;
		AlphaBlendEnable = true;
		SrcBlend = SrcAlpha;
		DestBlend = One;
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps();
	}
}

technique BlendModeAdd
{ 
	pass one 
	{	
		CullMode         = None;
		AlphaTestEnable  = false;	
		ZEnable = true;
		ZWriteEnable = false;
		AlphaBlendEnable = true;
		SrcBlend = One;
		DestBlend = One;
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps();
	}
}

