//--------------------------------------------------------------------------------------------------
// Normals and depth rendering (rev 3)
//--------------------------------------------------------------------------------------------------
#if SH_X360 
#define ISOLATE [isolate]
#define TEXTURELODBIAS MipMapLodBias 
#else
#define ISOLATE
#define TEXTURELODBIAS MipLODBias
#endif

#define DEFAULT_TEXTURELODBIAS -0.5f

#include "lib\lighting.fxh"
#include "lib\skinning.fxh"

//--------------------------------------------------------------------------------------------------
// Constants
//--------------------------------------------------------------------------------------------------
static const float ALPHA_REF = 150.0f / 255.0f;


//--------------------------------------------------------------------------------------------------
// Transformations
//--------------------------------------------------------------------------------------------------
float4x4 mWorldIT	: WORLDINVERSETRANSPOSE < string UIWidget = "None"; >;
float4x4 mWorldViewProjection 	: WORLDVIEWPROJECTION   < string UIWidget = "None"; >;
float    Shininess 			  	: Shininess   	      	< string UIName = "Shininess"; string UIWidget = "slider"; float UIMin = 1; float UIMax = 128; > = 40;
float	 fElapsedTime		  	: TIME;


//--------------------------------------------------------------------------------------------------
// Parameters
//--------------------------------------------------------------------------------------------------
texture  OpacityMap 	      	: OpacityMap            < string UIName = "Opacity Map"; 	string name = "default.tga"; string TextureType = "2D"; >;
float    OpacityMapScrollU    	: OpacityMapScrollU     < string UIName = "Opacity Map Scroll U"; > = 0.0f;
float    OpacityMapScrollV    	: OpacityMapScrollV     < string UIName = "Opacity Map Scroll V"; > = 0.0f;

texture  NormalMap            	: NormalMap             < string UIName = "Normal Map";   string name = "default.tga"; string TextureType = "2D"; >;
float    NormalMapScrollU     	: NormalMapScrollU      < string UIName = "Normal Map Scroll U"; > = 0.0f;
float    NormalMapScrollV     	: NormalMapScrollV      < string UIName = "Normal Map Scroll V"; > = 0.0f;

float    WindSpeedX       	    : WindSpeedX			< string UIName = "Wind Speed X-axis"; float UIMin = -99999; float UIMax = +99999; > = 0.0f;
float    WindSpeedY       	    : WindSpeedY			< string UIName = "Wind Speed Y-axis"; float UIMin = -99999; float UIMax = +99999; > = 0.0f;
float    WindFrequency    	    : WindFrequency			< string UIName = "Wind Frequency"; > = 0.0f;
float 	 WindHeightScale	    : WindHeightScale		< string UIName = "Wind Height Scale"; float UIMin = -999999; float UIMax = +999999; > = 1.0f;


//--------------------------------------------------------------------------------------------------
// Maps samplers
//--------------------------------------------------------------------------------------------------
sampler2D OpacityMapSampler = sampler_state
{
	Texture   = <OpacityMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};

sampler2D NormalMapSampler = sampler_state
{
	Texture   = <NormalMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};


//--------------------------------------------------------------------------------------------------
// Pack depth  in a float2
//--------------------------------------------------------------------------------------------------
float2 PackDepth(float Z)
{
	float2 output;  

	// High depth (currently in the 0..127 range  
	Z = saturate(Z);  
	output.x = floor(Z*255);  

	// Low depth 0..1  
	output.y = frac(Z*255);  

	// Convert to 0..1  
	output.x /= 255;  

	return output;  
}

