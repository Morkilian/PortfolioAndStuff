namespace Morkilian.Tools.ShaderToon
{
    using System.Collections;
    using System.Collections.Generic;
    using UnityEngine;
    using UnityEditor;
    using System.IO;
    using Morkilian.Helper;

    internal struct ToonWindowInfo
    {
        public string FileName;
        public MonochromeLookupTableMaker.Sizes Size;
        public float[] KeyTimes;
        public float[] KeyValues;
        public FilterMode FMode;
        public GameObject ModelUsed;
        

        public ToonWindowInfo(string currentFileName, MonochromeLookupTableMaker.Sizes currentSize, FilterMode currentFilterMode, GameObject currentModel, float[]keyTimes, float[] keyValues)
        {
            FileName = currentFileName;
            Size = currentSize;            
            FMode = currentFilterMode;
            ModelUsed = currentModel;
            KeyTimes = keyTimes;
            KeyValues = keyValues;
        }
    }

    [ExecuteInEditMode]
    public class MonochromeLookupTableMaker : EditorWindow
    {
        #region Serializables and privates
        public enum Sizes { T64 = 64, T128 = 128, T256 = 256, T512 = 512, T1024 = 1024 }
        private AnimationCurve myCurve;
        private FilterMode filterMode = FilterMode.Bilinear;
        private Sizes size = Sizes.T256;
        private FileInfo file;
        private bool snapColors = false;

        private PreviewRenderUtility previewRenderer;
        private MeshFilter previewMeshFilter;
        private Material previewMeshMaterial;


        Vector2 lastRelativePosition = new Vector2(0, 0);
        Vector2 deltaRelativeMovement = new Vector2(0, 0);
        Vector2 currentPosNormalized = new Vector2(0, 0);
        private bool clickedDown = false;
        private Texture2D defaultTex;
        private Vector2 previewMinMaxZoom = Vector2.zero;
        private float previewCurrentZoom = 0.5f;
        private GameObject modelMesh;
        private GameObject modelMeshCompare; 
        #endregion

        #region Statics and consts

        private const float PREVIEW_STARTING_Y_POS = 110;
        private const float PREVIEW_HORIZONTAL_MARGIN = 15;

        private const float PREVIEW_SPEED_HORIZONTAL = 270;
        private const float PREVIEW_SPEED_VERTICAL = 270;
        private const float PREVIEW_SPEED_ZOOM = .05f;

        private const string SHADER_NAME = "TFE/Toon/Lightning PBR";
        private const string SETTINGS_NAME = "ToonWindowSettings";
        private const string DEFAULT_MATERIAL_NAME = "M_ToonDefaultMat";
        public const string DEFAULT_MODEL_NAME = "Mo_SuzanneFixed";

        private static GUIContent gradientGUIContent; 
        #endregion

        #region Private properties
        private float _previewSize => this.position.width - PREVIEW_HORIZONTAL_MARGIN * 2;
        private Transform _previewCameraTransform => previewRenderer.camera.transform;
        private Camera _previewCamera => previewRenderer.camera;
        private Transform _previewLightTransform => previewRenderer.lights[0].transform;
        private Light _previewMainLight => previewRenderer.lights[0]; 
        #endregion


        [MenuItem("Window/Gradient Maker %&r")]
        static void InitWindows()
        {
            MonochromeLookupTableMaker window = (MonochromeLookupTableMaker)EditorWindow.GetWindow(typeof(MonochromeLookupTableMaker));
            window.Show();
            
        }

        void InitializeValues()
        {
            LoadSettings();
            InitializeCS();
            gradientGUIContent = new GUIContent("Custom Gradient", "The toggle on the right enables wether or not the colors will be snapped or not. Just test it out.");
            file = new FileInfo(Application.dataPath + "/T_Gradient_NewGradient.png");
            
            previewRenderer = new PreviewRenderUtility();            
            _previewCamera.clearFlags = CameraClearFlags.Skybox;
            _previewCameraTransform.position = new Vector3(0,0,10);
            //_previewCameraTransform.rotation = Quaternion.Euler(0, 180, 0);
            _previewCamera.aspect = 1f;
            _previewCamera.orthographic = false;
            _previewCamera.fieldOfView = 60;
            _previewCamera.farClipPlane = 100f;
            _previewCamera.nearClipPlane= 0.01f;            
            for (int i = 1; i < previewRenderer.lights.Length; i++)
            {
                previewRenderer.lights[i].enabled = false;
            }
            _previewLightTransform.position = _previewCameraTransform.position;
            _previewLightTransform.rotation = _previewCameraTransform.rotation;
            if(modelMesh==null || modelMesh.GetType()!=typeof(GameObject))
                modelMesh = Resources.Load<GameObject>(DEFAULT_MODEL_NAME);
            ReloadPreviewMeshInfo();

        }
        private void OnEnable()
        {
            InitializeValues();
        }
        private void OnDisable()
        {
            SaveChanges();
            SaveCurrentSettings();
            if (previewRenderer != null) previewRenderer.Cleanup();
            if(gradientTexture!=null) gradientTexture.Release();
        }
        private void Update()
        {
            if (previewRenderer != null)
            {
                Repaint();
            }
        }

        private void OnGUI()
        {
            if (previewRenderer == null) InitializeValues();            
            GUILayout.Label("Gradient", EditorStyles.boldLabel);
            EditorGUILayout.BeginHorizontal();
            if (myCurve == null || myCurve.keys.Length == 0)
            {
                myCurve = new AnimationCurve(new Keyframe(0f, 0f, 1, 1), new Keyframe(1f, 1f, 1, 1));
            }
            myCurve = EditorGUILayout.CurveField(gradientGUIContent, myCurve);
            
            snapColors = EditorGUILayout.Toggle(snapColors, GUILayout.Width(15));
            EditorGUILayout.EndHorizontal();


            EditorGUILayout.BeginHorizontal();
            filterMode = (FilterMode)EditorGUILayout.EnumPopup("FilterMode", filterMode);
            
            size = (Sizes)EditorGUILayout.EnumPopup("Size", size);
            EditorGUILayout.EndHorizontal();

            modelMesh= (GameObject)EditorGUILayout.ObjectField("Model Mesh", modelMesh, typeof(GameObject), true);
            if ((modelMeshCompare == null && modelMesh != null) //There wasn't a selected mesh but now there is
                || (modelMesh != null && modelMeshCompare != modelMesh))
            {
                modelMeshCompare = modelMesh;
                ReloadPreviewMeshInfo();
            }
            EditorGUILayout.Space(5);
            EditorGUILayout.BeginHorizontal();
            if(GUILayout.Button("Save To"))
            {
                string path = EditorUtility.SaveFilePanel("New gradient location:", file.DirectoryName, file.Name, "png");
                if (!string.IsNullOrEmpty(path))
                {
                    file = new FileInfo(path);
                    SaveNewTexture(path);
                }
            }
            GUILayout.Label(file.FullName);
            EditorGUILayout.EndHorizontal();            
            EditorGUILayout.Space(5);
            UpdateGradientTexture(); 
            PreviewCurrentGradient();
        }


        


        private void PreviewCurrentGradient()
        {
            //Preview control
            int controlID = GUIUtility.GetControlID(FocusType.Passive);
            switch (Event.current.GetTypeForControl(controlID))
            {
                case EventType.MouseDown:
                    if (Event.current.button == 0)
                    {
                        clickedDown = true;
                        //Debug.Log("Started rotating"); 
                    }
                break;
                case EventType.MouseUp:
                    if (Event.current.button == 0)
                    {
                        currentPosNormalized = lastRelativePosition = Vector2.zero;
                        clickedDown = false;
                        //Debug.Log("Stopped rotating"); 
                    }
                break;
                case EventType.KeyDown:
                    if(Event.current.keyCode == KeyCode.R)
                    {
                        ReloadPreviewMeshInfo();
                    }
                    break;
            }         
            if (clickedDown)
            {
                currentPosNormalized = Event.current.mousePosition;
                currentPosNormalized.x = Mathf.Clamp01((currentPosNormalized.x + PREVIEW_HORIZONTAL_MARGIN) /(_previewSize));
                currentPosNormalized.y = Mathf.Clamp01((currentPosNormalized.y - PREVIEW_STARTING_Y_POS + PREVIEW_HORIZONTAL_MARGIN)/(_previewSize));

                //Calcul new position
                if ((currentPosNormalized.x > 0 && currentPosNormalized.x < 1 && currentPosNormalized.y > 0 && currentPosNormalized.y < 1)) //Is within boundaries
                {
                    if (lastRelativePosition != Vector2.zero)//Has a last position (and withing boundaries) then there's a delta done
                    {
                        deltaRelativeMovement = currentPosNormalized - lastRelativePosition;
                    }
                    lastRelativePosition = currentPosNormalized;
                }
                else //Resets last position
                {
                    currentPosNormalized = deltaRelativeMovement = lastRelativePosition = Vector2.zero;
                    clickedDown = false;
                }

                if (Event.current.control) //Rotate on Z axis
                {
                    _previewCameraTransform.RotateAround(Vector3.zero, _previewCameraTransform.forward, deltaRelativeMovement.x * Time.deltaTime * PREVIEW_SPEED_HORIZONTAL);
                }
                else if (Event.current.alt) //Rotates light
                {
                    _previewLightTransform.Rotate(_previewCameraTransform.right * deltaRelativeMovement.y * Time.deltaTime * PREVIEW_SPEED_HORIZONTAL);
                    _previewLightTransform.Rotate(_previewCameraTransform.up * deltaRelativeMovement.x * Time.deltaTime * PREVIEW_SPEED_VERTICAL);                    
                }
                else //Simply rotates camera
                {
                    _previewCameraTransform.RotateAround(Vector3.zero, _previewCameraTransform.up.FlatOneAxis(Axis.x, true), deltaRelativeMovement.x * Time.deltaTime * PREVIEW_SPEED_HORIZONTAL);
                    _previewCameraTransform.RotateAround(Vector3.zero, _previewCameraTransform.right.FlatOneAxis(Axis.y,true), deltaRelativeMovement.y * Time.deltaTime * PREVIEW_SPEED_VERTICAL);

                }
            }
            else if (Event.current.isScrollWheel)
            {
                previewCurrentZoom = Mathf.Clamp01(previewCurrentZoom + Event.current.delta.y * Time.deltaTime * PREVIEW_SPEED_ZOOM);
                _previewCameraTransform.position = -_previewCameraTransform.forward * previewMinMaxZoom.Lerp(previewCurrentZoom);                
            }
            

            //Actual preview draw
            if(modelMesh != null)
            {
                float desiredHeight = 300;
                Rect previewRect = new Rect(0, 0, desiredHeight, desiredHeight);
                previewRenderer.BeginPreview(previewRect, GUIStyle.none);
                Matrix4x4 modelMatrix = Matrix4x4.TRS(Vector3.zero, Quaternion.identity, Vector3.one);
                previewRenderer.DrawMesh(previewMeshFilter.sharedMesh, modelMatrix, previewMeshMaterial, 0);
                previewRenderer.Render();
                Texture tex = previewRenderer.EndPreview();
                DrawTheTexture(tex);
            }
            else
            {
                DrawTheTexture(Texture2D.whiteTexture);
            }
        }
        private void DrawTheTexture(Texture tex)
        {
            float biggerBox = _previewSize + PREVIEW_HORIZONTAL_MARGIN *1.5f;
            GUILayout.Box(Texture2D.whiteTexture, GUILayout.Width(biggerBox), GUILayout.Height(biggerBox));
            //GUI.DrawTexture(new Rect(0, PREVIEW_STARTING_Y_POS - PREVIEW_HORIZONTAL_MARGIN, _previewSize + PREVIEW_HORIZONTAL_MARGIN * 3, _previewSize + PREVIEW_HORIZONTAL_MARGIN * 3), Texture2D.blackTexture, ScaleMode.StretchToFill, false, 1f,Color.black,0,5);
            GUI.DrawTexture(new Rect(PREVIEW_HORIZONTAL_MARGIN, PREVIEW_STARTING_Y_POS+ PREVIEW_HORIZONTAL_MARGIN, _previewSize, _previewSize), tex, ScaleMode.ScaleAndCrop, false, 0f, Color.gray, 0, 5);
        }


        /// <summary>
        /// Resets camera values among other things to conform to the new mesh.
        /// </summary>
        private void ReloadPreviewMeshInfo()
        {
            string toDebug = "Reloading mesh info!";
            try
            {
                previewMeshFilter = modelMesh.GetComponentInChildren<MeshFilter>();
            }
            catch (MissingReferenceException)
            {
                EditorUtility.DisplayDialog("Warning", "The loaded model doesn't have a mesh filter! Shown model will be the default one.", "Accept");
                modelMesh = Resources.Load<GameObject>(DEFAULT_MODEL_NAME);
                previewMeshFilter = modelMesh.GetComponentInChildren<MeshFilter>();
            }            

            MeshRenderer mr = modelMesh.GetComponentInChildren<MeshRenderer>();
            if(mr.sharedMaterial.shader.name == SHADER_NAME)
            {
                previewMeshMaterial = new Material(mr.sharedMaterial);
            }
            else
            {
                previewMeshMaterial = new Material(Resources.Load<Material>(DEFAULT_MATERIAL_NAME));
            }
            Mesh mesh = previewMeshFilter.sharedMesh;
            Bounds bounds = mesh.bounds;
            float maxBound = Mathf.Max(bounds.max.x, bounds.max.y, bounds.max.z, Mathf.Abs(bounds.min.x), Mathf.Abs(bounds.min.y), Mathf.Abs(bounds.min.z)) * 2.5f;
            float hypothenuse = maxBound / Mathf.Sin(_previewCamera.fieldOfView * 0.5f*Mathf.Deg2Rad);
            float cameraDistance = Mathf.Sqrt(hypothenuse * hypothenuse - maxBound * maxBound);
            _previewCameraTransform.position = Vector3.forward * cameraDistance;
            _previewCameraTransform.rotation = _previewLightTransform.rotation = Quaternion.Euler(0,180,0);           
            _previewCamera.farClipPlane = cameraDistance + maxBound * 1.5f;
            float halfDistance = cameraDistance * 0.5f;
            previewMinMaxZoom = new Vector2(halfDistance, cameraDistance + halfDistance);
            previewCurrentZoom = 0.5f;
            //Debug.Log(toDebug + $"\n Max bound {maxBound} and camera distance: {cameraDistance}, min max zoom: {previewMinMaxZoom}");
        }


        #region Gradient Texture
        private ComputeShader gradientMakerCS;
        /// <summary>
        /// The maximum points given to the curve.
        /// \n IF THIS VALUE IS CHANGED, THEN IT NEEDS TO BE DONE TOO IN THE COMPUTE SHADER;
        /// </summary>
        private const int MAX_CURVE_POINTS = 10;
        private Vector4[] curvePointsVector = new Vector4[MAX_CURVE_POINTS];
        private RenderTexture gradientTexture;
        private uint threadGroupX;
        private uint threadGroupY;
        private uint threadGroupZ;
        private float invTextureSize;
        private void InitializeCS()
        {
            invTextureSize = 1f / (float)((int)size);
            gradientMakerCS = Resources.Load<ComputeShader>("CS_GradientTex");
            gradientMakerCS.GetKernelThreadGroupSizes(0, out threadGroupX, out threadGroupY, out threadGroupZ); 

            gradientTexture = new RenderTexture((int)size, 1, 0, RenderTextureFormat.RGB111110Float, RenderTextureReadWrite.Linear); 
            gradientTexture.enableRandomWrite = true;
            gradientTexture.filterMode = FilterMode.Point;
            gradientTexture.wrapMode = TextureWrapMode.Clamp;
            gradientTexture.Create();
            curvePointsVector = new Vector4[MAX_CURVE_POINTS];
        }
        private void UpdateGradientTexture()
        {
            if (modelMesh!=null )
            {
                for (int i = 0; i < myCurve.keys.Length; i++)
                {
                    if (i >= MAX_CURVE_POINTS)
                    {
                        Debug.Log("Wotf it must be max " + MAX_CURVE_POINTS);
                    }

                    curvePointsVector[i].x = myCurve.keys[i].time;
                    curvePointsVector[i].y = myCurve.keys[i].value;
                    //Debug.Log($"For current {i} index, values are {curvePointsVector[i]}");
                }

                gradientMakerCS.SetFloat("maxPoints", Mathf.Min(myCurve.keys.Length, MAX_CURVE_POINTS));
                gradientMakerCS.SetFloat("invTextureSize", invTextureSize);
                gradientMakerCS.SetFloat("snapValue", snapColors?1:0);
                gradientMakerCS.SetFloat("time", Time.realtimeSinceStartup);
                gradientMakerCS.SetVectorArray("curveValues", curvePointsVector);
                gradientMakerCS.SetTexture(0, "outGradient", gradientTexture);

                gradientMakerCS.Dispatch(0, (int)size / (int)threadGroupX, 1, 1);
                previewMeshMaterial.SetTexture("_GradientMainLight", gradientTexture); 

                
            }
        } 
        #endregion

        private void SaveNewTexture(string path)
        {

            int texSize = (int)size;
            Texture2D newTex = new Texture2D(texSize, 1, TextureFormat.RGB24, true, true);
            newTex.filterMode = filterMode;
            newTex.alphaIsTransparency = false;
            newTex.wrapMode = TextureWrapMode.Clamp;
            
            float singleStep = 1f / (float)texSize;
            int currentCurvePoint = 0;
            for (int i = 0; i < texSize; i++)
            {
                float progress = (i+0.5f) * singleStep;
                float valueRemapped;
                if (snapColors)
                {
                    if(myCurve.keys[currentCurvePoint].time > progress)
                    {
                        if(currentCurvePoint == 0) //Hasn't reached first point, so we snap to this incoming point
                        {
                            valueRemapped = myCurve.keys[currentCurvePoint].value;
                        }
                        else // Otherwise snap to the value of the previous point
                        {
                            valueRemapped = myCurve.keys[currentCurvePoint - 1].value;
                        }
                    }
                    else //We're past the last registered point
                    {
                        valueRemapped = myCurve.keys[currentCurvePoint].value;
                        if(currentCurvePoint != myCurve.keys.Length)                        
                        {
                            currentCurvePoint++;
                        }                        
                    }
                }
                else
                {
                    valueRemapped = Mathf.Clamp01(myCurve.Evaluate(progress)); 
                }
                newTex.SetPixel(i, 0, Color.white * valueRemapped);
            }
            File.WriteAllBytes(path, newTex.EncodeToPNG());
            //string testAdress = path.Replace('\\', '/');
            //string localAddress = testAdress.Replace(Application.dataPath, "Assets");
            //Debug.Log($"address full: {testAdress}, data path: {Application.dataPath}, result: {localAddress}");
            //bool itIsDone = false;
            //float preTime = Time.realtimeSinceStartup;
            //int counter = 0;
            //while (!itIsDone)
            //{
            //    Texture2D lolo = AssetDatabase.LoadAssetAtPath<Texture2D>(localAddress);
            //    if(lolo == null)
            //    {
            //        if (Time.realtimeSinceStartup > preTime+10)
            //        {
            //            Debug.Log("F");
            //            break;
            //        }
            //        continue;
            //    }

            //    EditorUtility.SetDirty(lolo);
            //    lolo.wrapMode = TextureWrapMode.Clamp;
            //    Debug.Log(counter);
            //    itIsDone = true;
            //}

            EditorUtility.DisplayDialog("File saved.", "The file was saved successfully! You may need to reload (Ctrl+R) to see it in the Project window.", "Accept.");
            return;

        }

        private void SaveCurrentSettings()
        {
            float[] keyTimes = new float[myCurve.keys.Length];
            float[] keyValues = new float[myCurve.keys.Length];
            for(int i=0; i < keyTimes.Length; i++)
            {
                keyTimes[i] = myCurve.keys[i].time;
                keyValues[i] = myCurve.keys[i].value;
            }
            ToonWindowInfo currentSettings = new ToonWindowInfo(file.FullName, size, filterMode, modelMesh, keyTimes, keyValues);
            string jsoned = JsonUtility.ToJson(currentSettings);
            PlayerPrefs.SetString(SETTINGS_NAME, jsoned);
        }

        private void LoadSettings()
        {
            string jsoned = PlayerPrefs.GetString(SETTINGS_NAME);
            if (string.IsNullOrEmpty(jsoned)) Debug.Log("No settings were found for the toon window");
            else
            {
                ToonWindowInfo info = JsonUtility.FromJson<ToonWindowInfo>(jsoned);
                if (info.KeyTimes!=null && info.KeyTimes.Length!=0)
                {
                    myCurve = new AnimationCurve();

                    for (int i = 0; i < info.KeyTimes.Length; i++)
                    {
                        myCurve.AddKey(info.KeyTimes[i], info.KeyValues[i]);
                        AnimationUtility.SetKeyLeftTangentMode(myCurve, i, AnimationUtility.TangentMode.Linear);
                        AnimationUtility.SetKeyRightTangentMode(myCurve, i, AnimationUtility.TangentMode.Linear);
                        
                    } 
                }
                if(info.ModelUsed == null)
                {
                    Debug.Log("No model was found in the toon window settings. Maybe it was a scene model?");
                }
                else
                {
                    modelMesh = info.ModelUsed;
                }
                filterMode = info.FMode;
                file = new FileInfo(info.FileName);
                size = info.Size;
            }
        }
    }

}