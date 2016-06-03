//-----------------------------------------------------------------------------
// 
//-----------------------------------------------------------------------------
#define MAX_SAMPLES 9
float aSamplingOffsets[MAX_SAMPLES];
float fScreenOffset;
float aSamplingWeights[MAX_SAMPLES];
float fTotalWeights;

//-----------------------------------------------------------------------------
// 
//-----------------------------------------------------------------------------
texture TexMap1;
sampler2D TexMap1Sampler = sampler_state
{
	Texture = <TexMap1>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};
texture TexMap2;
sampler2D TexMap2Sampler = sampler_state
{
	Texture = <TexMap2>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

//-----------------------------------------------------------------------------
// 
//-----------------------------------------------------------------------------
struct VS_INPUT
{
	float4 vPosition : POSITION;
	float2 vTexcoord : TEXCOORD;
};
struct VS_OUTPUT
{
	float2 vTexcoord : TEXCOORD;
};
float4 BlurVS( in VS_INPUT vIn, out VS_OUTPUT vOut ) : POSITION
{
	vOut.vTexcoord = vIn.vTexcoord;
	return vIn.vPosition;
}

//-----------------------------------------------------------------------------
// 
//-----------------------------------------------------------------------------
float4 DownscalePS( in float2 vScreenPosition : TEXCOORD0 ) : COLOR
{
	return tex2D( TexMap1Sampler, vScreenPosition );
}
float4 BlurHorizontalPS( in float2 vScreenPosition : TEXCOORD0 ) : COLOR
{
    float4 sample = 0.0f;
	for( int i=0; i < MAX_SAMPLES; i++ )
	{
		sample += aSamplingWeights[i] * tex2D( TexMap1Sampler, vScreenPosition + float2(aSamplingOffsets[i], fScreenOffset) );
	}
	return float4(sample.rgb * fTotalWeights, 1.0f);
}
float4 BlurVerticalPS( in float2 vScreenPosition : TEXCOORD0 ) : COLOR
{
    float4 sample = 0.0f;
	for( int i=0; i < MAX_SAMPLES; i++ )
	{
		sample += aSamplingWeights[i] * tex2D( TexMap1Sampler, vScreenPosition + float2(fScreenOffset, aSamplingOffsets[i]) );
	}
	return float4(sample.rgb * fTotalWeights, 1.0f);
}
float4 CombinePS( in float2 vScreenPosition : TEXCOORD0 ) : COLOR
{
	float4 tex1 = tex2D( TexMap1Sampler, vScreenPosition );
	float4 tex2 = tex2D( TexMap2Sampler, vScreenPosition );	
	return tex1 *(1.0f - fScreenOffset) + tex2 * fScreenOffset;
}

//-----------------------------------------------------------------------------
// 
//-----------------------------------------------------------------------------
technique Downscale
{
    pass
    {
		VertexShader = compile vs_3_0 BlurVS();
        PixelShader  = compile ps_3_0 DownscalePS();
    }
}
technique BlurHorizontal
{
    pass
    {
		VertexShader = compile vs_3_0 BlurVS();
        PixelShader  = compile ps_3_0 BlurHorizontalPS();
    }
}
technique BlurVertical
{
    pass
    {
		VertexShader = compile vs_3_0 BlurVS();
        PixelShader  = compile ps_3_0 BlurVerticalPS();
    }
}
technique Combine
{
    pass
    {
		VertexShader = compile vs_3_0 BlurVS();
        PixelShader  = compile ps_3_0 CombinePS();
    }
}

