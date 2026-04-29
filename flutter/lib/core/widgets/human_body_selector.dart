import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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
  int painLevel;

  BodyPart({
    required this.id,
    required this.title,
    required this.path,
    this.transformedPath,
    this.painLevel = 0,
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
  final Color? selectedColor;
  final Color? dotColor;
  final _SizeController sizeController;
  final Listenable? repaint;
  double scale;

  _SvgPainter({
    required this.city,
    required this.sizeController,
    this.isSelected = false,
    this.isFocused = false,
    this.selectedColor,
    this.strokeColor,
    this.dotColor,
    this.repaint,
    this.scale = 1.0,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pen = Paint()
      ..color = strokeColor ?? Colors.white60
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Paint fillPen = Paint()
      ..color = Colors.white60
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    final Paint selectedPen = Paint()
      ..color = selectedColor ?? Colors.blue
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    final Paint redDot = Paint()
      ..color = dotColor ?? Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.fill;

    final Rect bounds = city.path.getBounds();

    scale = sizeController.calculateScale(size);
    canvas.scale(scale);

    if (isSelected) {
      canvas.drawPath(city.path, selectedPen);
      if (isFocused) {
        final Paint maskPaint = Paint()
          ..color = Colors.black
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12)
          ..style = PaintingStyle.fill;
        canvas.drawPath(city.path, maskPaint);
      }
    } else {
      canvas.drawPath(city.path, fillPen);
    }

    canvas.drawCircle(bounds.center, 3.0, redDot);
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
  final Function(List<BodyPart> city, BodyPart? active) onChanged;
  final Function(List<BodyPart> city) onLevelChanged;
  final List<String>? initialSelectedPartsList;
  final List<String>? initialPainLevels;
  final Color? strokeColor;
  final Color? selectedColor;
  final Color? dotColor;
  final bool multiSelect;
  final bool toggle;
  final Listenable? repaint;
  final bool enabled;
  final double scale;

  const HumanBodySelector({
    super.key,
    required this.map,
    required this.onChanged,
    required this.onLevelChanged,
    this.width,
    this.height,
    this.strokeColor,
    this.selectedColor,
    this.dotColor,
    this.multiSelect = false,
    this.toggle = false,
    this.repaint,
    this.enabled = true,
    this.initialSelectedPartsList,
    this.initialPainLevels,
    this.scale = 1.0,
  });

  @override
  SelectableSvgState createState() => SelectableSvgState();
}

class SelectableSvgState extends State<HumanBodySelector> {
  final LinearGradient sliderGradient = const LinearGradient(
    colors: <Color>[
      Color(0xff9ddefe),
      Color(0xffb3eedc),
      Color(0xffaaef9b),
      Color(0xffb4f170),
      Color(0xffc5f457),
      Color(0xffe4f05c),
      Color(0xffffe256),
      Color(0xfff5b547),
      Color(0xffed8b3d),
      Color(0xffed5d32),
      Color(0xffe72526),
    ],
  );

  final List<BodyPart> _partsList = <BodyPart>[];
  final List<BodyPart> selectedPartsList = <BodyPart>[];

  late _SizeController _sizeController;
  late _Parser _parser;
  Size? mapSize;

  BodyPart? lastSelected;
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

      if (widget.initialSelectedPartsList != null &&
          selectedPartsList.isEmpty) {
        for (int i = 0; i < widget.initialSelectedPartsList!.length; i++) {
          final String initialPart = widget.initialSelectedPartsList![i];

          for (final BodyPart element in frontPartsList) {
            if (element.title == initialPart) {
              if (widget.initialPainLevels != null &&
                  widget.initialPainLevels!.length > i) {
                element.painLevel =
                    int.tryParse(widget.initialPainLevels![i]) ?? 0;
              }
              selectedPartsList.add(element);
            }
          }

          for (final BodyPart element in backPartsList) {
            if (element.title == initialPart) {
              if (widget.initialPainLevels != null &&
                  widget.initialPainLevels!.length > i) {
                element.painLevel =
                    int.tryParse(widget.initialPainLevels![i]) ?? 0;
              }
              selectedPartsList.add(element);
            }
          }
        }
      }
    });
    widget.repaint?.addListener(rePaintSvg);
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
    _partsList.clear();
    setState(() {
      _partsList.addAll(
        (widget.map == BodySelectorMaps.femaleFront ||
                widget.map == BodySelectorMaps.maleFront)
            ? frontPartsList
            : backPartsList,
      );

      if (selectedPartsList.isNotEmpty) {
        for (final BodyPart element in selectedPartsList) {
          final bool rem1 = _partsList.remove(element);
          if (rem1) {
            _partsList.add(element);
          }
        }
      }
      mapSize = _sizeController.mapSize;
    });
  }

  void clearSelect() {
    setState(() {
      selectedPartsList.clear();
    });
  }

  void clearLastFocus() {
    setState(() {
      lastSelected = null;
    });
  }

  void updateSelection(List<BodyPart> parts) {
    setState(() {
      selectedPartsList.clear();
      selectedPartsList.addAll(parts);
    });
  }

  BodyPart? updateSelectionColor(double value) {
    if (lastSelected != null) {
      lastSelected!.painLevel = value.toInt();
      updatePart(lastSelected!);
    }
    return lastSelected;
  }

  void updatePart(BodyPart part) {
    setState(() {
      final bool rem1 = _partsList.remove(part);
      if (rem1) {
        _partsList.add(part);
      }
      final bool rem2 = selectedPartsList.remove(part);
      if (rem2) {
        selectedPartsList.add(part);
      }
    });
    widget.onLevelChanged.call(selectedPartsList);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: Stack(
        children: <Widget>[
          for (final BodyPart city in _partsList) _buildStackItem(city),
        ],
      ),
    );
  }

  Widget _buildStackItem(BodyPart city) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () => widget.enabled ? _toggleButton(city) : null,
      onLongPress: () => widget.enabled ? tryRemove(city) : null,
      child: CustomPaint(
        isComplex: true,
        foregroundPainter: _SvgPainter(
          city: city,
          sizeController: _sizeController,
          isSelected: selectedPartsList.contains(city),
          isFocused: lastSelected == city,
          dotColor: widget.dotColor,
          selectedColor:
              widget.selectedColor ?? sliderGradient.colors[city.painLevel],
          strokeColor: widget.strokeColor,
          repaint: widget.repaint,
          scale: widget.scale,
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
  }

  void _toggleButton(BodyPart city) {
    setState(() {
      if (widget.multiSelect) {
        if (!selectedPartsList.contains(city)) {
          selectedPartsList.add(city);
          lastSelected = city;
        } else if (widget.toggle) {
          city.painLevel = 0;
          selectedPartsList.remove(city);
          lastSelected = null;
        } else {
          lastSelected = city;
        }
      } else {
        selectedPartsList.clear();
        selectedPartsList.add(city);
        lastSelected = city;
      }
      widget.onChanged.call(selectedPartsList, lastSelected);
    });
  }

  void tryRemove(BodyPart city) {
    if (selectedPartsList.contains(city)) {
      setState(() {
        city.painLevel = 0;
        selectedPartsList.remove(city);
        lastSelected = null;
        widget.onChanged.call(selectedPartsList, lastSelected);
      });
    }
  }
}
