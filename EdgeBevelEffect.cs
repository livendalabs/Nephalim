using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class EdgeBevelEffect : MonoBehaviour
{
    public Shader edgeBevelShader;
    private Material effectMaterial;

    [Range(0.0f, 10.0f)]
    public float bevelRadius = 1.0f;

    [Range(0.001f, 1.0f)] // Min changed to 0.001f
    public float depthSensitivity = 0.1f;

    void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (edgeBevelShader == null)
        {
            Debug.LogError("EdgeBevelEffect: Shader not assigned!");
            enabled = false;
            Graphics.Blit(source, destination); // Pass through image if shader is missing
            return;
        }

        if (effectMaterial == null)
        {
            effectMaterial = new Material(edgeBevelShader);
            if (!edgeBevelShader.isSupported)
            {
                Debug.LogError("EdgeBevelEffect: Shader is not supported on this hardware!");
                enabled = false;
                Graphics.Blit(source, destination); // Pass through image
                return;
            }
        }

        effectMaterial.SetFloat("_BevelRadius", bevelRadius);
        effectMaterial.SetFloat("_DepthSensitivity", depthSensitivity);

        Graphics.Blit(source, destination, effectMaterial);
    }

    void OnDisable()
    {
        if (effectMaterial != null)
        {
            DestroyImmediate(effectMaterial);
        }
    }
}
