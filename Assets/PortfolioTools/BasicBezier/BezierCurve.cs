using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteInEditMode]
/// <summary>
/// Component that computes a Bezier curve
/// </summary>
public class BezierCurve : MonoBehaviour
{
    #region Public Members
    public bool GizmosOnSelectedOnly = false;
    /// <summary>
    /// Transform used to get the starting position
    /// </summary>
    public Transform startingPointTransform;
    /// <summary>
    /// Transform used to get the starting tangent position
    /// </summary>
    public Transform startingTangentTransform;
    /// <summary>
    /// Transform used to get the ending tangent position
    /// </summary>
    public Transform endingTangentTransform;
    /// <summary>
    /// Transform used to get the ending position
    /// </summary>
    public Transform endingPointTransform;
    [Header("Debug")]
    public bool m_Animate = false;
    public Color mLineColor = Color.green;
    public float mDebugSinTime = 1f;
    public AnimationCurve mAnimationCurve;
    #endregion

    #region Properties
    /// <summary>
    /// Tells if all the required reference transforms are set
    /// </summary>
    public bool AreReferenceTranformsFilled
    {
        get
        {
            return startingPointTransform != null &&
            startingTangentTransform != null &&
            endingPointTransform != null &&
            endingTangentTransform != null;
        }
    }

    /// <summary>
    /// Tells if the curve has changed
    /// </summary>
    public bool HasChanged
    {
        get
        {
            return startingPointTransform.hasChanged ||
                startingTangentTransform.hasChanged ||
                endingTangentTransform.hasChanged ||
                endingPointTransform.hasChanged;
        }
    }
    #endregion

    #region MonoBehaviour Functions
    /*
    private void OnDrawGizmosSelected()
    {
        if (AreReferenceTranformsFilled&&GizmosOnSelectedOnly)
        {
#if UNITY_EDITOR
            Handles.DrawBezier(startingPointTransform.position, endingPointTransform.position,
            startingTangentTransform.position, endingTangentTransform.position,
            Color.green, null, 2);

            float ratio = Mathf.Sin(Time.realtimeSinceStartup) * 0.5f + 0.5f;

            Vector3 positionOnCurve = GetPosition(ratio);
            //Gizmos.DrawSphere(positionOnCurve, 1.0f);
            Vector3 velociy = GetVelocity(ratio);
            Gizmos.color = Color.red;
            Gizmos.DrawLine(positionOnCurve, positionOnCurve + velociy.normalized * 3f);
            Handles.CircleHandleCap(0, positionOnCurve, GetRotation(ratio), 3f, EventType.Repaint);
#endif
        }
    }
    */
    private void OnEnable()
    {
        //if(transform.parent != null)
        //transform.localPosition = Vector3.zero;

        if (startingPointTransform == null)
        {
            name = "BezierCurve";
            startingPointTransform = new GameObject("StartPoint").transform;
            startingPointTransform.position = transform.position + transform.forward;

            startingTangentTransform = new GameObject("StartTangent").transform;
            startingTangentTransform.position = transform.position + transform.forward + transform.up;

            endingPointTransform = new GameObject("EndPoint").transform;
            endingPointTransform.position = transform.position + transform.forward * 2f;

            endingTangentTransform = new GameObject("EndTangent").transform;
            endingPointTransform.position = transform.position + transform.forward - transform.up;

            startingPointTransform.parent = endingPointTransform.parent = startingTangentTransform.parent = endingTangentTransform.parent = transform; 
        }
    }


    private void OnDrawGizmos()
    {
        DrawGizmos(false);
    }

    private void OnDrawGizmosSelected()
    {
        DrawGizmos(true);
    }

    private void DrawGizmos(bool isSelected)
    {
#if UNITY_EDITOR
        if (AreReferenceTranformsFilled && !GizmosOnSelectedOnly)
        {
            Color colorTuOse = mLineColor;
            const float unselectedAlpha = 0.4f;
            float alpha = isSelected ? mLineColor.a : mLineColor.a * unselectedAlpha;
            colorTuOse.a = alpha;
            Handles.DrawBezier(startingPointTransform.position, endingPointTransform.position,
            startingTangentTransform.position, endingTangentTransform.position,
            colorTuOse, null, 2);
            float timeRatio = Mathf.PI * (1 / mDebugSinTime);
            float ratio = Mathf.Sin(Time.realtimeSinceStartup * timeRatio) * 0.5f + 0.5f;

            Vector3 positionOnCurve = GetPosition(ratio);
            //Gizmos.DrawSphere(positionOnCurve, 1.0f);
            Vector3 velociy = GetVelocity(ratio);
            if (m_Animate)
            {
                float H, S, V;
                Color.RGBToHSV(colorTuOse, out H, out S, out V);
                Color toInject = Color.HSVToRGB((H + 0.5f) % 1, S, V);
                toInject.a = alpha;
                Gizmos.color = toInject;
                Gizmos.DrawLine(positionOnCurve, positionOnCurve + velociy.normalized * 3f);
                Handles.color = toInject;
                Handles.CircleHandleCap(0, positionOnCurve, GetRotation(ratio), 3f, EventType.Repaint);
            }
        }
#endif
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
        if (!AreReferenceTranformsFilled)
        {
            Debug.LogError("ATTENTION : Reference objects are not set to compute the Bezier curve", this);
            return Vector3.zero;
        }

        //Starting points
        Vector3 lerpBetweenStartingPoints =
            Vector3.Lerp(startingPointTransform.position,
            startingTangentTransform.position, ratio);

        //Ending points
        Vector3 lerpBetweenEndingPoints =
            Vector3.Lerp(endingTangentTransform.position,
            endingPointTransform.position, ratio);

        //Tangents
        Vector3 lerpBetweenTangents =
            Vector3.Lerp(startingTangentTransform.position,
            endingTangentTransform.position, ratio);
 
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
        Vector3 startingPosition = startingPointTransform.position;
        Vector3 startingTangent = startingTangentTransform.position;
        Vector3 endingTangent = endingTangentTransform.position;
        Vector3 endingPosition = endingPointTransform.position;

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
        Vector3 randomSphere = Random.onUnitSphere;
        startingPointTransform.position = origin;
        Vector3 rightAxis = Vector3.Cross(dir, Vector3.up).normalized;
        startingTangentTransform.position = origin + dir * .25f + Mathf.Sin(randomSphere.x * 2 * Mathf.PI) * rightAxis + Mathf.Sin(randomSphere.y * 2 * Mathf.PI) * Vector3.up;
        endingTangentTransform.position = origin + dir * .25f + Mathf.Sin(randomSphere.y * 2 * Mathf.PI) * rightAxis + Mathf.Sin(randomSphere.x * 2 * Mathf.PI) * Vector3.up;
        endingPointTransform.position = endPoint;
    }
    #endregion
}
