#include "lib/platform.fxh"
#include "lib/lighting.fxh"

//---------------------------------------------------------------------------------------------------------------------
// Screen space ambient occlusion shader (rev 3)
//---------------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------
// Uniform
//---------------------------------------------------------------------------------------------------------------------
uniform float4 vZNearFarAB;
uniform float4x4 viewMatrix;
uniform float4 quadCoeff;

//---------------------------------------------------------------------------------------------------------------------
// Texture Samplers
//---------------------------------------------------------------------------------------------------------------------
texture DepthMap;
sampler2D DepthMapSampler = sampler_state				// Depth buffer from scene
{
	Texture = <DepthMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

texture NormalMap;
sampler2D NormalMapSampler = sampler_state				// Normal map from scene (world-space normals)
{
	Texture = <NormalMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

texture DownscaledDepthMap;
sampler2D DownscaledDepthMapSampler = sampler_state		// Depth buffer from scene downscaled and linearized
{
	Texture = <DownscaledDepthMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

texture SSAOMap;
sampler2D SSAOMapSampler = sampler_state				// Raw SSAO buffer
{
	Texture = <SSAOMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};
texture BlurHMap;
sampler2D BlurHMapSampler = sampler_state				// Horizontal Blurred SSAO buffer
{
	Texture = <BlurHMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

//---------------------------------------------------------------------------------------------------------------------
// Constants : SSAO Kernel
// SAMPLE_COUNT *must* be multiple of 4
//---------------------------------------------------------------------------------------------------------------------
#define SAMPLE_COUNT	16

float4	KERNEL[SAMPLE_COUNT];

//---------------------------------------------------------------------------------------------------------------------
// Constants : Gaussian Blur Kernel
//---------------------------------------------------------------------------------------------------------------------
#define BLUR_COUNT 5
static const float aBlurKernel[BLUR_COUNT] = {
   -2.0,   		-1.0,    	0.0,   		+1.0,   	+2.0,
};
static const float aBlurWeight[BLUR_COUNT] = {
	0.08562916,	0.24266760,	0.34340648,	0.24266760,	0.08562916,
};

//---------------------------------------------------------------------------------------------------------------------
// Helper Function
//---------------------------------------------------------------------------------------------------------------------
float getDepth(in float2 uv)
{
	return tex2D(DownscaledDepthMapSampler, uv).r;
}
float3 getNormal(in float2 uv)
{
	float3	wsNormal = (tex2D(NormalMapSampler, uv).xyz - 0.5) * 2;
	float3	vsNormal = normalize(mul(wsNormal, (float3x3)viewMatrix)) * float3(1,-1,-1);	// make Y be down the screen; make Z be into the screen
	return vsNormal;
}

//---------------------------------------------------------------------------------------------------------------------
// Vertex Shader : outputs screen quad
//---------------------------------------------------------------------------------------------------------------------
void ScreenVS( in float4 iPos: POSITION, out float4 oPos : POSITION, in float2 iTex : TEXCOORD, out float2 oTex : TEXCOORD )
{
   oPos = iPos;
   oTex = iTex;
}

//---------------------------------------------------------------------------------------------------------------------
// Pixel Shader : Downscale Depth Buffer to 1/4 size
//---------------------------------------------------------------------------------------------------------------------
#define UVPIXEL(X,Y)	float2(1.0 / X, 1.0 / Y)

float4 DownscaleDepthPS( float2 texcoord : TEXCOORD ) : COLOR0
{
#if 1
    // offset by 0.25 screen pixel to match the upper left pixel of the depth buffer
    float2 uv = texcoord - 0.25f * UVPIXEL(640,360);
    float z = GetZ(DepthMapSampler, uv);
    float z2 = GetZ(DepthMapSampler, uv + float2(0.5,0) * UVPIXEL(640,360));
    float z3 = GetZ(DepthMapSampler, uv + float2(0,0.5) * UVPIXEL(640,360));
    float z4 = GetZ(DepthMapSampler, uv + float2(0.5,0.5) * UVPIXEL(640,360));
    z = (z + z2 + z3 + z4) * 0.25;
    // output linear Z between ZNear and ZFar
    float lin = vZNearFarAB.w / (z - vZNearFarAB.z);
    return lin;
#else
	// can't get this to work ...
	float2	uv = texcoord - 0.25f * UVPIXEL(640,360);
	float		Z = tex2D(DepthMapSampler, uv).arg;
			Z += tex2D(DepthMapSampler, uv + float2(0.5,0) * UVPIXEL(640,360)).arg;
			Z += tex2D(DepthMapSampler, uv + float2(0,0.5) * UVPIXEL(640,360)).arg;
			Z += tex2D(DepthMapSampler, uv + float2(0.5,0.5) * UVPIXEL(640,360)).arg;
	float		z = dot(Z, float3(255 * 65536, 255 * 256, 255 * 1)) / 4*8388608 - 1;
	float		lin = vZNearFarAB.w / (z - vZNearFarAB.z);

	return lin;
#endif
}

//---------------------------------------------------------------------------------------------------------------------
// Pixel Shader : Compute Screen Space Ambient Occlusion
//---------------------------------------------------------------------------------------------------------------------
float4 ScreenSpaceAmbientOcclusionPS( float2 texcoord : TEXCOORD ) : COLOR
{
	const float2 uv0 = texcoord;

	// sample normal from image
	float3		N = getNormal(uv0);
	// sample Z from image
	float			Z = getDepth(uv0);

	// construct the mirror plane to reflect normal -> (0,0,-1)
	float3		mirror;
	if (N.z < -0.999)
      {
		mirror = normalize(float3(N.z, 0, -N.y));
      }
	else
	{
		float3	H = (N + float3(0,0,-1)) / 2;
		float3	Perp = cross(N, H);
		mirror = normalize(cross(H,Perp));
	}

	float2	projScale = float2(1.4,2.4) * 2 / Z;

	float	ao = 0;
#if 0
	for (int sample = 0; sample < SAMPLE_COUNT; sample++)
	{
		float3	ray = reflect(KERNEL[sample], mirror);
		float2	uv1 = uv0 + ray.xy * projScale;
		float		occluder_z = Z + ray.z;
		float		scene_z = getDepth(uv1);

		float		depth_diff = occluder_z - scene_z;

		// calculate clamped quadratic
		float		local_ao = clamp(depth_diff*depth_diff*quadCoeff.x + depth_diff*quadCoeff.y + quadCoeff.z, 0, 1);

		ao += local_ao;
	}
#else
	for (int sample = 0; sample < SAMPLE_COUNT; sample += 4)
	{
		float3	ray0 = reflect(KERNEL[sample + 0], mirror);
		float3	ray1 = reflect(KERNEL[sample + 1], mirror);
		float3	ray2 = reflect(KERNEL[sample + 2], mirror);
		float3	ray3 = reflect(KERNEL[sample + 3], mirror);

		float4	uv01 = uv0.xyxy + float4(ray0.xy,ray1.xy) * projScale.xyxy;
		float4	uv23 = uv0.xyxy + float4(ray2.xy,ray3.xy) * projScale.xyxy;
		float4	occluder_z0123 = Z + float4(ray0.z,ray1.z,ray2.z,ray3.z);
		float4	scene_z0123 = float4(getDepth(uv01.xy), getDepth(uv01.zw), getDepth(uv23.xy), getDepth(uv23.zw));
		float4	depth_diff0123 = occluder_z0123 - scene_z0123;
		float4	local_ao = clamp(depth_diff0123*depth_diff0123*quadCoeff.xxxx + depth_diff0123*quadCoeff.yyyy + quadCoeff.zzzz, 0, 1);

		ao += dot(local_ao, float4(1,1,1,1));
	}
#endif

	return 1 - ao / SAMPLE_COUNT;
}

//---------------------------------------------------------------------------------------------------------------------
// Pixel Shader : Hortizontal Blur
//---------------------------------------------------------------------------------------------------------------------
float4 BlurHPS( float2 texcoord : TEXCOORD ) : COLOR0
{   
    float4 color = 0;
    for( int i = 0 ; i < BLUR_COUNT ; ++i )
    {
        float2 uv = texcoord + float2(aBlurKernel[i],0) * UVPIXEL(640,360);
        color += aBlurWeight[i] * tex2D(SSAOMapSampler, uv);
    }
    return color;
}

//---------------------------------------------------------------------------------------------------------------------
// Pixel Shader : Vertical Blur
//---------------------------------------------------------------------------------------------------------------------
float4 BlurVPS( float2 texcoord : TEXCOORD ) : COLOR0
{   
    float4 color = 0;
    for( int i = 0 ; i < BLUR_COUNT ; ++i )
    {
        float2 uv = texcoord + float2(0,aBlurKernel[i]) * UVPIXEL(640,360);
        color += aBlurWeight[i] * tex2D(BlurHMapSampler, uv);
    }
    return color;
}

//---------------------------------------------------------------------------------------------------------------------
// Technique Definition
//---------------------------------------------------------------------------------------------------------------------
technique DownscaleDepth
{
    pass
    {
		VertexShader = compile vs_3_0 ScreenVS();
        PixelShader  = compile ps_3_0 DownscaleDepthPS();
    }
}
technique ScreenSpaceAmbientOcclusion
{
    pass
    {
		VertexShader = compile vs_3_0 ScreenVS();
        PixelShader  = compile ps_3_0 ScreenSpaceAmbientOcclusionPS();
    }
}
technique BlurH
{
    pass
    {
		VertexShader = compile vs_3_0 ScreenVS();
        PixelShader  = compile ps_3_0 BlurHPS();
    }
}
technique BlurV
{
    pass
    {
		VertexShader = compile vs_3_0 ScreenVS();
        PixelShader  = compile ps_3_0 BlurVPS();
    }
}
