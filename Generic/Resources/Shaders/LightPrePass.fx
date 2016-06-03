//--------------------------------------------------------------------------------------------------
// Light pass (rev 2)
//--------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------
// Includes
//--------------------------------------------------------------------------------------------------
#include "lib\platform.fxh"
#include "lib\lighting.fxh"


//--------------------------------------------------------------------------------------------------
// Defines
//--------------------------------------------------------------------------------------------------
// In order not to overflow the constant buffer on Xbox 360, we must have :
// MAX_DIRECTIONAL_LIGHT_PER_PASS + MAX_POINT_LIGHT_PER_PASS < ~100
// the value must match 'CShFullScreenEffectLightPass.h'
#define MAX_DIRECTIONAL_LIGHT_PER_PASS  1
#define MAX_POINT_LIGHT_PER_PASS        48
#define MAX_SPECIALIZED_LIGHT_PASS      8

//--------------------------------------------------------------------------------------------------
// Viewport and scene
//--------------------------------------------------------------------------------------------------
uniform float4x4        mInverseViewProj;
uniform float3          vCameraPosition;
uniform float			fSSAOFactor;


//--------------------------------------------------------------------------------------------------
// Directionnal Light
//--------------------------------------------------------------------------------------------------
uniform float3			DirectionalLightVector[MAX_DIRECTIONAL_LIGHT_PER_PASS];
uniform float4			DirectionalLightColor[MAX_DIRECTIONAL_LIGHT_PER_PASS];


//--------------------------------------------------------------------------------------------------
// Point Lights
//--------------------------------------------------------------------------------------------------
uniform float4          PointLight_Position_AttNear[MAX_POINT_LIGHT_PER_PASS];
uniform float4          PointLight_Color_AttFar[MAX_POINT_LIGHT_PER_PASS];


//--------------------------------------------------------------------------------------------------
// Loop counter
//--------------------------------------------------------------------------------------------------
#if SH_X360
static const int TEST_LIGHT_COUNT = 8;
uniform int LightCount : register(i0) = (TEST_LIGHT_COUNT-(TEST_LIGHT_COUNT/4)*4);
uniform int LightCount4 : register(i1) = (TEST_LIGHT_COUNT/4);
#else
uniform int LightCount;
#endif


