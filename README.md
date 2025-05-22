# Edge Bevel Post-Processing Effect for Unity

`EdgeBevelEffect` is a screen-space post-processing effect for Unity that detects and smooths sharp edges in a scene based on depth differences. This can help reduce the harshness of polygonal edges and give a softer, more stylized look.

## Files

*   `EdgeBevelEffect.cs`: The C# script that manages the effect and interfaces with the Unity camera.
*   `EdgeBevel.shader`: The shader that performs the edge detection and beveling.

## I. Usage Instructions

1.  **Create the Shader File:**
    *   In your Unity Project window, right-click and select `Create -> Shader -> Unlit Shader` (or any basic shader type, as you'll replace the content).
    *   Name the new shader file `EdgeBevel.shader` (ensure the name matches exactly, or update the reference in the C# script if you choose a different name).
    *   Open the created `.shader` file and replace its entire content with the code provided for `EdgeBevel.shader`.

2.  **Create the C# Script:**
    *   In your Unity Project window, right-click and select `Create -> C# Script`.
    *   Name the script `EdgeBevelEffect.cs`.
    *   Open the script file and replace its entire content with the code provided for `EdgeBevelEffect.cs`.

3.  **Apply the Effect to a Camera:**
    *   Select the Camera object in your scene that you want to apply the effect to.
    *   In the Inspector for the Camera, click `Add Component`.
    *   Search for `EdgeBevelEffect` (the name of your C# script) and add it.
    *   In the `Edge Bevel Effect` component that now appears in the Camera's Inspector:
        *   Drag your `EdgeBevel.shader` file from the Project window to the `Edge Bevel Shader` slot.

4.  **Adjust Parameters:**
    The following parameters are available on the `EdgeBevelEffect` component in the Inspector:

    *   **`Bevel Radius`**: Controls the "thickness" or extent of the smoothing along detected edges.
        *   Range: `0.0` to `10.0`
        *   Default: `1.0`
        *   A value of `0` should result in no visible smoothing (sharp edges will remain sharp, though the edge detection pass still runs).
        *   Small values (e.g., `0.5` to `1.5`) will give a subtle softening.
        *   Larger values will create a more pronounced, wider blur along edges. Experiment to find the desired look.

    *   **`Depth Sensitivity`**: Determines how different the depth of adjacent pixels must be to be considered an edge.
        *   Range: `0.001` to `1.0`
        *   Default: `0.1`
        *   Lower values (e.g., `0.001` to `0.05`) make the effect more sensitive to smaller depth changes, detecting more subtle edges (potentially including more surface details).
        *   Higher values (e.g., `0.1` to `1.0`) will only detect more significant depth discontinuities (e.g., object silhouettes or major changes in geometry).
        *   Adjust this based on your scene's scale and the desired level of edge detection.

## II. Testing Guidelines

1.  **Scene Setup:**
    *   Test on a variety of scenes:
        *   Scenes with sharp geometric shapes (e.g., cubes, stairs, primitives) to clearly observe the bevel/smoothing effect.
        *   Scenes with complex organic models and varying depth levels.
        *   Scenes with different lighting conditions (though this effect is primarily screen-space and depth-based, lighting can affect overall visual perception).

2.  **Parameter Adjustments:**
    *   **`Bevel Radius`**:
        *   Start at `0` and incrementally increase it to its maximum value. Observe how the edge smoothing width and intensity change.
        *   Verify that `Bevel Radius = 0` results in no visual smoothing (the image should look as if the effect is disabled, aside from any minor performance overhead of the edge detection pass).
    *   **`Depth Sensitivity`**:
        *   Test very low values (e.g., `0.001`). Observe if it picks up too many internal edges on flat or slightly curved surfaces, or noise in the depth buffer.
        *   Test very high values (e.g., `1.0`). Observe if it only picks up major object outlines and misses finer edge details.
        *   Adjust to find a balance that captures the desired edges for your scene.

3.  **Performance:**
    *   Open the Unity Profiler (`Window -> Analysis -> Profiler`).
    *   Monitor CPU usage (specifically calls related to `Camera.OnRenderImage` and `Graphics.Blit` for this effect) and GPU usage.
    *   Enable and disable the `EdgeBevelEffect` component on the Camera to measure its performance impact.
    *   Test on your target hardware if possible, as performance characteristics can vary significantly. The effect involves multiple texture samples for each edge pixel, which can be demanding on lower-end hardware.

4.  **Visual Artifacts:**
    *   Look for any unwanted visual artifacts, such as:
        *   Edges appearing overly blurry or, conversely, not smooth enough for the desired effect.
        *   Flickering or unstable edges, particularly with small or thin objects, or during camera movement and animation.
        *   Incorrect smoothing or interaction with transparent objects. This effect primarily relies on the opaque depth buffer, so transparent objects might not be correctly beveled or might cause visual discrepancies.
        *   Issues at screen edges (e.g., bevels appearing cut off or behaving differently).

5.  **Compatibility:**
    *   **Rendering Paths:** If your project might use different rendering paths, test in both Forward and Deferred rendering modes (configurable in `Project Settings -> Graphics`). The effect is designed to be compatible with both, but practical testing is recommended.
    *   **Anti-Aliasing:** Test with different anti-aliasing settings in Unity (e.g., MSAA, or post-processing AA like FXAA/SMAA if used). Observe how this effect interacts with other AA solutions. This effect itself provides a form of edge smoothing.

6.  **Stereo Rendering (VR/AR):**
    *   If VR or AR is a target platform, test the effect in a stereo rendering environment. The shader includes `UnityStereoScreenSpaceUVAdjust` to handle UV adjustments for stereo, but visual confirmation of correct behavior in both eyes is crucial. Look for depth inconsistencies or eye-strain issues.

## III. How it Works (Brief Overview)

The `EdgeBevelEffect` is a screen-space post-processing effect that smooths sharp edges in a scene. It operates in two main steps after the scene has been rendered to a texture:

1.  **Edge Detection:**
    The effect's shader first analyzes the scene's depth buffer (provided by Unity as `_CameraDepthTexture`). For each pixel on the screen, it compares its depth value with the depth values of its immediate neighbors (up, down, left, right). If the difference in depth between the current pixel and any of its neighbors is greater than the `Depth Sensitivity` threshold, that pixel is marked as being part of an edge.

2.  **Edge Smoothing (Beveling):**
    Once a pixel is identified as part of an edge, the shader applies a localized blur to it. It samples the colors of the pixels in a small neighborhood around the edge pixel (including 4 cardinal and 4 diagonal neighbors). The size of this sampling neighborhood and the distance of the samples from the central edge pixel are determined by the `Bevel Radius` parameter. The colors sampled from this neighborhood are then averaged together. This averaged color becomes the new color for the edge pixel, resulting in a softer, smoother appearance. Pixels that were not identified as edges are left unchanged and display their original rendered color.

This technique provides a real-time method to reduce the visual harshness of sharp polygonal edges and can contribute to a more stylized or polished visual presentation without requiring modifications to the underlying 3D geometry.
