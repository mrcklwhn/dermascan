import 'dart:convert';

import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/enums.dart';
import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HumanBody3DController extends GetxController {
  final void Function(BodyLesion lesion) onPointAdded;
  final BuildContext buildContext;
  final RxList<BodyLesion> lesions;
  final RxnString selectedPosition;
  final void Function()? onModelLoaded;
  final Gender gender;

  late final WebViewController webViewController;
  final RxBool isModelReady = false.obs;

  Worker? _lesionWorker;
  Worker? _selectionWorker;

  bool _isSyncing = false;
  bool _needsSyncAgain = false;

  HumanBody3DController({
    required this.onPointAdded,
    required this.lesions,
    required this.selectedPosition,
    required this.gender,
    required this.buildContext,
    this.onModelLoaded,
  });

  @override
  void onInit() {
    super.onInit();
    _initializeWebView(buildContext);

    _lesionWorker = ever(lesions, (_) => _syncAllHotspots(buildContext));
    _selectionWorker = ever(selectedPosition, (_) => _syncAllHotspots(buildContext));
  }

  @override
  void onClose() {
    _lesionWorker?.dispose();
    _selectionWorker?.dispose();
    super.onClose();
  }

  void _initializeWebView(BuildContext context) {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) => _handleJavaScriptMessage(context, message),
      )
      ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
        if (message.message.contains(
          'Ignored attempt to cancel a touch move event',
        )) {
          return;
        }
        debugPrint('JS Console: [${message.level.name}] ${message.message}');
      })
      ..loadHtmlString(_buildHtml());
  }

  Future<void> resetModelPosition() async {
    if (!isModelReady.value) return;

    final String resetScript = '''
      (function() {
        const viewer = document.getElementById('viewer');
        if (!viewer) return;
        
        viewer.cameraOrbit = 'unset';
        viewer.cameraTarget = '0m 0.3m 0m'; 
        viewer.fieldOfView = 'unset';
        
      })();
    ''';

    await webViewController.runJavaScript(resetScript);
  }

  Future<void> _handleJavaScriptMessage(BuildContext context, JavaScriptMessage message) async {
    try {
      final Map<String, dynamic> data = jsonDecode(message.message);
      final String type = data['type'] ?? '';

      if (type == 'MODEL_LOADED') {
        isModelReady.value = true;
        onModelLoaded?.call();
        await _syncAllHotspots(context);
        return;
      }

      final String? position = data['position'];

      if (type == 'HOTSPOT_CLICKED') {
        if (position == null) return;
        final BodyLesion? lesion = lesions.firstWhereOrNull(
          (BodyLesion l) => l.position == position,
        );
        if (lesion != null) {
          selectedPosition.value = lesion.position;
          onPointAdded(lesion);
        }
        return;
      }

      if (type == 'POINT_CLICKED') {
        final BodyLesion newLesion = BodyLesion(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          position: data['position'] ?? '',
          normal: data['normal'] ?? '',
          patientId: '',
          diagnoses: <Diagnosis>[].obs,
          isSuspicious: false.obs,
          wasRemoved: false.obs,
          notes: '',
          locationName: '',
        );

        selectedPosition.value = newLesion.position;
        onPointAdded(newLesion);
      }
    } catch (error, stackTrace) {
      debugPrint('HumanBody3DSelector error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _syncAllHotspots(BuildContext context) async {
    if (!isModelReady.value) return;

    if (_isSyncing) {
      _needsSyncAgain = true;
      return;
    }

    _isSyncing = true;

    try {
      do {
        _needsSyncAgain = false;

        final List<BodyLesion> snapshot = lesions.toList();

        for (final BodyLesion lesion in snapshot) {
          await _injectOrUpdateHotspot(context, lesion);
        }

        await _cleanupOldHotspots(snapshot);
      } while (_needsSyncAgain);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _injectOrUpdateHotspot(BuildContext context, BodyLesion lesion) async {
    final bool isSelected = selectedPosition.value == lesion.position;
    final bool isSuspicious = lesion.isSuspicious.value;
    final bool wasRemoved = lesion.wasRemoved.value;

    final Color displayColor = wasRemoved
        ? Colors.grey
        : (isSuspicious
              ? Colors.red
              : (isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary));

    final String colorHex =
        '#${displayColor.toARGB32().toRadixString(16).substring(2)}';
    final String safePosition = jsonEncode(lesion.position);
    final String safeNormal = jsonEncode(lesion.normal);

    final String script =
        '''
      (function () {
        const viewer = document.getElementById('viewer');
        if (!viewer) return;

        const posVal = $safePosition;
        const normVal = $safeNormal;
        const hotspotSelector = 'div[data-position="' + posVal + '"]';
        let hotspot = viewer.querySelector(hotspotSelector);

        if (!hotspot) {
          hotspot = document.createElement('div');
          hotspot.className = 'hotspot-dot';
          hotspot.slot = 'hotspot-' + posVal.replace(/[^a-zA-Z0-9]/g, '-');
          hotspot.dataset.position = posVal;
          hotspot.dataset.normal = normVal;

          hotspot.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopPropagation();
            window.FlutterChannel.postMessage(JSON.stringify({
              type: 'HOTSPOT_CLICKED',
              position: hotspot.dataset.position
            }));
          }, true);
          viewer.appendChild(hotspot);
        }

        hotspot.style.backgroundColor = '$colorHex';
        hotspot.style.transform = '${isSelected ? 'scale(1.35)' : 'scale(1.0)'}';
        hotspot.style.border = '${isSelected ? '3px solid #FFFFFF' : '2px solid #FFFFFF'}';
        hotspot.style.zIndex = '${isSelected ? '999' : '10'}';
      })();
    ''';

    await webViewController.runJavaScript(script);
  }

  Future<void> _cleanupOldHotspots(List<BodyLesion> currentLesions) async {
    final List<String> validPositions = currentLesions
        .map((BodyLesion l) => l.position)
        .toList();
    final String positionsJson = jsonEncode(validPositions);

    final String cleanupScript =
        '''
      (function() {
        const viewer = document.getElementById('viewer');
        if (!viewer) return;
        const valid = $positionsJson;
        viewer.querySelectorAll('.hotspot-dot').forEach(dot => {
          if (!valid.includes(dot.dataset.position)) dot.remove();
        });
      })();
    ''';
    await webViewController.runJavaScript(cleanupScript);
  }

  String _buildHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.4.0/model-viewer.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    
    html, body { 
      width: 100%; 
      height: 100%; 
      overflow: hidden; 
      background: transparent; 
      touch-action: none; 
    }
    
    model-viewer { 
      width: 100vw; 
      height: 100vh; 
      background: transparent; 
      touch-action: none; 
    }
    
    .hotspot-dot {
      width: 20px; height: 20px; border-radius: 50%; cursor: pointer;
      transition: all 0.15s ease; box-shadow: 0 0 10px rgba(0,0,0,0.3);
      pointer-events: auto; -webkit-tap-highlight-color: transparent;
    }
  </style>
</head>
<body>
  <model-viewer id="viewer" src="http://0.0.0.0:8080/${gender == Gender.female ? 'female' : 'male'}.glb" camera-controls shadow-intensity="1" touch-action="none"></model-viewer>
  <script>
    const viewer = document.getElementById('viewer');
    
    document.addEventListener('touchmove', function(e) {
      if (e.cancelable) e.preventDefault();
    }, { passive: false });

    viewer.addEventListener('load', () => {
      viewer.cameraTarget = '0m 0.3m 0m';
      window.FlutterChannel.postMessage(JSON.stringify({ type: 'MODEL_LOADED' }));
    });

    viewer.addEventListener('click', (event) => {
      if (event.target.classList.contains('hotspot-dot')) return;
      const hit = viewer.positionAndNormalFromPoint(event.clientX, event.clientY);
      if (hit) {
        window.FlutterChannel.postMessage(JSON.stringify({
          type: 'POINT_CLICKED',
          position: hit.position.toString(),
          normal: hit.normal.toString()
        }));
      }
    }, true);
  </script>
</body>
</html>
''';
  }
}

class HumanBody3DSelector extends StatelessWidget {
  final void Function(BodyLesion lesion) onPointAdded;
  final RxList<BodyLesion> lesions;
  final RxnString selectedPosition;
  final void Function()? onModelLoaded;
  final Gender gender;

  const HumanBody3DSelector({
    super.key,
    required this.onPointAdded,
    required this.lesions,
    required this.selectedPosition,
    this.onModelLoaded,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HumanBody3DController>(
      init: HumanBody3DController(
        onPointAdded: onPointAdded,
        lesions: lesions,
        selectedPosition: selectedPosition,
        onModelLoaded: onModelLoaded,
        gender: gender,
        buildContext: context,
      ),
      builder: (HumanBody3DController controller) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: WebViewWidget(controller: controller.webViewController),
            ),

            Obx(
              () => controller.isModelReady.value
                  ? const Center()
                  : const Center(child: CircularProgressIndicator.adaptive()),
            ),

            Obx(
              () => controller.isModelReady.value
                  ? Positioned(
                      top: AppTheme.spaceMedium + AppTheme.radiusLarge * 2,
                      left: AppTheme.spaceMedium,
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spaceSmall),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _LegendItem(
                              color: Colors.red,
                              label: 'Suspicious'.tr,
                            ),

                            const SizedBox(height: AppTheme.spaceSmall),
                            _LegendItem(
                              color: Colors.grey,
                              label: 'Excised'.tr,
                            ),

                            const SizedBox(height: AppTheme.spaceSmall),
                            _LegendItem(
                              color: Theme.of(context).colorScheme.secondary,
                              label: 'Normal'.tr,
                            ),
                          ],
                        ),
                      ),
                    )
                  : const Center(),
            ),

            Obx(
              () => controller.isModelReady.value
                  ? Positioned(
                      top: AppTheme.spaceMedium + AppTheme.radiusLarge * 2,
                      right: AppTheme.spaceMedium,
                      child: IconButton(
                        padding: const EdgeInsets.all(AppTheme.spaceSmall),
                        constraints: BoxConstraints.tight(
                          const Size(
                            AppTheme.radiusLarge * 2,
                            AppTheme.radiusLarge * 2,
                          ),
                        ),
                        onPressed: controller.resetModelPosition,
                        icon: const Icon(Icons.gps_fixed),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            Theme.of(context).colorScheme.surface,
                          ),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLarge,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const Center(),
            ),
          ],
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Colors.black26, blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
