//--------------------------------------------------------------------------------------------------
// FXAA effect file
// See: http://timothylottes.blogspot.com/2011/07/fxaa-311-released.html
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
// FXAA defines for '"Fxaa3_11.h'
//--------------------------------------------------------------------------------------------------
#if SH_PC
#if SH_DX11
	#define FXAA_HLSL_5 			1
#else
	#define FXAA_HLSL_3 			1
#endif
	#define FXAA_PC					1
	#define FXAA_QUALITY__PRESET 	29
	//#define FXAA_PC_CONSOLE			1
#endif
#if SH_X360
	#define FXAA_360 1
#endif
#if SH_PS3
	#define FXAA_PS3 1
#endif


//--------------------------------------------------------------------------------------------------
// FXAA source code
//--------------------------------------------------------------------------------------------------
#include "lib/platform.fxh"
#include "lib/Fxaa3_11.fxh"


//--------------------------------------------------------------------------------------------------
// Uniform
//--------------------------------------------------------------------------------------------------
FxaaFloat4 fxaaQualityRcpFrame;
FxaaFloat4 fxaaConsoleRcpFrameOpt;
FxaaFloat4 fxaaConsoleRcpFrameOpt2;
FxaaFloat4 fxaaConsole360RcpFrameOpt2;
FxaaFloat fxaaQualitySubpix;
FxaaFloat fxaaQualityEdgeThreshold;
FxaaFloat fxaaQualityEdgeThresholdMin;
FxaaFloat fxaaConsoleEdgeSharpness;
FxaaFloat fxaaConsoleEdgeThreshold;
FxaaFloat fxaaConsoleEdgeThresholdMin;
FxaaFloat4 fxaaConsole360ConstDir;

//--------------------------------------------------------------------------------------------------
// Texture
//--------------------------------------------------------------------------------------------------
#if !SH_DX11

#if !SH_PS3
sampler2D tex								: register(s0);
#if SH_X360
sampler2D fxaaConsole360TexExpBiasNegOne	: register(s1);
sampler2D fxaaConsole360TexExpBiasNegTwo	: register(s2);
#endif // SH_X360
#else
texture t0;
sampler2D tex = sampler_state
{
	Texture = <t0>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};
#endif

#else
SamplerState smpl;
Texture2D tex;
#endif

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_INPUT
{
	float4 position : POSITION;
	float2 texcoord : TEXCOORD0;
};


//--------------------------------------------------------------------------------------------------
// Pixel shader input structure
//--------------------------------------------------------------------------------------------------
struct PS_INPUT
{
	float2 texcoord	: TEXCOORD0;
};


//--------------------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------------------
float4 VS( in VS_INPUT vIn, out PS_INPUT vOut ) : POSITION
{
    vOut.texcoord.xy = vIn.texcoord;
    return float4(vIn.position.xy, 1.0f, 1.0f);
}


//--------------------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------------------
#if SH_DX11
float4 PS_EnableFXAA( float4 pos : POSITION, PS_INPUT vIn ) : COLOR0
#else
float4 PS_EnableFXAA( PS_INPUT vIn ) : COLOR0
#endif
{
#if !SH_DX11
	float4 fxaa = FxaaPixelShader(
		vIn.texcoord,
		FxaaFloat4(vIn.texcoord - 0.5f * SCREEN_SIZE.zw, vIn.texcoord + 0.5f * SCREEN_SIZE.zw),
		tex,
#if SH_X360
		fxaaConsole360TexExpBiasNegOne,
		fxaaConsole360TexExpBiasNegTwo,
#else
		tex,
		tex,
#endif
		fxaaQualityRcpFrame.xy,
		fxaaConsoleRcpFrameOpt,
		fxaaConsoleRcpFrameOpt2,
		fxaaConsole360RcpFrameOpt2,
		fxaaQualitySubpix,
		fxaaQualityEdgeThreshold,
		fxaaQualityEdgeThresholdMin,
		fxaaConsoleEdgeSharpness,
		fxaaConsoleEdgeThreshold,
		fxaaConsoleEdgeThresholdMin,
		fxaaConsole360ConstDir
	);
#else

	 FxaaTex  t;
	 t.smpl = smpl;
	 t.tex = tex;
 
	float4 fxaa = FxaaPixelShader(
		vIn.texcoord,
		FxaaFloat4(vIn.texcoord - 0.5f * SCREEN_SIZE.zw, vIn.texcoord + 0.5f * SCREEN_SIZE.zw),
		t,
#if SH_X360
		fxaaConsole360TexExpBiasNegOne,
		fxaaConsole360TexExpBiasNegTwo,
#else
		t,
		t,
#endif
		fxaaQualityRcpFrame.xy,
		fxaaConsoleRcpFrameOpt,
		fxaaConsoleRcpFrameOpt2,
		fxaaConsole360RcpFrameOpt2,
		fxaaQualitySubpix,
		fxaaQualityEdgeThreshold,
		fxaaQualityEdgeThresholdMin,
		fxaaConsoleEdgeSharpness,
		fxaaConsoleEdgeThreshold,
		fxaaConsoleEdgeThresholdMin,
		fxaaConsole360ConstDir
	);
#endif
	
	return(fxaa);
}

#if SH_DX11
float4 PS_DisableFXAA( float4 position : POSITION, PS_INPUT vIn ) : COLOR0
#else
float4 PS_DisableFXAA( PS_INPUT vIn ) : COLOR0
#endif
{
	// return alpha = 0 if scene alpha is 0, otherwise alpha = 1
#if SH_DX11
	float4 color = tex.Sample(smpl, vIn.texcoord);
#else
	float4 color = tex2D(tex, vIn.texcoord);
#endif
	color.a = sign(color.a);
	return(color);
}

#if !SH_DX11
//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique EnableFXAA
{
    pass
    {
        VertexShader 	= compile vs_3_0 VS();
        PixelShader  	= compile ps_3_0 PS_EnableFXAA();
    }
}
technique DisableFXAA
{
    pass
    {
        VertexShader 	= compile vs_3_0 VS();
        PixelShader  	= compile ps_3_0 PS_DisableFXAA();
    }
}
#else
technique11 EnableFXAA
{
    pass
    {
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_5_0, PS_EnableFXAA() ) );
    }
}
technique11 DisableFXAA
{
    pass
    {
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, PS_DisableFXAA() ) );
    }
}
#endif