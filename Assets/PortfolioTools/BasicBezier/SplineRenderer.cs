using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using SubjectNerd.Utilities;

/// <summary>
/// Component allowing to make the line renderer follow a bezier curve
/// </summary>
[ExecuteInEditMode, RequireComponent(typeof(LineRenderer))]
public class SplineRenderer : MonoBehaviour
{
    /* 
     IDEA: Have a slide from 0 to 1 so that the spline can develop from 0 to one.
     The tangents will be childs of the points.
     0 and 1 will also be ratios of the local position of the tangents, so that the curves evolves smoothly, without heavy tangents at short distances.
     Problem: How to make sure the transformations stay put? They adapt to the points/tangents.
     Solution 1: Have not one, but two bezier curves. One for reference(at slider = 1), and the other as the actual curve.
     */



    #region Public Members
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
    [Header("Custom")]
    public bool UseSlider = true;
    [Range(0.01f,1f)]public float Slider;
    public Vector3 StartTangentDirection = Vector3.right;
    public Vector3 EndingTangentDirection = Vector3.left;
    [Range(0f,3f)]public float TangentBiasIntensity = 1f;
    [SerializeField] public Vector3[] previousPositions;

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
                CapFrame.inTangent = 3;
                CapFrame.inWeight = 1;
                CapFrame.outTangent = 0;
                CapFrame.outWeight = 1;

                sliderWidthCurve = new AnimationCurve(SnapFrame, CapFrame);
                return sliderWidthCurve;
            }
            return sliderWidthCurve;
        }
    }
	#endregion

	#region Private Members
	/// <summary>
	/// Reference to the line renderer component
	/// </summary>
	private LineRenderer _lineRendererComponent;
	#endregion

	#region MonoBehaviour Functions
	void OnEnable()
	{
        sliderWidthCurve = null;
        previousSliderValue = Slider;
		_lineRendererComponent = GetComponent<LineRenderer>();
		_lineRendererComponent.useWorldSpace = true;
        lineMaterial = _lineRendererComponent.material;
	}

	void Update ()
	{
        if (previousSliderValue != Slider && UseSlider)
        {
            float difference = previousSliderValue - Slider;
            Vector3 Dir = (bezierCurve.endingPointTransform.position - bezierCurve.startingPointTransform.position).normalized;
            bezierCurve.startingTangentTransform.position += StartTangentDirection * TangentBiasIntensity * difference * Mathf.Sin(Slider * Mathf.PI * 0.5f);
            bezierCurve.endingTangentTransform.position += EndingTangentDirection * TangentBiasIntensity * difference * Mathf.Sin(Slider * Mathf.PI * 0.5f);

            SnapFrame.time = Slider*0.5f;
            SnapFrame.value = Mathf.Abs(Mathf.Sqrt(Mathf.Abs(Mathf.Sqrt(Slider))));
            CapFrame.time = Slider;
            WidthCurve.MoveKey(0, SnapFrame);
            WidthCurve.MoveKey(1, CapFrame);
            _lineRendererComponent.widthCurve = WidthCurve;
		    _lineRendererComponent.widthMultiplier = widthFactor * Slider;
		    _lineRendererComponent.colorGradient = colorGradient;
            lineMaterial.SetFloat("_Slider", Slider);
            lineMaterial.SetFloat("_Width", widthFactor);

        }
        else if (!UseSlider)
        {
            _lineRendererComponent.widthCurve = customWidthCurve;
            _lineRendererComponent.widthMultiplier = widthFactor * Slider;
            _lineRendererComponent.colorGradient = colorGradient;
        }
        previousSliderValue = Slider;
        resolution = Mathf.Max(resolution, 1);
		if(bezierCurve.HasChanged || (_lineRendererComponent.positionCount != resolution + 1))
		{
			UpdateLine();

        }
	}
	#endregion

	#region Functions
	/// <summary>
	/// Updates the line renderer and make it follow the Bezier curve
	/// </summary>
	public void UpdateLine()
	{
        length = 0;
		if(bezierCurve != null)
		{
            //Adds the last point
			_lineRendererComponent.positionCount = resolution + 1;

            //Iterates through the points
			for(int i = 0; i < _lineRendererComponent.positionCount; ++i)
			{
				float ratio = (float)i / (float)resolution;
                Matrix4x4 localTransformationMatrix = bezierCurve.GetMatrix(ratio);

                for(int j = 0; j < transformations.Length; j++)
                {
                    SplineTransformation currentTransformation = transformations[transformations.Length - 1 - j];
                    localTransformationMatrix *= currentTransformation.GetMatrix(ratio);
                }

				Vector3 pointPosition = localTransformationMatrix.MultiplyPoint(Vector3.zero);
				_lineRendererComponent.SetPosition(i, pointPosition);

                if (i > 2)
                {
                    length += Vector3.Distance(_lineRendererComponent.GetPosition(i), _lineRendererComponent.GetPosition(i - 1));
                }
			}
		}
        lineMaterial.SetFloat("_Length", length);
	}

	#endregion
}
