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
	return(DiffuseColor * vIn.color);
}

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

