//--------------------------------------------------------------------------------------------------
// Standard material for MAX (rev 1)
//--------------------------------------------------------------------------------------------------
#ifdef _3DSMAX_

//
//
//
#include "lib\platform.fxh"
// 3DSMAX 2009 BUG: after including "lib\platform.fxh", MAX sets the current directory to "lib\"
#include "lighting.fxh"

//
// Transformations parameters
//
float4x4 mWorld  		: WORLD			< string UIWidget = "None"; >;
float4x4 mWorldIT		: WORLDINVERSETRANSPOSE	< string UIWidget = "None"; >;
float4x4 mWorldViewProjection	: WORLDVIEWPROJECTION	< string UIWidget = "None"; >;
float4x4 mView                  : VIEW                  < string UIWidget = "None"; >;
float4x4 mViewInv               : VIEWINVERSE           < string UIWidget = "None"; >;

//
// Material parameters
//
texture  NormalMap              : NormalMap             < string UIName = "Normal Map"; string name = "_nomap_nrm.tga"; string TextureType = "2D"; >;
bool 	 FlipNormalMapY		: FlipNormalMapY	< string UIName = "Flip Normal Map Green Channel"; string gui = "slider"; > = false;

//
// Maps samplers
//
sampler2D NormalMapSampler = sampler_state
{
	Texture   = <NormalMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	MipLODBias=-1;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_INPUT
{
	float4 position		: POSITION;		// Vertex position
	float2 texcoord		: TEXCOORD0;	// Texture coordinates
	float3 tangent          : TANGENT;		// Tangent (in local space)
	float3 binormal		: BINORMAL;		// Binormal (in local space)
	float3 normal           : NORMAL;		// Normal (in local space)
	float3 color            : COLOR;		// Vertex color
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float2 texcoord		: TEXCOORD0;	// Texture coordinates
	float3 worldNormal	: TEXCOORD3;	// Normal (in world space)
	float3 worldTangent	: TEXCOORD4;	// Tangent (in world space)
	float3 worldBinormal	: TEXCOORD5;	// Binormal (in world space)
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(in VS_INPUT vIn, out float4 position : POSITION)
{
	//
	// Output structure declaration
	VS_OUTPUT Out;

	//
	// Compute normal in world space
	Out.worldNormal = normalize(mul(vIn.normal, (float3x3)mWorldIT).xyz);

	//
	// Compute tangent in world space
	Out.worldTangent = normalize(mul(vIn.tangent, (float3x3)mWorldIT).xyz);

	//
	// Compute binormal in world space
	Out.worldBinormal = normalize(mul(vIn.binormal, (float3x3)mWorldIT).xyz);

	//
	// Both positive and negative y format normal maps supported
	if (FlipNormalMapY == true)
	{
		Out.worldTangent = -Out.worldTangent;
	}

	//
	// Forward texture coordinates
	Out.texcoord.xy = vIn.texcoord;

	//
	// Compute projected position
	position = mul(float4(vIn.position.xyz,1.0f), mWorldViewProjection);

	return Out;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 normal_mapping(VS_OUTPUT vIn) : COLOR
{
	//
	// Get the normal from the normal map
	float3 normalMapTexel = normalize(tex2D(NormalMapSampler, vIn.texcoord.xy).xyz * 2.0 - 1.0);
	float3 N = ApplyNormalMapping(normalMapTexel, vIn.worldTangent, vIn.worldBinormal, vIn.worldNormal);
	return float4(N, 1.0f);
	
}
float4 normal(VS_OUTPUT vIn) : COLOR
{
	return float4(vIn.worldNormal, 1.0f);
}
float4 tangent(VS_OUTPUT vIn) : COLOR
{
	return float4(vIn.worldTangent, 1.0f);
}
float4 binormal(VS_OUTPUT vIn) : COLOR
{
	return float4(vIn.worldBinormal, 1.0f);
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique NormalMapping
{
	pass
	{
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 normal_mapping();
	}
}
technique Normals
{
	pass
	{
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 normal();
	}
}
technique Tangents
{
	pass
	{
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 tangent();
	}
}
technique Binormals
{
	pass
	{
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 binormal();
	}
}

#else // _3DSMAX_

technique
{
    pass
    {
        vertexShader = null;
        pixelShader  = null;
    }
}

#endif // _3DSMAX_