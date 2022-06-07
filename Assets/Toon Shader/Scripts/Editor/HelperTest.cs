namespace Morkilian.Tools.ShaderToon
{
    using System.Collections;
    using System.Collections.Generic;
    using UnityEngine;
    using UnityEditor;
    [ExecuteInEditMode]
    [CustomEditor(typeof(MonochromeLookupTableMaker))]
    public class HelperTest : Editor
    {
        public override void OnInspectorGUI()
        {
            Debug.Log("test");
            base.OnInspectorGUI();
        }

        public override void DrawPreview(Rect previewArea)
        {
            Debug.Log("test draw preview");
            base.DrawPreview(previewArea);
        }

        public override GUIContent GetPreviewTitle()
        {
            Debug.Log("preview title");
            return base.GetPreviewTitle();
        }

        public override bool HasPreviewGUI()
        {
            Debug.Log("test has preview gui");
            return base.HasPreviewGUI();
        }

        public override void OnInteractivePreviewGUI(Rect r, GUIStyle background)
        {
            Debug.Log("test interactive preview");
            base.OnInteractivePreviewGUI(r, background);
        }

        public override void OnPreviewGUI(Rect r, GUIStyle background)
        {
            base.OnPreviewGUI(r, background);
            Debug.Log("test on preview gui");
        }

        void Update()
        {
            Debug.Log("test!!!");

        }
        
    }

}