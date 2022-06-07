using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Portfolio
{
    [System.Serializable]
    public class BezierPoint
    {
        [SerializeField] private int mReferenceID = 0;
        [SerializeField] private Vector3 mLastPosition;
        [SerializeField] private Transform mReference;
        public Transform TransformReference
        {
            get
            {
#if UNITY_EDITOR
                if (mReference == null)
                {
                    bool createNewPoint = false;
                    if (mReferenceID != 0)
                    {
                        Transform go = EditorUtility.InstanceIDToObject(mReferenceID) as Transform;
                        if (go != null)
                        {
                            mReference = go;
                        }
                        else
                        {
                            Debug.LogError("[Portfolio, BezierPoint] Had a ReferenceID but couldn't find it! ");
                            createNewPoint = true;
                        }
                    }
                    else createNewPoint = true;
                    if (createNewPoint)
                    {
                        mReference = new GameObject().transform;
                        //mReference.gameObject.hideFlags = HideFlags.HideInHierarchy | HideFlags.HideInInspector | HideFlags.DontSaveInBuild;
                        if (mLastPosition != null) mReference.position = mLastPosition;
                        mReferenceID = mReference.GetInstanceID();
                        mReference.name = mReferenceID.ToString();

                    }

                }
#endif
                return mReference; 
            }
        }
        public BezierPoint() { }
        public Vector3 Position
        {
            get
            {
                mLastPosition = TransformReference.position;
                return TransformReference.position;
            }
            set
            {
                mLastPosition = value;
                TransformReference.position = value;
            }
        }

        

        public static implicit operator Vector3(BezierPoint point) => point.Position;
    }

    [ExecuteInEditMode]
    [System.Serializable]
    /// <summary>
    /// Component that computes a Bezier curve
    /// </summary>
    public class Spline : MonoBehaviour
    {
        #region Public Members
        public bool GizmosOnSelectedOnly = false;
        /// <summary>
        /// Transform used to get the starting position
        /// </summary>
        public BezierPoint StartPoint;
        /// <summary>
        /// Transform used to get the starting tangent position
        /// </summary>
        public BezierPoint StartTangent;
        /// <summary>
        /// Transform used to get the ending tangent position
        /// </summary>
        public BezierPoint EndPoint;
        /// <summary>
        /// Transform used to get the ending position
        /// </summary>
        public BezierPoint EndTangent;

        public Color LineColor => PresetInstance.CameraSplineColor;
        private float _LapTime => CameraPortfolioManager.TimeToCompleteLap;
        private AnimationCurve _AnimationCurve => PresetInstance.CameraSplineCurve;
        private PortfolioSplineSO PresetInstance { get; set; }
        #endregion

        #region Properties
        /// <summary>
        /// Tells if all the required reference transforms are set
        /// </summary>
        public bool AreReferenceTranformsFilled
        {
            get
            {
                return StartPoint != null &&
                StartTangent != null &&
                EndTangent != null &&
                EndPoint != null;
            }
        }


        #endregion

        #region MonoBehaviour Functions

        public void Initialize(PortfolioSplineSO presetInstance)
        {
            if(StartPoint == null)
            {
                StartPoint = new BezierPoint();
                StartTangent = new BezierPoint();
                EndPoint = new BezierPoint();
                EndTangent = new BezierPoint();
            }
            PresetInstance = presetInstance;
            RandomLinearPlacement(new Vector3(2, 2, 2), new Vector3(-4, 5 - 6));
        }


        private void OnDrawGizmos()
        {
            if (AreReferenceTranformsFilled && !GizmosOnSelectedOnly && PresetInstance!=null)
            {
#if UNITY_EDITOR
            Handles.DrawBezier(StartPoint, EndTangent,
            StartTangent, EndPoint,
            LineColor, null, 2);
            float timeRatio = Mathf.PI  * (1/_LapTime);
            float ratio = Mathf.Sin(Time.realtimeSinceStartup*timeRatio) * 0.5f + 0.5f;

            Vector3 positionOnCurve = GetPosition(ratio);
            //Gizmos.DrawSphere(positionOnCurve, 1.0f);
            Vector3 velociy = GetVelocity(ratio);
            float H, S, V;
            Color.RGBToHSV(LineColor,out H,out S,out V);
            Gizmos.color = Color.HSVToRGB((H + 0.5f) % 1, S, V);
            Gizmos.DrawLine(positionOnCurve, positionOnCurve + velociy.normalized * 3f);
            Handles.CircleHandleCap(0, positionOnCurve, GetRotation(ratio), 3f, EventType.Repaint);
#endif
            }
        }
        #endregion

        #region Functions
        /// <summary>
        /// Compute the position on the Bezier curve at ratio
        /// </summary>
        /// <param name="ratio">The reference "percentage" to query on the curve</param>
        /// <returns>The position at ratio</returns>
        public Vector3 GetPosition(float ratio)
        {
           

            //Starting points
            Vector3 lerpBetweenStartingPoints =
                Vector3.Lerp(StartPoint,
                StartTangent, ratio);

            //Ending points
            Vector3 lerpBetweenEndingPoints =
                Vector3.Lerp(EndPoint,
                EndTangent, ratio);

            //Tangents
            Vector3 lerpBetweenTangents =
                Vector3.Lerp(StartTangent,
                EndPoint, ratio);

            Vector3 entryCurve =
                Vector3.Lerp(lerpBetweenStartingPoints, lerpBetweenTangents, ratio);

            Vector3 exitCurve =
                Vector3.Lerp(lerpBetweenTangents, lerpBetweenEndingPoints, ratio);

            Vector3 interpolatedCurves =
                Vector3.Lerp(entryCurve, exitCurve, ratio);

            return interpolatedCurves;
        }


        /// <summary>
        /// Computes the velocity (direction * speed) of the curve
        /// </summary>
        /// <param name="ratio">The point[0,1] to compute the velocity</param>
        /// <returns>The velocity of the curve at given ratio</returns>
        public Vector3 GetVelocity(float ratio)
        {
            if (!AreReferenceTranformsFilled)
            {
                Debug.LogError("ATTENTION : Reference objects are not set to compute the Bezier curve", this);
                return Vector3.zero;
            }
            //Velocity = Derivative of GetPosition(ratio)
            float inverseRatio = 1.0f - ratio;
            Vector3 startingPosition = StartPoint;
            Vector3 startingTangent = StartTangent;
            Vector3 endingTangent = EndPoint;
            Vector3 endingPosition = EndTangent;

            //The derivative of the already factorized GetPosition function
            Vector3 velocity = 3f * inverseRatio * inverseRatio * (startingTangent - startingPosition)
                            + 6f * inverseRatio * ratio * (endingTangent - startingTangent)
                            + 3f * ratio * ratio * (endingPosition - endingTangent);

            return velocity;
        }


        /// <summary>
        /// Computes the rotation of the curve(orientation in quaternion)
        /// </summary>
        /// <param name="ratio"> The point[0,1] in the curve</param>
        /// <returns>The rotation at given ratio</returns>
        public Quaternion GetRotation(float ratio)
        {
            if (!AreReferenceTranformsFilled)
            {
                Debug.LogError("ATTENTION : Reference objects are not set to compute the Bezier curve", this);
                return Quaternion.identity;
            }

            return Quaternion.LookRotation(GetVelocity(ratio).normalized);
        }

        /// <summary>
        /// Computes the matrix of the curve(direction, position, scale)
        /// </summary>
        /// <param name="ratio">The point [0,1] of the curve</param>
        /// <returns>The matrix transformation at given ratio</returns>
        public Matrix4x4 GetMatrix(float ratio)
        {
            Vector3 position = GetPosition(ratio);
            Quaternion rotation = GetRotation(ratio);
            //Usually there's the scale too, but we assume it's always 1

            return Matrix4x4.TRS(position, rotation, Vector3.one);
        }


        public void RandomLinearPlacement(Vector3 origin, Vector3 endPoint, float radiusPercentage = 0.2f)
        {
            Vector3 dir = endPoint - origin;
            float distance = dir.magnitude;
            float distanceRandom = distance * radiusPercentage;
            Vector3 randomSphere = Random.onUnitSphere;
            StartPoint.Position = origin;
            Vector3 rightAxis = Vector3.Cross(dir, Vector3.up).normalized;
            StartTangent.Position = origin + dir * .25f + Mathf.Sin(randomSphere.x * 2 * Mathf.PI) * rightAxis* distanceRandom + Mathf.Sin(randomSphere.y * 2 * Mathf.PI) * Vector3.up* distanceRandom;
            EndPoint.Position = origin + dir * .25f + Mathf.Sin(randomSphere.y * 2 * Mathf.PI) * rightAxis* distanceRandom + Mathf.Sin(randomSphere.x * 2 * Mathf.PI) * Vector3.up* distanceRandom;
            EndTangent.Position = endPoint;
        }
        #endregion
    } 
}
