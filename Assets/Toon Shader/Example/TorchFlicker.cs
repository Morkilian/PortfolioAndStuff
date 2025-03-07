using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Morkilian.Helper;
using Morkilian;
//using NaughtyAttributes;
[ExecuteInEditMode]
public class TorchFlicker : MonoBehaviour
{

      
    [SerializeField] private bool m_PreviewEditor = false;
    [Header("MinMax")]
    [Tooltip("The minimal and maximal values of the light intensity.")]public MinMaxCurved m_RelativeIntensityInfo = new MinMaxCurved(0.9f, 1.1f);
    [Tooltip("The minimal and maximal values of the light movement (sphere distance).")] public MinMaxCurved m_AbsoluteDistanceOffsetInfo = new MinMaxCurved(0.2f, 0.5f);
    [Tooltip("The minimal and maximal values of the light range.")] public MinMaxCurved m_RelativeRangeFlicker = new MinMaxCurved(.9f, 1.1f);
    [Header("Regular")]
    [Tooltip("The ratio between which the regular flicking will have its intensity (0 being the minimal, 1 being the maximal)")] [MinMaxSlider(0f, 1f)] public Vector2 m_RegularFlickIntensity = new Vector2(0.4f, 0.6f);
    //[Range(0f, .5f)] [Tooltip("The ratio between which the regular flicking will have its range (0 being the minimal, 1 being the maximal)")] public float m_RegularDistanceFlick = 0.2f;
    [Tooltip("The ratio between which the regular flicking will have its movement (0 being the minimal, 1 being the maximal)")] [MinMaxSlider(0f,1f)] public Vector2 m_RegularFlickRange = new Vector2(0.4f,0.6f);
    [Header("Timing")]
    [Tooltip("The minimal and maximal time before the next big flickering comes.")] public MinMaxCurved m_TimeUntilNextBigFlick = new MinMaxCurved(2f, 7f);
    [Tooltip("The minimal and maximal intensity added when a big flick comes.")] public MinMaxCurved m_BigFlickInfo = new MinMaxCurved(1f, 1.5f);
    [Tooltip("The minimal and maximal overall duration of the flickering.")]public MinMaxCurved m_FlickDuration = new MinMaxCurved(0.2f, 0.3f);
    //[Tooltip("The curve deciding the duration repartition of the flickerings.")] public AnimationCurve m_FlickDurationCurve = new AnimationCurve(MathHelper.LinearCurve.keys);

    private new Light light;
    private Light _Light { get { if (light == null) light = GetComponent<Light>(); return light; } }
    private float flickTime = 0f;
    private float flickDuration = 0f;
    private float nextBigFlickTime = 0f;
    private Vector3 defaultPosition = default;
    private float defaultIntensity = 0;
    private float defaultRange = 0;

    private bool previousFramePreviewEditor = false;

    //Intensity, Range (alphabetical order)
    private Vector2 startFlickValues = default;
    private Vector2 targetFlickValues = default;
    private Vector3 startFlickPosition = default;
    private Vector3 targetFlickPosition = default;

    private void OnEnable()
    {
        previousFramePreviewEditor = m_PreviewEditor;
        m_PreviewEditor = false;
        defaultPosition = transform.localPosition;
        defaultIntensity = _Light.intensity;
        defaultRange = _Light.range;

        startFlickValues = targetFlickValues = new Vector2(defaultIntensity, defaultRange);
        startFlickPosition = targetFlickPosition = transform.localPosition;
        ComputeNewFlick();
    }

    private void OnDisable()
    {
        if (m_PreviewEditor)
        {
            transform.localPosition = defaultPosition;
            _Light.intensity = defaultIntensity;
            _Light.range = defaultRange; 
        }
    }

    private void Update()
    {
#if UNITY_EDITOR
        if(Application.isEditor && m_PreviewEditor)
        {

#endif
            if (_Light.enabled)
            {
                flickTime += Time.deltaTime;
                float progress = Mathf.SmoothStep(0f, 1f, flickTime / flickDuration);
                transform.localPosition = Vector3.Lerp(startFlickPosition, targetFlickPosition, progress);
                _Light.intensity = Mathf.SmoothStep(startFlickValues.x, targetFlickValues.x, progress);
                _Light.range = Mathf.SmoothStep(startFlickValues.y, targetFlickValues.y, progress);
                if (progress == 1f) ComputeNewFlick(Time.time < nextBigFlickTime); 
            }
#if UNITY_EDITOR
        } 
#endif
    }



    public void ComputeNewFlick(bool regular = true, bool editor = false)
    {
        startFlickValues = targetFlickValues;
        startFlickPosition = transform.localPosition;

        float intensityChoice = defaultIntensity * m_RelativeIntensityInfo*(regular?1f:m_BigFlickInfo);
        float rangeChoice = defaultRange * m_RelativeRangeFlicker*(regular?1f:m_BigFlickInfo);

        targetFlickPosition = defaultPosition+ Random.onUnitSphere * m_AbsoluteDistanceOffsetInfo * (regular ? 1f:m_BigFlickInfo);
        
        targetFlickValues = new Vector3(intensityChoice, rangeChoice);
        flickTime = 0f;
        flickDuration = m_FlickDuration; //This way we can control the amount of small or bigger flicks
        if (!regular) nextBigFlickTime = m_BigFlickInfo + (Application.isEditor ? Time.realtimeSinceStartup : Time.time);

    }


}
