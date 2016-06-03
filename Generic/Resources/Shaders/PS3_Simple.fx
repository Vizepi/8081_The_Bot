
float4x4 mWorldViewProjection;

struct a2vConnector
{
    float4 objCoord : POSITION;
    float4 tex : TEXCOORD0;
};

struct v2fConnector
{
    float4 projCoord : POSITION;
    float4 tex       : TEXCOORD0;
};

struct f2fConnector
{
	float4 COL0 : COLOR0;
};

v2fConnector vs(a2vConnector a2v)
{
    v2fConnector v2f;
    v2f.projCoord = mul(a2v.objCoord, mWorldViewProjection);
    v2f.tex       = a2v.tex; 
    return v2f;
}

texture DiffuseMap;

sampler2D texture0s = sampler_state
{
	Texture   = <DiffuseMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

f2fConnector ps(v2fConnector v2f)
{
    f2fConnector f2f;
    f2f.COL0 = tex2D(texture0s, v2f.tex.xy);
    return f2f;
}

technique Solid
{
	pass
	{
		VertexShader = compile vs_3_0 vs();
		PixelShader  = compile ps_3_0 ps();
		
		ZENABLE = TRUE;
		ALPHABLENDENABLE = FALSE;
	}
}
