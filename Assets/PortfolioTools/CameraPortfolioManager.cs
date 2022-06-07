using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using Toolbox.Editor.Drawers;
using MyBox;
#if UNITY_EDITOR
using UnityEditor.Recorder;
#endif
using UnityEngine.Events;


namespace Portfolio
{
    [System.Serializable]
    public class PortfolioEvent
    {
        public string Name = "Event";
        public UnityEngine.Events.UnityEvent EventToExecute;
        [Range(0f, 1f)] public float TimeToActivate = 0.5f;
        [HideInInspector] public bool HasBeenActivated = false;
    }
    public enum CameraRecordingType
    {
        [Tooltip("Test")]
        Static,
        Spline
    }
    public enum SplineTrajectoryType { Go, GoAndBack, Back, BackAndGo }
    public enum EventsToCall { CharacterSkillRanged, CharacterSkillAOE, EnemyRanged, AOE, Debug}

    public class CameraPortfolioManager : MonoBehaviour
    {
        [HideInInspector]public bool UseCustomEditor = false;
        public PortfolioSplineSO mPresetToUse;
        [Tooltip("Is our current session set as a \"Portfolio\" or nor?")]
        public bool UsePorfolio = false;
        [Tooltip("Type of recording we want to use. \n Static: Uses a single transform as a look from. \n Bruh")]
        public CameraRecordingType CurrentCameraRecording = CameraRecordingType.Static;
        [Header("Camera")]
        [Header("Spline")]
        public SplineTrajectoryType mTrajectoryType;
        public AnimationCurve[] mSplineAnimationCurves = new AnimationCurve[] 
        {
            new AnimationCurve(new Keyframe(0, 0, 0, 0, 1, 1), new Keyframe(1, 1, 0, 0, 1, 1)),
            new AnimationCurve(new Keyframe(0, 0, 0, 0, 1, 1), new Keyframe(1, 1, -0.5f, 0.5f, 1, 1)),
            new AnimationCurve(new Keyframe(0, 0, -0.5f, 0.5f, 1, 1), new Keyframe(1, 1, 0, 0, 1, 1))
        };
        [Range(0,4)]public int mSplineTrajectorySpeedIndex = 0;
        public BezierCurve mSplineSelected;
        [Header("Angle")]
        public Transform mAngle;
        [Header("LookAt")]
        public bool mDoesLookAt = true;
        public CameraRecordingType mLookAtType;
        public BezierCurve mSplineLookAt;
        [Range(0,4)] public int mSplineLookatSpeedIndex = 0;
        public Transform mTransformToLookAt;
        [Space]
        [Header("Info events to call")]
        public bool m_CallEvents = true;
        [Range(0f, 1f)] public float mPercentageTimeToCallEvent = 0.5f;
        [Min(0.5f)]public float mTimeToCompleteLap = 1f;
        [Min(0f)] public float mTimeToWaitBeforeStarting = 0f;
        [Min(0f)] public float mTimeToWaitAfterwards = 0f;
        public PortfolioEvent[] mEvents;

        private bool _IsSpline => CurrentCameraRecording == CameraRecordingType.Spline;
        private bool _LookAtSpline => mDoesLookAt && mLookAtType == CameraRecordingType.Spline;
        private bool _LookAtTransform => mDoesLookAt && mLookAtType == CameraRecordingType.Static;

        private bool _LapsBack => _IsSpline && (mTrajectoryType == SplineTrajectoryType.BackAndGo || mTrajectoryType == SplineTrajectoryType.GoAndBack);
        private bool _Go => (_IsSpline || _LookAtSpline) && mTrajectoryType == SplineTrajectoryType.Go;
        private bool _Back => (_IsSpline || _LookAtSpline) && mTrajectoryType == SplineTrajectoryType.Back;
        private bool _BackAndGo => (_IsSpline || _LookAtSpline) && mTrajectoryType == SplineTrajectoryType.BackAndGo;


        private Camera mCam;
        public static Camera ThisCamera { get { if (sInstance.mCam == null) sInstance.mCam = sInstance.GetComponentInChildren<Camera>(); return sInstance.mCam; } }
        public static Transform CameraTransform => sInstance.transform;

        private static CameraPortfolioManager sInstance;

        public static bool IsPortfolio => sInstance != null && sInstance.UsePorfolio;
        public static float TimeToCompleteLap => sInstance != null ? sInstance.mTimeToCompleteLap : 1f;


#if UNITY_EDITOR
        private RecorderWindow recorderWindow;
        private RecorderWindow _RecorderWindow
        {
            get
            {
                if (recorderWindow == null)
                {
                    recorderWindow = (RecorderWindow)EditorWindow.GetWindow(typeof(RecorderWindow));
                }
                return recorderWindow;

            }

        } 
#endif

        private void Awake()
        {
            sInstance = this;
            if (mCameraTest != null) mCameraTest.GetComponent<Camera>().enabled = false;
            if(UsePorfolio)ThisCamera.enabled = true;
            if (!mDoesLookAt && !_IsSpline) transform.rotation = Quaternion.LookRotation(mAngle.forward);


        }
        private void Start()
        {
            if (UsePorfolio)
            {
                StartCoroutine(RecordingCoroutine()); 
            }
        }

