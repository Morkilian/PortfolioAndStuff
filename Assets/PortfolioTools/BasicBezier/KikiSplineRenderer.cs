using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using SubjectNerd.Utilities;

/// <summary>
/// Component allowing to make the line renderer follow a bezier curve
/// </summary>
[ExecuteInEditMode, RequireComponent(typeof(LineRenderer))]
public class KikiSplineRenderer : MonoBehaviour
{
    /* 
     IDEA: Have a slide from 0 to 1 so that the spline can develop from 0 to one.
     The tangents will be childs of the points.
     0 and 1 will also be ratios of the local position of the tangents, so that the curves evolves smoothly, without heavy tangents at short distances.
     Problem: How to make sure the transformations stay put? They adapt to the points/tangents.
     Solution 1: Have not one, but two bezier curves. One for reference(at slider = 1), and the other as the actual curve.
     */



    #region Public Members
    public bool NeedsSlider = true;
    public bool UseSlider = true;
    [Range(0.01f,1f)]public float slider;
	/// <summary>
	/// The reference Bezier curve to follow
	/// </summary>
	public BezierCurve bezierCurve;
	/// <summary>
	/// Amount of segments on the line
	/// </summary>
	public int resolution = 50;
	/// <summary>
	/// Curve used for the width of the line
	/// </summary>
	public AnimationCurve customWidthCurve = AnimationCurve.Linear(0,1,1,1);
	/// <summary>
	/// Overall width factor of the line
	/// </summary>
	public float widthFactor = 1.0f;
	/// <summary>
	/// Color of the line
	/// </summary>
	public Gradient colorGradient;
    public Material LineMaterial;


    public float length;
    [Reorderable]public SplineTransformation[] transformations;

    private Material lineMaterial;
    private Keyframe SnapFrame;
    private Keyframe CapFrame;
    private AnimationCurve sliderWidthCurve;
    private float previousSliderValue;

    private AnimationCurve WidthCurve
    {
        get
        {
            if(sliderWidthCurve == null || sliderWidthCurve.keys.Length != 2)
            {

                SnapFrame = new Keyframe(0.5f, 1);
                SnapFrame.inTangent = 0;
                SnapFrame.inWeight = 1;
                SnapFrame.outTangent = 0;
                SnapFrame.outWeight = 1;

                CapFrame = new Keyframe(1, 0);
                CapFrame.inTangent = 1;
                CapFrame.inWeight = 1;
                CapFrame.outTangent = 0;
                CapFrame.outWeight = 1;

                sliderWidthCurve = new AnimationCurve(SnapFrame, CapFrame);
                return sliderWidthCurve;
            }
            return sliderWidthCurve;
        }
    }

    public float Slider { get { return slider; } set { slider = Mathf.Clamp01(value); } }
	#endregion

	#region Private Members
	/// <summary>
	/// Reference to the line renderer component
	/// </summary>
	private LineRenderer mLineRendererComponent;
    private LineRenderer _Line { get { if (mLineRendererComponent == null) mLineRendererComponent = GetComponent<LineRenderer>(); return mLineRendererComponent; } }
	#endregion

	#region MonoBehaviour Functions
	void OnEnable()
	{
        previousSliderValue = slider;
        mLineRendererComponent = GetComponent<LineRenderer>();
		_Line.useWorldSpace = true;
        lineMaterial = new Material(LineMaterial.shader);
        lineMaterial.CopyPropertiesFromMaterial(LineMaterial);
        _Line.material = lineMaterial;

        if (!UseSlider)
        {
            _Line.widthCurve = customWidthCurve;
            _Line.widthMultiplier = widthFactor;
            _Line.colorGradient = colorGradient;
        }


    }
    private void Start()
    {
        OnEnable();
    }

    void Update ()
	{
        if (NeedsSlider)
        {
            if (UseSlider)
            {
                SnapFrame.time = slider*0.5f;
                SnapFrame.value = Mathf.Abs(Mathf.Sqrt(Mathf.Abs(Mathf.Sqrt(slider))));
                CapFrame.time = slider;
                WidthCurve.MoveKey(0, SnapFrame);
                WidthCurve.MoveKey(1, CapFrame);
                lineMaterial.SetFloat("_Slider", slider);
                //lineMaterial.SetFloat("_Width", widthFactor);
                _Line.widthCurve = WidthCurve;
                //_lineRendererComponent.widthMultiplier = widthFactor;
            }
            if (previousSliderValue == slider) UseSlider = false;
            else
            {
                previousSliderValue = slider;
                UseSlider = true;
            }
            resolution = Mathf.Max(resolution, 1);
		    if(bezierCurve.HasChanged || (_Line.positionCount != resolution + 1))
		    {
			    UpdateLine();

            }
        }
	}
	#endregion

	#region Functions
    public void TurnOffSlider()
    {
        _Line.enabled = false;
        NeedsSlider = false;
    }
	/// <summary>
	/// Updates the line renderer and make it follow the Bezier curve
	/// </summary>
	public void UpdateLine()
	{
        length = 0;
		if(bezierCurve != null)
		{
            //Adds the last point
			_Line.positionCount = resolution + 1;

            //Iterates through the points
			for(int i = 0; i < _Line.positionCount; ++i)
			{
				float ratio = (float)i / (float)resolution;
                Matrix4x4 localTransformationMatrix = bezierCurve.GetMatrix(ratio);

                for(int j = 0; j < transformations.Length; j++)
                {
                    SplineTransformation currentTransformation = transformations[transformations.Length - 1 - j];
                    localTransformationMatrix *= currentTransformation.GetMatrix(ratio);
                }

				Vector3 pointPosition = localTransformationMatrix.MultiplyPoint(Vector3.zero);
				_Line.SetPosition(i, pointPosition);

                if (i > 2)
                {
                    length += Vector3.Distance(_Line.GetPosition(i), _Line.GetPosition(i - 1));
                }
			}
		}
        lineMaterial.SetFloat("_Length", length);
	}

    public Matrix4x4 GetMatrix(float ratio)
    {
        Matrix4x4 localTransformationMatrix = bezierCurve.GetMatrix(ratio);
        for (int j = 0; j < transformations.Length; j++)
        {
            SplineTransformation currentTransformation = transformations[transformations.Length - 1 - j];
            localTransformationMatrix *= currentTransformation.GetMatrix(ratio);
        }
        return localTransformationMatrix;
    }

    public void SetMatrix(Transform transf,  float ratio)
    {
        if (bezierCurve != null)
        {

            Matrix4x4 localTransformationMatrix = bezierCurve.GetMatrix(ratio);

            for (int j = 0; j < transformations.Length; j++)
            {
                SplineTransformation currentTransformation = transformations[transformations.Length - 1 - j];
                localTransformationMatrix *= currentTransformation.GetMatrix(ratio);
            }

            transf.position = localTransformationMatrix.MultiplyPoint(Vector3.zero);
            transf.rotation = localTransformationMatrix.rotation;
            
        }
    }
    public Vector3 GetPosition(float ratio)
    {
        if (bezierCurve != null)
        {

            Matrix4x4 localTransformationMatrix = bezierCurve.GetMatrix(ratio);

            for (int j = 0; j < transformations.Length; j++)
            {
                SplineTransformation currentTransformation = transformations[transformations.Length - 1 - j];
                localTransformationMatrix *= currentTransformation.GetMatrix(ratio);
            }

            return localTransformationMatrix.MultiplyPoint(Vector3.zero);

        }
        return Vector3.zero;
    }

	#endregion
}
