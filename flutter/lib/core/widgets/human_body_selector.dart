import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:svg_path_parser/svg_path_parser.dart';

// ==========================================
// CONSTANTS & ENUMS
// ==========================================

class BodySelectorConstants {
  static const String mapRegexp = '.* id="(.*)" title="(.*)" .* d="(.*)"';
  static const String mapSizeRegexp = '<svg.* height="(.*)" width="(.*)"';
  static const String assetPath = 'assets/';
}

class BodySelectorMaps {
  static const String femaleFront = 'female.svg';
  static const String femaleBack = 'female1.svg';
  static const String maleFront = 'male.svg';
  static const String maleBack = 'male1.svg';
}

// ==========================================
// MODELS
// ==========================================

class BodyPart {
  String id;
  String title;
  Path path;
  Path? transformedPath;

  BodyPart({
    required this.id,
    required this.title,
    required this.path,
    this.transformedPath,
  });

  void transform(Matrix4 matrix) =>
      transformedPath = path.transform(matrix.storage);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BodyPart && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class _MapArea {
  double? minX;
  double? maxX;
  double? minY;
  double? maxY;

  _MapArea();

  bool get anyEmpty =>
      minX == null || minY == null || maxX == null || maxY == null;
}

// ==========================================
// CONTROLLERS & PARSER
// ==========================================

class _SizeController {
  final _MapArea _mapArea = _MapArea();
  Size mapSize = Size.zero;

  void addBounds(Rect bound) {
    if (_mapArea.anyEmpty) {
      _mapArea
        ..minX = bound.left
        ..maxX = bound.right
        ..minY = bound.top
        ..maxY = bound.bottom;
    } else {
      if (bound.left < _mapArea.minX!) {
        _mapArea.minX = bound.left;
      }
      if (bound.right > _mapArea.maxX!) {
        _mapArea.maxX = bound.right;
      }
      if (bound.top < _mapArea.minY!) {
        _mapArea.minY = bound.top;
      }
      if (bound.bottom > _mapArea.maxY!) {
        _mapArea.maxY = bound.bottom;
      }
    }
    calculateArea();
  }

  void calculateArea() {
    if (_mapArea.anyEmpty) {
      mapSize = Size.zero;
      return;
    }
    final double width = _mapArea.maxX! - _mapArea.minX!;
    final double height = _mapArea.maxY! - _mapArea.minY!;
    mapSize = Size(width, height);
  }

  double calculateScale(Size? containerSize) {
    if (containerSize == null) {
      return 1.0;
    }

    final double newWidth = containerSize.width;
    double newHeight = containerSize.height;

    if (containerSize.width > containerSize.height) {
      newHeight = 1 / (mapSize.aspectRatio / containerSize.width);
    } else {
      newHeight = containerSize.width / mapSize.aspectRatio;
    }
    containerSize = Size(newWidth, newHeight);

    final double scale1 = containerSize.width / mapSize.width;
    final double scale2 = containerSize.height / mapSize.height;

    return scale1 > scale2 ? scale1 : scale2;
  }

  double inverseOfScale(double scale) => 1.0 / scale;
}

class _Parser {
  final _SizeController sizeController;

  _Parser(this.sizeController);

