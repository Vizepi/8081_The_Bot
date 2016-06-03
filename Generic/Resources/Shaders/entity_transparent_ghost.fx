//--------------------------------------------------------------------------------------------------
// Transparent material (rev 4)
//--------------------------------------------------------------------------------------------------
#include "lib\platform.fxh"
#include "lib\lighting.fxh"
#include "lib\skinning.fxh"

//--------------------------------------------------------------------------------------------------
// Automatic Parameters
//--------------------------------------------------------------------------------------------------
float4x4 	mWorld;
float4x4	mWorldIT;
float4x4	mView;
float4x4 	mWorldViewProjection;
float4		vCameraPosition;

//--------------------------------------------------------------------------------------------------
// Automatic Shadow Parameters
//--------------------------------------------------------------------------------------------------
float4x4 	mShadowTexture;

//--------------------------------------------------------------------------------------------------
// Automatic Fog Parameters
//--------------------------------------------------------------------------------------------------
float3  	verticalFogColor;
float2   	verticalFogStartEnd;

//--------------------------------------------------------------------------------------------------
// Automatic Colors Parameters
//--------------------------------------------------------------------------------------------------
float3   	AmbientColor;
float3		SelfIllumColor2;

//--------------------------------------------------------------------------------------------------
// Material parameters
//--------------------------------------------------------------------------------------------------
texture  	DiffuseMap;
texture  	OpacityMap;
texture  	SelfIllumMap;
float3   	DiffuseMapModulator;
float3   	SelfIllumMapModulator;
float3   	SelfIllumColor;
float 	 	SilhouetteMin;
float 	 	SilhouetteMax;
float3	 	SilhouetteColor;
float 	 	SilhouetteDiffuseIntensity;
float 	 	SilhouetteModulateIntensity;
float 	 	SilhouetteColorIntensity;
float    	TexCoordOffsetU;
float    	TexCoordOffsetV;

//--------------------------------------------------------------------------------------------------
// Maps Samplers
//--------------------------------------------------------------------------------------------------
sampler2D DiffuseMapSampler = sampler_state
{
	Texture   = <DiffuseMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};
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
sampler2D SelfIllumMapSampler = sampler_state
{
	Texture   = <SelfIllumMap>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = POINT;
	AddressU  = WRAP;
	AddressV  = WRAP;
	TEXTURELODBIAS = DEFAULT_TEXTURELODBIAS;
};

//--------------------------------------------------------------------------------------------------
// LightBuffer map sampler
//--------------------------------------------------------------------------------------------------
texture LightBufferMap;
sampler2D LightBufferMapSampler = sampler_state
{
	Texture   = <LightBufferMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

//--------------------------------------------------------------------------------------------------
// Shadow map sampler
//--------------------------------------------------------------------------------------------------
texture ShadowMap;
sampler2D ShadowMapSampler = sampler_state
{
	Texture   = <ShadowMap>;
#if !SH_PS3
    MinFilter = POINT;
    MagFilter = POINT;
#else
    MinFilter = LINEAR;
    MagFilter = LINEAR;
#endif
    MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float2 texcoord		 : TEXCOORD0;		// Texture coordinates
	float3 worldPos 	 : TEXCOORD1;		// Vertex position (in world space)
	float4 shadtexcoord	 : TEXCOORD2;		// Shadow mapping texcoords
	float3 vertexToEye   : TEXCOORD3;		// Vertex to eye vector (in world space)
	float3 viewNormal	 : TEXCOORD4;		// Vertex normal (in view space)
};

//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
VS_OUTPUT vs(VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
	ISOLATE position = mul(vIn.position0, mWorldViewProjection);

	VS_OUTPUT Out;
	Out.texcoord.xy = vIn.texcoord.xy + float2(TexCoordOffsetU, TexCoordOffsetV);
	Out.worldPos = mul(vIn.position0, mWorld).xyz;
	Out.shadtexcoord = mul(vIn.position0, mShadowTexture);
	Out.vertexToEye = vCameraPosition - Out.worldPos;
	Out.viewNormal = mul(normalize(mul(vIn.normal0, (float3x3)mWorldIT).xyz), (float3x3)mView).xyz;

	return Out;
}
VS_OUTPUT vs_skin(VS_SKIN_INPUT vIn, out float4 position : POSITION)
{
	skin(vIn);
	ISOLATE position = mul(vIn.position0, mWorldViewProjection);

	VS_OUTPUT Out;
	Out.texcoord.xy = vIn.texcoord.xy + float2(TexCoordOffsetU, TexCoordOffsetV);
	Out.worldPos = mul(vIn.position0,mWorld).xyz;
	Out.shadtexcoord = mul(vIn.position0, mShadowTexture);
	Out.vertexToEye = vCameraPosition - Out.worldPos;
	Out.viewNormal = mul(normalize(mul(vIn.normal0, (float3x3)mWorldIT).xyz), (float3x3)mView).xyz;

	return Out;
}

//--------------------------------------------------------------------------------------------------
// Pixel shader code
//--------------------------------------------------------------------------------------------------
float4 ps(VS_OUTPUT vIn, in float2 ScreenPos : VPOS) : COLOR
{
	//
	// Compute screen position
	ScreenPos = (ScreenPos + VPOS_offset) * SCREEN_SIZE.zw;

	//
	// Get the diffuse color from the diffuse map
	float3 diffuseMapTexel = tex2D(DiffuseMapSampler, vIn.texcoord.xy).rgb * DiffuseMapModulator;

	//
	// Get the opacity factor from the opacity map
	float opacityMapTexel = tex2D(OpacityMapSampler, vIn.texcoord.xy).r;

	//
	// Get the self illumination color from the self illumination map
	float3 selfIllumMapTexel = tex2D(SelfIllumMapSampler, vIn.texcoord.xy).rgb * SelfIllumMapModulator;

	//
	// LightBuffer values
	float4 lightsparams = tex2D(LightBufferMapSampler, ScreenPos);

	//
	// Final color = Ambient + Diffuse + Specular
	float3 C = AmbientColor;

	//
	// Fake color
	const float diffuseFactor = 0.4f;
	const float lightingFactor = 0.8f;
	C += opacityMapTexel.r * diffuseMapTexel * (lightsparams * lightingFactor + diffuseFactor);

	//
	// Add outline
	float2 vSilhouetteThreshold = { SilhouetteMin, SilhouetteMax };
	float3 vSilhouetteConstant = { SilhouetteDiffuseIntensity, SilhouetteModulateIntensity, SilhouetteColorIntensity };
	C = _ComputeSilhouette(C, vSilhouetteThreshold, SilhouetteColor, vSilhouetteConstant, vIn.vertexToEye, vIn.viewNormal, mView);
	
	//
	// Final color += self illumination term
	C += selfIllumMapTexel + SelfIllumColor + SelfIllumColor2;

	//
    // Shadow
	C *= ComputeShadow(vIn.shadtexcoord, ShadowMapSampler);

	//
	// Fog
	C = ApplyVFog(C, vIn.worldPos.z, verticalFogColor, verticalFogStartEnd);
	
	//
	// Final color opacity
	return float4(C, opacityMapTexel);

}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
technique Solid
{
	pass
	{
		VertexShader     = compile vs_3_0 vs();
		PixelShader      = compile ps_3_0 ps();
	}
}

technique SolidSkinning
{
	pass
	{
		VertexShader     = compile vs_3_0 vs_skin();
		PixelShader      = compile ps_3_0 ps();
	}
}
