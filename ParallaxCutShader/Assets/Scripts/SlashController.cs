using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DG.Tweening;
using Random = UnityEngine.Random;

public class SlashController : MonoBehaviour
{
    public Material slashMaterial;
    public float targetLength;
    public float targetAlpha;
    public float targetSlimness;
    public float startAnimDuration;

    private float currentLength, currentAlpha, currentSlimness, currentLightningStrength;
    
    private float lastLightningAngleUpdateTime;

    private void Update()
    {
        if(Input.GetKeyDown(KeyCode.Space))
           StartAnimation();
        
        
        if (lastLightningAngleUpdateTime + 0.35f < Time.time)
        {
            lastLightningAngleUpdateTime = Time.time;

            float angle = Random.Range(30, 85);
            slashMaterial.SetFloat("_AngleOffset", angle);
        }
    }
    

    private void StartAnimation()
    {
        currentLength = currentLightningStrength = 0;
        float initialSlimness = targetSlimness * 2;
        currentSlimness = initialSlimness;
        currentAlpha = 0.85f;
        lastLightningAngleUpdateTime = Time.time;
        UpdateMaterialValues();

        Sequence inSequence = DOTween.Sequence();
        inSequence.Append(DOVirtual.Float(0, targetLength, startAnimDuration / 2, (x) => currentLength = x).SetEase(Ease.OutSine));
        inSequence.AppendInterval(startAnimDuration / 4);
        inSequence.Append(DOVirtual.Float(0.5f, 1, startAnimDuration / 3, (x) => currentSlimness = x));
        inSequence.Append(DOVirtual.Float(initialSlimness, targetSlimness, startAnimDuration/4, (x) => currentSlimness = x).SetEase(Ease.OutBack));
        inSequence.Append(DOVirtual.Float(0.85f, targetAlpha, startAnimDuration/4, (x) => currentAlpha = x).SetEase(Ease.OutBack));
        inSequence.Insert(4, DOVirtual.Float(0, 1, startAnimDuration/4, (x) => currentLightningStrength = x));
        inSequence.OnUpdate(() => UpdateMaterialValues());
        inSequence.Play();
    }

    private void UpdateMaterialValues()
    {
        slashMaterial.SetFloat("_DiagonalLength", currentLength);
        slashMaterial.SetFloat("_Cutoff", currentAlpha);
        slashMaterial.SetFloat("_CutSlimness", currentSlimness);
        slashMaterial.SetFloat("_LightningStrength", currentLightningStrength);
    }
}