  Future<List<BodyPart>> svgToCityList(String fileName) async {
    final String svgString = await rootBundle.loadString(
      '${BodySelectorConstants.assetPath}$fileName',
    );
    final List<BodyPart> cityList = <BodyPart>[];

    final RegExp regExp = RegExp(
      BodySelectorConstants.mapRegexp,
      multiLine: true,
      caseSensitive: false,
      dotAll: false,
    );

    for (final RegExpMatch cityData in regExp.allMatches(svgString)) {
      final BodyPart city = BodyPart(
        id: cityData.group(1)!,
        title: cityData.group(2)!.split('"')[0],
        path: parseSvgPathData(cityData.group(3)!),
        transformedPath: parseSvgPath(cityData.group(3)!),
      );

      final RegExp sizeRegExp = RegExp(
        BodySelectorConstants.mapSizeRegexp,
        multiLine: true,
        caseSensitive: false,
        dotAll: false,
      );
      final RegExpMatch? firstMatch = sizeRegExp.firstMatch(svgString);
      final String? sHeight = firstMatch?.group(1);
      final String? sWidth = firstMatch?.group(2);

      if (sHeight != null && sWidth != null) {
        final double? height = double.tryParse(sHeight);
        final double? width = double.tryParse(sWidth);
        if (height != null && width != null) {
          sizeController.addBounds(Rect.fromLTRB(0, 0, width, height));
        } else {
          sizeController.addBounds(city.path.getBounds());
        }
      } else {
        sizeController.addBounds(city.path.getBounds());
      }
      cityList.add(city);
    }
    return cityList;
  }
}

// ==========================================
// PAINTER
// ==========================================

class _SvgPainter extends CustomPainter {
  final BodyPart city;
  final bool isSelected;
  final bool isFocused;
  final Color? strokeColor;
  final Color fillColor;
  final Color highlightColor;
  final _SizeController sizeController;
  final Listenable? repaint;
  double scale = 1.0;

  _SvgPainter({
    required this.city,
    required this.sizeController,
    required this.fillColor,
    required this.highlightColor,
    this.isSelected = false,
    this.isFocused = false,
    this.strokeColor,
    this.repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pen = Paint()
      ..color = strokeColor ?? Colors.white60
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    scale = sizeController.calculateScale(size);
    canvas.scale(scale);

    if (isSelected && isFocused) {
      final Paint highlightPen = Paint()
        ..color = highlightColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(city.path, highlightPen);
    } else {
      final Paint fillPen = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(city.path, fillPen);
    }

    canvas.drawPath(city.path, pen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  @override
  bool hitTest(Offset position) {
    final double inverseScale = sizeController.inverseOfScale(scale);
    return city.path.contains(position.scale(inverseScale, inverseScale));
  }
}

// ==========================================
// MAIN WIDGET
// ==========================================

class HumanBodySelector extends StatefulWidget {
  final double? width;
  final double? height;
  final String map;
  final Function(BodyPart? active) onTap;
  final RxMap<String, ({int count, bool isSuspicious})> lesionMap;
  final Color? strokeColor;
  final Color? selectedColor;
  final Color? intensityColor;
  final bool multiSelect;
  final Listenable? repaint;

  const HumanBodySelector({
    super.key,
    required this.map,
    required this.onTap,
    required this.lesionMap,
    this.width,
    this.height,
    this.strokeColor,
    this.selectedColor,
    this.intensityColor,
    this.multiSelect = false,
    this.repaint,
  });

  @override
  SelectableSvgState createState() => SelectableSvgState();
}

class SelectableSvgState extends State<HumanBodySelector> {
  final List<BodyPart> _partsList = <BodyPart>[];

  final RxList<BodyPart> selectedPartsList = <BodyPart>[].obs;
  final Rxn<BodyPart> lastSelected = Rxn<BodyPart>();

  String? _pendingSelectionId;

  late _SizeController _sizeController;
  late _Parser _parser;
  Size? mapSize;

  late List<BodyPart> frontPartsList;
  late List<BodyPart> backPartsList;

  @override
  void initState() {
    super.initState();
    _sizeController = _SizeController();
    _parser = _Parser(_sizeController);

    final bool isFemale =
        widget.map == BodySelectorMaps.femaleFront ||
        widget.map == BodySelectorMaps.femaleBack;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      frontPartsList = isFemale
          ? await _parser.svgToCityList(BodySelectorMaps.femaleFront)
          : await _parser.svgToCityList(BodySelectorMaps.maleFront);
      backPartsList = isFemale
          ? await _parser.svgToCityList(BodySelectorMaps.femaleBack)
          : await _parser.svgToCityList(BodySelectorMaps.maleBack);

      await loadCityList();
    });

    widget.repaint?.addListener(rePaintSvg);
  }

  @override
  void didUpdateWidget(covariant HumanBodySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.map != widget.map) {
      loadCityList();
    }
  }

