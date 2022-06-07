using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
/// <summary>
/// Contains transformation local to a single Spline
/// </summary>
public struct SplineTransformation 
{
    
    #region Variables
    /// <summary>
    /// The type of transformation
    /// </summary>
    public TransformationType transformation;

    /// <summary>
    /// The intensity to apply to this transformation
    /// </summary>
    public float Value;

    /// <summary>
    /// The curve at which the value will be applied along the curve
    /// </summary>
    public AnimationCurve Curve;

    
    #endregion
    #region Methods
    /// <summary>
    /// Computes the local transformation matrix corresponding to the parameters
    /// </summary>
    /// <param name="ratio">The reference "percentage" to query on the curve</param>
    /// <returns>The local matrix</returns>
    public Matrix4x4 GetMatrix(float ratio)
    {
        
        float modulatedIntensity = Curve.Evaluate(ratio) * Value;
        switch (transformation)
        {
            case TransformationType.Offset:
                return Matrix4x4.TRS(Vector3.right*Value* modulatedIntensity, Quaternion.identity, Vector3.one);
            case TransformationType.Rotation:
                return Matrix4x4.TRS(Vector3.zero, Quaternion.Euler(0f, 0f, (modulatedIntensity*Value) % 360), Vector3.one);
            case TransformationType.SinWave:
                return Matrix4x4.TRS(Mathf.Sin(Value*ratio)*modulatedIntensity*Vector3.up, Quaternion.identity, Vector3.one);
            default:
                return Matrix4x4.identity;
        }
    }


    #endregion

}
