//--------------------------------------------------------------------------------------
// Shaders related to Xbox 360 specific techniques
//--------------------------------------------------------------------------------------
#if SH_X360

//--------------------------------------------------------------------------------------
static const float EDRAM_TILE_WIDTH = 80.0f;


//--------------------------------------------------------------------------------------
uniform texture DepthMap;
uniform sampler2D DepthMapSampler : register(s0) = sampler_state
{
	Texture   = <DepthMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
	AddressW  = CLAMP;
};



//--------------------------------------------------------------------------------------
float4 ScreenVS( const float2 ObjPos: POSITION ) : POSITION
{
    return float4( ObjPos, 0, 1 );
}

//--------------------------------------------------------------------------------------
void CopyDepthPS( float2 ScreenPos : VPOS, out float4 oColor : COLOR, out float oDepth : DEPTH )
{
    float4 DepthData;
    asm
    {
        tfetch2D DepthData,
                 ScreenPos,
                 DepthMapSampler,
                 UnnormalizedTextureCoords = true
    };
    oColor = DepthData;
    oDepth = DepthData;
}

//--------------------------------------------------------------------------------------
float4 FastDepthRestorePS( float2 ScreenPos : VPOS ) : COLOR
{
    float ColumnIndex = ScreenPos.x / EDRAM_TILE_WIDTH;
    float HalfColumn = frac( ColumnIndex );
    float2 TexCoord = ScreenPos;
    if( HalfColumn >= 0.5 )
        TexCoord.x -= ( EDRAM_TILE_WIDTH / 2 );
    else
        TexCoord.x += ( EDRAM_TILE_WIDTH / 2 );

    float4 DepthData;
    asm
    {
        tfetch2D DepthData,
                 TexCoord,
                 DepthMapSampler,
                 UnnormalizedTextureCoords = true
    };
    return DepthData.zyxw;
}

//--------------------------------------------------------------------------------------
technique CopyDepth
{ 
	pass 
	{		
		VertexShader = compile vs_3_0 ScreenVS();
		PixelShader  = compile ps_3_0 CopyDepthPS();
	}
}

technique FastDepthRestore
{ 
	pass 
	{		
		VertexShader = compile vs_3_0 ScreenVS();
		PixelShader  = compile ps_3_0 FastDepthRestorePS();
	}
}

technique UpdateHiZ
{ 
	pass 
	{		
		VertexShader = compile vs_3_0 ScreenVS();
		PixelShader  = null;
	}
}

#else // SH_X360
// Create a dummy technique so that PC shader compiler does not complain...
technique
{
        pass
        {
        
        }
}
#endif // SH_X360