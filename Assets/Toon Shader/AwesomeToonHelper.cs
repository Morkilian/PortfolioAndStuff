

/*
 * Modified script, original made by SnutiHQ https://github.com/SnutiHQ/Toon-Shader/tree/master/Awesome%20Toon
 */


//using Aura2API;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AwesomeToon {
    [System.Serializable]
    struct LightSet {
        public int id;
        public Light light;
        public Vector3 dir;
        public Color color;
        public float atten;
        public float inView;

        public LightSet(Light newLight) {
            light = newLight;
            id = newLight.GetInstanceID();
            dir = Vector3.zero;
            color = Color.black;
            color.a = 0.01f;
            atten = 0f;
            inView = 1.1f; // Range -0.1 to 1.1 which is clamped 0-1 for faster consistent fade
        }
    }

    [ExecuteInEditMode]
    public class AwesomeToonHelper : MonoBehaviour {

        // Params
        [SerializeField] Material material = null;
        [SerializeField] Texture2D defaultGradient = null;
        [SerializeField] public float intensitySimulated = 30;
        [SerializeField] bool instanceMaterial = true;
        [SerializeField] Vector3 meshCenter = Vector3.zero;
        [SerializeField] int maxLights = 6;

        [Header("Recieve Shadow Check")]
        [SerializeField] bool raycast = true;
        [SerializeField] LayerMask raycastMask = new LayerMask();
        [SerializeField] float raycastFadeSpeed = 10f;

        // State
        Vector3 posAbs;
        Dictionary<int, LightSet> lightSets;

        // Refs
        Material materialInstance;
        SkinnedMeshRenderer skinRenderer;
        MeshRenderer meshRenderer;
        List<LightSet> sortedLights = new List<LightSet>();

        void Start() {
            Init();
            GetLights();
        }

        void OnValidate() {
            Init();
            Update();
        }

        void Init() {
            if (!material) return;
            if (instanceMaterial) {
                materialInstance = new Material(material);
                materialInstance.name = "Instance of " + material.name;
            } else {
                materialInstance = material;
            }

            skinRenderer = GetComponent<SkinnedMeshRenderer>();
            meshRenderer = GetComponent<MeshRenderer>();
            if (skinRenderer) skinRenderer.sharedMaterial = materialInstance;
            if (meshRenderer) meshRenderer.sharedMaterial = materialInstance;
        }

        // NOTE: If your game loads lights dynamically, this should be called to init new lights
        public void GetLights() {
            if (lightSets == null) {
                lightSets = new Dictionary<int, LightSet>();
            }

            Light[] lights = FindObjectsOfType<Light>();
            List<int> newIds = new List<int>();

            // Initialise new lights
            foreach (Light light in lights) {
                int id = light.GetInstanceID();
                newIds.Add(id);
                if (!lightSets.ContainsKey(id)) {
                    lightSets.Add(id, new LightSet(light));
                }
            }

            // Remove old lights
            List<int> oldIds = new List<int>(lightSets.Keys);
            foreach (int id in oldIds) {
                if (!newIds.Contains(id)) {
                    lightSets.Remove(id);
                }
            }
        }

        void Update() {
            posAbs = transform.position + meshCenter;

            // Always update lighting while in editor
            if (Application.isEditor && !Application.isPlaying) {
                GetLights();
            }

            UpdateMaterial();
        }

        void UpdateMaterial() {
            if (!material) return;

            // Refresh light data
            sortedLights = new List<LightSet>();
            if (lightSets != null) {
                foreach (LightSet lightSet in lightSets.Values) 
                {
                    if(lightSet.light.enabled && lightSet.light.gameObject.activeSelf == true)
                    sortedLights.Add(CalcLight(lightSet));
                }
            }

            // Sort lights by brightness
            sortedLights.Sort((x, y) => {
                float yBrightness = y.color.grayscale * y.atten;
                float xBrightness = x.color.grayscale * x.atten;
                return yBrightness.CompareTo(xBrightness);
            });

            // Apply lighting
            int i = 1;
            foreach (LightSet lightSet in sortedLights) {
                if (i > maxLights) break;
                if (lightSet.atten <= Mathf.Epsilon) break;

                // Use color Alpha to pass attenuation data
                Color color = lightSet.color;
                //color.a = lightSet.light.type == LightType.Directional ? 0 : (lightSet.light.type == LightType.Point ? 1 : 2);
                color.a = Mathf.Clamp(lightSet.atten, 0.01f, 0.99f); // UV might wrap around if attenuation is >1 or 0<
                Vector4 dir = lightSet.dir.normalized;
                dir.w = lightSet.light.type == LightType.Directional ? 0 : (lightSet.light.type == LightType.Point ? 1 : 2);
                materialInstance.SetVector($"_L{i}_dir", dir);
                materialInstance.SetColor($"_L{i}_color", color);

                materialInstance.SetVector($"_L{i}_customInfo", new Vector4(lightSet.light.transform.position.x,
                    lightSet.light.transform.position.y, lightSet.light.transform.position.z, lightSet.light.range));
                

                i++;
            }

            materialInstance.SetFloat("_lightsAmount", i-1);
            // Turn off the remaining light slots
            while (i <= maxLights) {
                materialInstance.SetVector($"_L{i}_dir", Vector3.up);
                materialInstance.SetVector($"_L{i}_customInfo", Vector3.one*999);
                materialInstance.SetColor($"_L{i}_color", Color.black);
                i++;
            }

            // Store updated light data
            foreach (LightSet lightSet in sortedLights) {
                lightSets[lightSet.id] = lightSet;
            }
        }

        LightSet CalcLight(LightSet lightSet) {
            Light light = lightSet.light;
            float inView = 1.1f;
            float dist;

            if (!light.isActiveAndEnabled) {
                lightSet.atten = 0f;
                return lightSet;
            }

            switch (light.type) {
                case LightType.Directional:
                    lightSet.dir = light.transform.forward * -1f;
                    inView = TestInView(lightSet.dir, 100f);
                    lightSet.color = light.color * light.intensity;
                    lightSet.atten = 1f;
                    break;

                case LightType.Point:
                    lightSet.dir = light.transform.position - posAbs;
                    dist = ClosestDistance(meshRenderer, light.transform.position)/light.range;
                    //dist = Mathf.Clamp01(lightSet.dir.magnitude / light.range);
                    inView = TestInView(lightSet.dir, lightSet.dir.magnitude);
                    lightSet.atten = CalcAttenuation(dist);
                    lightSet.color = light.color * lightSet.atten * light.intensity * 0.1f * intensitySimulated;
                    break;

                case LightType.Spot:
                    lightSet.dir = light.transform.position*-1f;
                    dist = Mathf.Clamp01(lightSet.dir.magnitude / light.range);
                    float angle = Vector3.Angle(light.transform.forward * -1f, lightSet.dir.normalized);
                    float inFront = Mathf.Lerp(0f, 1f, (light.spotAngle - angle * 2f) / lightSet.dir.magnitude); // More edge fade when far away from light source
                    inView = inFront * TestInView(lightSet.dir, lightSet.dir.magnitude);
                    lightSet.atten = CalcAttenuation(dist);
                    lightSet.color = light.color * lightSet.atten * light.intensity * 0.05f * intensitySimulated;
                    break;

                default:
                    Debug.Log("Lighting type '" + light.type + "' not supported by Awesome Toon Helper (" + light.name + ").");
                    lightSet.atten = 0f;
                    break;
            }

            // Slowly fade lights on and off
            float fadeSpeed = (Application.isEditor && !Application.isPlaying)
                ? raycastFadeSpeed / 60f
                : raycastFadeSpeed * Time.deltaTime;

            lightSet.inView = Mathf.Lerp(lightSet.inView, inView, fadeSpeed);
            lightSet.color *= Mathf.Clamp01(lightSet.inView);

            return lightSet;
        }

        float TestInView(Vector3 dir, float dist) {
            if (!raycast) return 1.1f;
            RaycastHit hit;
            if (Physics.Raycast(posAbs, dir, out hit, dist, raycastMask)) {
                Debug.DrawRay(posAbs, dir.normalized * hit.distance, Color.red);
                return -0.1f;
            } else {
                Debug.DrawRay(posAbs, dir.normalized * dist, Color.green);
                return 1.1f;
            }
        }

        // Ref - Light Attenuation calc: https://forum.unity.com/threads/light-attentuation-equation.16006/#post-3354254
        float CalcAttenuation(float dist) {
            return Mathf.Clamp01(1.0f / (1.0f + 25f * dist * dist) * Mathf.Clamp01((1f - dist) * 5f));
        }

        float ClosestDistance(Renderer rend, Vector3 comparisonPoint)
        {
            Vector3 closestPoint = transform.position + meshCenter;
            float sqrToMiddle = Vector3.SqrMagnitude(comparisonPoint - (transform.position + meshCenter));
            return Vector3.Distance(rend.bounds.ClosestPoint(comparisonPoint), comparisonPoint);
        }

        private void OnDrawGizmosSelected() {
            Gizmos.DrawWireSphere(posAbs, 0.1f);
        }
    }
}