        private void Update()
        {
            
        }

        public void RecordNextLoop()
        {
            
        }



        private void SetPosition(float ratio)
        {
            if (_IsSpline)
            {
                transform.position = mSplineSelected.GetPosition(ratio);
            }
            else transform.position = mAngle.position;
        }

        private void SetRotation(float ratio)
        {
           
            if (_LookAtSpline)
            {
                Vector3 targetPos = mSplineLookAt.GetPosition(mSplineAnimationCurves[mSplineLookatSpeedIndex].Evaluate(ratio));
                transform.LookAt(targetPos);
            }
            else if (_LookAtTransform)
            {
                transform.LookAt(mTransformToLookAt);
            }
            else
            {
                transform.rotation = Quaternion.LookRotation(mAngle.forward, Vector3.up);
            }
            
        }
        
        private IEnumerator RecordingCoroutine()
        {
            SetPosition(_Go?0f:1f);
            SetRotation(_Go ? 0f : 1f);
            float currentTime = 0f;
            yield return new WaitForSeconds(mTimeToWaitBeforeStarting);

            while (currentTime < mTimeToCompleteLap)
            {
                currentTime += Time.deltaTime;
                float progress = Mathf.Clamp01(currentTime / mTimeToCompleteLap);
                float remappedProgress  = _Go ? progress : 1 - progress;
                float remappedProgressPosition = remappedProgress;
                if (_IsSpline) remappedProgressPosition = mSplineAnimationCurves[mSplineTrajectorySpeedIndex].Evaluate(remappedProgress);
                SetPosition(remappedProgressPosition);
                SetRotation(remappedProgress);
                
                if (m_CallEvents && mEvents.Length>0)
                {
                    for(int i = 0; i < mEvents.Length; i++)
                    {
                        PortfolioEvent currentEvent = mEvents[i];
                        if(!currentEvent.HasBeenActivated && progress > currentEvent.TimeToActivate)
                        {
                            currentEvent.EventToExecute.Invoke();
                            currentEvent.HasBeenActivated = true;
                        }
                    }                                        
                }
                yield return null;
            }
            if (_LapsBack)
            {
                currentTime = 0f;
                while (currentTime < mTimeToCompleteLap)
                {
                    currentTime += Time.deltaTime;
                    float progress = Mathf.Clamp01(currentTime / mTimeToCompleteLap);
                    float remappedProgress = _BackAndGo ? progress : 1 - progress;
                    
                    if (_IsSpline) remappedProgress = mSplineAnimationCurves[mSplineTrajectorySpeedIndex].Evaluate(remappedProgress);
                    SetPosition(progress);
                    SetRotation(progress);
                    yield return null;
                }
            }
            yield return new WaitForSeconds(mTimeToWaitAfterwards);

#if UNITY_EDITOR
            _RecorderWindow.StopRecording(); 
#endif

        }
        public Transform mCameraTest;
#if UNITY_EDITOR
        [Header("PreviewEditor")]
        public bool mPreviewEditor = false;
        public bool mUseSlider = false;
        [Range(0f,1f)]public float mPositionInTheSpline = 0.5f;
        private void OnDrawGizmos()
        {
            if(mPreviewEditor && mCameraTest != null && mSplineSelected != null && mSplineLookAt != null)
            {
                
                float timeRatio = Mathf.PI * (1 / mTimeToCompleteLap);
                float ratio = Mathf.Abs(Time.realtimeSinceStartup * (1 / mTimeToCompleteLap) % 2 - 1);
                if (mUseSlider) ratio = mPositionInTheSpline;
                Vector3 camPos, targetPos;
                if (_IsSpline)
                {
                    if (mPresetToUse != null) camPos = mPresetToUse.GetCameraPosition(ratio);
                    else
                    {
                        float cameraPosRemapped = mSplineAnimationCurves[mSplineTrajectorySpeedIndex].Evaluate(ratio);
                        camPos = mSplineSelected.GetPosition(cameraPosRemapped);
                    }
                }
                else camPos = mAngle.position;
                if (_LookAtSpline)
                {
                    float targetPosRemapped = mSplineAnimationCurves[mSplineLookatSpeedIndex].Evaluate(ratio);
                    targetPos = mSplineLookAt.GetPosition(targetPosRemapped);
                }
                else if(mTransformToLookAt !=null)
                {
                    targetPos = mTransformToLookAt.position;
                }
                else
                {
                    if (_IsSpline)
                    {
                        targetPos = mSplineLookAt.startingPointTransform.position + mSplineLookAt.startingPointTransform.forward;
                    }
                    else
                    {
                        targetPos = mAngle.position + mAngle.forward;
                    }
                }
                
                mCameraTest.position = camPos;
                if (_LookAtTransform || _LookAtSpline) mCameraTest.LookAt(targetPos);
                else mCameraTest.rotation = Quaternion.LookRotation(mAngle.forward);

                Gizmos.color = Color.red;
                Gizmos.DrawLine(camPos, targetPos);
                Gizmos.DrawWireSphere(camPos, 0.25f);

            }
        }
#endif
    }


}
