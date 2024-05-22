#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Assets/Shaders/Utilities/NoiseFunctions.hlsl"

struct Attributes
{
    float4 positionOS   : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
};

struct Varyings
{
    float4 positionCS  : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 positionNDC : TEXCOORD1;
    float3 positionWS : TEXCOORD2;
    float3 normalWS : TEXCOORD3;
};

TEXTURE2D(_BaseTexture);
SAMPLER(sampler_BaseTexture);

CBUFFER_START(UnityPerMaterial)

float4 _BaseColor;
float4 _BaseTexture_ST;
float _Cutoff;

float _CutSlimness;
float _CutCenterWidth;
float _DiagonalFalloff;
float _DiagonalLength;
float _DiagonalAsymmetry;
float _WaveDistortion;
float _DistortionStrength;

float4 _EdgeColor;
float _EdgeStrength;

float _AngleOffset;
float _CellDensity;
float _LightningStrength;
float _LightningSpeed;
float _LightningWidth;

float _Smoothness;
float4 _EmissionColor;
float _EmissionStrength;
float _EmissionMulByBaseColor;

CBUFFER_END
            
Varyings vert(Attributes i)
{
    Varyings o;
                
    VertexPositionInputs vertexPositions = GetVertexPositionInputs(i.positionOS.xyz);
    o.positionCS = vertexPositions.positionCS;
    o.positionNDC = vertexPositions.positionNDC;
    o.positionWS = vertexPositions.positionWS;
    o.normalWS = GetVertexNormalInputs(i.normal).normalWS;
    o.uv = i.uv;

    return o;
}

InputData SetupLightingData(float3 positionWS, float3 normalWS)
{
    InputData lightingData = (InputData)0;
    lightingData.positionWS = positionWS;
    lightingData.normalWS = normalWS;
    lightingData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(positionWS);
    lightingData.shadowCoord = TransformWorldToShadowCoord(positionWS);

    return lightingData;
}

SurfaceData SetupSurfaceData(float3 albedo, float3 specular, float3 emission, half alpha)
{
    SurfaceData surfaceData = (SurfaceData)0;
    surfaceData.albedo = albedo * _BaseColor.rgb;
    surfaceData.alpha = alpha * _BaseColor.a;
    surfaceData.specular = specular;

    float3 emissionResult = lerp(emission * _EmissionColor.rgb, emission * _BaseColor.rgb, _EmissionMulByBaseColor);
    emissionResult *= _EmissionStrength;
    surfaceData.emission = emissionResult;
    surfaceData.smoothness = _Smoothness;

    return surfaceData;
}

float4 CalculateLighting(InputData lightingData, SurfaceData surfaceData)
{
    //Blinn Phong shading

    return UniversalFragmentBlinnPhong(lightingData, surfaceData);
}

float CalculateLightningEffectMask(Varyings i)
{
    i.uv.x += _SinTime * _LightningSpeed;
    i.uv.y += _CosTime * _LightningSpeed;
    float angle = _AngleOffset + 15 * (abs(_SinTime) * _LightningSpeed);
    float mainMask = Voronoi(i.uv, angle, _CellDensity);
    float minorMask = Voronoi(i.uv, angle, _CellDensity * 2);
    float blend = max(mainMask, minorMask * 0.5);
    return pow(blend, _LightningWidth) * _LightningStrength;;
}
            
float4 frag(Varyings i) : SV_Target
{
    float triWave = 2 * abs(((i.uv.x + (_SinTime.x * 0.075))/_WaveDistortion) - floor(((i.uv.x + (_SinTime.x * 0.075))/_WaveDistortion) + 0.5));
    float offsetTriWave = (2 * abs((((i.uv.x * 2)+ 0.5 +  (_SinTime.x * 0.075))/_WaveDistortion) - floor((((i.uv.x * 2) + 0.5 + + (_SinTime.x * 0.075))/_WaveDistortion) + 0.5)) * .75);
    float distortionWave = max(triWave, offsetTriWave);
    float d = pow(abs(0.5 - i.uv.x) + abs(0.5 - i.uv.y), _CutCenterWidth);
    float diagonalWeight = abs((i.uv.x) - i.uv.y)  * _DiagonalFalloff + (d * (10 * abs(1-_DiagonalLength)));
    float flippedWeight = (abs((abs((i.uv.x) - 1)) - (i.uv.y))  * _DiagonalFalloff) + (d * (10 * abs(1-_DiagonalLength * abs(1-_DiagonalAsymmetry))));
    diagonalWeight = min(flippedWeight, diagonalWeight) * _CutSlimness;
    

    float color = d * (diagonalWeight - (distortionWave * _DistortionStrength * abs(1-d)));
    float lightningMask = saturate(CalculateLightningEffectMask(i));
    
    color = abs(1-saturate(color));
    float clipColor =  max(color,lightningMask) - _Cutoff;;
    color = color - _Cutoff;
    //early exit
    clip(clipColor - 0.1);

    float edgeTransition = smoothstep(frac(pow(color.xxx, 0.25)), 1, _EdgeStrength);
    
    float4 textureColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.positionNDC.xy/i.positionNDC.w);
    float4 finalColor = lerp(_BaseColor * textureColor, _EdgeColor, edgeTransition);
    
    float4 lightningColor = lerp(_EdgeColor, _BaseColor, lightningMask);
    lightningColor = lightningColor / (2 - (1 * abs(_SinTime * _LightningSpeed)));
    finalColor = lerp(finalColor, lightningColor, step(color - lightningMask, lightningMask));

    InputData lightData = SetupLightingData(i.positionWS, i.normalWS);
    SurfaceData surfData = SetupSurfaceData(finalColor.xyz, 1, finalColor.xyz, 1);

    float4 shadedColor = CalculateLighting(lightData, surfData);

    return float4(shadedColor.xyz, 1);
}