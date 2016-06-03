//--------------------------------------------------------------------------------------------------
// Shadow shader for lava material (rev 1)
//--------------------------------------------------------------------------------------------------
#include "lib\platform.fxh"
#include "lib\skinning.fxh"

//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
float4x4 mWorldViewProjection;

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4	position		: POSITION;		// Vertex position
#if SH_PC
	float2	depth		    : TEXCOORD0;	// Texture coordinates
#endif
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(in VS_SKIN_INPUT vIn)
{
	//
	// Output structure declaration
	VS_OUTPUT Out;
	
	//
	// Compute projected position
	Out.position = mul(vIn.position0, mWorldViewProjection);
#if SH_PC
	Out.depth = Out.position.zw;
#endif

	return Out;
}
VS_OUTPUT vs_noskin(in VS_SKIN_INPUT vIn)
{
	return(vs(vIn));
}
VS_OUTPUT vs_skin(in VS_SKIN_INPUT vIn)
{
	skin(vIn);
	return(vs(vIn));
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
#if SH_PC
float4 ps(VS_OUTPUT vIn) : COLOR
{
	return(vIn.depth.x/vIn.depth.y );
}
#elif SH_PS3
float4 ps(VS_OUTPUT vIn) : COLOR
{
	return float4(0,0,0,0);
}
#endif

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique Solid
{ 
	pass 
	{		
		VertexShader     = compile vs_3_0 vs_noskin();
#if (SH_PC || SH_PS3)
		PixelShader      = compile ps_3_0 ps();
#else
        // On Xbox 360, we use the double-Z fill with a no pixel shader
		PixelShader      = null;
#endif
	}
}

technique SolidSkinning
{
	pass 
	{		
		VertexShader     = compile vs_3_0 vs_skin();
#if (SH_PC || SH_PS3)
		PixelShader      = compile ps_3_0 ps();
#else
        // On Xbox 360, we use the double-Z fill with a no pixel shader
		PixelShader      = null;
#endif
	}
}