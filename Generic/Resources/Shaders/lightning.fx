#include "lib/platform.fxh"

//--------------------------------------------------------------------------------------------------
// Constants
//--------------------------------------------------------------------------------------------------
#define MAX_SAMPLES            16    // Maximum texture grabs

//--------------------------------------------------------------------------------------------------
// Transformations
//--------------------------------------------------------------------------------------------------
float4x4	WorldViewProj : WORLDVIEWPROJECTION   < string UIWidget = "None"; >;
float4		aSamplingOffsets[MAX_SAMPLES];	
float4		aSamplingWeights[MAX_SAMPLES];
float4		BlurColor = {1.0f, 1.0f, 1.0f, 1.0f};

//-----------------------------------------------------------------------------
// Texture samplers
//-----------------------------------------------------------------------------
#if !SH_PS3
sampler s0 : register(s0);
sampler s1 : register(s1);
sampler s2 : register(s2);
#else
texture t0;
texture t1;
texture t2;
sampler2D s0 = sampler_state
{
	Texture = <t0>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};
sampler2D s1 = sampler_state
{
	Texture = <t1>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};
sampler2D s2 = sampler_state
{
	Texture = <t2>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};
#endif

	
//-----------------------------------------------------------------------------
// Name: DownScale4x4
// Type: Pixel shader                                      
// Desc: Scale the source texture down to 1/16 scale
//-----------------------------------------------------------------------------
float4 DownScale4x4PS( in float2 vScreenPosition : TEXCOORD0 ) : COLOR
{
    float4 sample = 0.0f;
	for( int i=0; i < 16; i++ )
	{
		sample += tex2D( s0, vScreenPosition + aSamplingOffsets[i] );
	}
	return saturate(sample); // / 16;
} 


//-----------------------------------------------------------------------------
// Name: GaussBlur5x5
// Type: Pixel shader                                      
// Desc: Simulate a 5x5 kernel gaussian blur by sampling the 12 points closest
//       to the center point.
//-----------------------------------------------------------------------------
float4 GaussBlur5x5PS( in float2 vScreenPosition : TEXCOORD0 ) : COLOR
{
    float4 sample = 0.0f;
	for( int i=0; i < 12; i++ )
	{
		sample += aSamplingWeights[i] * tex2D( s0, vScreenPosition + aSamplingOffsets[i] );
	}
	return sample*BlurColor;//float4(1.0, 0.0, 0.0, 1.0);
}


//-----------------------------------------------------------------------------
// Name: LightningFinal
// Type: Pixel shader                                      
// Desc: Perform blue shift, tone map the scene, and add post-processed light
//       effects
//-----------------------------------------------------------------------------
float4 LightningFinalPS( in float2 vScreenPosition : TEXCOORD0 ) : COLOR
{
	float4 vBlurred = tex2D(s1, vScreenPosition);
	float4 vSample = tex2D(s0, vScreenPosition);

	float4 vLightning = tex2D(s2, vScreenPosition);
	vSample += vBlurred + vLightning * 0.4f;

	return vSample;
}
	

//--------------------------------------------------------------------------------------------------
// 
//--------------------------------------------------------------------------------------------------
void default_vs(in float4 iPos : POSITION, in float4 iTex : TEXCOORD0, out float4 oPos : POSITION, out float4 oTex : TEXCOORD0 )
{
	oPos = iPos;
	oTex = iTex;
}


//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
float4 vs( float3 position	: POSITION ) : POSITION
{
	float4 outPosition = mul( float4(position, 1.0), WorldViewProj);
	return outPosition;
}
#if !SH_PS3
float4 ps(float4 vIn : POSITION, uniform float4 color) : COLOR
{
	return float4(color);
}
#else
float4 ps() : COLOR
{
	return float4(1,1,1,1);
}
#endif

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Name: DownScale4x4
// Type: Technique                                     
// Desc: Scale the source texture down to 1/16 scale
//-----------------------------------------------------------------------------
technique DownScale4x4
{
    pass P0
    {
		ZEnable = false;
		ZWriteEnable = false;
		VertexShader = compile vs_3_0 default_vs();
		PixelShader  = compile ps_3_0 DownScale4x4PS();
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
    pass P0
    {
		ZEnable = false;
		ZWriteEnable = false;
		VertexShader = compile vs_3_0 default_vs();   
		PixelShader  = compile ps_3_0 GaussBlur5x5PS();
    }
}


technique DefaultTechnique
{ 
	pass 
	{		
		ZEnable = true;
		ZWriteEnable = false;
		AlphaBlendEnable = false;
		VertexShader     = compile vs_3_0 vs();
#if !SH_PS3
		PixelShader      = compile ps_3_0 ps(float4(1.0, 1.0, 1.0, 1.0));
#else
		PixelShader      = compile ps_3_0 ps();
#endif
	}
}

//-----------------------------------------------------------------------------
// Name: FinalScenePass
// Type: Technique                                     
// Desc: Minimally transform and texture the incoming geometry
//-----------------------------------------------------------------------------
technique LightningFinal
{
    pass P0
    {
		ZEnable = false;
		ZWriteEnable = false;
		VertexShader = compile vs_3_0 default_vs();   		
        PixelShader  = compile ps_3_0 LightningFinalPS();
    }
}