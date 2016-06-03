#include "lib/platform.fxh"
#include "lib/lighting.fxh"

//---------------------------------------------------------------------------------------------------------------------
// Screen space ambient occlusion shader (rev 2)
//---------------------------------------------------------------------------------------------------------------------
//#define ENABLE_VERY_HIGH_QUALITY_STEPS
#define ENABLE_VERY_HIGH_QUALITY_KERNEL
#define ENABLE_ROTATED_KERNEL

//---------------------------------------------------------------------------------------------------------------------
// Uniform
//---------------------------------------------------------------------------------------------------------------------
uniform float fRadius;
uniform float fFalloff;
uniform float4 vZNearFarAB;

//---------------------------------------------------------------------------------------------------------------------
// Constants : viewport
//---------------------------------------------------------------------------------------------------------------------
static const float4 vViewport = { HALFSCREENW, HALFSCREENH, 1.0 / HALFSCREENW, 1.0 / HALFSCREENH };
static const float 	fInverseRandomNormalMapSize = 1.0 / 4.0;

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
texture RandomNormalMap;
sampler2D RandomNormalMapSampler = sampler_state		// 4x4 random normal texture
{
	Texture = <RandomNormalMap>;
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
#ifdef ENABLE_VERY_HIGH_QUALITY_KERNEL
#define SAMPLE_COUNT 24
static const float3 KERNEL[SAMPLE_COUNT] = {
    normalize(float3(+1,+1,-1)),
    normalize(float3( 0,+1,-1)),
    normalize(float3(-1,+1,-1)),
    normalize(float3(+1, 0,-1)),
    //normalize(float3( 0, 0,-1)),
    normalize(float3(-1, 0,-1)),
    normalize(float3(+1,-1,-1)),
    normalize(float3( 0,-1,-1)),
    normalize(float3(-1,-1,-1)),
    normalize(float3(+1,+1, 0)),
    normalize(float3( 0,+1, 0)),
    normalize(float3(-1,+1, 0)),
    normalize(float3(+1, 0, 0)),
	//normalize(float3(0, 0, 0)),
    normalize(float3(-1, 0, 0)),
    normalize(float3(+1,-1, 0)),
    normalize(float3( 0,-1, 0)),
    normalize(float3(-1,-1, 0)),
    normalize(float3(+1,+1,+1)),
    normalize(float3( 0,+1,+1)),
    normalize(float3(-1,+1,+1)),
    normalize(float3(+1, 0,+1)),
    //normalize(float3( 0, 0,+1)),
    normalize(float3(-1, 0,+1)),
    normalize(float3(+1,-1,+1)),
    normalize(float3( 0,-1,+1)),
    normalize(float3(-1,-1,+1)),
   };
#else // ENABLE_VERY_HIGH_QUALITY_KERNEL
#define SAMPLE_COUNT 8
static const float3 KERNEL[SAMPLE_COUNT] = {
    normalize(float3(+1,+1,-1)),
    normalize(float3(-1,+1,-1)),
    normalize(float3(+1,-1,-1)),
    normalize(float3(-1,-1,-1)),
    normalize(float3(+1,+1,+1)),
    normalize(float3(-1,+1,+1)),
    normalize(float3(+1,-1,+1)),
    normalize(float3(-1,-1,+1)),
};
#endif // ENABLE_VERY_HIGH_QUALITY_KERNEL

//---------------------------------------------------------------------------------------------------------------------
// Constants : SSAO Steps
//---------------------------------------------------------------------------------------------------------------------
#ifdef ENABLE_VERY_HIGH_QUALITY_STEPS
#define STEP_COUNT 4
static const float2 STEP_SIZE[STEP_COUNT] = {
    float2(4.00f, 0.25f*fRadius), // weight, radius
    float2(2.00f, 0.50f*fRadius), // weight, radius
    float2(1.33f, 0.75f*fRadius), // weight, radius
    float2(1.00f, 1.00f*fRadius), // weight, radius
};
#else
#define STEP_COUNT 2
static const float2 STEP_SIZE[STEP_COUNT] = {
    float2(2.00f, 0.50f*fRadius), // weight, radius
    float2(1.00f, 1.00f*fRadius), // weight, radius
};
#endif

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
float2 getScreentoClipSpace(in float2 uv)
{
    float2 clip_space = uv - 0.5f * vViewport.zw;
    clip_space.x = clip_space.x * 2.0f - 1.0f;
    clip_space.y = (1.0f - clip_space.y) * 2.0f - 1.0f;
    return clip_space;
}
float3 getClipSpacePosition(in float2 uv)
{
    float3 clip_space;
    clip_space.xy = getScreentoClipSpace(uv);
    clip_space.z = getDepth(uv); 
    return clip_space;
}
float3 getRandomNormal(in float2 uv)
{
#ifdef ENABLE_ROTATED_KERNEL
    return normalize(tex2D(RandomNormalMapSampler, uv * vViewport.xy * fInverseRandomNormalMapSize).xyz * 2.0f - 1.0f);
#else
    return float3(1,0,0);
#endif
}

//---------------------------------------------------------------------------------------------------------------------
// Vertex Shader : outputs screen quad
//---------------------------------------------------------------------------------------------------------------------
void ScreenVS( in float4 iPos: POSITION, out float4 oPos : POSITION, out float2 oTex : TEXCOORD )
{
   oPos = iPos;
   oTex = (float2(iPos.x, -iPos.y) + 1.0 + vViewport.zw) * 0.5;
}

//---------------------------------------------------------------------------------------------------------------------
// Pixel Shader : Downscale Depth Buffer to 1/4 size
//---------------------------------------------------------------------------------------------------------------------
#if !SH_PS3
float4 DownscaleDepthPS( float4 oPos : POSITION, float2 texcoord : TEXCOORD0 ) : COLOR0
{
    // offset by 0.25 screen pixel to match the upper left pixel of the depth buffer
    float2 uv = texcoord - 0.25f * vViewport.zw;
    float z = tex2D(DepthMapSampler, uv).r;
    // output linear Z between ZNear and ZFar
    float lin = vZNearFarAB.w / (z - vZNearFarAB.z);
    return lin;
}
#else
float4 DownscaleDepthPS( float4 oPos : POSITION, float2 texcoord : TEXCOORD0 ) : COLOR0
{
    // offset by 0.25 screen pixel to match the upper left pixel of the depth buffer
    float2 uv = texcoord - 0.25f * vViewport.zw;
    float z = GetZ(DepthMapSampler, uv);
    float z2 = GetZ(DepthMapSampler, uv + float2(0.5,0) * vViewport.zw);
    float z3 = GetZ(DepthMapSampler, uv + float2(0,0.5) * vViewport.zw);
    float z4 = GetZ(DepthMapSampler, uv + float2(0.5,0.5) * vViewport.zw);
    z = (z + z2 + z3 + z4) * 0.25;
    // output linear Z between ZNear and ZFar
    float lin = vZNearFarAB.w / (z - vZNearFarAB.z);
    return lin;
}
#endif

//---------------------------------------------------------------------------------------------------------------------
// Pixel Shader : Compute Screen Space Ambient Occlusion
//---------------------------------------------------------------------------------------------------------------------
float4 ScreenSpaceAmbientOcclusionPS( float4 oPos : POSITION, float2 texcoord : TEXCOORD0 ) : COLOR
{
    const float2 uv0 = texcoord;
    const float3 scene0 = getClipSpacePosition(uv0);
    const float3 random_normal = getRandomNormal(uv0);
    const float  occlusion_radius = vZNearFarAB.x + fRadius * vZNearFarAB.y;
    float ao = 0.0f;
    float total_weight = 0.0f;
    LOOP for (int range = 0 ; range < STEP_COUNT ; ++range)
    {
        const float weight = STEP_SIZE[range].x;
        const float radius = STEP_SIZE[range].y;
        total_weight += weight * SAMPLE_COUNT;
#if 1
#ifdef SH_X360
       [unroll] for (int sample = 0 ; sample < SAMPLE_COUNT ; sample += 4)
#else
       LOOP for (int sample = 0 ; sample < SAMPLE_COUNT ; sample += 4)
#endif
        {
            const float3 ray0 = reflect(KERNEL[sample+0],random_normal) * radius;
            const float3 ray1 = reflect(KERNEL[sample+1],random_normal) * radius;
            const float3 ray2 = reflect(KERNEL[sample+2],random_normal) * radius;
            const float3 ray3 = reflect(KERNEL[sample+3],random_normal) * radius;
			
            const float4 uv01 = uv0.xyxy + float4(ray0.xy,ray1.xy);
            const float4 uv23 = uv0.xyxy + float4(ray2.xy,ray3.xy);
			
            const float4 occluder_z = scene0.zzzz + float4(ray0.z,ray1.z,ray2.z,ray3.z);
            const float4 scene_z = float4(getDepth(uv01.xy),getDepth(uv01.zw),getDepth(uv23.xy),getDepth(uv23.zw));
            
            const float4 depth_diff = occluder_z - scene_z;
            const float4 d = depth_diff / occlusion_radius;
			
			const float4 local_ao = (d > 0.0f ? min(d,fFalloff) : 1.0f) *  weight;
            ao += local_ao.x + local_ao.y + local_ao.z + local_ao.w;
        }
#else
        [unroll] for (int sample = 0 ; sample < SAMPLE_COUNT ; ++sample)
        {
            const float3 ray = reflect(KERNEL[sample],random_normal) * radius;
            const float2 uv = uv0 + ray.xy;
            const float occluder_z = scene0.z + ray.z;
            const float scene_z = getDepth(uv);
            const float depth_diff = occluder_z - scene_z;
            const float d = depth_diff / occlusion_radius;
			ao += (d >= 0.0f ? min(d,fFalloff) : 1.0f) * weight;
        }
#endif
    }
    
    ao /= total_weight;
    return(ao);
}

//---------------------------------------------------------------------------------------------------------------------
// Pixel Shader : Hortizontal Blur
//---------------------------------------------------------------------------------------------------------------------
float4 BlurHPS( float4 oPos : POSITION, float2 texcoord : TEXCOORD0 ) : COLOR0
{   
    float4 color = 0;
    for( int i = 0 ; i < BLUR_COUNT ; ++i )
    {
        float2 uv = texcoord + float2(aBlurKernel[i],0) * vViewport.zw;
        color += aBlurWeight[i] * tex2D(SSAOMapSampler, uv);
    }
    return color;
}

//---------------------------------------------------------------------------------------------------------------------
// Pixel Shader : Vertical Blur
//---------------------------------------------------------------------------------------------------------------------
float4 BlurVPS( float4 oPos : POSITION, float2 texcoord : TEXCOORD0 ) : COLOR0
{   
    float4 color = 0;
    for( int i = 0 ; i < BLUR_COUNT ; ++i )
    {
        float2 uv = texcoord + float2(0,aBlurKernel[i]) * vViewport.zw;
        color += aBlurWeight[i] * tex2D(BlurHMapSampler, uv);
    }
    return color;
}

//---------------------------------------------------------------------------------------------------------------------
// Technique Definition
//---------------------------------------------------------------------------------------------------------------------
#if SH_DX11
technique11 DownscaleDepth
{
    pass
    {
		SetVertexShader( CompileShader( vs_4_0, ScreenVS() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, DownscaleDepthPS() ) );
    }
}
technique11 ScreenSpaceAmbientOcclusion
{
    pass
    {
		SetVertexShader( CompileShader( vs_4_0, ScreenVS() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, ScreenSpaceAmbientOcclusionPS() ) );
    }
}
technique11 BlurH
{
    pass
    {
		SetVertexShader( CompileShader( vs_4_0, ScreenVS() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, BlurHPS() ) );
    }
}
technique11 BlurV
{
    pass
    {
		SetVertexShader( CompileShader( vs_4_0, ScreenVS() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, BlurVPS() ) );
    }
}
#else
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
#endif
