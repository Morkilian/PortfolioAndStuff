using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class CanvasManager : MonoBehaviour
{
    public Slider m_RoughSlider;
    public Slider m_MetalSlider;

    private static CanvasManager sInstance;
    private void Awake()
    {
        sInstance = this;
    }

    public static void SetSmoothness(float value) { sInstance.m_RoughSlider.value = value; }
    public static void SetMetalness(float value) { sInstance.m_MetalSlider.value = value; }
}
