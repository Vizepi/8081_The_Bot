//--------------------------------------------------------------------------------------------------
// Normal depth for diffuse material (rev 1)
//--------------------------------------------------------------------------------------------------
#include "lib\platform.fxh"
#include "lib\skinning.fxh"

//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
float4x4 	mWorldIT;
float4x4 	mWorldViewProjection;

//--------------------------------------------------------------------------------------------------
// Vertex shader output structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float2	depth  			 : TEXCOORD0;	// Depth
	float3	worldNormal		 : TEXCOORD2;	// Normal (in world space)
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(in VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
	ISOLATE position = mul(vIn.position0, mWorldViewProjection);

	//
	// Output structure declaration
	VS_OUTPUT Out;

	//
	// Compute normal in world space
	Out.worldNormal = normalize(mul(vIn.normal0, (float3x3)mWorldIT).xyz);

	//
	// Forward depth value
	Out.depth.xy = position.zw;
	
	return Out;
}


//--------------------------------------------------------------------------------------------------
// Pixel shader output structure
//--------------------------------------------------------------------------------------------------
struct PS_OUTPUT
{
	float4 Normal_Shininess : COLOR0;
#if SH_PC
	float4 Depth  			: COLOR1;
#endif
};

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
PS_OUTPUT ps(VS_OUTPUT vIn)
{
	PS_OUTPUT Out;

	//
	// Compute normal map
	float3 N = vIn.worldNormal;

	//
	// Pack the outputs into RGBA8
	Out.Normal_Shininess.xyz = N * 0.5f + 0.5f;
	Out.Normal_Shininess.w   = 0.0f / 128.0f;
#if SH_PC
	Out.Depth                = vIn.depth.x / vIn.depth.y;
#endif

	return Out;
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique Solid
{
    pass
    {
        VertexShader 	= compile vs_3_0 vs();
        PixelShader  	= compile ps_3_0 ps();
    }
}
technique SolidSkinning
{
    pass
    {
        VertexShader 	= compile vs_3_0 vs();
        PixelShader  	= compile ps_3_0 ps();
    }
}
