Shader "Custom/SlashCutout"
{
    Properties
    { 
        [MainColor][HDR] _BaseColor ("Base Color", Color) = (1,1,1,1)
        [MainTexture] _BaseTexture("Base Texture", 2D) = "white" {}
        _Cutoff ("Alpha Cutoff", Range(0.001,1)) = 1
        
        [Header(Cut)]
        _DiagonalLength ("  Length", Range(0,1)) = 1
        _DiagonalFalloff ("  Falloff", Float) = 1
        _DiagonalAsymmetry("    Asymmetry Strength", Range(0,1)) = 0  
        _CutCenterWidth ("   Center Width", Float) = 1
        _CutSlimness ("    Slimness", Range(0.01,1)) = 1
        _WaveDistortion("   Horizontal Distortion Amount", Range(0,1)) = 1
        _DistortionStrength ("  Distortion Strength", Float) = 1
        
        [Header(Edge)]
        _EdgeColor ("   Color", Color) = (1,1,1,1)
        _EdgeStrength ("    Strength", Range(0.01,1)) = 1
        
        [Header(Lightning Effect)]
        _AngleOffset (" Voronoi Angle Offset", Float) = 1
        _CellDensity ("  Voronoi Cell Density", Float) = 1
        _LightningStrength ("    Strength", Range(0,1)) = 1
        _LightningWidth (" Width", Float) = 1
        _LightningSpeed (" Speed", Range(0.001, 1)) = 1
        
        [Header(Lighting)]
        _Smoothness ("  Smoothness", Range(0,1)) = 0.5
        [HDR]_EmissionColor ("   Color", Color) = (1,1,1,1)
        _EmissionStrength   ("  Strength", Float) = 1
        [Toggle]_EmissionMulByBaseColor (" Multiply by Base Color?", Range(0,1)) = 0
    }
    
    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // URP Keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #include "SlashCutout_Shared.hlsl"
            ENDHLSL
        }
    }
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
