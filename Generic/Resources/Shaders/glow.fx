//-----------------------------------------------------------------------------
// Global constants
//-----------------------------------------------------------------------------
// Maximum texture grabs
#define MAX_SAMPLES		16
   
// The per-color weighting to be used for luminance calculations in RGB order.
static const float3 LUMINANCE_VECTOR  	= float3(0.299f, 0.587f, 0.114f);

// The luminance theshold value for glow
float fGlowThreshold = 1.0f;       


//-----------------------------------------------------------------------------
// Global variables
//-----------------------------------------------------------------------------
// Contains sampling offsets used by the techniques
float4 aSamplingOffsets[MAX_SAMPLES];
float4 aSamplingWeights[MAX_SAMPLES];


//-----------------------------------------------------------------------------
// Texture samplers
//-----------------------------------------------------------------------------
texture texPoint0Map;
sampler2D texPoint0MapSampler = sampler_state
{
	Texture   = <texPoint0Map>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU = CLAMP;
	AddressV = CLAMP;
};
texture texPoint1Map;
sampler2D texPoint1MapSampler = sampler_state
{
	Texture   = <texPoint1Map>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU = CLAMP;
	AddressV = CLAMP;
};
texture texLin0Map;
sampler2D texLin0MapSampler = sampler_state
{
	Texture   = <texLin0Map>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU = CLAMP;
	AddressV = CLAMP;
};
texture texLin1Map;
sampler2D texLin1MapSampler = sampler_state
{
	Texture   = <texLin1Map>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU = CLAMP;
	AddressV = CLAMP;
};


//-----------------------------------------------------------------------------
// Name: DownScale4x4
// Type: Pixel shader                                      
// Desc: Scale the source texture down to 1/16 scale
//-----------------------------------------------------------------------------
float4 DownScale4x4PS( in float4 position : POSITION, in float2 vScreenPosition : TEXCOORD0 ) : COLOR
{
	float4 sample = 0.0f;
    for( int i=0; i < 16; i++ )
	{
		sample += tex2D( texPoint0MapSampler, vScreenPosition + aSamplingOffsets[i] );
	}
	return sample / 16;
}


//-----------------------------------------------------------------------------
// Name: BrightPassFilter
// Type: Pixel shader                                      
// Desc: Perform a brightness filter on the source texture
//-----------------------------------------------------------------------------
float4 BrightPassFilterPS( in float4 position : POSITION, in float2 vScreenPosition : TEXCOORD0 ) : COLOR
{
	float4 vSample = tex2D( texPoint0MapSampler, vScreenPosition );
	float lum = log(1.0 + dot(vSample.xyz, LUMINANCE_VECTOR));
	lum = saturate(lum - fGlowThreshold);
	return vSample * lum;
}


//-----------------------------------------------------------------------------
// Name: GaussBlur5x5
// Type: Pixel shader                                      
// Desc: Simulate a 5x5 kernel gaussian blur by sampling the 12 points closest
//       to the center point.
//-----------------------------------------------------------------------------
float4 GaussBlur5x5PS( in float4 position : POSITION, in float2 vScreenPosition : TEXCOORD0 ) : COLOR
{
    float4 sample = 0.0f;
	for( int i=0; i < 12; i++ )
	{
		sample += aSamplingWeights[i] * tex2D( texPoint0MapSampler, vScreenPosition + aSamplingOffsets[i] );
	}
	return sample;
}


//-----------------------------------------------------------------------------
// Name: DownScale2x2
// Type: Pixel shader                                      
// Desc: Scale the source texture down to 1/4 scale
//-----------------------------------------------------------------------------
#if !SH_PS3
float4 DownScale2x2PS( in float4 position : POSITION, in float2 vScreenPosition : TEXCOORD0 ) : COLOR
{
      float4 sample = 0.0f;
	for( int i=0; i < 4; i++ )
	{
		sample += tex2D( texPoint0MapSampler, vScreenPosition + aSamplingOffsets[i] );
	}
	return sample / 4;
}
#else
float4 DownScale2x2PS( in float4 position : POSITION, in float2 vScreenPosition : TEXCOORD0 ) : COLOR
{
	return tex2D(texLin0MapSampler, vScreenPosition);
}
#endif

//-----------------------------------------------------------------------------
// Name: Glow
// Type: Pixel shader                                      
// Desc: Blur the source image along one axis using a gaussian
//       distribution. Since gaussian blurs are separable, this shader is called 
//       twice; first along the horizontal axis, then along the vertical axis.
//-----------------------------------------------------------------------------
float4 GlowPS( in float4 position : POSITION, in float2 vScreenPosition : TEXCOORD0 ) : COLOR
{
    float4 vSample = 0.0f;
    float4 vColor = 0.0f;
        
    // Perform a one-directional gaussian blur
    for(int iSample = 0; iSample < 15; iSample++)
    {
        float2 vSamplePosition = vScreenPosition + aSamplingOffsets[iSample];
        vColor = tex2D(texPoint0MapSampler, vSamplePosition);
        vSample += aSamplingWeights[iSample]*vColor;
    }
    
    return vSample;
}


//-----------------------------------------------------------------------------
// Name: FinalScenePass
// Type: Pixel shader                                      
//-----------------------------------------------------------------------------
float4 FinalScenePassPS( in float4 position : POSITION, in float2 vScreenPosition : TEXCOORD0 ) : COLOR
{
    float4 vSample = tex2D(texPoint0MapSampler, vScreenPosition);
    float4 vGlow = tex2D(texLin1MapSampler, vScreenPosition);
  
    // Add the glow
    vSample += vGlow;
    
    return vSample;
}


