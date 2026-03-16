# Flutter Porting Analysis: Ensemble Voting vs. ABCD Algorithms

This document summarizes the analysis of porting the Python-based Ensemble Voting system and ABCD algorithms to a Flutter/Dart environment.

## 1. Difficulty Comparison

| Feature | Ensemble Voting (PyTorch -> Flutter) | ABCD Algorithms (Python -> Dart) |
| :--- | :--- | :--- |
| **Core Logic** | **Easy (Model Export)**<br>Voting logic is simple (averaging probabilities). The heavy lifting is done by the model execution engine (ONNX/TFLite). | **Hard (Re-implementation)**<br>Complex geometric and statistical logic (`convex_hull`, `find_contours`, `moments`) must be rewritten or adapted from libraries. |
| **Preprocessing** | **Very Hard (Filter Consistency)**<br>Models require *exact* pixel-level matches for inputs (e.g., Gabor 40ch, GLCM 32ch). Replicating `skimage` specific implementations in Dart to match training data is mathematically complex and error-prone. | **Medium (Image Ops)**<br>Most operations (resize, threshold, contour) have direct equivalents in `opencv_dart` or the `image` package. |
| **Performance** | **High Risk**<br>Computing complex filters (GLCM/Gabor) on high-res images in Dart can be slow without optimized C++ FFI. | **Manageable**<br>Most ABCD steps are efficient (masking, simple stats). The heavy geometric steps are fast enough on modern mobile devices. |
| **Dependencies** | **Complex**<br>Requires `onnxruntime` or `tflite_flutter` plus a robust image processing library. | **Moderate**<br>Requires `ml_linalg` (for matrix math) and `opencv_dart` (for contours/hulls). |

## 2. Ensemble Voting Porting Strategy

### A. Model Export
- **Action**: Export existing PyTorch models to ONNX format.
- **Proof of Concept**: A script `python/ensemble_voting/model_exporter.py` has been created to demonstrate exporting RGB, Gabor (40ch), LBP (1ch), and GLCM (32ch) models.
- **Recommendation**: Use ONNX Runtime for Flutter to load and run these models.

### B. Inference & Input Generation
The primary challenge is generating input tensors on the mobile device that match the Python training data exactly.

1.  **RGB Images (3D Input)**:
    - Straightforward conversion of `CameraImage` or `File` to `Uint8List`.
    - Normalization: Apply mean/std normalization typical for ResNet (e.g., `mean=[0.485, 0.456, 0.406]`).
    - Flatten to `Float32List`.

2.  **LBP Filtered Image (2D Input)**:
    - **Challenge**: Must match `skimage.feature.local_binary_pattern` "uniform" method.
    - **Implementation**: Write a Dart function to iterate pixels, compare 8 neighbors to center, and map the resulting bit-string to uniform codes via a lookup table.

3.  **Gabor Filters (40 Channels)**:
    - **Challenge**: The model expects a bank of filters (e.g., 5 frequencies $\times$ 8 orientations).
    - **Implementation**: Use `opencv_dart` wrappers for `getGaborKernel` and `filter2D`. Generate 40 response maps and stack them into a single tensor.

4.  **GLCM Filters (32 Channels)**:
    - **Challenge**: High dimensionality (32 channels) typically implies a sliding window computing texture features per pixel.
    - **Risk**: Implementing sliding window GLCM in pure Dart is computationally expensive.
    - **Recommendation**: Use C++ FFI via OpenCV to compute these features if possible, or retrain models on simpler features that are easier to compute on mobile.

## 3. ABCD Algorithms Porting Strategy

Porting the logic from `asymmetry_scorer.py`, `border_scorer.py`, and others requires mapping `numpy` and `scikit-image` functions to Dart.

### Native Matrix Manipulations (Dart)
Instead of importing a heavy linear algebra library, targeted implementations are often sufficient:

- **Basic Stats**: Implement helper functions for `mean`, `std_dev`, and `sum` operating on `Float32List`.
- **Arrays**: Use `List.generate` or `Float32List` for vector operations.
- **Masking**: Implement logical operations (AND, OR, XOR) as loops over boolean lists.

### Geometric Complexity
Do **not** attempt to implement complex geometric algorithms manually.

- **Contours & Convex Hulls**: Use `opencv_dart` bindings.
- **Moments & Rotation**: Use `cv2.moments` to calculate the principal axis for the Asymmetry score, replacing the `skimage.measure.regionprops` logic.
- **Morphology**: Use OpenCV for dilation/erosion/closing to clean masks (hair removal step).

## 4. Conclusion
- **Ensemble Voting** is feasible but carries **high technical risk** regarding the fidelity of the texture filters (Gabor/GLCM). If the mobile implementation of these filters drifts even slightly from the Python version, model accuracy will collapse.
- **ABCD Algorithms** require more coding effort to port logic but are **lower risk** because the underlying operations (contours, moments) are standard computer vision tasks well-supported by mobile libraries.

