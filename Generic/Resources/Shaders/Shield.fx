//--------------------------------------------------------------------------------------------------
// Standard material
//--------------------------------------------------------------------------------------------------

//
// Transformations parameters
//
float4x4	mWorldViewProjection   : WORLDVIEWPROJECTION;
float4x4        mWorldView             : WORLDVIEW;
float4x4        mWorld                 : WORLD;
float		fElapsedTime            : TIME;

//
// Material parameters
//
float           RimSize                : RimSize                 < string UIName = "Rim Light Size"; > = 1.0f;
float           RimPower               : RimPower                < string UIName = "Rim Light Power"; > = 1.0f;
float4          RimColor               : RimColor                < string UIName = "Rim Light Color";  > = {1.0f, 1.0f, 1.0f, 1.0f};

float		Diffuse01MapScrollU    : Diffuse01MapScrollU     < string UIName = "Diffuse Map Scroll U"; > = 0.0f;
float		Diffuse01MapScrollV    : Diffuse01MapScrollV     < string UIName = "Diffuse Map Scroll V"; > = 0.0f;
texture		Diffuse01Map 	       : Diffuse01Map            < string UIName = "Diffuse Map";  string name = "default.tga"; string TextureType = "2D"; >;

float		Diffuse02MapScrollU    : Diffuse02MapScrollU     < string UIName = "Diffuse Map Scroll U"; > = 0.0f;
float		Diffuse02MapScrollV    : Diffuse02MapScrollV     < string UIName = "Diffuse Map Scroll V"; > = 0.0f;
texture		Diffuse02Map 	       : Diffuse02Map            < string UIName = "Diffuse Map";  string name = "default.tga"; string TextureType = "2D"; >;


//
// Maps samplers
//
sampler2D Diffuse01MapSampler = sampler_state
{
	Texture   = <Diffuse01Map>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = Point;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

sampler2D Diffuse02MapSampler = sampler_state
{
	Texture   = <Diffuse02Map>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = Point;
	AddressU  = WRAP;
	AddressV  = WRAP;
};


//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_INPUT
{
	float4	position	 : POSITION;	// Vertex Position
	float3  normal           : NORMAL;      // Vertex Normal
	float2	texcoord	 : TEXCOORD0;	// Texture Coordinates
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4 position		 : POSITION;	// Vertex Position
	float3 worldPosition     : TEXCOORD0;   // Position in world space
	float3 viewNormal        : TEXCOORD1;   // Normal in view space
	float2 texcoord		 : TEXCOORD2;	// Texture coordinates
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
	Out.texcoord.xy = vIn.texcoord;
		
	//
	// Vertex in world space
	Out.worldPosition = mul(vIn.position, mWorld);

	//
	// Normal in view space
	Out.viewNormal = mul(vIn.normal, mWorldView);
	Out.viewNormal = normalize(Out.viewNormal);

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
	float4 texcolor01 = tex2D(Diffuse01MapSampler, vIn.texcoord.xy + float2(Diffuse01MapScrollU, Diffuse01MapScrollV)*fElapsedTime);
	float4 texcolor02 = tex2D(Diffuse02MapSampler, vIn.texcoord.xy + float2(Diffuse02MapScrollU, Diffuse02MapScrollV)*fElapsedTime);
	
	float2 uv1 = vIn.texcoord.xy + float2(texcolor01.a, texcolor01.a);
	float2 uv2 = vIn.texcoord.xy + float2(texcolor02.a, texcolor02.a);

	texcolor01 = tex2D(Diffuse01MapSampler,	uv1);
	texcolor02 = tex2D(Diffuse02MapSampler,	uv2);	
	texcolor01.a = max(max(texcolor01.r, texcolor01.g), texcolor01.b);
	texcolor02.a = max(max(texcolor02.r, texcolor02.g), texcolor02.b);

        float4 texcolor = 0.5f * (texcolor01+texcolor02);

        // Fake rim light
#ifdef _3DSMAX_
        vIn.viewNormal.z = -vIn.viewNormal.z;
#endif
        float rim = saturate(vIn.viewNormal.z);
        rim = pow(rim, RimSize);
        rim = (1.0f - rim) * RimPower;

        return (texcolor + rim) * RimColor;
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique Solid
{ 
	pass one 
	{
		ZEnable				= true; 
		ZWriteEnable		= false;
		AlphaBlendEnable	= true;
		SrcBlend			= SrcAlpha;
		DestBlend			= InvSrcAlpha;
		VertexShader		= compile vs_3_0 vs();
		PixelShader			= compile ps_3_0 ps();
	}
}

