using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
#if UNITY_EDITOR

using UnityEditor; 
#endif
namespace Portfolio
{
    [CreateAssetMenu(fileName = "PortfolioPreset", menuName = "Plugin / Portfolio / Preset")]
    public class PortfolioSplineSO : ScriptableObject
    {



        #region Camera Position
        private int cameraSplineInstanceID;
        private Spline camSpline;
        public Spline CameraSpline
        {
            get
            {
                
#if UNITY_EDITOR
        if(camSpline == null)
                {
                    bool needsNewSpline = false;
                    if (cameraSplineInstanceID != 0)
                    {
                        Spline go = EditorUtility.InstanceIDToObject(cameraSplineInstanceID) as Spline;
                        if (go != null)
                        {
                            camSpline = go;
                        }
                        else
                        {
                            Debug.LogError("[Portfolio, PortfolioPreset] Had a spline ID but couldn't find it!");
                            needsNewSpline = true;
                        }
                    }
                    else needsNewSpline = true;
                    if (needsNewSpline)
                    {
                        camSpline = new GameObject().AddComponent<Spline>();
                        camSpline.name = "CameraSpline";
                        camSpline.Initialize(this);
                        cameraSplineInstanceID = camSpline.GetInstanceID();
                    }
                    //camSpline.gameObject.hideFlags = HideFlags.HideInHierarchy | HideFlags.HideInInspector | HideFlags.DontSaveInBuild;

                } 
#endif
                return camSpline;
            }
        }
        public Color CameraSplineColor = Color.yellow;
        public AnimationCurve CameraSplineCurve = new AnimationCurve(new Keyframe(0f, 0f), new Keyframe(1f, 1f));


        public Vector3 GetCameraPosition(float ratio)
        {
            float remappedRatio = CameraSplineCurve.Evaluate(Mathf.Clamp01(ratio));
            return CameraSpline.GetPosition(remappedRatio);
        }

        private void Awake()
        {
            Debug.Log("haha");
        }
        #endregion




        #region Overrides
        public override int GetHashCode()
        {
            return base.GetHashCode();
        }

        public override bool Equals(object other)
        {
            return base.Equals(other);
        }
        public static bool operator ==(PortfolioSplineSO lhs, PortfolioSplineSO rhs)
        {
            //If the first object is null, returns wether the second object is also null or not
            if (object.ReferenceEquals(lhs, null))
            {
                return (object.ReferenceEquals(rhs, null));
            }

            //Else compare them (without fear of infinite recursion)
            return lhs.Equals(rhs);
        }

        public static bool operator !=(PortfolioSplineSO lhs, PortfolioSplineSO rhs)
        {

            if (object.ReferenceEquals(lhs, null))
            {
                return !object.ReferenceEquals(rhs, null);
            }

            return !lhs.Equals(rhs);
        } 
        #endregion

    } 
}
