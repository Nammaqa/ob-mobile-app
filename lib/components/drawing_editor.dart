// components/drawing_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';

enum DrawingTool {
  none,
  pen,
  highlighter,
  eraser,
}

class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'x': offset.dx,
      'y': offset.dy,
      'color': paint.color.value,
      'strokeWidth': paint.strokeWidth,
      'blendMode': paint.blendMode.index,
    };
  }

  // Create from JSON
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

  DrawingPath({required this.points, required this.paint});

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p.toJson()).toList(),
      'color': paint.color.value,
      'strokeWidth': paint.strokeWidth,
      'blendMode': paint.blendMode.index,
    };
  }

  // Create from JSON
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

    return DrawingPath(points: points, paint: paint);
  }
}

class DrawingOverlay extends StatefulWidget {
  final Widget child;
  final Function(Uint8List)? onSave;
  final String noteId;
  final int currentPage; // Add current page parameter

  const DrawingOverlay({
    Key? key,
    required this.child,
    required this.noteId,
    required this.currentPage, // Make this required
    this.onSave,
  }) : super(key: key);

  @override
  State<DrawingOverlay> createState() => _DrawingOverlayState();
}

class _DrawingOverlayState extends State<DrawingOverlay> with AutomaticKeepAliveClientMixin {
  DrawingTool _currentTool = DrawingTool.none;
  Color _currentColor = Colors.red;
  double _strokeWidth = 3.0;
  bool _toolbarVisible = true;

  // Store drawings per page
  Map<int, List<DrawingPath>> _pageDrawings = {};
  DrawingPath? _currentPath;

  final GlobalKey _drawingKey = GlobalKey();
  bool _isLoading = true;
  int _lastPageNumber = -1;

  // Keep the state alive when navigating
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

