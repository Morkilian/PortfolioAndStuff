using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;




[PostProcess(typeof(SobelEdgeRenderer), PostProcessEvent.BeforeStack, "SobelOutline")]
public class SobelEdge : PostProcessEffectSettings
{
    [Range(0f,1f)]public FloatParameter thickness = new FloatParameter { value = 1.0f };
    public FloatParameter depthMultiplier = new FloatParameter { value = 1.0f };
    public FloatParameter depthBias = new FloatParameter { value = 1.0f };
    public FloatParameter normalMultiplier = new FloatParameter { value = 1.0f };
    public FloatParameter normalBias = new FloatParameter { value = 10.0f };
    public ColorParameter color = new ColorParameter { value = Color.black };
}

public sealed class SobelEdgeRenderer : PostProcessEffectRenderer<SobelEdge>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("ASESampleShaders/Post Process/Sobel"));

        sheet.properties.SetFloat("_OutlineThickness", settings.thickness);
        sheet.properties.SetFloat("_OutlineDepthMultiplier", settings.depthMultiplier);
        sheet.properties.SetFloat("_OutlineDepthBias", settings.depthBias);
        sheet.properties.SetFloat("_OutlineNormalMultiplier", settings.normalMultiplier);
        sheet.properties.SetFloat("_OutlineNormalBias", settings.normalBias);
        sheet.properties.SetColor("_OutlineColor", settings.color);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
