Shader "Hidden/EdgeBevelEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BevelRadius ("Bevel Radius", Range(0.0, 10.0)) = 1.0
        _DepthSensitivity ("Depth Sensitivity", Range(0.01, 1.0)) = 0.1
        // _CameraDepthTexture is supplied by Unity automatically
    }

    CGINCLUDE
    #include "UnityCG.cginc"

    sampler2D _MainTex;
    float _BevelRadius;
    float _DepthSensitivity;
    sampler2D _CameraDepthTexture;
    float4 _MainTex_TexelSize; // xy = 1/width, 1/height; zw = width, height

    struct appdata_img
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct v2f_img
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    v2f_img vert(appdata_img v)
    {
        v2f_img o;
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv = v.uv; // Using non-adjusted UVs here, will adjust in frag
        return o;
    }

    fixed4 frag(v2f_img i) : SV_Target
    {
        float2 texelSize = _MainTex_TexelSize.xy;
        // Adjust UVs for stereo rendering once. Used for all subsequent sampling.
        float2 uv = UnityStereoScreenSpaceUVAdjust(i.uv, _MainTex_TexelSize);

        // --- 1. Edge Detection using Depth Buffer ---
        // Sample depth of current pixel and its direct neighbors, then convert to linear depth.
        // Using the pre-adjusted 'uv' for consistent stereo rendering.
        float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
        float depthUp = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv + float2(0, texelSize.y)));
        float depthDown = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv - float2(0, texelSize.y)));
        float depthLeft = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv - float2(texelSize.x, 0)));
        float depthRight = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv + float2(texelSize.x, 0)));
        
        // Determine if it's an edge by comparing depth differences against sensitivity.
        // An edge is detected if the depth difference with any direct neighbor exceeds _DepthSensitivity.
        bool isEdge = (abs(depth - depthUp) > _DepthSensitivity) ||
                      (abs(depth - depthDown) > _DepthSensitivity) ||
                      (abs(depth - depthLeft) > _DepthSensitivity) ||
                      (abs(depth - depthRight) > _DepthSensitivity);

        if (isEdge)
        {
            // --- 2. Apply Bevel/Smoothing Effect via Blur ---
            // For edge pixels, calculate a blurred color by averaging with neighbors.
            // This creates the "bevel" or "smoothing" effect.

            fixed4 accumulatedColor = tex2D(_MainTex, uv); // Start with current pixel's color.
            int sampleCount = 1;

            // Define sample offsets for cardinal directions (scaled by _BevelRadius).
            // _BevelRadius = 0 means offsets are (0,0), effectively no blur.
            // _BevelRadius = 1 samples immediate neighbors.
            float2 cardinalOffsets[4];
            cardinalOffsets[0] = float2(0, texelSize.y * _BevelRadius);   // Up
            cardinalOffsets[1] = float2(0, -texelSize.y * _BevelRadius);  // Down
            cardinalOffsets[2] = float2(-texelSize.x * _BevelRadius, 0); // Left
            cardinalOffsets[3] = float2(texelSize.x * _BevelRadius, 0);  // Right
            
            // Sample cardinal directions.
            // Loop is unrolled by compiler; using a 'for' loop for conciseness here.
            for (int c = 0; c < 4; c++) {
                accumulatedColor += tex2D(_MainTex, uv + cardinalOffsets[c]);
                sampleCount++;
            }

            // Define sample offsets for diagonal directions (scaled by _BevelRadius).
            float2 diagonalOffsets[4];
            diagonalOffsets[0] = float2(texelSize.x * _BevelRadius, texelSize.y * _BevelRadius);   // North-East
            diagonalOffsets[1] = float2(-texelSize.x * _BevelRadius, texelSize.y * _BevelRadius);  // North-West
            diagonalOffsets[2] = float2(texelSize.x * _BevelRadius, -texelSize.y * _BevelRadius);  // South-East
            diagonalOffsets[3] = float2(-texelSize.x * _BevelRadius, -texelSize.y * _BevelRadius); // South-West
            
            // Sample diagonal directions.
            for (int d = 0; d < 4; d++) {
                accumulatedColor += tex2D(_MainTex, uv + diagonalOffsets[d]);
                sampleCount++;
            }

            return accumulatedColor / sampleCount; // Return blurred color for edge pixels.
        }
        else
        {
            // Not an edge, return original pixel color.
            return tex2D(_MainTex, uv);
        }
    }
    ENDCG

    SubShader
    {
        Pass
        {
            ZTest Always Cull Off ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
    Fallback Off
}
