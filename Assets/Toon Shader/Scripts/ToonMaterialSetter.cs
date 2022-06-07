namespace Morkilian.Tools.ShaderToon
{
#if UNITY_EDITOR
    using System.Collections;
    using System.Collections.Generic;
    using UnityEngine;
    using NaughtyAttributes;
    using Toolbox.Editor.Drawers;

    [System.Serializable]
    public class ToonMaterialApply
    {
        public Material MaterialToApply;
        public bool Apply = true;
    }


    public class ToonMaterialSetter : MonoBehaviour
    {
        public ToonMaterialApply[] m_MaterialsToUpdate;
        [Range(0f, 1f)] public float m_ShadowAttenuationPosition = 0.5f;
        [Range(0f, .5f)] public float m_ShadowAttenuationWidth = 0.1f;
        public bool InvertYMain = false;
        public bool InvertYOthers = false;
        public Texture2D m_MainLightGradient;
        public Texture2D m_SecondaryLightGradient;



        [MyBox.ButtonMethod(MyBox.ButtonMethodDrawOrder.AfterInspector)]
        void UpdateMaterials()
        {
            for (int i = 0; i < m_MaterialsToUpdate.Length; i++)
            {
                ToonMaterialApply mat = m_MaterialsToUpdate[i];
                if (mat.Apply)
                {
                    mat.MaterialToApply.SetFloat("_LightAttenuationPosition", m_ShadowAttenuationPosition);
                    mat.MaterialToApply.SetFloat("_LightAttenuationWidth", m_ShadowAttenuationWidth);
                    if (m_MainLightGradient != null)
                        mat.MaterialToApply.SetTexture("_GradientMainLight", m_MainLightGradient);
                    if (m_SecondaryLightGradient != null)
                        mat.MaterialToApply.SetTexture("_GradientOtherLights", m_SecondaryLightGradient);

                    mat.MaterialToApply.SetFloat("_InvertYMain", InvertYMain?1:0);
                    mat.MaterialToApply.SetFloat("_InvertYOthers", InvertYOthers?1:0);
                }
            }
        }
    } 
#endif
}