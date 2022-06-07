using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//https://www.vertexfragment.com/ramblings/unity-postprocessing-sobel-outline/#sobel-operator

[RequireComponent(typeof(Camera))]
public class FlagOutline : MonoBehaviour
{
    public Camera CameraMain;
    public string TagName = "OutlineSobel";
    public string ShaderName = "";
    public static RenderTexture OutlineFlagRenderTexture = null;

    private Camera cam;
    private Shader ReplacementShader = null;
    void Start()
    {
        cam = GetComponent<Camera>();
        if (string.IsNullOrEmpty(ShaderName) == false)
        {
            ReplacementShader = Shader.Find(ShaderName);
        }
    }

    // Update is called once per frame
    void Update()
    {
        if(string.IsNullOrEmpty(TagName)== false 
            && string.IsNullOrEmpty(ShaderName) == false
            && cam != null)
        {

            if(OutlineFlagRenderTexture == null 
                || (Screen.width != OutlineFlagRenderTexture.width)
                || (Screen.height != OutlineFlagRenderTexture.height))
            {
                OutlineFlagRenderTexture = new RenderTexture(Screen.width, Screen.height, 16, RenderTextureFormat.Depth);
            }
            UpdateCamera();


            // Render with the bare-bones replacement shader to generate our depth texture.
            // It will render for all objects whose shaders have a "RenderType" tag (most, if not all) which has a replacement pass in the pass through shader.
            // Any objects whose shader does not have this tag, or the tag does not have a replacement, will not be rendered.
            cam.RenderWithShader(ReplacementShader, TagName);

            // Set the occlusion texture globally so it can be used by any other shader.
            Shader.SetGlobalTexture("_OcclusionDepthMap", OutlineFlagRenderTexture);

            cam.enabled = false;
        }
    }

    private void UpdateCamera()
    {

        // Note that we do not use Camera.CopyFrom as, for currently unknown reasons, it does not produce the correct results.

        // Update it's transform to match the main camera
        transform.position = CameraMain.transform.position;
        transform.rotation = CameraMain.transform.rotation;
        cam.nearClipPlane = CameraMain.nearClipPlane;
        cam.farClipPlane = CameraMain.farClipPlane;
        cam.fieldOfView = CameraMain.fieldOfView;

        // Make sure all of the clear and target settings are correct
        cam.depthTextureMode = DepthTextureMode.Depth;
        cam.targetTexture = OutlineFlagRenderTexture;
        cam.clearFlags = CameraClearFlags.SolidColor;
        cam.backgroundColor = Color.black;
        cam.enabled = false;                                 // Disable so it does not perform normal rendering
    }
}
