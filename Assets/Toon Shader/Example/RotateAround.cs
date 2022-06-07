using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateAround : MonoBehaviour
{
    public float m_GradientTime = 4f;
    public bool m_DoChangeColor = true;
    public float m_RotationTime = 3f;

    private Color currentColor = Color.red;
    private float rotationSpeed = 0;
    Light light;

    private void Start()
    {
        light = GetComponentInChildren<Light>();
        rotationSpeed = 360f / m_RotationTime;
    }

    void Update()
    {
        if (m_DoChangeColor)
        {
            float currentGradientPercentage = (Time.time % m_GradientTime) / m_GradientTime;        
            light.color = Color.HSVToRGB(currentGradientPercentage, 0.75f, 0.80f);
        }
        //float currentRotationPercentage = (Time.time % m_RotationTime) / m_RotationTime;
        transform.Rotate(Vector3.up* rotationSpeed*Time.deltaTime, Space.Self);
    }
}
