// components/drawing_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;

enum DrawingTool {
  none,
  select,
  pen,
  highlighter,
  eraser,
  rectangle,
  circle,
  line,
  arrow,
  text,
  note,
  magnifier,
  lasso,
  shapes,
}

enum ShapeType {
  rectangle,
  circle,
  line,
  arrow,
}

class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});

  Map<String, dynamic> toJson() {
    return {
      'x': offset.dx,
      'y': offset.dy,
      'color': paint.color.value,
      'strokeWidth': paint.strokeWidth,
      'blendMode': paint.blendMode.index,
    };
  }

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    final paint = Paint()
      ..color = Color(json['color'])
      ..strokeWidth = json['strokeWidth']
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.values[json['blendMode']];

    return DrawingPoint(
      offset: Offset(json['x'], json['y']),
      paint: paint,
    );
  }
}

class DrawingPath {
  final List<DrawingPoint> points;
  final Paint paint;
  final DrawingTool tool;
  final ShapeType? shapeType;

  DrawingPath({
    required this.points,
    required this.paint,
    required this.tool,
    this.shapeType,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p.toJson()).toList(),
      'color': paint.color.value,
      'strokeWidth': paint.strokeWidth,
      'blendMode': paint.blendMode.index,
      'tool': tool.index,
      'shapeType': shapeType?.index,
    };
  }

  factory DrawingPath.fromJson(Map<String, dynamic> json) {
    final paint = Paint()
      ..color = Color(json['color'])
      ..strokeWidth = json['strokeWidth']
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.values[json['blendMode']];

    final points = (json['points'] as List)
        .map((p) => DrawingPoint.fromJson(p))
        .toList();

    return DrawingPath(
      points: points,
      paint: paint,
      tool: DrawingTool.values[json['tool']],
      shapeType: json['shapeType'] != null ? ShapeType.values[json['shapeType']] : null,
    );
  }
}

class TextAnnotation {
  final Offset position;
  final String text;
  final TextStyle style;

  TextAnnotation({
    required this.position,
    required this.text,
    required this.style,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': position.dx,
      'y': position.dy,
      'text': text,
      'fontSize': style.fontSize ?? 16.0,
      'color': style.color?.value ?? Colors.black.value,
    };
  }

  factory TextAnnotation.fromJson(Map<String, dynamic> json) {
    return TextAnnotation(
      position: Offset(json['x'], json['y']),
      text: json['text'],
      style: TextStyle(
        fontSize: json['fontSize'],
        color: Color(json['color']),
      ),
    );
  }
}

class DrawingOverlay extends StatefulWidget {
  final Widget child;
  final Function(Uint8List)? onSave;
  final String noteId;
  final int currentPage;

  const DrawingOverlay({
    Key? key,
    required this.child,
    required this.noteId,
    required this.currentPage,
    this.onSave,
  }) : super(key: key);

  @override
  State<DrawingOverlay> createState() => _DrawingOverlayState();
}

class _DrawingOverlayState extends State<DrawingOverlay> with AutomaticKeepAliveClientMixin {
  DrawingTool _currentTool = DrawingTool.select;
  Color _currentColor = Colors.white;
  double _strokeWidth = 2.0;
  double _magnification = 1.0;
  bool _isTextMode = false;

  // Store drawings and annotations per page
  Map<int, List<DrawingPath>> _pageDrawings = {};
  Map<int, List<TextAnnotation>> _pageTextAnnotations = {};
  DrawingPath? _currentPath;

  // Undo/Redo stacks per page
  Map<int, List<List<DrawingPath>>> _undoStacks = {};
  Map<int, List<List<DrawingPath>>> _redoStacks = {};

  final GlobalKey _drawingKey = GlobalKey();
  bool _isLoading = true;

