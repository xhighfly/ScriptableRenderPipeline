#ifndef UNITY_SHADER_VARIABLES_FUNCTIONS_INCLUDED
#define UNITY_SHADER_VARIABLES_FUNCTIONS_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

// This function always return the absolute position in WS
float3 GetAbsolutePositionWS(float3 positionRWS)
{
#if (SHADEROPTIONS_CAMERA_RELATIVE_RENDERING != 0)
    positionRWS += GetWorldSpaceCameraPos();
#endif
    return positionRWS;
}

// This function return the camera relative position in WS
float3 GetCameraRelativePositionWS(float3 positionWS)
{
#if (SHADEROPTIONS_CAMERA_RELATIVE_RENDERING != 0)
    positionWS -= GetWorldSpaceCameraPos();
#endif
    return positionWS;
}

// Return absolute world position of current object
float3 GetObjectAbsolutePositionWS()
{
    float4x4 modelMatrix = UNITY_MATRIX_M;
    return GetAbsolutePositionWS(modelMatrix._m03_m13_m23); // Translation object to world
}

float3 GetPrimaryCameraPosition()
{
#if (SHADEROPTIONS_CAMERA_RELATIVE_RENDERING != 0)
    return float3(0, 0, 0);
#else
    return GetWorldSpaceCameraPos();
#endif
}

// Could be e.g. the position of a primary camera or a shadow-casting light.
float3 GetCurrentViewPosition()
{
#if (defined(SHADERPASS) && (SHADERPASS != SHADERPASS_SHADOWS)) && (!UNITY_SINGLE_PASS_STEREO) // Can't use camera position when rendering stereo
    return GetPrimaryCameraPosition();
#else
    // This is a generic solution.
    // However, using '_WorldSpaceCameraPos' is better for cache locality,
    // and in case we enable camera-relative rendering, we can statically set the position is 0.
    return UNITY_MATRIX_I_V._14_24_34;
#endif
}

// Returns the forward (central) direction of the current view in the world space.
float3 GetViewForwardDir()
{
    float4x4 viewMat = GetWorldToViewMatrix();
    return -viewMat[2].xyz;
}

// Returns 'true' if the current view performs a perspective projection.
bool IsPerspectiveProjection()
{
#if defined(SHADERPASS) && (SHADERPASS != SHADERPASS_SHADOWS)
    return (unity_OrthoParams.w == 0);
#else
    // This is a generic solution.
    // However, using 'unity_OrthoParams' is better for cache locality.
    // TODO: set 'unity_OrthoParams' during the shadow pass.
    return UNITY_MATRIX_P[3][3] == 0;
#endif
}

// Computes the world space view direction (pointing towards the viewer).
float3 GetWorldSpaceViewDir(float3 positionRWS)
{
    if (IsPerspectiveProjection())
    {
        // Perspective
        return GetCurrentViewPosition() - positionRWS;
    }
    else
    {
        // Orthographic
        return -GetViewForwardDir();
    }
}

float3 GetWorldSpaceNormalizeViewDir(float3 positionRWS)
{
    return normalize(GetWorldSpaceViewDir(positionRWS));
}

// UNITY_MATRIX_V defines a right-handed view space with the Z axis pointing towards the viewer.
// This function reverses the direction of the Z axis (so that it points forward),
// making the view space coordinate system left-handed.
void GetLeftHandedViewSpaceMatrices(out float4x4 viewMatrix, out float4x4 projMatrix)
{
    viewMatrix = UNITY_MATRIX_V;
    viewMatrix._31_32_33_34 = -viewMatrix._31_32_33_34;

    projMatrix = UNITY_MATRIX_P;
    projMatrix._13_23_33_43 = -projMatrix._13_23_33_43;
}

// This method should be used for rendering any full screen quad that uses an auto-scaling Render Targets (see RTHandle/HDCamera)
// It will account for the fact that the textures it samples are not necesarry using the full space of the render texture but only a partial viewport.
float2 GetNormalizedFullScreenTriangleTexCoord(uint vertexID)
{
    return GetFullScreenTriangleTexCoord(vertexID) * _ScreenToTargetScale.xy;
}

// The size of the render target can be larger than the size of the viewport.
// This function returns the fraction of the render target covered by the viewport:
// ViewportScale = ViewportResolution / RenderTargetResolution.
// Do not assume that their size is the same, or that sampling outside of the viewport returns 0.
float2 GetViewportScaleCurrentFrame()
{
    return _ScreenToTargetScale.xy;
}

float2 GetViewportScalePreviousFrame()
{
    return _ScreenToTargetScale.zw;
}

float4 SampleSkyTexture(float3 texCoord, int sliceIndex)
{
    return SAMPLE_TEXTURECUBE_ARRAY(_SkyTexture, s_trilinear_clamp_sampler, texCoord, sliceIndex);
}

float4 SampleSkyTexture(float3 texCoord, float lod, int sliceIndex)
{
    return SAMPLE_TEXTURECUBE_ARRAY_LOD(_SkyTexture, s_trilinear_clamp_sampler, texCoord, sliceIndex, lod);
}

float2 TexCoordStereoOffset(float2 texCoord)
{
#if defined(UNITY_SINGLE_PASS_STEREO)
    return texCoord + float2(GetStereoEyeIndex() * _ScreenSize.x, 0.0);
#endif
    return texCoord;
}
#endif // UNITY_SHADER_VARIABLES_FUNCTIONS_INCLUDED
