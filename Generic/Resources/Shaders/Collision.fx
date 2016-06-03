//--------------------------------------------------------------------------------------------------
// Pick buffer
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
// Parameters
//--------------------------------------------------------------------------------------------------
float4x4 WorldViewProjection : WORLDVIEWPROJECTION < string UIWidget = "None"; >;

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
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_INPUT vIn)
{
	VS_OUTPUT vOut;
	vOut.position = mul(vIn.position, WorldViewProjection);
	return(vOut);
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn) : COLOR
{
	float4 DiffuseColor = {1.0f, 0.0f, 0.0f, 1.0f};
	
	return(DiffuseColor);
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
Technique DefaultTechnique
{
		Pass DefaultPass
    {
				AlphaBlendEnable     = FALSE;
        FillMode             = SOLID;
        ZEnable              = TRUE;
        ZWriteEnable         = TRUE;
        ZFunc                = LESSEQUAL;
        MultiSampleAntialias = FALSE;

        VertexShader         = compile vs_3_0 vs();
        PixelShader          = compile ps_3_0 ps();
	}
}

