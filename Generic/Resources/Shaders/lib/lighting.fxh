//--------------------------------------------------------------------------------------------------
// Compute color luminance
//--------------------------------------------------------------------------------------------------
half ComputeLuminance(half3 color)
{
        static const half3 RGB_TO_LUMA = { 0.2126, 0.7152, 0.0722 }; // or 0.299 + 0.587 + 0.114
        return(dot(RGB_TO_LUMA,color));        
}

//--------------------------------------------------------------------------------------------------
// Unpack normal from DXT5_X_Y normal map
//--------------------------------------------------------------------------------------------------
float3 UnpackNormalMap(sampler2D map, float2 uv)
{
	float3 normal;
#if SH_X360
	normal.xy = tex2D(map, uv).rg;
#else
	normal.xy = tex2D(map, uv).ag * 2.0f - 1.0f;
#endif
	normal.z = sqrt(1.0 - normal.x * normal.x - normal.y * normal.y);
	return normal;
}

//--------------------------------------------------------------------------------------------------
// Unpack normal from DXT5_X_Y normal map
//--------------------------------------------------------------------------------------------------
#if SH_DX11
float3 UnpackNormalMap(Texture2D t, SamplerState s, float2 uv)
{
	float3 normal;
	normal.xy = t.Sample(s, uv).ag * 2.0f - 1.0f;
	normal.z = sqrt(1.0 - normal.x * normal.x - normal.y * normal.y);
	return normal;
}
#endif

//--------------------------------------------------------------------------------------------------
// helper to read the Z buffer
//--------------------------------------------------------------------------------------------------
float GetZ(sampler2D tex, float2 position)
{
#if !SH_PS3
	float	Z = tex2D(tex, position).r;
#else
	// read three bytes from the texture (they get / by 255 to go into floats)
	float3	ZHiMidLow = tex2D(tex, position).arg;
  #if 1
	// * 255 to get back the integer byte values 0-255
	ZHiMidLow *= float3(255,255,255);
	ZHiMidLow = round(ZHiMidLow);
	// scale by digit value
	ZHiMidLow *= float3(65536,256,1);
	// sum and scale back down
	float Z = dot(ZHiMidLow, float3(1,1,1)) / 16777216;
	// undo the weird shit from the viewport
	Z = 2 * Z - 1;
  #else
	float Z = dot(ZHiMidLow, float3(255.0f * 65536 / 8388608, 255.0f * 256 / 8388608, 255.0f * 1 / 8388608)) - 1;
  #endif
#endif

	return Z;
}

#if SH_DX11
float GetZ(Texture2D t, SamplerState s, float2 position)
{
	float Z = t.SampleLevel(s, position, 0, 0).r;
	return Z;
}
#endif

//--------------------------------------------------------------------------------------------------
// Compute pixel normal value from tangent space and normal map texel value
//--------------------------------------------------------------------------------------------------
half3 ApplyNormalMapping(const half3 normalmap_value, const half3 world_tangent, const half3 world_binormal, const half3 world_normal)
{
	//
	// Construct tangent space
	half3x3 tangentSpace;
#ifdef _3DSMAX_
	tangentSpace[0] = world_binormal;
	tangentSpace[1] = -world_tangent;
	tangentSpace[2] = world_normal;
#else
	tangentSpace[0] =  world_tangent;
	tangentSpace[1] =  world_binormal;
	tangentSpace[2] =  world_normal;
#endif

	//
	// Normalize tangent space
	// (can be disabled to improve shader performance on lower end graphic cards but it will reduce image quality)
	//tangentSpace[0] = normalize(tangentSpace[0]);
	//tangentSpace[1] = normalize(tangentSpace[1]);
	//tangentSpace[2] = normalize(tangentSpace[2]);

	//
	// Offset world space normal with normal map values
	half3 N = mul(normalmap_value, tangentSpace);
	
	//
	// Normalize World space normal
	N = normalize(N);
	
	//
	// Return new normal value
	return N;
}
	
//--------------------------------------------------------------------------------------------------
// Compute blinn lighting diffuse and specular factor
//--------------------------------------------------------------------------------------------------
half2 BlinnFactor(const half3 normal_vector, const half3 light_vector, const half3 view_vector, const half1 shininess)
{
        half n_dot_l = dot(normal_vector, light_vector);
        half3 half_vector = normalize(view_vector + light_vector);
        half n_dot_h = dot(normal_vector, half_vector);
        half diffuse_factor = (n_dot_l < 0) ? 0 : n_dot_l;
        half specular_factor = (n_dot_l < 0) || (n_dot_h < 0) ? 0 : pow(n_dot_h, shininess);
        return half2( diffuse_factor, specular_factor );
}