  @override
  void dispose() {
    widget.repaint?.removeListener(rePaintSvg);
    super.dispose();
  }

  void rePaintSvg() {
    Future<void>.delayed(const Duration(milliseconds: 100), loadCityList);
  }

  Future<void> loadCityList() async {
    final List<BodyPart> sourceList =
        (widget.map == BodySelectorMaps.femaleFront ||
            widget.map == BodySelectorMaps.maleFront)
        ? frontPartsList
        : backPartsList;

    setState(() {
      _partsList.clear();
      _partsList.addAll(sourceList);

      if (lastSelected.value != null) {
        final String targetId = lastSelected.value!.id;

        final BodyPart? matchingPart = _partsList.firstWhereOrNull(
          (BodyPart p) => p.id == targetId,
        );

        if (matchingPart != null) {
          selectedPartsList.clear();
          selectedPartsList.add(matchingPart);
          lastSelected.value = matchingPart;
        }
      }

      mapSize = _sizeController.mapSize;

      if (_pendingSelectionId != null) {
        selectPartById(_pendingSelectionId!);
      }
    });
  }

  void clearSelection() {
    selectedPartsList.clear();
    lastSelected.value = null;
    _pendingSelectionId = null;
    widget.onTap.call(null);
  }

  void selectPartById(String bodyPartId) {
    if (_partsList.isEmpty) {
      _pendingSelectionId = bodyPartId;
      return;
    }

    final BodyPart? city = _partsList.firstWhereOrNull(
      (BodyPart part) => part.id == bodyPartId,
    );

    if (city != null) {
      selectedPartsList.clear();
      selectedPartsList.add(city);
      lastSelected.value = city;
      _pendingSelectionId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: clearSelection,
      child: Container(
        color: Colors.transparent,
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        child: Stack(
          children: <Widget>[
            for (final BodyPart city in _partsList) _buildStackItem(city),
          ],
        ),
      ),
    );
  }

  Widget _buildStackItem(BodyPart city) {
    final Color activeSelectionColor =
        widget.selectedColor ?? Theme.of(context).primaryColor;

    return Obx(() {
      final bool isSelected = selectedPartsList.contains(city);
      final bool isFocused = lastSelected.value == city;

      final ({int count, bool isSuspicious})? data = widget.lesionMap[city.id];
      final int lesionCount = data?.count ?? 0;
      final bool isSuspiciousData = data?.isSuspicious ?? false;

      final double intensity = (lesionCount * 0.2).clamp(0.0, 1.0);
      final Color baseColor = Colors.white60;
      final Color heatmapColor =
          widget.intensityColor ?? Theme.of(context).colorScheme.secondary;

      Color partColor =
          Color.lerp(baseColor, heatmapColor, intensity) ?? baseColor;

      if (isSuspiciousData) {
        partColor = Color.alphaBlend(
          Colors.red.withValues(alpha: 0.3),
          partColor,
        );
      }

      return GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () => _handleTap(city),
        child: CustomPaint(
          isComplex: true,
          foregroundPainter: _SvgPainter(
            city: city,
            sizeController: _sizeController,
            fillColor: partColor,
            highlightColor: activeSelectionColor,
            isSelected: isSelected,
            // Funktioniert jetzt zu 100% jedes Mal
            isFocused: isFocused,
            strokeColor: widget.strokeColor,
            repaint: widget.repaint,
          ),
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height ?? double.infinity,
            constraints: BoxConstraints(
              maxWidth: mapSize?.width ?? 0,
              maxHeight: mapSize?.height ?? 0,
            ),
            alignment: Alignment.center,
          ),
        ),
      );
    });
  }

  void _handleTap(BodyPart city) {
    if (widget.multiSelect) {
      if (!selectedPartsList.contains(city)) {
        selectedPartsList.add(city);
      }
      lastSelected.value = city;
    } else {
      selectedPartsList.clear();
      selectedPartsList.add(city);
      lastSelected.value = city;
    }

    widget.onTap.call(city);
  }
}
