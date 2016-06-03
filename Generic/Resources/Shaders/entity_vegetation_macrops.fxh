#if !SH_DX11
float4 PS_NAME(VS_OUTPUT vIn, in float2 ScreenPos : VPOS) : COLOR
{
#else
float4 PS_NAME(in float4 position : SV_Position, VS_OUTPUT vIn) : COLOR
{
	float2 ScreenPos = position.xy;
#endif
	//
	// Get the opacity factor from the opacity map
#if !SH_DX11
	float opacityMapTexel = tex2D(OpacityMapSampler, vIn.texcoord.xy).r;
#else
	float opacityMapTexel = OpacityMap.Sample(bilinear_wrap_sampler, vIn.texcoord.xy).r;
#endif
	clip(opacityMapTexel - FLOAT_ALPHA_REF);

	//
	// Get the diffuse color from the diffuse map
#if SH_DX11
	half3 diffuseMapTexel = DiffuseMap.Sample(bilinear_wrap_sampler, vIn.texcoord.xy).rgb * DiffuseMapModulator;
#else
	half3 diffuseMapTexel = tex2D(DiffuseMapSampler, vIn.texcoord.xy).rgb * DiffuseMapModulator;
#endif

#if USE_SPECULAR_MAP
	//
	// Get the specular color from the specular map
	#if SH_DX11
		half3 specularMapTexel = SpecularMap.Sample(bilinear_wrap_sampler, vIn.texcoord.xy).rgb * SpecularMapModulator;
	#else
		half3 specularMapTexel = tex2D(SpecularMapSampler, vIn.texcoord.xy).rgb * SpecularMapModulator;
	#endif
#endif

	//
	// Compute screen position
	ScreenPos = (ScreenPos + VPOS_offset) * SCREEN_SIZE.zw;

	//
	// LightBuffer values
#if SH_DX11
	half4 lightsparams     = LightBufferMap.Sample(point_clamp_sampler, ScreenPos);
#else
	half4 lightsparams     = tex2D(LightBufferMapSampler, ScreenPos);
#endif
	half3 diffuse_color    = lightsparams.xyz;
	half  specular_factor  = lightsparams.w;

	//
	// Final color
	half3 C = AmbientColor;

	//
	// Compute Blinn
#if USE_SPECULAR_MAP
	C += Blinn(diffuseMapTexel, diffuse_color, specularMapTexel, SpecularLevel, half2(1,specular_factor));
#else
	C += diffuseMapTexel * diffuse_color;
#endif

	//
	// Final color += self illumination term
	C += SelfIllumColor + SelfIllumColor2;

    //
    // Shadow
#if SH_DX11
	C *= ComputeShadow(vIn.shadtexcoord, ShadowMap, point_clamp_sampler);
#else
	C *= ComputeShadow(vIn.shadtexcoord, ShadowMapSampler);
#endif

	//
	// Fog
	C = ApplyVFog(C, vIn.worldPos.z, verticalFogColor, verticalFogStartEnd);

    //
    // Alpha channel is used by FXAA
    return FXAALuminance(C);
}
