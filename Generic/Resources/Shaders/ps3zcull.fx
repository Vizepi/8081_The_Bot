

float4 vp_ZcullFarReload(float4 pos_in : POSITION) : POSITION
{
    return float4(pos_in.xy, 1, 1);
}

float4 fp_ZcullFarReload() : COLOR
{
    return float4(0,0,0,0);
}

technique ZcullFarReload
{
   pass p0
   {
       cullmode = none;
       ZEnable = true;
       ZWriteEnable = true;
       AlphaBlendEnable = false;
       AlphaTestEnable = false;
       ColorWriteEnable = 0x0;
       FillMode = Solid;

       VertexShader = compile vs_3_0 vp_ZcullFarReload();
       PixelShader  = compile ps_3_0 fp_ZcullFarReload();
   }
}
