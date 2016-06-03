//--------------------------------------------------------------------------------------------------
// Diffuse + Specular bump mapping
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
// Transformations
//--------------------------------------------------------------------------------------------------
float4x4 mWorldViewProjection : WORLDVIEWPROJECTION   < string UIWidget = "None"; >;

//--------------------------------------------------------------------------------------------------
// Parameters
//--------------------------------------------------------------------------------------------------
texture DiffuseMap    : DiffuseMap    < string UIName = "Diffuse Map"; string name = "default.tga"; string TextureType = "2D"; >;

texture DistortMap    : DistortMap    < string UIName = "Distort Map"; string name = "default.tga"; string TextureType = "2D"; >;
float   DistortFactor : DistortFactor < string UIName = "Distort Factor"; string UIWidget = "slider"; float UIMin = 0; float UIMax = 1; > = 1;
float   DistortZoom   : DistortZoom   < string UIName = "Distort Zoom"; string UIWidget = "slider"; float UIMin = 0; float UIMax = 128; > = 0;
bool    FlipV		  : FlipV         < string UIName = "Flip V Channel"; string gui = "slider"; > = false;
float4  Center    : Center;

//--------------------------------------------------------------------------------------------------
// Maps samplers
//--------------------------------------------------------------------------------------------------
sampler2D DiffuseMapSampler = sampler_state
{
	Texture   = <DiffuseMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

sampler2D DistortMapSampler = sampler_state
{
	Texture   = <DistortMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_INPUT
{
	float4	position		: POSITION;		// Vertex position
	float2	texcoord		: TEXCOORD0;	// Texture coordinates
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4	position		: POSITION;		// Vertex position
	float2	texcoord		: TEXCOORD0;	// Texture coordinates
	float2	popo : TEXCOORD1;	// Texture coordinates
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_INPUT vIn)
{
	VS_OUTPUT Out;
	Out.texcoord.xy = vIn.texcoord;
	Out.position = mul(vIn.position, mWorldViewProjection);
	Out.popo.x = Out.position.x;
	Out.popo.y = Out.position.y;
	return Out;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn) : COLOR
{
	float2 uvDistort = vIn.texcoord.xy - float2((Center.x+1.0f)/2, (1.0-Center.y)/2) + float2(0.5, 0.5);

	uvDistort.x -= 0.5;
	if (FlipV)
	{
	uvDistort.y += 0.5;
	}
	else
	{
		uvDistort.y -= 0.5;
	}
	
	uvDistort.xy *= DistortZoom;
	uvDistort.x += 0.5;
	uvDistort.y += 0.5;

  float4 distort = tex2D(DistortMapSampler, uvDistort);
  
  distort.rg -= 0.5.xx;
  distort.rg *= DistortFactor;
  distort.rg += 0.5.xx;

  float2 distortion = distort.rg + vIn.texcoord.xy - float2(0.5,0.5);

  float4 diffuseMapTexel = tex2D(DiffuseMapSampler, distortion);

	return diffuseMapTexel;
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique DefaultTechnique
{ 
	pass one 
	{		
		CullMode         = None;
		AlphaTestEnable  = false;
		AlphaBlendEnable = false;
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps();
	}
}