//-----------------------------------------------------------------------------
// Name: ScreenPositionVS
// Type: Vertex shader                                      
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
float4 ScreenPositionVS( in VS_INPUT vIn, out VS_OUTPUT vOut ) : POSITION
{
	vOut.vTexcoord = vIn.vTexcoord;
	return vIn.vPosition;
}

#if SH_DX11

//-----------------------------------------------------------------------------
// Name: DownScale4x4
// Type: Technique                                     
// Desc: Scale the source texture down to 1/16 scale
//-----------------------------------------------------------------------------
technique11 DownScale4x4
{
    pass
    {
		SetVertexShader( CompileShader( vs_4_0, ScreenPositionVS() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, DownScale4x4PS() ) );
    }
}

//-----------------------------------------------------------------------------
// Name: BrightPassFilter
// Type: Technique                                     
// Desc: Perform a high-pass filter on the source texture
//-----------------------------------------------------------------------------
technique11 BrightPassFilter
{
    pass
    {
		SetVertexShader( CompileShader( vs_4_0, ScreenPositionVS() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, BrightPassFilterPS() ) );
    }
}


//-----------------------------------------------------------------------------
// Name: GaussBlur5x5
// Type: Technique                                     
// Desc: Simulate a 5x5 kernel gaussian blur by sampling the 12 points closest
//       to the center point.
//-----------------------------------------------------------------------------
technique11 GaussBlur5x5
{
    pass
    {
		SetVertexShader( CompileShader( vs_4_0, ScreenPositionVS() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, GaussBlur5x5PS() ) );
    }
}


//-----------------------------------------------------------------------------
// Name: DownScale2x2
// Type: Technique                                     
// Desc: Scale the source texture down to 1/4 scale
//-----------------------------------------------------------------------------
technique11 DownScale2x2
{
    pass
    {
		SetVertexShader( CompileShader( vs_4_0, ScreenPositionVS() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, DownScale2x2PS() ) );
    }
}

//-----------------------------------------------------------------------------
// Name: Bloom
// Type: Technique                                     
// Desc: Performs a single horizontal or vertical pass of the blooming filter
//-----------------------------------------------------------------------------
technique11 Glow
{
    pass
    {        
		SetVertexShader( CompileShader( vs_4_0, ScreenPositionVS() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, GlowPS() ) );
    }

}


//-----------------------------------------------------------------------------
// Name: FinalScenePass
// Type: Technique                                     
// Desc: Minimally transform and texture the incoming geometry
//-----------------------------------------------------------------------------
technique11 FinalScenePass
{
    pass
    {
		SetVertexShader( CompileShader( vs_4_0, ScreenPositionVS() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, FinalScenePassPS() ) );
    }
}
#else

//-----------------------------------------------------------------------------
// Name: DownScale4x4
// Type: Technique                                     
// Desc: Scale the source texture down to 1/16 scale
//-----------------------------------------------------------------------------
technique DownScale4x4
{
    pass
    {
		VertexShader = compile vs_3_0 ScreenPositionVS();
        PixelShader  = compile ps_3_0 DownScale4x4PS();
    }
}


//-----------------------------------------------------------------------------
// Name: BrightPassFilter
// Type: Technique                                     
// Desc: Perform a high-pass filter on the source texture
//-----------------------------------------------------------------------------
technique BrightPassFilter
{
    pass
    {
		VertexShader = compile vs_3_0 ScreenPositionVS();
        PixelShader  = compile ps_3_0 BrightPassFilterPS();
    }
}


//-----------------------------------------------------------------------------
// Name: GaussBlur5x5
// Type: Technique                                     
// Desc: Simulate a 5x5 kernel gaussian blur by sampling the 12 points closest
//       to the center point.
//-----------------------------------------------------------------------------
technique GaussBlur5x5
{
    pass
    {
		VertexShader = compile vs_3_0 ScreenPositionVS();
        PixelShader  = compile ps_3_0 GaussBlur5x5PS();
    }
}


//-----------------------------------------------------------------------------
// Name: DownScale2x2
// Type: Technique                                     
// Desc: Scale the source texture down to 1/4 scale
//-----------------------------------------------------------------------------
technique DownScale2x2
{
    pass
    {
		VertexShader = compile vs_3_0 ScreenPositionVS();
        PixelShader  = compile ps_3_0 DownScale2x2PS();
    }
}

//-----------------------------------------------------------------------------
// Name: Bloom
// Type: Technique                                     
// Desc: Performs a single horizontal or vertical pass of the blooming filter
//-----------------------------------------------------------------------------
technique Glow
{
    pass
    {        
		VertexShader = compile vs_3_0 ScreenPositionVS();
        PixelShader  = compile ps_3_0 GlowPS();
    }

}


//-----------------------------------------------------------------------------
// Name: FinalScenePass
// Type: Technique                                     
// Desc: Minimally transform and texture the incoming geometry
//-----------------------------------------------------------------------------
technique FinalScenePass
{
    pass
    {
		VertexShader = compile vs_3_0 ScreenPositionVS();
        PixelShader  = compile ps_3_0 FinalScenePassPS();
    }
}
#endif