using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SimplePostprocess : MonoBehaviour
{
	public enum SobelType { Depth, Normal, Both}
	public Material PostProcessMat;
	[Header("Depth")]
	[Range(0f,10f)]public float m_OutlineDepthThickness = 0.1f;
	[Range(0f, 15f)] public float m_OutlineDepthMultiplier = 0f;
	[Range(0f, 15f)] public float m_OutlineDepthBias = 0f;
	[Header("Normal")]
	[Range(0f,10f)]public float m_OutlineNormalThickness = 0.1f;
	[Range(0f, 15f)] public float m_OutlineNormalMultiplier = 0f;
	[Range(0f, 15f)] public float m_OutlineNormalBias = 0f;
	public bool m_SobelOnly = false;
	public bool m_ShowBaseImage = false;
	public SobelType m_SobelType =SobelType.Depth;
	public Color m_ColorToApply = Color.black;
	private bool m_DoTheThing = true;

	private Camera m_cam;
	private void OnEnable()
	{
		m_cam = GetComponent<Camera>();
		if (PostProcessMat == null)
		{
			enabled = false;
		}
		else
		{
			// This is on purpose ... it prevents the know bug
			// https://issuetracker.unity3d.com/issues/calling-graphics-dot-blit-destination-null-crashes-the-editor
			// from happening
			PostProcessMat.mainTexture = PostProcessMat.mainTexture;
		}

	}

    private void Update()
    {
		m_cam.depthTextureMode = m_SobelType == SobelType.Depth ? DepthTextureMode.Depth: DepthTextureMode.DepthNormals;
		if (Input.GetKeyDown(KeyCode.Space)) m_DoTheThing = !m_DoTheThing;

    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
        if (m_DoTheThing)
        {

            PostProcessMat.SetFloat("_OutlineDepthThickness", m_OutlineDepthThickness);
            PostProcessMat.SetFloat("_OutlineDepthMultiplier", m_OutlineDepthMultiplier);
            PostProcessMat.SetFloat("_OutlineDepthBias", m_OutlineDepthBias);

            PostProcessMat.SetFloat("_OutlineNormalThickness", m_OutlineNormalThickness);
            PostProcessMat.SetFloat("_OutlineNormalMultiplier", m_OutlineNormalMultiplier);
            PostProcessMat.SetFloat("_OutlineNormalBias", m_OutlineNormalBias);

            PostProcessMat.SetFloat("_SobelOnly", m_SobelOnly ? 1 : 0);
            PostProcessMat.SetFloat("_ShowBaseImage", m_ShowBaseImage ? 1 : 0);
            PostProcessMat.SetInt("_SobelType", (int)m_SobelType);
            PostProcessMat.SetColor("_ColorToApply", m_ColorToApply);
            Graphics.Blit(src, dest, PostProcessMat); 
        }
        else
        {
			Graphics.Blit(src, dest);
        }
	}
}
