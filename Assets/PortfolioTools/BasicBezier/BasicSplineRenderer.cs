using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using SubjectNerd.Utilities;
/// <summary>
/// Basic spline renderer learnt in class
/// </summary>
[ExecuteInEditMode]
public class BasicSplineRenderer : MonoBehaviour
{
    [Header("Spline Settings")]
    /// <summary>
	/// The reference Bezier curve to follow
	/// </summary>
	public BezierCurve mBezierCurve;
    /// <summary>
	/// Amount of segments on the line
	/// </summary>
	[Min(4)]public int mResolution = 50;
    public bool mStickStartToRoot = true;

    [Disable, SerializeField]private float length;
    [Reorderable] public SplineTransformation[] transformations;
    /// <summary>
	/// Overall width factor of the line
	/// </summary>
	public float mWidthFactor = 1.0f;
    /// <summary>
	/// Curve used for the width of the line
	/// </summary>
	public AnimationCurve mCustomWidthCurve = AnimationCurve.Linear(0, 1, 1, 1);
    public Material mMatRef;


    private LineRenderer mLineRenderer;
    private LineRenderer _LineRend
    {
        get
        {
            if (mLineRenderer == null)
            {
                mLineRenderer = GetComponentInChildren<LineRenderer>();
                if (mLineRenderer == null)
                {
                    mLineRenderer = gameObject.AddComponent<LineRenderer>();
                    mLineRenderer.useWorldSpace = true;
                    mLineRenderer.widthMultiplier = mWidthFactor;
                    mLineRenderer.material = Mat;
                }
            }
            return mLineRenderer;
            
        }
    }

    private Material mMatInstantiated;
    protected Material Mat
    {
        get
        {
#if UNITY_EDITOR
            if(!UnityEditor.EditorApplication.isPlaying)
            {
                if (_LineRend.sharedMaterial == null) _LineRend.sharedMaterial = mMatRef;
                return mMatRef;
            }
            else
            {
                if (mMatInstantiated == null)
                {
                    mMatInstantiated = new Material(mMatRef);
                    _LineRend.material = mMatInstantiated;
                    return mMatInstantiated;
                }
                
            }
#else
            if (mMatInstantiated == null)
            {
                mMatInstantiated = new Material(mMatRef);
                _LineRend.material = mMatInstantiated;
            }
#endif
            return mMatInstantiated;
        }
    }

    protected void OnEnable()
    {
        if(mBezierCurve != null) UpdateLine();
        ExtraOnEnable();
    }

    protected void Update()
    {
        if (mBezierCurve != null && mBezierCurve.HasChanged || (_LineRend.positionCount != mResolution + 1))
        {
            UpdateLine();
        }
        ExtraUpdate();
    }

    protected virtual void ExtraOnEnable()
    {
        //OnEnable for childs
    }
    protected virtual void ExtraUpdate()
    {
        //Update for childs
    }
    /// <summary>
	/// Updates the line renderer and make it follow the Bezier curve
	/// </summary>
	protected void UpdateLine()
    {
        length = 0;
        if (mBezierCurve != null)
        {
            if (mStickStartToRoot) mBezierCurve.startingPointTransform.localPosition = Vector3.zero;
            //Adds the last point
            _LineRend.positionCount = mResolution + 1;

            //Iterates through the points
            for (int i = 0; i < _LineRend.positionCount; ++i)
            {
                float ratio = (float)i / (float)mResolution;
                Matrix4x4 localTransformationMatrix = mBezierCurve.GetMatrix(ratio);

                for (int j = 0; j < transformations.Length; j++)
                {
                    SplineTransformation currentTransformation = transformations[transformations.Length - 1 - j];
                    localTransformationMatrix *= currentTransformation.GetMatrix(ratio);
                }

                Vector3 pointPosition = localTransformationMatrix.MultiplyPoint(Vector3.zero);
                _LineRend.SetPosition(i, pointPosition);

                if (i > 2)
                {
                    length += Vector3.Distance(_LineRend.GetPosition(i), _LineRend.GetPosition(i - 1));
                }
            }
        }
        Mat.SetFloat("_Length", length);
        if(mCustomWidthCurve != null) _LineRend.widthCurve = mCustomWidthCurve;
    }

}

