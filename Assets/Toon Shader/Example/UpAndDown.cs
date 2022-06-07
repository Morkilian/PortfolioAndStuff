using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UpAndDown : MonoBehaviour
{
    public float m_Speed = 2f;
    public float m_MaxDistance = 1.5f;
    public float m_TransitionTime = 2;
    public float m_WaitingTime = 2f;
    
    private Vector3 startPos;
    private Material mat;
    void Start()
    {
        startPos = transform.position;
        MeshRenderer mr = GetComponent<MeshRenderer>();
        mat = new Material(mr.sharedMaterial);
        mr.material = mat;
    }

    // Update is called once per frame
    void Update()
    {
        transform.position = startPos + Mathf.Sin(Time.time * m_Speed) * Vector3.up * m_MaxDistance;
    }

    public void LaunchRoughness()
    {
        StartCoroutine(TransitionMaterial("_Smoothness"));
    }

    public void LaunchMetalness()
    {
        StartCoroutine(TransitionMaterial("_Metalness"));
    }

    private IEnumerator TransitionMaterial(string name)
    {
        float currentTransitionTime = 0;
        float progress = 0;
        bool isComingBack = false;
        while (currentTransitionTime < m_TransitionTime)
        {
            currentTransitionTime += Time.deltaTime;
            progress = Mathf.Clamp01(currentTransitionTime / m_TransitionTime);
            if (!isComingBack)
            {
                mat.SetFloat(name, progress);
                if (name == "_Smoothness")
                {
                    CanvasManager.SetSmoothness(progress);
                }
                else
                {
                    CanvasManager.SetMetalness(progress);
                }
                if (progress == 1)
                {
                    isComingBack = true;
                    currentTransitionTime = 0;
                    yield return new WaitForSeconds(m_WaitingTime);
                }
            }
            else
            {
                mat.SetFloat(name, 1 - progress);     
                if(name == "_Smoothness")
                {
                    CanvasManager.SetSmoothness(1 - progress);
                }
                else
                {
                    CanvasManager.SetMetalness(1 - progress);
                }
            }
            yield return null;            
        }
    }
}