//--------------------------------------------------------------------------------------------------
// Maps samplers
//--------------------------------------------------------------------------------------------------
texture         NormalShininessMap;
sampler2D       NormalShininessMapSampler = sampler_state
{
        Texture   = <NormalShininessMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

texture         DepthMap;
sampler2D       DepthMapSampler = sampler_state
{
	Texture   = <DepthMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

texture			SSAOMap;
sampler2D       SSAOMapSampler = sampler_state
{
	Texture   = <SSAOMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};


//--------------------------------------------------------------------------------------------------
// Vertex shader input structure
//--------------------------------------------------------------------------------------------------
struct VS_INPUT
{
	float2 position : POSITION;
	float2 texcoord : TEXCOORD0;
};


//--------------------------------------------------------------------------------------------------
// Pixel shader input structure
//--------------------------------------------------------------------------------------------------
struct PS_INPUT
{
	float4 texcoord_screen : TEXCOORD0;
};


//--------------------------------------------------------------------------------------------------
// Vertex shader code
//--------------------------------------------------------------------------------------------------
float4 vs(in VS_INPUT In, out PS_INPUT Out) : POSITION
{
    // XY: texture coordinates (top,left) = (0,0)
    Out.texcoord_screen.xy = In.texcoord;

    // ZW: clip space coordinates (top,left) = (-1,+1)
    Out.texcoord_screen.zw = In.position;
        
    // Output position
    return float4(In.position,1,1);
}


//--------------------------------------------------------------------------------------------------
// Compute Point Light
//--------------------------------------------------------------------------------------------------
half4 ComputeDirectionalLightParams(
        in  float3      world_position,
        in  half3      world_normal,
        in  half3      view_vector,
        in  half 		shininess,
		in  half		occlusion,

        in  half3      light_vector,
        in  half3      light_diffuse )
{
        half2 lighting         = BlinnFactor(world_normal, -light_vector, view_vector, shininess);
#if !SH_PS3
        return( half4(light_diffuse * (lighting.x + lighting.x * occlusion), ComputeLuminance(light_diffuse) * lighting.y) );
#else
        return( half4(light_diffuse * (lighting.x * occlusion), ComputeLuminance(light_diffuse) * lighting.y) );
#endif
}


//--------------------------------------------------------------------------------------------------
// Compute Point Light
//--------------------------------------------------------------------------------------------------
half4 ComputePointLightParams(
        in  float3      world_position,
        in  half3      world_normal,
        in  half3      view_vector,
        in  half 		shininess,
		in  half		occlusion,

        in  float3      light_position,
        in  half3      light_diffuse,
        in  half2      light_attenuation )
{
        half attenuation       = AttenutaionPointLight(world_position, light_position, light_attenuation);
        half3 light_vector     = normalize(light_position - world_position);
        half2 lighting         = BlinnFactor(world_normal, light_vector, view_vector, shininess) * attenuation;
#if !SH_PS3
        return( half4(light_diffuse * (lighting.x + lighting.x * occlusion), ComputeLuminance(light_diffuse) * lighting.y) );
#else
        return( half4(light_diffuse * (lighting.x * occlusion), ComputeLuminance(light_diffuse) * lighting.y) );
#endif
}

//--------------------------------------------------------------------------------------------------
// Pixel Shader Code
//--------------------------------------------------------------------------------------------------
#if SH_DX11
float4 ps(float4 position : POSITION, PS_INPUT Vin, uniform int directional_light_count, uniform int point_light_count) : COLOR0
#else
float4 ps(PS_INPUT Vin, uniform int directional_light_count, uniform int point_light_count) : COLOR0
#endif
{
	//
	// Scale and Bias Normal / Shininess
	float4 normal_shininess = tex2D(NormalShininessMapSampler, Vin.texcoord_screen.xy) * float4(2, 2, 2, 128) - float4(1, 1, 1, 0);
	half3 world_normal = normalize(normal_shininess.xyz);
	half1 shininess = normal_shininess.w;

	//
	// Reconstruct world position using inverse viewproj matrix
	float	Z = GetZ(DepthMapSampler, Vin.texcoord_screen.xy);
	float4 unproject_world_position = mul(float4(Vin.texcoord_screen.zw,Z,1),mInverseViewProj);
	float3 world_position = unproject_world_position.xyz / unproject_world_position.w;

	//
	// Camera/World Vector
	half3 view_vector = normalize(vCameraPosition - world_position);

    //
    // SSAO Factor
	float2 ssao_uv = Vin.texcoord_screen.xy - 0.5f * float2(1.0/SCREENW,1.0/SCREENH) + 0.5 * float2(1.0/HALFSCREENW, 1.0/HALFSCREENH);
#if !SH_PS3
	float ssao_factor = fSSAOFactor * (tex2D(SSAOMapSampler, ssao_uv).r * 2.0 - 1.0);
#else
	float ssao_factor = 1 - fSSAOFactor + fSSAOFactor * tex2D(SSAOMapSampler, ssao_uv).r;
#endif
    
	//
	// Accumulate lights
	float4 accum_light = float4(0,0,0,0);
	
	//
	// Directionnal Light
	//
    for( int i = 0 ; i < directional_light_count ; i++ )
    {
        accum_light += ComputeDirectionalLightParams(
            world_position, 
            world_normal, 
            view_vector, 
            shininess, 
			ssao_factor,
            DirectionalLightVector[i].xyz, 
            DirectionalLightColor[i].rgb);
    }
        
    //
    // Point Light
	//
#if SH_PC
    [unroll] for( int i = 0 ; i < point_light_count ; i += 1 )
    {
        accum_light += ComputePointLightParams(
            world_position, 
            world_normal, 
            view_vector, 
            shininess,
			ssao_factor,
            PointLight_Position_AttNear[i].xyz, 
            PointLight_Color_AttFar[i].rgb, 
            float2(PointLight_Position_AttNear[i].w, PointLight_Color_AttFar[i].w) );
    }
#endif

#if SH_PS3
	for( int i = 0 ; i < point_light_count ; i += 1 )
	{
        accum_light += ComputePointLightParams(
            world_position, 
            world_normal, 
            view_vector, 
            shininess,
			ssao_factor,
            PointLight_Position_AttNear[i].xyz, 
            PointLight_Color_AttFar[i].rgb, 
            float2(PointLight_Position_AttNear[i].w, PointLight_Color_AttFar[i].w) );
	}
#endif

#if SH_X360
	if( point_light_count < MAX_SPECIALIZED_LIGHT_PASS )
	{
	        // for small light count we use a special optimized pass
                [unroll] for( int i = 0 ; i < point_light_count ; i += 1 )
                {
                        accum_light += ComputePointLightParams(
                                world_position, 
                                world_normal, 
                                view_vector, 
                                shininess,
								ssao_factor,
                                PointLight_Position_AttNear[i].xyz, 
                                PointLight_Color_AttFar[i].rgb, 
                                float2(PointLight_Position_AttNear[i].w, PointLight_Color_AttFar[i].w) );
                }
	}
	else
        {
                // for big light count, we process lights 4 by 4
                [loop] for( int i = 0 ; i < LightCount4 ; i += 1 )
                {
                        accum_light += ComputePointLightParams(
                                world_position, 
                                world_normal, 
                                view_vector, 
                                shininess,
								ssao_factor,
                                PointLight_Position_AttNear[i+0].xyz, 
                                PointLight_Color_AttFar[i+0].rgb, 
                                float2(PointLight_Position_AttNear[i+0].w, PointLight_Color_AttFar[i+0].w) );
                        accum_light += ComputePointLightParams(
                                world_position, 
                                world_normal, 
                                view_vector, 
                                shininess,
								ssao_factor,
                                PointLight_Position_AttNear[i+1].xyz, 
                                PointLight_Color_AttFar[i+1].rgb, 
                                float2(PointLight_Position_AttNear[i+1].w, PointLight_Color_AttFar[i+1].w) );
                        accum_light += ComputePointLightParams(
                                world_position, 
                                world_normal, 
                                view_vector, 
                                shininess,
								ssao_factor,
                                PointLight_Position_AttNear[i+2].xyz, 
                                PointLight_Color_AttFar[i+2].rgb, 
                                float2(PointLight_Position_AttNear[i+2].w, PointLight_Color_AttFar[i+2].w) );
                        accum_light += ComputePointLightParams(
                                world_position, 
                                world_normal, 
                                view_vector, 
                                shininess,
								ssao_factor,
                                PointLight_Position_AttNear[i+3].xyz, 
                                PointLight_Color_AttFar[i+3].rgb, 
                                float2(PointLight_Position_AttNear[i+3].w, PointLight_Color_AttFar[i+3].w) );
                }
                // the remaining light will be set in LightCount also the starting value will be set by the CPU (it is *NOT* i = 0)
                [loop] for( int i = 0 ; i < LightCount ; i += 1 )
                {
                        accum_light += ComputePointLightParams(
                                world_position, 
                                world_normal, 
                                view_vector, 
                                shininess,
								ssao_factor,
                                PointLight_Position_AttNear[i].xyz, 
                                PointLight_Color_AttFar[i].rgb, 
                                float2(PointLight_Position_AttNear[i].w, PointLight_Color_AttFar[i].w) );
                }
        }
#endif

    return accum_light;
}

//--------------------------------------------------------------------------------------------------
// Techniques definition
//--------------------------------------------------------------------------------------------------
#if SH_DX11

#define DIR_1_PASS(x) \
pass\
{\
		SetVertexShader( CompileShader( vs_4_0, vs() ) );\
		SetGeometryShader( NULL );\
		SetPixelShader( CompileShader( ps_4_0, ps(1,x) ) );\
}

technique11 directional_1
{
        // On PC we have to make 1 pass for each possible light count...
        DIR_1_PASS( 0)
        DIR_1_PASS( 1)
        DIR_1_PASS( 2)
        DIR_1_PASS( 3)
        DIR_1_PASS( 4)
        DIR_1_PASS( 5)
        DIR_1_PASS( 6)
        DIR_1_PASS( 7)
        DIR_1_PASS( 8)
        DIR_1_PASS( 9)
        
        DIR_1_PASS(10)
        DIR_1_PASS(11)
        DIR_1_PASS(12)
        DIR_1_PASS(13)
        DIR_1_PASS(14)
        DIR_1_PASS(15)
        DIR_1_PASS(16)
        DIR_1_PASS(17)
        DIR_1_PASS(18)
        DIR_1_PASS(19)

        DIR_1_PASS(20)
        DIR_1_PASS(21)
        DIR_1_PASS(22)
        DIR_1_PASS(23)
        DIR_1_PASS(24)
        DIR_1_PASS(25)
        DIR_1_PASS(26)
        DIR_1_PASS(27)
        DIR_1_PASS(28)
        DIR_1_PASS(29)

        DIR_1_PASS(30)
        DIR_1_PASS(31)
        DIR_1_PASS(32)
        DIR_1_PASS(33)
        DIR_1_PASS(34)
        DIR_1_PASS(35)
        DIR_1_PASS(36)
        DIR_1_PASS(37)
        DIR_1_PASS(38)
        DIR_1_PASS(39)

        DIR_1_PASS(40)
        DIR_1_PASS(41)
        DIR_1_PASS(42)
        DIR_1_PASS(43)
        DIR_1_PASS(44)
        DIR_1_PASS(45)
        DIR_1_PASS(46)
        DIR_1_PASS(47)
}

#else

#define DIR_1_PASS(x) \
pass\
{\
        VertexShader = compile vs_3_0 vs();\
        PixelShader  = compile ps_3_0 ps(1,x);\
}

technique directional_1
{
#if SH_X360
        // On Xbox 360 we use specialized pass for slow light count else we use loop/endloop
        DIR_1_PASS( 0)
        DIR_1_PASS( 1)
        DIR_1_PASS( 2)
        DIR_1_PASS( 3)
        DIR_1_PASS( 4)
        DIR_1_PASS( 5)
        DIR_1_PASS( 6)
        DIR_1_PASS( 7)
        DIR_1_PASS(MAX_SPECIALIZED_LIGHT_PASS)
#endif

#if SH_PC || SH_PS3
        // On PC we have to make 1 pass for each possible light count...
        DIR_1_PASS( 0)
        DIR_1_PASS( 1)
        DIR_1_PASS( 2)
        DIR_1_PASS( 3)
        DIR_1_PASS( 4)
        DIR_1_PASS( 5)
        DIR_1_PASS( 6)
        DIR_1_PASS( 7)
        DIR_1_PASS( 8)
        DIR_1_PASS( 9)
        
        DIR_1_PASS(10)
        DIR_1_PASS(11)
        DIR_1_PASS(12)
        DIR_1_PASS(13)
        DIR_1_PASS(14)
        DIR_1_PASS(15)
        DIR_1_PASS(16)
        DIR_1_PASS(17)
        DIR_1_PASS(18)
        DIR_1_PASS(19)

        DIR_1_PASS(20)
        DIR_1_PASS(21)
        DIR_1_PASS(22)
        DIR_1_PASS(23)
        DIR_1_PASS(24)
        DIR_1_PASS(25)
        DIR_1_PASS(26)
        DIR_1_PASS(27)
        DIR_1_PASS(28)
        DIR_1_PASS(29)

        DIR_1_PASS(30)
        DIR_1_PASS(31)
        DIR_1_PASS(32)
        DIR_1_PASS(33)
        DIR_1_PASS(34)
        DIR_1_PASS(35)
        DIR_1_PASS(36)
        DIR_1_PASS(37)
        DIR_1_PASS(38)
        DIR_1_PASS(39)

        DIR_1_PASS(40)
        DIR_1_PASS(41)
        DIR_1_PASS(42)
        DIR_1_PASS(43)
        DIR_1_PASS(44)
        DIR_1_PASS(45)
        DIR_1_PASS(46)
        DIR_1_PASS(47)
#endif
}

#endif // SH_DX11