  // Text editing
  TextEditingController _textController = TextEditingController();
  Offset? _textPosition;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDrawingState();
  }

  @override
  void didUpdateWidget(DrawingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _saveCurrentPageDrawing(oldWidget.currentPage);
      _loadCurrentPageDrawing();
    }
  }

  @override
  void dispose() {
    _saveDrawingState();
    _textController.dispose();
    super.dispose();
  }

  List<DrawingPath> get _currentPagePaths {
    return _pageDrawings[widget.currentPage] ?? [];
  }

  List<TextAnnotation> get _currentPageTextAnnotations {
    return _pageTextAnnotations[widget.currentPage] ?? [];
  }

  Future<void> _loadDrawingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'page_drawings_${widget.noteId}';
      final String textKey = 'page_texts_${widget.noteId}';
      final String? drawingsJson = prefs.getString(key);
      final String? textsJson = prefs.getString(textKey);

      if (drawingsJson != null) {
        final Map<String, dynamic> drawingsMap = json.decode(drawingsJson);
        _pageDrawings.clear();

        drawingsMap.forEach((pageStr, pathsList) {
          final pageNum = int.parse(pageStr);
          final List<DrawingPath> paths = (pathsList as List)
              .map((p) => DrawingPath.fromJson(p))
              .toList();
          _pageDrawings[pageNum] = paths;
        });
      }

      if (textsJson != null) {
        final Map<String, dynamic> textsMap = json.decode(textsJson);
        _pageTextAnnotations.clear();

        textsMap.forEach((pageStr, textsList) {
          final pageNum = int.parse(pageStr);
          final List<TextAnnotation> texts = (textsList as List)
              .map((t) => TextAnnotation.fromJson(t))
              .toList();
          _pageTextAnnotations[pageNum] = texts;
        });
      }

      _currentColor = Color(prefs.getInt('drawing_color_${widget.noteId}') ?? Colors.black.value);
      _strokeWidth = prefs.getDouble('drawing_stroke_${widget.noteId}') ?? 2.0;

    } catch (e) {
      print('Error loading drawing state: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadCurrentPageDrawing() {
    setState(() {});
  }

  void _saveCurrentPageDrawing(int pageNumber) {
    if (_pageDrawings[pageNumber]?.isNotEmpty == true ||
        _pageTextAnnotations[pageNumber]?.isNotEmpty == true) {
      _saveDrawingState();
    }
  }

  Future<void> _saveDrawingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'page_drawings_${widget.noteId}';
      final String textKey = 'page_texts_${widget.noteId}';

      // Save drawings
      if (_pageDrawings.isNotEmpty) {
        final Map<String, dynamic> drawingsMap = {};
        _pageDrawings.forEach((pageNum, paths) {
          if (paths.isNotEmpty) {
            drawingsMap[pageNum.toString()] = paths.map((p) => p.toJson()).toList();
          }
        });

        if (drawingsMap.isNotEmpty) {
          await prefs.setString(key, json.encode(drawingsMap));
        } else {
          await prefs.remove(key);
        }
      } else {
        await prefs.remove(key);
      }

      // Save text annotations
      if (_pageTextAnnotations.isNotEmpty) {
        final Map<String, dynamic> textsMap = {};
        _pageTextAnnotations.forEach((pageNum, texts) {
          if (texts.isNotEmpty) {
            textsMap[pageNum.toString()] = texts.map((t) => t.toJson()).toList();
          }
        });

        if (textsMap.isNotEmpty) {
          await prefs.setString(textKey, json.encode(textsMap));
        } else {
          await prefs.remove(textKey);
        }
      } else {
        await prefs.remove(textKey);
      }

      await prefs.setInt('drawing_color_${widget.noteId}', _currentColor.value);
      await prefs.setDouble('drawing_stroke_${widget.noteId}', _strokeWidth);

    } catch (e) {
      print('Error saving drawing state: $e');
    }
  }

  void _pushToUndoStack() {
    final pageNum = widget.currentPage;
    if (_undoStacks[pageNum] == null) _undoStacks[pageNum] = [];

    _undoStacks[pageNum]!.add(List<DrawingPath>.from(_currentPagePaths));

    // Limit undo stack size
    if (_undoStacks[pageNum]!.length > 50) {
      _undoStacks[pageNum]!.removeAt(0);
    }

    // Clear redo stack when new action is performed
    _redoStacks[pageNum] = [];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return Stack(
        children: [
          widget.child,
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    final currentPagePaths = _currentPagePaths;
    final currentPageTexts = _currentPageTextAnnotations;

    return Stack(
      children: [
        // PDF Viewer (background)
        Positioned(
          top: 70, // Height of toolbar
          left: 0,
          right: 0,
          bottom: 0,
          child: Transform.scale(
            scale: _magnification,
            child: widget.child,
          ),
        ),

        // Drawing overlay
        if (_currentTool != DrawingTool.select)
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            bottom: 0,
            child: RepaintBoundary(
              key: _drawingKey,
              child: GestureDetector(
                onTapDown: _onTapDown,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  color: Colors.transparent,
                  child: CustomPaint(
                    painter: DrawingPainter(
                      paths: currentPagePaths,
                      textAnnotations: currentPageTexts,
                      currentPath: _currentPath,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),

        // Always show existing drawings
        if (_currentTool == DrawingTool.select && (currentPagePaths.isNotEmpty || currentPageTexts.isNotEmpty))
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: CustomPaint(
                painter: DrawingPainter(
                  paths: currentPagePaths,
                  textAnnotations: currentPageTexts,
                  currentPath: null,
                ),
                size: Size.infinite,
              ),
            ),
          ),

        // Enhanced Toolbar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildExactToolbar(),
        ),

        // Text input dialog
        if (_isTextMode && _textPosition != null)
          Positioned(
            left: _textPosition!.dx,
            top: _textPosition!.dy + 70,
            child: _buildTextInput(),
          ),

        // Tool indicator
        if (_currentTool != DrawingTool.select)
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _currentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_getToolName(_currentTool)} - Page ${widget.currentPage}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExactToolbar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2C2C2C),
            const Color(0xFF1A1A1A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Navigation tools
              _buildNavSection(),
              _buildSeparator(),

              // Selection and basic tools
              _buildBasicToolsSection(),
              _buildSeparator(),

              // Drawing tools
              _buildDrawingToolsSection(),
              _buildSeparator(),

              // Shape tools
              _buildShapeToolsSection(),
              _buildSeparator(),

              // Text and annotation tools
              _buildAnnotationToolsSection(),
              _buildSeparator(),

              // Utility tools
              _buildUtilityToolsSection(),

              const Spacer(),

              // Action tools
              _buildActionToolsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavSection() {
    return Row(
      children: [
        _buildToolButton(
          icon: Icons.arrow_back_ios,
          onTap: () {},
          tooltip: 'Back',
        ),
        _buildToolButton(
          icon: Icons.arrow_forward_ios,
          onTap: () {},
          tooltip: 'Forward',
        ),
        _buildToolButton(
          icon: Icons.fullscreen,
          onTap: () {},
          tooltip: 'Fullscreen',
        ),
      ],
    );
  }

  Widget _buildBasicToolsSection() {
    return Row(
      children: [
        _buildToolButton(
          icon: Icons.near_me,
          isSelected: _currentTool == DrawingTool.select,
          onTap: () => _selectTool(DrawingTool.select),
          tooltip: 'Select',
        ),
        _buildToolButton(
          icon: Icons.edit,
          isSelected: _currentTool == DrawingTool.pen,
          onTap: () => _selectTool(DrawingTool.pen),
          tooltip: 'Pen',
        ),
        _buildToolButton(
          icon: Icons.brush,
          isSelected: _currentTool == DrawingTool.highlighter,
          onTap: () => _selectTool(DrawingTool.highlighter),
          tooltip: 'Highlighter',
        ),
        _buildToolButton(
          icon: Icons.auto_fix_high,
          isSelected: _currentTool == DrawingTool.eraser,
          onTap: () => _selectTool(DrawingTool.eraser),
          tooltip: 'Eraser',
        ),
      ],
    );
  }

  Widget _buildDrawingToolsSection() {
    return Row(
      children: [
        _buildToolButton(
          icon: Icons.crop_free,
          isSelected: _currentTool == DrawingTool.lasso,
          onTap: () => _selectTool(DrawingTool.lasso),
          tooltip: 'Lasso',
        ),
      ],
    );
  }

  Widget _buildShapeToolsSection() {
    return Row(
      children: [
        _buildToolButton(
          icon: Icons.crop_square,
          isSelected: _currentTool == DrawingTool.rectangle,
          onTap: () => _selectTool(DrawingTool.rectangle),
          tooltip: 'Rectangle',
        ),
        _buildToolButton(
          icon: Icons.circle_outlined,
          isSelected: _currentTool == DrawingTool.circle,
          onTap: () => _selectTool(DrawingTool.circle),
          tooltip: 'Circle',
        ),
        _buildToolButton(
          icon: Icons.horizontal_rule,
          isSelected: _currentTool == DrawingTool.line,
          onTap: () => _selectTool(DrawingTool.line),
          tooltip: 'Line',
        ),
        _buildToolButton(
          icon: Icons.arrow_forward,
          isSelected: _currentTool == DrawingTool.arrow,
          onTap: () => _selectTool(DrawingTool.arrow),
          tooltip: 'Arrow',
        ),
      ],
    );
  }

  Widget _buildAnnotationToolsSection() {
    return Row(
      children: [
        _buildToolButton(
          icon: Icons.text_fields,
          isSelected: _currentTool == DrawingTool.text,
          onTap: () => _selectTool(DrawingTool.text),
          tooltip: 'Text',
        ),
        _buildToolButton(
          icon: Icons.sticky_note_2_outlined,
          isSelected: _currentTool == DrawingTool.note,
          onTap: () => _selectTool(DrawingTool.note),
          tooltip: 'Sticky Note',
        ),
      ],
    );
  }

  Widget _buildUtilityToolsSection() {
    return Row(
      children: [
        _buildToolButton(
          icon: Icons.search,
          isSelected: _currentTool == DrawingTool.magnifier,
          onTap: () => _selectTool(DrawingTool.magnifier),
          tooltip: 'Magnifier',
        ),
        _buildColorPicker(),
        _buildToolButton(
          icon: Icons.line_weight,
          onTap: _showStrokeWidthPicker,
          tooltip: 'Stroke Width',
        ),
      ],
    );
  }

  Widget _buildActionToolsSection() {
    return Row(
      children: [
        _buildToolButton(
          icon: Icons.undo,
          onTap: _canUndo() ? _undo : null,
          tooltip: 'Undo',
        ),
        _buildToolButton(
          icon: Icons.redo,
          onTap: _canRedo() ? _redo : null,
          tooltip: 'Redo',
        ),
        _buildToolButton(
          icon: Icons.more_horiz,
          onTap: _showMoreOptions,
          tooltip: 'More Options',
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    bool isSelected = false,
    required VoidCallback? onTap,
    required String tooltip,
    Color? customColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4A9EFF)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.5))
                  : null,
            ),
            child: Icon(
              icon,
              size: 18,
              color: onTap != null
                  ? (isSelected ? Colors.white : (customColor ?? const Color(0xFFE0E0E0)))
                  : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.brown,
      Colors.pink,
      Colors.cyan,
    ];

    return PopupMenuButton<Color>(
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: _currentColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF555555), width: 1),
        ),
        child: _currentColor == Colors.white
            ? const Icon(Icons.color_lens_outlined, size: 16, color: Colors.grey)
            : null,
      ),
      color: const Color(0xFF2C2C2C),
      itemBuilder: (context) => colors.map((color) {
        return PopupMenuItem<Color>(
          value: color,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: _currentColor == color ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
      onSelected: (color) {
        setState(() {
          _currentColor = color;
        });
      },
    );
  }

  Widget _buildSeparator() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFF444444),
    );
  }

  Widget _buildTextInput() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter text...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _addTextAnnotation,
                  child: const Text('Add'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _cancelTextInput,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectTool(DrawingTool tool) {
    setState(() {
      _currentTool = tool;
      _isTextMode = tool == DrawingTool.text;
      if (!_isTextMode) {
        _textPosition = null;
      }
    });
  }

  String _getToolName(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.select: return 'Select';
      case DrawingTool.pen: return 'Pen';
      case DrawingTool.highlighter: return 'Highlighter';
      case DrawingTool.eraser: return 'Eraser';
      case DrawingTool.rectangle: return 'Rectangle';
      case DrawingTool.circle: return 'Circle';
      case DrawingTool.line: return 'Line';
      case DrawingTool.arrow: return 'Arrow';
      case DrawingTool.text: return 'Text';
      case DrawingTool.note: return 'Note';
      case DrawingTool.magnifier: return 'Magnifier';
      case DrawingTool.lasso: return 'Lasso';
      default: return 'Tool';
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (_currentTool == DrawingTool.text) {
      setState(() {
        _textPosition = details.localPosition;
        _isTextMode = true;
      });
    } else if (_currentTool == DrawingTool.magnifier) {
      _handleMagnification(details.localPosition);
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_currentTool == DrawingTool.select || _currentTool == DrawingTool.text) return;

    _pushToUndoStack();

    final paint = Paint()
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (_currentTool) {
      case DrawingTool.pen:
        paint.color = _currentColor;
        break;
      case DrawingTool.highlighter:
        paint.color = _currentColor.withOpacity(0.4);
        paint.strokeWidth = _strokeWidth * 3;
        break;
      case DrawingTool.eraser:
        paint.color = Colors.white;
        paint.blendMode = BlendMode.clear;
        paint.strokeWidth = _strokeWidth * 2;
        break;
      case DrawingTool.rectangle:
      case DrawingTool.circle:
      case DrawingTool.line:
      case DrawingTool.arrow:
        paint.color = _currentColor;
        paint.style = PaintingStyle.stroke;
        break;
      default:
        return;
    }

    _currentPath = DrawingPath(
      points: [DrawingPoint(offset: details.localPosition, paint: paint)],
      paint: paint,
      tool: _currentTool,
      shapeType: _getShapeType(),
    );

    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentPath == null) return;

    if (_isShapeTool(_currentTool)) {
      // For shapes, we only need start and end points
      if (_currentPath!.points.length > 1) {
        _currentPath!.points.removeLast();
      }
      _currentPath!.points.add(
        DrawingPoint(offset: details.localPosition, paint: _currentPath!.paint),
      );
    } else {
      // For free drawing tools
      _currentPath!.points.add(
        DrawingPoint(offset: details.localPosition, paint: _currentPath!.paint),
      );
    }

    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPath != null) {
      if (_pageDrawings[widget.currentPage] == null) {
        _pageDrawings[widget.currentPage] = [];
      }
      _pageDrawings[widget.currentPage]!.add(_currentPath!);
      _currentPath = null;
      setState(() {});
      _saveDrawingState();
    }
  }

  bool _isShapeTool(DrawingTool tool) {
    return [
      DrawingTool.rectangle,
      DrawingTool.circle,
      DrawingTool.line,
      DrawingTool.arrow,
    ].contains(tool);
  }

  ShapeType? _getShapeType() {
    switch (_currentTool) {
      case DrawingTool.rectangle:
        return ShapeType.rectangle;
      case DrawingTool.circle:
        return ShapeType.circle;
      case DrawingTool.line:
        return ShapeType.line;
      case DrawingTool.arrow:
        return ShapeType.arrow;
      default:
        return null;
    }
  }

  void _addTextAnnotation() {
    if (_textController.text.isNotEmpty && _textPosition != null) {
      _pushToUndoStack();

      if (_pageTextAnnotations[widget.currentPage] == null) {
        _pageTextAnnotations[widget.currentPage] = [];
      }

      _pageTextAnnotations[widget.currentPage]!.add(
        TextAnnotation(
          position: _textPosition!,
          text: _textController.text,
          style: TextStyle(
            color: _currentColor,
            fontSize: 16.0,
          ),
        ),
      );

      _textController.clear();
      setState(() {
        _textPosition = null;
        _isTextMode = false;
      });

      _saveDrawingState();
    }
  }

  void _cancelTextInput() {
    setState(() {
      _textPosition = null;
      _isTextMode = false;
    });
    _textController.clear();
  }

  void _handleMagnification(Offset position) {
    setState(() {
      _magnification = _magnification == 1.0 ? 1.5 : 1.0;
    });
  }

  bool _canUndo() {
    final undoStack = _undoStacks[widget.currentPage];
    return undoStack != null && undoStack.isNotEmpty;
  }

  bool _canRedo() {
    final redoStack = _redoStacks[widget.currentPage];
    return redoStack != null && redoStack.isNotEmpty;
  }

  void _undo() {
    final pageNum = widget.currentPage;
    final undoStack = _undoStacks[pageNum];

    if (undoStack != null && undoStack.isNotEmpty) {
      // Push current state to redo stack
      if (_redoStacks[pageNum] == null) _redoStacks[pageNum] = [];
      _redoStacks[pageNum]!.add(List<DrawingPath>.from(_currentPagePaths));

      // Restore previous state
      final previousState = undoStack.removeLast();
      _pageDrawings[pageNum] = List<DrawingPath>.from(previousState);

      setState(() {});
      _saveDrawingState();
    }
  }

  void _redo() {
    final pageNum = widget.currentPage;
    final redoStack = _redoStacks[pageNum];

    if (redoStack != null && redoStack.isNotEmpty) {
      // Push current state to undo stack
      if (_undoStacks[pageNum] == null) _undoStacks[pageNum] = [];
      _undoStacks[pageNum]!.add(List<DrawingPath>.from(_currentPagePaths));

      // Restore next state
      final nextState = redoStack.removeLast();
      _pageDrawings[pageNum] = List<DrawingPath>.from(nextState);

      setState(() {});
      _saveDrawingState();
    }
  }

  void _showStrokeWidthPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Stroke Width', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Width: ${_strokeWidth.toInt()}px',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF4A9EFF),
                  inactiveTrackColor: const Color(0xFF555555),
                  thumbColor: const Color(0xFF4A9EFF),
                  overlayColor: const Color(0xFF4A9EFF).withOpacity(0.2),
                ),
                child: Slider(
                  value: _strokeWidth,
                  min: 1.0,
                  max: 15.0,
                  divisions: 14,
                  onChanged: (value) {
                    setDialogState(() {
                      _strokeWidth = value;
                    });
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Preview
              Container(
                height: 50,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  painter: StrokePreviewPainter(
                    color: _currentColor,
                    strokeWidth: _strokeWidth,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: Color(0xFF4A9EFF))),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('More Options', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionTile(
              icon: Icons.clear_all,
              title: 'Clear Current Page',
              subtitle: 'Remove all drawings and annotations',
              onTap: () {
                Navigator.pop(context);
                _showClearCurrentPageDialog();
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_forever,
              title: 'Clear All Pages',
              subtitle: 'Remove all drawings from document',
              onTap: () {
                Navigator.pop(context);
                _showClearAllPagesDialog();
              },
            ),
            _buildOptionTile(
              icon: Icons.save,
              title: 'Export Annotations',
              subtitle: 'Save annotations to file',
              onTap: () {
                Navigator.pop(context);
                _exportAnnotations();
              },
            ),
            _buildOptionTile(
              icon: Icons.settings,
              title: 'Tool Settings',
              subtitle: 'Customize tool behavior',
              onTap: () {
                Navigator.pop(context);
                _showToolSettings();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF4A9EFF))),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFE0E0E0)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFFAAAAAA))),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showClearCurrentPageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(
          'Clear Page ${widget.currentPage}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove all drawings and annotations from page ${widget.currentPage}? This cannot be undone.',
          style: const TextStyle(color: Color(0xFFE0E0E0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFAAAAAA))),
          ),
          TextButton(
            onPressed: () {
              _pushToUndoStack();
              setState(() {
                _pageDrawings.remove(widget.currentPage);
                _pageTextAnnotations.remove(widget.currentPage);
              });
              _saveDrawingState();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showClearAllPagesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Clear All Pages', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Remove all drawings and annotations from all pages? This cannot be undone.',
          style: TextStyle(color: Color(0xFFE0E0E0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFAAAAAA))),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _pageDrawings.clear();
                _pageTextAnnotations.clear();
                _undoStacks.clear();
                _redoStacks.clear();
              });
              _saveDrawingState();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _exportAnnotations() {
    // Placeholder for export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality would be implemented here'),
        backgroundColor: Color(0xFF4A9EFF),
      ),
    );
  }

  void _showToolSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Tool Settings', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Smooth Strokes', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Apply smoothing to pen strokes',
                  style: TextStyle(color: Color(0xFFAAAAAA))),
              value: true,
              onChanged: (value) {},
              activeColor: const Color(0xFF4A9EFF),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Pressure Sensitivity', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Vary stroke width with pressure',
                  style: TextStyle(color: Color(0xFFAAAAAA))),
              value: false,
              onChanged: (value) {},
              activeColor: const Color(0xFF4A9EFF),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: Color(0xFF4A9EFF))),
          ),
        ],
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPath> paths;
  final List<TextAnnotation> textAnnotations;
  final DrawingPath? currentPath;

  DrawingPainter({
    required this.paths,
    required this.textAnnotations,
    this.currentPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed paths
    for (final drawingPath in paths) {
      _drawPath(canvas, drawingPath);
    }

    // Draw current path
    if (currentPath != null) {
      _drawPath(canvas, currentPath!);
    }

    // Draw text annotations
    for (final textAnnotation in textAnnotations) {
      _drawText(canvas, textAnnotation);
    }
  }

  void _drawPath(Canvas canvas, DrawingPath drawingPath) {
    if (drawingPath.points.isEmpty) return;

    if (drawingPath.points.length == 1) {
      canvas.drawCircle(
        drawingPath.points.first.offset,
        drawingPath.paint.strokeWidth / 2,
        drawingPath.paint,
      );
      return;
    }

    // Handle different shape types
    switch (drawingPath.shapeType) {
      case ShapeType.rectangle:
        _drawRectangle(canvas, drawingPath);
        break;
      case ShapeType.circle:
        _drawCircle(canvas, drawingPath);
        break;
      case ShapeType.line:
        _drawLine(canvas, drawingPath);
        break;
      case ShapeType.arrow:
        _drawArrow(canvas, drawingPath);
        break;
      default:
        _drawFreeForm(canvas, drawingPath);
    }
  }

  void _drawRectangle(Canvas canvas, DrawingPath drawingPath) {
    if (drawingPath.points.length < 2) return;

    final start = drawingPath.points.first.offset;
    final end = drawingPath.points.last.offset;

    final rect = Rect.fromPoints(start, end);
    canvas.drawRect(rect, drawingPath.paint);
  }

  void _drawCircle(Canvas canvas, DrawingPath drawingPath) {
    if (drawingPath.points.length < 2) return;

    final start = drawingPath.points.first.offset;
    final end = drawingPath.points.last.offset;

    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
    final radius = (end - start).distance / 2;

    canvas.drawCircle(center, radius, drawingPath.paint);
  }

  void _drawLine(Canvas canvas, DrawingPath drawingPath) {
    if (drawingPath.points.length < 2) return;

    final start = drawingPath.points.first.offset;
    final end = drawingPath.points.last.offset;

    canvas.drawLine(start, end, drawingPath.paint);
  }

  void _drawArrow(Canvas canvas, DrawingPath drawingPath) {
    if (drawingPath.points.length < 2) return;

    final start = drawingPath.points.first.offset;
    final end = drawingPath.points.last.offset;

    // Draw line
    canvas.drawLine(start, end, drawingPath.paint);

    // Draw arrowhead
    const arrowLength = 20.0;
    const arrowAngle = math.pi / 6; // 30 degrees

    final direction = (end - start).direction;
    final arrowPoint1 = end + Offset(
      arrowLength * math.cos(direction + math.pi - arrowAngle),
      arrowLength * math.sin(direction + math.pi - arrowAngle),
    );
    final arrowPoint2 = end + Offset(
      arrowLength * math.cos(direction + math.pi + arrowAngle),
      arrowLength * math.sin(direction + math.pi + arrowAngle),
    );

    canvas.drawLine(end, arrowPoint1, drawingPath.paint);
    canvas.drawLine(end, arrowPoint2, drawingPath.paint);
  }

  void _drawFreeForm(Canvas canvas, DrawingPath drawingPath) {
    final path = Path();
    path.moveTo(
      drawingPath.points.first.offset.dx,
      drawingPath.points.first.offset.dy,
    );

    for (int i = 1; i < drawingPath.points.length; i++) {
      path.lineTo(
        drawingPath.points[i].offset.dx,
        drawingPath.points[i].offset.dy,
      );
    }

    canvas.drawPath(path, drawingPath.paint);
  }

  void _drawText(Canvas canvas, TextAnnotation textAnnotation) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: textAnnotation.text,
        style: textAnnotation.style,
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, textAnnotation.position);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StrokePreviewPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  StrokePreviewPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final startPoint = Offset(20, size.height / 2);
    final endPoint = Offset(size.width - 20, size.height / 2);

    canvas.drawLine(startPoint, endPoint, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}