//--------------------------------------------------------------------------------------------------
// Vertex shader output structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4	texcoord_depth   : TEXCOORD0;	// Texture coordinates / Depth zw
	float3	worldNormal		 : TEXCOORD2;	// Normal (in world space)
	float3	worldTangent	 : TEXCOORD3;	// Tangent (in world space)
	float3	worldBinormal	 : TEXCOORD4;	// Binormal (in world space)
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_SKIN_INPUT vIn, ISOLATE out float4 position : POSITION)
{
	{
		//
		// Wind
		wind(vIn.position0.xyz,fElapsedTime,float2(WindSpeedX,WindSpeedY),WindFrequency,WindHeightScale);
		
		//
		// Compute projected position
		position = mul(vIn.position0, mWorldViewProjection);
	}

	//
	// Output structure declaration
	VS_OUTPUT Out;

	//
	// Compute normal in world space
	Out.worldNormal = normalize(mul(vIn.normal0, (float3x3)mWorldIT).xyz);

	//
	// Compute tangent in world space
	Out.worldTangent = normalize(mul(vIn.tangent0, (float3x3)mWorldIT).xyz);

	//
	// Compute binormal in world space
	Out.worldBinormal = normalize(mul(vIn.binormal0, (float3x3)mWorldIT).xyz);

	//
	// Forward texture coordinates
	Out.texcoord_depth.xy = vIn.texcoord;
	Out.texcoord_depth.zw = position.zw;

	return Out;
}
VS_OUTPUT vs_skin(VS_SKIN_INPUT vIn, ISOLATE out float4 position : POSITION)
{
	{
		//
		// Skinning
		skin(vIn);
		
		//
		// Wind
		wind(vIn.position0.xyz,fElapsedTime,float2(WindSpeedX,WindSpeedY),WindFrequency,WindHeightScale);
		
		//
		// Compute projected position
		position = mul(vIn.position0, mWorldViewProjection);
	}

	//
	// Output structure declaration
	VS_OUTPUT Out;

	//
	// Compute normal in world space
	Out.worldNormal = normalize(mul(vIn.normal0, (float3x3)mWorldIT).xyz);

	//
	// Compute tangent in world space
	Out.worldTangent = normalize(mul(vIn.tangent0, (float3x3)mWorldIT).xyz);

	//
	// Compute binormal in world space
	Out.worldBinormal = normalize(mul(vIn.binormal0, (float3x3)mWorldIT).xyz);

	//
	// Forward texture coordinates
	Out.texcoord_depth.xy = vIn.texcoord;
	Out.texcoord_depth.zw = position.zw;

	return Out;
}



//--------------------------------------------------------------------------------------------------
// Pixel shader output structure
//--------------------------------------------------------------------------------------------------
struct PS_OUTPUT
{
	float4 Normal_Shininess : COLOR0;
#ifndef SH_X360	
	float4 Depth  : COLOR1;
#endif	
};



//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
PS_OUTPUT ps(VS_OUTPUT vIn, uniform bool bIsAlphaTest)
{
	PS_OUTPUT Out;

	//
	// Check opacity map
	if(bIsAlphaTest)
	{
		float opacityMapTexel = tex2D(OpacityMapSampler, vIn.texcoord_depth.xy + float2(OpacityMapScrollU, OpacityMapScrollV)).r;
		clip(opacityMapTexel - ALPHA_REF);
	}
	
	//
	// Get the normal from the normal map
	float3 normalMapTexel = UnpackNormalMap(NormalMapSampler, vIn.texcoord_depth.xy + float2(NormalMapScrollU, NormalMapScrollV));

	//
	// Compute normal map
	float3 N = ApplyNormalMapping(normalMapTexel, vIn.worldTangent, vIn.worldBinormal, vIn.worldNormal);

	//
	// Pack the outputs into RGBA8
	Out.Normal_Shininess.xyz = N * 0.5f + 0.5f;
	Out.Normal_Shininess.w   = Shininess / 128.0f;
#ifndef SH_X360
	Out.Depth                = vIn.texcoord_depth.z / vIn.texcoord_depth.w;
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
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps(false);
	}
}

technique AlphaTest
{ 
	pass 
	{		
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps(true);
	}
}

technique SolidSkinning
{ 
	pass 
	{		
		VertexShader     = compile vs_3_0 vs_skin();
		PixelShader      = compile ps_3_0 ps(false);
	}
}

technique AlphaTestSkinning
{ 
	pass 
	{		
		VertexShader     = compile vs_3_0 vs_skin();
		PixelShader      = compile ps_3_0 ps(true);
	}
}