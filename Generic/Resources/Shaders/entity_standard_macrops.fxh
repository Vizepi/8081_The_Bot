#if !SH_DX11
float4 PS_NAME(VS_OUTPUT vIn, in float2 ScreenPos : VPOS) : COLOR
{
#else
float4 PS_NAME(VS_OUTPUT vIn, in float4 position : SV_Position) : SV_TARGET
{
	float2 ScreenPos = position.xy;
#endif

	//
	// Get the diffuse color from the diffuse map
#if SH_DX11
	float3 diffuseMapTexel = DiffuseMap.Sample(DiffuseMapSampler, vIn.texcoord.xy).rgb * DiffuseMapModulator;

#if USE_SPECULAR_MAP
	//
	// Get the specular color from the specular map
	float3 specularMapTexel = SpecularMap.Sample(SpecularMapSampler, vIn.texcoord.xy).rgb * SpecularMapModulator;
#endif
#else
	float3 diffuseMapTexel = tex2D(DiffuseMapSampler, vIn.texcoord.xy).rgb * DiffuseMapModulator;

#if USE_SPECULAR_MAP
	//
	// Get the specular color from the specular map
	float3 specularMapTexel = tex2D(SpecularMapSampler, vIn.texcoord.xy).rgb * SpecularMapModulator;
#endif

#endif
	//
	// Compute screen position
	ScreenPos = (ScreenPos + VPOS_offset) * SCREEN_SIZE.zw;

	//
	// LightBuffer values
#if SH_DX11
	float4 lightsparams     = LightBufferMap.Sample(LightBufferMapSampler, ScreenPos);
#else
	float4 lightsparams     = tex2D(LightBufferMapSampler, ScreenPos);
#endif

	float3 diffuse_color    = lightsparams.xyz;
	float  specular_factor  = lightsparams.w;

	//
	// Final color
	float3 C = AmbientColor;

#if USE_SPECULAR_MAP
	//
	// Compute Blinn
	C += Blinn(diffuseMapTexel, diffuse_color, specularMapTexel, SpecularLevel, float2(1,specular_factor));
#else
	C += diffuseMapTexel * diffuse_color;
#endif

	//
	// Final color += self illumination term
	C += SelfIllumColor + SelfIllumColor2;

    //
    // Shadow
#if SH_DX11
	C *= ComputeShadow(vIn.shadtexcoord, ShadowMap, ShadowMapSampler);
#else
	C *= ComputeShadow(vIn.shadtexcoord, ShadowMapSampler);
#endif

#if USE_SILHOUETTE
	//
	// Silhouette Effect (Outline, Ghost, Invisibility)
	C = LightingComputeSilhouette(C, vIn.worldPos, vIn.viewNormal, mView);
#endif

#if USE_OCCLUDED
	//
	// Modulate + Saturate
	//C *= ModulateColor;	C += SaturateColor;
	C = (1.0f - RenderIfOccluded) * C + RenderIfOccluded * (C * ModulateColor.rgb + SaturateColor.rgb);
#endif

	//
	// Fog
	C = ApplyVFog(C, vIn.worldPos.z, verticalFogColor, verticalFogStartEnd);

    //
    // Alpha channel is used by FXAA
    return FXAALuminance(C);
}
