float4 PS_NAME(VS_OUTPUT vIn, in half2 ScreenPos : VPOS) : COLOR
{
	//
	// Get the opacity factor from the opacity map
	half opacityMapTexel = tex2D(OpacityMapSampler, vIn.texcoord.xy).r;
	clip(opacityMapTexel - FLOAT_ALPHA_REF);

	//
	// Get the diffuse color from the diffuse map
	half3 diffuseMapTexel = tex2D(DiffuseMapSampler, vIn.texcoord.xy).rgb * DiffuseMapModulator;

#if USE_SELF_ILLUM
	//
	// Get the self illumination color from the self illumination map
	half3 selfIllumMapTexel = tex2D(SelfIllumMapSampler, vIn.texcoord.xy).rgb * SelfIllumMapModulator;
#endif

#if USE_SPECULAR_MAP
	//
	// Get the specular color from the specular map
	half3 specularMapTexel = tex2D(SpecularMapSampler, vIn.texcoord.xy).rgb * SpecularMapModulator;
#endif

	//
	// Compute screen position
	ScreenPos = (ScreenPos + VPOS_offset) * SCREEN_SIZE.zw;

#if USE_ENVMAP
	//
	// Get the envmap texel from the environment map
	half3 viewNormal = 0.5f + normalize(vIn.viewNormal) * 0.5f;
	viewNormal.y = -viewNormal.y;
	half3 EnvMapTexel = tex2D(EnvMapSampler, viewNormal) * tex2D(EnvMapMaskSampler, vIn.texcoord.xy).r;
#endif

	//
	// LightBuffer values
	half4 lightsparams     = tex2D(LightBufferMapSampler, ScreenPos);
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
#if USE_SELF_ILLUM
	C += selfIllumMapTexel + SelfIllumColor + SelfIllumColor2;
#else
	C += SelfIllumColor + SelfIllumColor2;
#endif

#if USE_ENVMAP
	//
	// EnvMap
	C += EnvMapTexel * EnvMapFactor;
#endif
	
    //
    // Shadow
	C *= ComputeShadow(vIn.shadtexcoord, ShadowMapSampler);

#if USE_SILHOUETTE
	//
	// Silhouette Effect (Outline, Ghost, Invisibility)
	C = LightingComputeSilhouette(C, vIn.worldPos, vIn.viewNormal, mView);
#endif
	
#if USE_OCCLUDED
	//
	// Modulate + Saturate
	//C *= ModulateColor;	C += SaturateColor;
	C = (1.0f - RenderIfOccluded) * C + RenderIfOccluded * (C * ModulateColor + SaturateColor);
#endif
	
	//
	// Fog
	C = ApplyVFog(C, vIn.worldPos.z, verticalFogColor, verticalFogStartEnd);

	//
	// Alpha channel is used by FXAA
	return FXAALuminance(C);
}
