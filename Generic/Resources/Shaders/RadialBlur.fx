//---------------------------------------------------------------------------------------------------------------------
// Constants : sample count
//---------------------------------------------------------------------------------------------------------------------
#define RADIAL_SAMPLE_COUNT		8
static const float aRadialKernel[RADIAL_SAMPLE_COUNT] = {
    0.125,
    0.250,
    0.375,
    0.500,
    0.625,
    0.750,
    0.875,
    1.000,
};

#define GAUSSIAN_SAMPLE_COUNT	8
static const float aGaussianKernel[GAUSSIAN_SAMPLE_COUNT] = {
    0.125,
    0.250,
    0.375,
    0.500,
    0.625,
    0.750,
    0.875,
    1.000,
};


//---------------------------------------------------------------------------------------------------------------------
// Uniform
//---------------------------------------------------------------------------------------------------------------------
float2 		vClipSpaceCenter;
float 		fStrength;
float 		fRadius;


//---------------------------------------------------------------------------------------------------------------------
// Texture Samplers
//---------------------------------------------------------------------------------------------------------------------
texture 	ColorMap;
sampler2D 	ColorMapSampler = sampler_state
{
	Texture 	= <ColorMap>;
	MinFilter 	= LINEAR;
	MagFilter 	= LINEAR;
	MipFilter 	= NONE;
	AddressU  	= CLAMP;
	AddressV  	= CLAMP;
};

//-----------------------------------------------------------------------------
// Vertex Shader
//-----------------------------------------------------------------------------
struct VS_INPUT
{
	float4 vPosition : POSITION;
	float2 vTexcoord : TEXCOORD;
};

float4 VS( in VS_INPUT vIn, out float2 vTexcoord : TEXCOORD ) : POSITION
{
	vTexcoord = vIn.vTexcoord;
	return vIn.vPosition;
}

//-----------------------------------------------------------------------------
// Pixel Shader
//-----------------------------------------------------------------------------
float4 RadialPS(in float2 vTexcoord  : TEXCOORD0) : COLOR
{
    float2 vOffset = vClipSpaceCenter - vTexcoord;
    float  fDistance = length(vOffset);
    float3 vScene = tex2D(ColorMapSampler, vTexcoord).rgb;
    float3 vBlur = float3(0,0,0);
    for( int i = 0 ; i < RADIAL_SAMPLE_COUNT ; ++i )
    {
        float2 uv = vTexcoord + vOffset * aRadialKernel[i] * fStrength;
        vBlur += tex2D(ColorMapSampler, uv).rgb;
    }
    vBlur /= RADIAL_SAMPLE_COUNT;
    return float4(lerp(vScene,vBlur,saturate(fDistance/max(1e-6,fRadius))),1);
}

float4 GaussianPS(in float2 vTexcoord  : TEXCOORD0) : COLOR
{
    float2 vOffset = vClipSpaceCenter - vTexcoord;
    float  fDistance = length(vOffset);
    float3 vScene = tex2D(ColorMapSampler, vTexcoord).rgb;
    float3 vBlur = float3(0,0,0);
    
    for( int i = 0 ; i < GAUSSIAN_SAMPLE_COUNT ; ++i )
    {
        float2 uv = vTexcoord + float2(vOffset.x, 0.0) * aGaussianKernel[i] * fStrength;
        vBlur += tex2D(ColorMapSampler, uv).rgb;
    }
    
    for( int j = 0 ; j < GAUSSIAN_SAMPLE_COUNT ; ++j )
		{
        float2 uv = vTexcoord + float2(0.0, vOffset.y) * aGaussianKernel[j] * fStrength;
			vBlur += tex2D(ColorMapSampler, uv).rgb;
		}
    
    vBlur /= 3.0 * GAUSSIAN_SAMPLE_COUNT;
    return float4(lerp(vScene,vBlur,saturate(fDistance/max(1e-6,fRadius))),1);
    }
//-----------------------------------------------------------------------------
// Techniques
//-----------------------------------------------------------------------------
technique Radial
{
    pass
    {
		VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 RadialPS();
    }
}

technique Gaussian
{
    pass
    {
		VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 GaussianPS();
    }
}