//--------------------------------------------------------------------------------------------------
// Compute blinn lighting color
//--------------------------------------------------------------------------------------------------
half3 Blinn(const half3 diffuse_map_color, const half3 light_diffuse_color, const half3 specular_map_color, const half1 specular_level, const half2 blinn_factor)
{
        half3 diffuse = light_diffuse_color * diffuse_map_color * blinn_factor.x;
        half3 specular = ComputeLuminance(light_diffuse_color) * specular_map_color * specular_level.x * blinn_factor.y;
	return diffuse + specular;
}

//--------------------------------------------------------------------------------------------------
// Compute point light attenuation
//--------------------------------------------------------------------------------------------------
float1 AttenutaionPointLight(const float3 world_position, const float3 light_position, const float2 attenuation_factor)
{
        float distance = length(light_position - world_position);
        return 1.0f - smoothstep(attenuation_factor.x, attenuation_factor.y, distance);
}

//--------------------------------------------------------------------------------------------------
// Compute vertical fog color
//--------------------------------------------------------------------------------------------------
half3 ApplyVFog(const half3 color, const half z, const half3 fog_color, const half2 fog_start_end)
{
	half f = saturate((z - fog_start_end.x) / (fog_start_end.y - fog_start_end.x));
	return fog_color * (1.0f - f) + color * f;
}

#if SH_DX11
//--------------------------------------------------------------------------------------------------
// Compute shadow term
//--------------------------------------------------------------------------------------------------
float ComputeShadow(in float4 shadow_texcoord, in Texture2D t, in SamplerState ShadowMapSampler)
{
	float2 ShadowTexC = 0.5 * shadow_texcoord.xy / shadow_texcoord.w + float2( 0.5, 0.5 );
	ShadowTexC.y = 1.0f - ShadowTexC.y;

	//read in bilerp stamp, doing the shadow checks
	float LightAmount = 1.0f;
	if (shadow_texcoord.w > 0)
	{
		if (ShadowTexC.x < 0.0f || ShadowTexC.y < 0.0f || ShadowTexC.x > 1.0f || ShadowTexC.y > 1.0f)
		{
			LightAmount = 1.0f;
		}
		else
		{
			float z = GetZ(t, ShadowMapSampler, ShadowTexC);
			LightAmount = (z + 0.001f < (shadow_texcoord.z / shadow_texcoord.w ))? 0.6f: 1.0f;  
		}
	}
	return LightAmount;
}
#else
//--------------------------------------------------------------------------------------------------
// Compute shadow term
//--------------------------------------------------------------------------------------------------
float ComputeShadow(in float4 shadow_texcoord, in sampler2D ShadowMapSampler)
{
	float2 ShadowTexC = 0.5 * shadow_texcoord.xy / shadow_texcoord.w + float2( 0.5, 0.5 );
	ShadowTexC.y = 1.0f - ShadowTexC.y;
#if SH_X360
	float object_z = shadow_texcoord.z / shadow_texcoord.w;
	float4 Weights;
	float4 SampledDepth;
	asm {
			tfetch2D SampledDepth.x___, ShadowTexC, ShadowMapSampler, OffsetX = -0.5, OffsetY = -0.5
			tfetch2D SampledDepth._x__, ShadowTexC, ShadowMapSampler, OffsetX =  0.5, OffsetY = -0.5
			tfetch2D SampledDepth.__x_, ShadowTexC, ShadowMapSampler, OffsetX = -0.5, OffsetY =  0.5
			tfetch2D SampledDepth.___x, ShadowTexC, ShadowMapSampler, OffsetX =  0.5, OffsetY =  0.5
			getWeights2D Weights, ShadowTexC, ShadowMapSampler, MagFilter=linear, MinFilter=linear
	};
	float scene_z = SampledDepth.x;
	Weights = float4( (1-Weights.x)*(1-Weights.y), Weights.x*(1-Weights.y), (1-Weights.x)*Weights.y, Weights.x*Weights.y );
	float4 Attenuation = step( object_z, SampledDepth );
	float LightAmount = 0.6f + dot( Attenuation, Weights ) * 0.4;
	LightAmount = scene_z == 0.0f ? 1.0f : LightAmount;  
	return LightAmount;
#elif SH_PS3
	float LightAmount = 0.0f; // for objects behind the directional light, there is no light!
	if (shadow_texcoord.w > 0)
	{
		// for objects in front of the directional light, use hardware PCF
		// transform X,Y,Z into the [0,1] domain after divide by W
		float4 tc = shadow_texcoord * float4(0.5,-0.5,0.5,0.0) + float4(0.5,0.5,0.5,1.0) * shadow_texcoord.w;
		// use tex2Dproj, which does hardware PCF
		float sample = tex2Dproj(ShadowMapSampler, tc).x;
		// shadow is 0.4 of total light
		LightAmount = sample * 0.4 + 0.6;
	}
	return LightAmount;
#else
	//read in bilerp stamp, doing the shadow checks
	float LightAmount = 1.0f;
	if (shadow_texcoord.w > 0)
	{
		if (ShadowTexC.x < 0.0f || ShadowTexC.y < 0.0f || ShadowTexC.x > 1.0f || ShadowTexC.y > 1.0f)
		{
			LightAmount = 1.0f;
		}
		else
		{
			float z = GetZ(ShadowMapSampler, ShadowTexC);
			LightAmount = (z + 0.001f < (shadow_texcoord.z / shadow_texcoord.w ))? 0.6f: 1.0f;  
		}
	}
	return LightAmount;
#endif
}
#endif

