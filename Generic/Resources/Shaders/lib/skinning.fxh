//--------------------------------------------------------------------------------------------------
// Texture with bones matrix
//--------------------------------------------------------------------------------------------------
float4 vBoneMapSize : register(c127);

#if SH_X360
sampler1D BoneMapSampler : register(s0) = sampler_state
{
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
};
#elif SH_PS3
texture BoneMapTexture;
sampler2D BoneMapSampler : register(s0) = sampler_state
{
	Texture = <BoneMapTexture>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
};
#else

#if SH_DX11
Texture2D BoneMap;
SamplerState BoneMapSampler : register(s0)
{
	Filter = Min_Mag_Mip_Point;
	AddressU  = CLAMP;
};
#else
sampler2D BoneMapSampler : register(s0) = sampler_state
{
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
};
#endif
#endif

//
//
//
struct VS_SKIN_INPUT
{
	float4	position0			: POSITION0;
	float2	texcoord			: TEXCOORD0;
	float3	tangent0			: TANGENT0;	
	float3	binormal0			: BINORMAL0;
	float3	normal0				: NORMAL0;	
	
#if SH_PS3
	float3	position1			: TEXCOORD1;
	float3	tangent1			: TEXCOORD2;	
	float3	binormal1			: TEXCOORD3;
	float3	normal1				: TEXCOORD4;	
	
	float3	position2			: TEXCOORD5;
	float3	tangent2			: TEXCOORD6;	
	float3	binormal2			: COLOR0;
	float3	normal2				: COLOR1;	
#else
	float3	position1			: POSITION1;
	float3	tangent1			: TANGENT1;	
	float3	binormal1			: BINORMAL1;
	float3	normal1				: NORMAL1;	
	
	float3	position2			: POSITION2;
	float3	tangent2			: TANGENT2;	
	float3	binormal2			: BINORMAL2;
	float3	normal2				: NORMAL2;	
#endif
	
	float4	weights				: BLENDWEIGHT;
	float4	indices				: BLENDINDICES;
};

//
// Return the bone matrix at index u
//
#if SH_X360
float4x3 sample_bone_matrix(float u)
{
	float4 texcoord = float4(u, 0.5f, 0.0f, 0.0f);
	float4 v1,v2,v3;
	asm {
		tfetch1D v1, texcoord, BoneMapSampler, OffsetX = 0.0, UseComputedLOD = false
		tfetch1D v2, texcoord, BoneMapSampler, OffsetX = 1.0, UseComputedLOD = false
		tfetch1D v3, texcoord, BoneMapSampler, OffsetX = 2.0, UseComputedLOD = false
	};
	return transpose(float3x4(v1,v2,v3));
}
#else
float4x3 sample_bone_matrix(float u)
{
#if SH_DX11
	float3x4 m = float3x4( 
		BoneMap.SampleLevel(BoneMapSampler, float2(u + vBoneMapSize.x * 0.0f, 0.5f), 0.0f, 0.0f).rgba,
		BoneMap.SampleLevel(BoneMapSampler, float2(u + vBoneMapSize.x * 1.0f, 0.5f), 0.0f, 0.0f).rgba,
		BoneMap.SampleLevel(BoneMapSampler, float2(u + vBoneMapSize.x * 2.0f, 0.5f), 0.0f, 0.0f).rgba
	);
#else
	float3x4 m = float3x4( 
		tex2Dlod(BoneMapSampler, float4(u + vBoneMapSize.x * 0.0f, 0.5f, 0.0f, 0.0f)).rgba,
		tex2Dlod(BoneMapSampler, float4(u + vBoneMapSize.x * 1.0f, 0.5f, 0.0f, 0.0f)).rgba,
		tex2Dlod(BoneMapSampler, float4(u + vBoneMapSize.x * 2.0f, 0.5f, 0.0f, 0.0f)).rgba
	);
#endif
	return transpose(m);
}
#endif

//
//
//
void skin(inout VS_SKIN_INPUT v)
{
#if !SH_PS3
		v.indices = (v.indices * 3.0f + 0.5f) * vBoneMapSize.xxxx;
		
		float4x3 mat0 = sample_bone_matrix(v.indices.x);
		float4x3 mat1 = sample_bone_matrix(v.indices.y);
		float4x3 mat2 = sample_bone_matrix(v.indices.z);
	
		v.position0 = float4(mul(float4(v.position0.xyz,1.0f), mat0) * v.weights.x
					       + mul(float4(v.position1.xyz,1.0f), mat1) * v.weights.y
					       + mul(float4(v.position2.xyz,1.0f), mat2) * v.weights.z, 1.0f);

		v.tangent0 = mul(v.tangent0.xyz, (float3x3)mat0) * v.weights.x
				   + mul(v.tangent1.xyz, (float3x3)mat1) * v.weights.y
				   + mul(v.tangent2.xyz, (float3x3)mat2) * v.weights.z;

		v.binormal0 = mul(v.binormal0.xyz, (float3x3)mat0) * v.weights.x
					+ mul(v.binormal1.xyz, (float3x3)mat1) * v.weights.y
					+ mul(v.binormal2.xyz, (float3x3)mat2) * v.weights.z;

		v.normal0 = mul(v.normal0.xyz, (float3x3)mat0) * v.weights.x
				  + mul(v.normal1.xyz, (float3x3)mat1) * v.weights.y
				  + mul(v.normal2.xyz, (float3x3)mat2) * v.weights.z;
#endif
}

//
//
//
void wind(inout float3 v, float time, float2 speed, float freq, float scale)
{
	float time_freq = 6.283185f * time * freq;
	v.xy += float2(cos(time_freq),sin(time_freq)) * speed * v.z / scale;
}

//
//
//
void wind(inout float3 v, float2 offset, float scale)
{
	v.xy += offset * v.z * v.z / scale;
}