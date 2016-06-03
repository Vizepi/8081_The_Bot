//--------------------------------------------------------------------------------------------------
// Pick buffer
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
// Parameters
//--------------------------------------------------------------------------------------------------
float4x4 mWorldViewProjection : WORLDVIEWPROJECTION;
float4   DiffuseColor         : DiffuseColor;

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_INPUT
{
	float4	position			: POSITION;				// Vertex position
	float2	texcoord			: TEXCOORD0;			// Texture coordinates
	float3	tangent				: TANGENT;				// Tangent (in local space)
	float3	binormal			: BINORMAL;				// Binormal (in local space)
	float3	normal				: NORMAL;				// Normal (in local space)
	float3	color				: COLOR;				// Vertex color
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT_VC
{
	float4	position			: POSITION;				// Vertex position
	float4  color               : COLOR;				// Vertex color
};

struct VS_OUTPUT
{
	float4	position			: POSITION;				// Vertex position
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT_VC vsVC(VS_INPUT vIn)
{
	VS_OUTPUT_VC vOut;
	vOut.position = mul(vIn.position, mWorldViewProjection);
	vOut.color    = float4(vIn.color, 1);
	return(vOut);
}

VS_OUTPUT vs(VS_INPUT vIn)
{
	VS_OUTPUT vOut;
	vOut.position = mul(vIn.position, mWorldViewProjection);
	return(vOut);
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 psVC(VS_OUTPUT_VC vIn) : COLOR
{
	return(DiffuseColor * vIn.color);
}

float4 ps(VS_OUTPUT vIn) : COLOR
{
	return(DiffuseColor);
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
#if !SH_DX11
technique DefaultTechnique
{
    Pass DefaultPass
    {
		CullMode			 = NONE;
		AlphaTestEnable      = FALSE;
		AlphaBlendEnable     = FALSE;
        FillMode             = SOLID;
        VertexShader         = compile vs_3_0 vsVC();
        PixelShader          = compile ps_3_0 psVC();
	}
}

technique DefaultTechniqueNoVertexColor
{
    Pass DefaultPass
    {
		CullMode			 = NONE;
		AlphaTestEnable      = FALSE;
		AlphaBlendEnable     = FALSE;
        FillMode             = SOLID;
        VertexShader         = compile vs_3_0 vs();
        PixelShader          = compile ps_3_0 ps();
	}
}
#else

RasterizerState _rs
{
	CullMode = NONE;
	FillMode = SOLID;
	MultiSampleEnable = FALSE;
};

BlendState _bs
{
	AlphaToCoverageEnable = FALSE;
	BlendEnable[0] = FALSE;
};

technique11 DefaultTechnique
{
   Pass DefaultPass
    {
		SetRasterizerState(_rs);
		SetBlendState(_bs, float4( 1.0f, 1.0f, 1.0f, 1.0f ), 0xFFFFFFFF);
		SetVertexShader( CompileShader( vs_4_0, vsVC() ) );
		SetPixelShader( CompileShader( ps_4_0, psVC() ) );

	}
}

technique11 DefaultTechniqueNoVertexColor
{
    Pass DefaultPass
    {
		SetRasterizerState(_rs);
		SetBlendState(_bs, float4( 1.0f, 1.0f, 1.0f, 1.0f ), 0xFFFFFFFF);
     	SetVertexShader( CompileShader( vs_4_0, vs() ) );
		SetPixelShader( CompileShader( ps_4_0, ps() ) );
	}
}

#endif