    // If page changed, save current page and load new page
    if (oldWidget.currentPage != widget.currentPage) {
      _saveCurrentPageDrawing(oldWidget.currentPage);
      _loadCurrentPageDrawing();
    }
  }

  @override
  void dispose() {
    _saveDrawingState();
    super.dispose();
  }

  // Get current page drawings
  List<DrawingPath> get _currentPagePaths {
    return _pageDrawings[widget.currentPage] ?? [];
  }

  // Load drawing state from SharedPreferences
  Future<void> _loadDrawingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'page_drawings_${widget.noteId}';
      final String? drawingsJson = prefs.getString(key);

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

      // Load tool settings
      _currentColor = Color(prefs.getInt('drawing_color_${widget.noteId}') ?? Colors.red.value);
      _strokeWidth = prefs.getDouble('drawing_stroke_${widget.noteId}') ?? 3.0;
      _toolbarVisible = prefs.getBool('drawing_toolbar_${widget.noteId}') ?? true;

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

  // Load drawings for current page
  void _loadCurrentPageDrawing() {
    setState(() {
      // This will trigger a rebuild with the current page's drawings
    });
  }

  // Save current page drawing before switching
  void _saveCurrentPageDrawing(int pageNumber) {
    if (_pageDrawings[pageNumber]?.isNotEmpty == true) {
      _saveDrawingState();
    }
  }

  // Save drawing state to SharedPreferences
  Future<void> _saveDrawingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'page_drawings_${widget.noteId}';

      if (_pageDrawings.isNotEmpty) {
        final Map<String, dynamic> drawingsMap = {};
        _pageDrawings.forEach((pageNum, paths) {
          if (paths.isNotEmpty) {
            drawingsMap[pageNum.toString()] = paths.map((p) => p.toJson()).toList();
          }
        });

        if (drawingsMap.isNotEmpty) {
          final drawingsJson = json.encode(drawingsMap);
          await prefs.setString(key, drawingsJson);
        } else {
          await prefs.remove(key);
        }
      } else {
        await prefs.remove(key);
      }

      // Save tool settings
      await prefs.setInt('drawing_color_${widget.noteId}', _currentColor.value);
      await prefs.setDouble('drawing_stroke_${widget.noteId}', _strokeWidth);
      await prefs.setBool('drawing_toolbar_${widget.noteId}', _toolbarVisible);

    } catch (e) {
      print('Error saving drawing state: $e');
    }
  }

  // Clear drawing state from storage
  Future<void> _clearDrawingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('page_drawings_${widget.noteId}');
      await prefs.remove('drawing_color_${widget.noteId}');
      await prefs.remove('drawing_stroke_${widget.noteId}');
      await prefs.remove('drawing_toolbar_${widget.noteId}');
    } catch (e) {
      print('Error clearing drawing state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_isLoading) {
      return Stack(
        children: [
          widget.child,
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    final currentPagePaths = _currentPagePaths;

    return Stack(
      children: [
        // PDF Viewer (background)
        widget.child,

        // Drawing overlay (only when tool is active)
        if (_currentTool != DrawingTool.none)
          Positioned.fill(
            child: RepaintBoundary(
              key: _drawingKey,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  color: Colors.transparent,
                  child: CustomPaint(
                    painter: DrawingPainter(
                      paths: currentPagePaths,
                      currentPath: _currentPath,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),

        // Always show the drawing overlay for current page (even in select mode)
        if (_currentTool == DrawingTool.none && currentPagePaths.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: DrawingPainter(
                  paths: currentPagePaths,
                  currentPath: null,
                ),
                size: Size.infinite,
              ),
            ),
          ),

        // Drawing Toolbar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              transform: Matrix4.translationValues(
                  0,
                  _toolbarVisible ? 0 : -80,
                  0
              ),
              child: _buildToolbar(),
            ),
          ),
        ),

        // Toggle button
        Positioned(
          top: 0,
          right: 16,
          child: SafeArea(
            child: FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  _toolbarVisible = !_toolbarVisible;
                });
              },
              backgroundColor: Colors.white,
              child: Icon(
                _toolbarVisible ? Icons.keyboard_arrow_up : Icons.draw,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),

        // Tool indicator with page info
        if (_currentTool != DrawingTool.none)
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

        // Page drawing indicator (show if current page has drawings)
        if (currentPagePaths.isNotEmpty && _currentTool == DrawingTool.none)
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.draw, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Page ${widget.currentPage} has drawings',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToolbar() {
    final currentPagePaths = _currentPagePaths;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Select tool
            _buildToolButton(
              icon: Icons.touch_app,
              tool: DrawingTool.none,
              tooltip: 'Select Mode',
              color: Colors.grey[600],
            ),

            const SizedBox(width: 8),

            // Pen
            _buildToolButton(
              icon: Icons.edit,
              tool: DrawingTool.pen,
              tooltip: 'Pen',
              color: Colors.blue[600],
            ),

            const SizedBox(width: 8),

            // Highlighter
            _buildToolButton(
              icon: Icons.highlight,
              tool: DrawingTool.highlighter,
              tooltip: 'Highlighter',
              color: Colors.yellow[600],
            ),

            const SizedBox(width: 8),

            // Eraser
            _buildToolButton(
              icon: Icons.cleaning_services,
              tool: DrawingTool.eraser,
              tooltip: 'Eraser',
              color: Colors.red[400],
            ),

            const SizedBox(width: 16),

            // Color picker
            GestureDetector(
              onTap: _showColorPicker,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Stroke width
            GestureDetector(
              onTap: _showStrokeWidthPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: _strokeWidth.clamp(2, 8),
                      decoration: BoxDecoration(
                        color: _currentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_strokeWidth.toInt()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Undo (for current page only)
            IconButton(
              onPressed: currentPagePaths.isNotEmpty ? _undo : null,
              icon: const Icon(Icons.undo),
              iconSize: 20,
              tooltip: 'Undo',
            ),

            // Clear current page
            IconButton(
              onPressed: currentPagePaths.isNotEmpty ? _showClearCurrentPageDialog : null,
              icon: const Icon(Icons.clear),
              iconSize: 20,
              tooltip: 'Clear Page',
            ),

            // Clear all pages
            IconButton(
              onPressed: _pageDrawings.isNotEmpty ? _showClearAllDialog : null,
              icon: const Icon(Icons.clear_all),
              iconSize: 20,
              tooltip: 'Clear All Pages',
            ),

            // Save current page drawing
            IconButton(
              onPressed: currentPagePaths.isNotEmpty ? _saveDrawing : null,
              icon: const Icon(Icons.save),
              iconSize: 20,
              tooltip: 'Save Page Drawing',
              color: Colors.green[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required DrawingTool tool,
    required String tooltip,
    Color? color,
  }) {
    final isSelected = _currentTool == tool;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          setState(() {
            _currentTool = tool;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? (color ?? Colors.blue).withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: color ?? Colors.blue, width: 2) : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? (color ?? Colors.blue) : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  String _getToolName(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.none:
        return 'Select';
      case DrawingTool.pen:
        return 'Pen';
      case DrawingTool.highlighter:
        return 'Highlighter';
      case DrawingTool.eraser:
        return 'Eraser';
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_currentTool == DrawingTool.none) return;

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
      case DrawingTool.none:
        return;
    }

    _currentPath = DrawingPath(
      points: [DrawingPoint(offset: details.localPosition, paint: paint)],
      paint: paint,
    );

    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentTool == DrawingTool.none || _currentPath == null) return;

    _currentPath!.points.add(
      DrawingPoint(offset: details.localPosition, paint: _currentPath!.paint),
    );
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPath != null) {
      // Add to current page's drawings
      if (_pageDrawings[widget.currentPage] == null) {
        _pageDrawings[widget.currentPage] = [];
      }
      _pageDrawings[widget.currentPage]!.add(_currentPath!);

      _currentPath = null;
      setState(() {});
      _saveDrawingState(); // Save after each stroke
    }
  }

  void _showColorPicker() {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.brown,
      Colors.pink,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: Wrap(
          spacing: 8,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentColor = color;
                });
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _currentColor == color ? Colors.white : Colors.grey,
                    width: _currentColor == color ? 3 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showStrokeWidthPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stroke Width'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Width: ${_strokeWidth.toInt()}px'),
            Slider(
              value: _strokeWidth,
              min: 1.0,
              max: 10.0,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _strokeWidth = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _undo() {
    final currentPagePaths = _pageDrawings[widget.currentPage];
    if (currentPagePaths != null && currentPagePaths.isNotEmpty) {
      setState(() {
        currentPagePaths.removeLast();
        if (currentPagePaths.isEmpty) {
          _pageDrawings.remove(widget.currentPage);
        }
      });
      _saveDrawingState();
    }
  }

  void _showClearCurrentPageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Page ${widget.currentPage}'),
        content: Text('Remove all drawings from page ${widget.currentPage}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _pageDrawings.remove(widget.currentPage);
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

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Pages'),
        content: const Text('Remove all drawings from all pages? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _pageDrawings.clear();
              });
              _clearDrawingState();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDrawing() async {
    try {
      final renderObject = _drawingKey.currentContext?.findRenderObject();
      if (renderObject is RenderRepaintBoundary) {
        final image = await renderObject.toImage();
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();

        if (widget.onSave != null) {
          widget.onSave!(bytes);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Page ${widget.currentPage} drawing saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPath> paths;
  final DrawingPath? currentPath;

  DrawingPainter({
    required this.paths,
    this.currentPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final drawingPath in paths) {
      _drawPath(canvas, drawingPath);
    }

    if (currentPath != null) {
      _drawPath(canvas, currentPath!);
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}