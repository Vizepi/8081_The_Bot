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

#if !SH_DX11
	float3	tangent				: TANGENT;				// Tangent (in local space)
	float3	binormal			: BINORMAL;				// Binormal (in local space)
	float3	normal				: NORMAL;				// Normal (in local space)
#endif
	float3	color				: COLOR;				// Vertex color
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4	position			: POSITION;				// Vertex position
	float4  color               : COLOR;				// Vertex color
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_INPUT vIn)
{
	VS_OUTPUT vOut;
	vOut.position = mul(vIn.position, mWorldViewProjection);
	vOut.color    = float4(vIn.color, 1);
	return(vOut);
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn) : COLOR
{
#if !SH_DX11
	return(DiffuseColor * vIn.color);
#else
	return(DiffuseColor ); // The stream is not compliant with the input in DX11 and produce invalid IA.
#endif
}

#if !SH_DX11
//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique DefaultTechnique
{
    Pass DefaultPass
    {
		CullMode			 = NONE;
		AlphaTestEnable      = FALSE;
		AlphaBlendEnable     = FALSE;
        FillMode             = WIREFRAME;
        ZEnable              = FALSE;
        ZWriteEnable         = FALSE;
        ZFunc                = LESSEQUAL;
        MultiSampleAntialias = FALSE;

        VertexShader         = compile vs_3_0 vs();
        PixelShader          = compile ps_3_0 ps();
	}
}
#else

RasterizerState wireframe_rs
{
	CullMode = NONE;
	FillMode = WIREFRAME;
	MultiSampleEnable = FALSE;
};

DepthStencilState wireframe_ds
{
	DepthEnable = FALSE;
};

BlendState wireframe_bs
{
	AlphaToCoverageEnable = FALSE;
	BlendEnable[0] = FALSE;
};

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique11 DefaultTechnique
{
    Pass DefaultPass
    {
		SetRasterizerState(wireframe_rs);
		SetDepthStencilState(wireframe_ds, 0);
		SetBlendState(wireframe_bs, float4( 1.0f, 1.0f, 1.0f, 1.0f ), 0xFFFFFFFF);
		SetVertexShader( CompileShader( vs_4_0, vs() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, ps() ) );
	}
}
#endif