//--------------------------------------------------------------------------------------------------
// Compute Silhouette (ghost/outline)
//--------------------------------------------------------------------------------------------------

float3 vWorldCameraPosition;
bool   bLightingSilhouette          = false;
float4 vLightingSilhouetteConstant  = { 1.0f, 0.0f, 0.0f, 0.0f };
float4 vLightingSilhouetteColor     = { 1.0f, 1.0f, 1.0f, 1.0f };
float2 vLightingSilhouetteThreshold = { 0.7f, 0.9f };

float3 LightingComputeSilhouette(in float3 vColor, in float3 vWorldPosition, in float3 vViewNormal, in float4x4 mView)
{
	float3 K;
	float3 VN;

	float3 VZ = -normalize(mul(vWorldPosition - vWorldCameraPosition, (float3x3)mView).xyz);

	//K = 1.0f - 2.0f * (dot(vViewNormal, vViewNormal).xxx - 0.5f);
	//VN = 0.5f + normalize(vViewNormal) * 0.5f;
	VN = normalize(vViewNormal);
	K = 0.5f + dot(VN, VZ) * 0.5f;
	//K = dot(VN, VZ);
	//K = smoothstep(0.7f, 0.9f, K); //smoothstep(min, max, x) 
	K = smoothstep(vLightingSilhouetteThreshold.x, vLightingSilhouetteThreshold.y, K); //smoothstep(min, max, x) 
	K = 1.0f - K;
	K = K * vLightingSilhouetteColor.rgb;

	//K.x = K.x * 2.8f; K.y = K.y * 2.9f; K.z = K.z * 0.5f;
	//K = K * 2.0f * 3.145f - 3.145f;K = 0.5f + sin(C) * 0.5f;
	
	float3 x = vLightingSilhouetteConstant.xxx;
	float3 y = vLightingSilhouetteConstant.yyy;
	float3 z = vLightingSilhouetteConstant.zzz;
	float3 w = vLightingSilhouetteConstant.www;
	
	return x * vColor + y * vColor * K + z * K + w;
}

float3 _ComputeSilhouette(in float3 vColor, in float2 vThreshold, in float3 vSilhouetteColor, in float3 vSilhouetteConstant, in float3 vVertexToEye, in float3 vViewNormal, in float4x4 mView)
{
	float3 VZ = normalize(mul(vVertexToEye, (float3x3)mView));
	float3 VN = normalize(vViewNormal);
	
	float3 K;
	K = 0.5f + dot(VN, VZ) * 0.5f;
	K = smoothstep(vThreshold.x, vThreshold.y, K);
	K = 1.0f - K;
	K = K * vSilhouetteColor;

	float3 x = vSilhouetteConstant.xxx;
	float3 y = vSilhouetteConstant.yyy;
	float3 z = vSilhouetteConstant.zzz;

	return x * vColor + y * vColor * K + z * K;
}

//--------------------------------------------------------------------------------------------------
// Stuff to support shader option builds
//--------------------------------------------------------------------------------------------------
// FEATURE SET:
// 00000 - 11111
// ABCD
//
// A = silhouette flag
// B = specular map flag
// C = env map flag
// D = self illumination flag
// E = render if occluded flag
//
// 11111 = original shader

#define FEATURE_FLAG_SILHOUETTE	16
#define FEATURE_FLAG_SPECULAR_MAP	8
#define FEATURE_FLAG_ENVMAP		4
#define FEATURE_FLAG_SELF_ILLUM	2
#define FEATURE_FLAG_OCCLUDED		1

#define USE_SILHOUETTE		(FEATURE_FLAGS & FEATURE_FLAG_SILHOUETTE)
#define USE_SPECULAR_MAP	(FEATURE_FLAGS & FEATURE_FLAG_SPECULAR_MAP)
#define USE_ENVMAP		(FEATURE_FLAGS & FEATURE_FLAG_ENVMAP)
#define USE_SELF_ILLUM		(FEATURE_FLAGS & FEATURE_FLAG_SELF_ILLUM)
#define USE_OCCLUDED		(FEATURE_FLAGS & FEATURE_FLAG_OCCLUDED)

