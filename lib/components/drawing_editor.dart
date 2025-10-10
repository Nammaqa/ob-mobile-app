import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/note_service.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'drawing_models.dart';
import 'drawing_painter.dart';
import 'drawing_toolbar.dart';
import 'drawing_tools/pen_tool.dart';
import 'drawing_tools/pencil_tool.dart';
import 'drawing_tools/marker_tool.dart';
import 'drawing_tools/eraser_tool.dart';
import 'drawing_tools/selector_tool.dart';
import 'drawing_tools/text_tool.dart';
import 'drawing_tools/shape_tool.dart';
import 'drawing_tools/image_tool.dart';

// ============================================================================
// DRAWING OVERLAY WIDGET
// ============================================================================

class DrawingOverlay extends StatefulWidget {
  final Widget child;
  final Function(Uint8List)? onSave;
  final Function(Map<String, dynamic>)? onDrawingChanged;
  final String noteId;
  final int currentPage;

  const DrawingOverlay({
    Key? key,
    required this.child,
    required this.noteId,
    required this.currentPage,
    this.onSave,
    this.onDrawingChanged,
  }) : super(key: key);

  @override
  State<DrawingOverlay> createState() => _DrawingOverlayState();
}

// ============================================================================
// DRAWING OVERLAY STATE
// ============================================================================

class _DrawingOverlayState extends State<DrawingOverlay> with AutomaticKeepAliveClientMixin {

  // ========================================
  // STATE VARIABLES
  // ========================================

  // Current tool and settings
  DrawingTool _currentTool = DrawingTool.selector;
  Color _currentColor = Colors.black;
  double _strokeWidth = 2.0;
  double _zoomLevel = 1.0;
  bool _isTextMode = false;
  bool _showShapesDropdown = false;

  // Tool instances
  late PenTool _penTool;
  late PencilTool _pencilTool;
  late MarkerTool _markerTool;
  late EraserTool _eraserTool;
  late SelectorTool _selectorTool;
  late TextTool _textTool;
  late ShapeTool _shapeTool;
  late ImageTool _imageTool;

  // Page-specific data
  Map<int, List<DrawingPath>> _pageDrawings = {};
  Map<int, List<TextAnnotation>> _pageTextAnnotations = {};
  Map<int, List<ImageAnnotation>> _pageImageAnnotations = {};
  Map<int, List<ShapeAnnotation>> _pageShapeAnnotations = {};
  DrawingPath? _currentPath;

  // Undo/Redo stacks
  Map<int, List<List<DrawingPath>>> _undoStacks = {};
  Map<int, List<List<DrawingPath>>> _redoStacks = {};

  // Keys and controllers
  final GlobalKey _drawingKey = GlobalKey();
  final GlobalKey _cameraIconKey = GlobalKey();
  final NoteService _noteService = NoteService();
  final TextEditingController _textController = TextEditingController();

  // State flags
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _hasUnsavedChanges = false;
  DateTime? _lastSyncTime;
  Timer? _autoSyncTimer;

  // Image handling
  Map<String, ui.Image> _loadedImages = {};
  List<DrawingPath> _copiedPaths = [];

  static const Duration _autoSyncDelay = Duration(seconds: 3);

  @override
  bool get wantKeepAlive => true;

  // ========================================
  // COMPUTED PROPERTIES
  // ========================================

  List<DrawingPath> get _currentPagePaths => _pageDrawings[widget.currentPage] ?? [];
  List<TextAnnotation> get _currentPageTextAnnotations => _pageTextAnnotations[widget.currentPage] ?? [];
  List<ImageAnnotation> get _currentPageImageAnnotations => _pageImageAnnotations[widget.currentPage] ?? [];
  List<ShapeAnnotation> get _currentPageShapeAnnotations => _pageShapeAnnotations[widget.currentPage] ?? [];

  // ========================================
  // LIFECYCLE METHODS
  // ========================================

  @override
  void initState() {
    super.initState();
    _initializeTools();
    _loadDrawingStateFromFirebase();
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
    _autoSyncTimer?.cancel();
    _saveDrawingStateToFirebase();
    _textController.dispose();
    super.dispose();
  }

  // ========================================
  // INITIALIZATION
  // ========================================

  void _initializeTools() {
    _penTool = PenTool(color: _currentColor, strokeWidth: _strokeWidth);
    _pencilTool = PencilTool(color: _currentColor, strokeWidth: _strokeWidth);
    _markerTool = MarkerTool(color: _currentColor, strokeWidth: _strokeWidth);
    _eraserTool = EraserTool(strokeWidth: _strokeWidth);
    _selectorTool = SelectorTool();
    _textTool = TextTool(color: _currentColor);
    _shapeTool = ShapeTool(color: _currentColor, strokeWidth: _strokeWidth);
    _imageTool = ImageTool();
  }

  // ========================================
  // BUILD METHOD
  // ========================================

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

    return Stack(
      children: [
        _buildPdfViewer(),
        _buildOverlay(),
        DrawingToolbar(
          currentTool: _currentTool,
          currentColor: _currentColor,
          canUndo: _canUndo(),
          canRedo: _canRedo(),
          isSyncing: _isSyncing,
          hasUnsavedChanges: _hasUnsavedChanges,
          onToolSelected: _selectTool,
          onUndo: _undo,
          onRedo: _redo,
          onColorPicker: _showColorPicker,
          onShapesPressed: _toggleShapesDropdown,
          onImagePressed: _showImageOptions,
          onMoreOptions: _showFutureOptions,
          cameraIconKey: _cameraIconKey,
        ),
        if (_showShapesDropdown) _buildShapesDropdown(),
        if (_isTextMode && _textTool.textPosition != null) _buildTextInputDialog(),
        if (_currentTool != DrawingTool.selector) _buildToolIndicator(),
      ],
    );
  }

  // ========================================
  // UI BUILDING METHODS
  // ========================================

  Widget _buildPdfViewer() {
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      bottom: 0,
      child: Transform.scale(
        scale: _zoomLevel,
        child: widget.child,
      ),
    );
  }

  Widget _buildOverlay() {
    final shouldIgnoreGestures = _currentTool == DrawingTool.selector &&
        _selectorTool.selectedAnnotation == null;

    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () {
          if (_showShapesDropdown) {
            setState(() => _showShapesDropdown = false);
          }
        },
        child: IgnorePointer(
          ignoring: shouldIgnoreGestures,
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
                    paths: _currentPagePaths,
                    textAnnotations: _currentPageTextAnnotations,
                    imageAnnotations: _currentPageImageAnnotations,
                    shapeAnnotations: _currentPageShapeAnnotations,
                    loadedImages: _loadedImages,
                    currentPath: _currentPath,
                    selectedAnnotation: _selectorTool.selectedAnnotation,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolIndicator() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_getToolName(_currentTool)} - Page ${widget.currentPage}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  // ========================================
  // GESTURE HANDLING
  // ========================================

  void _onTapDown(TapDownDetails details) {
    if (_showShapesDropdown) return;

    switch (_currentTool) {
      case DrawingTool.text:
        _textTool.onTapDown(details.localPosition);
        setState(() => _isTextMode = true);
        break;
      case DrawingTool.zoom:
        _handleZoom(details.localPosition);
        break;
      case DrawingTool.selector:
        _selectorTool.selectAnnotation(
          details.localPosition,
          _currentPagePaths,
          _currentPageShapeAnnotations,
          _currentPageImageAnnotations,
          _currentPageTextAnnotations,
        );
        setState(() {});
        break;
      default:
        break;
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_showShapesDropdown) return;

    // Handle selector tool with selected annotation
    if (_currentTool == DrawingTool.selector && _selectorTool.selectedAnnotation != null) {
      _selectorTool.onPanStart(details.localPosition);
      _pushToUndoStack();
      return;
    }

    // Skip non-drawing tools
    if (_shouldSkipTool(_currentTool)) return;

    _pushToUndoStack();

    // Handle eraser
    if (_currentTool == DrawingTool.eraser) {
      _eraserTool.onPanStart(details.localPosition, _currentPagePaths);
      setState(() {});
      _scheduleAutoSync();
      return;
    }

    // Handle drawing tools
    _currentPath = _createPathForTool(details.localPosition);
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_showShapesDropdown) return;

    // Handle selector tool dragging
    if (_currentTool == DrawingTool.selector && _selectorTool.selectedAnnotation != null) {
      final newPosition = _selectorTool.onPanUpdate(details.localPosition);
      if (newPosition != null) {
        _updateSelectedAnnotationPosition(newPosition);
      }
      return;
    }

    // Handle eraser
    if (_currentTool == DrawingTool.eraser) {
      _eraserTool.onPanUpdate(details.localPosition, _currentPagePaths);
      setState(() {});
      _scheduleAutoSync();
      return;
    }

    // Handle drawing tools
    if (_currentPath != null) {
      _updatePathForTool(_currentPath!, details.localPosition);
      setState(() {});
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_showShapesDropdown) return;

    // Handle selector tool end
    if (_currentTool == DrawingTool.selector && _selectorTool.selectedAnnotation != null) {
      _selectorTool.onPanEnd();
      setState(() => _selectorTool.selectedAnnotation = null);
      _scheduleAutoSync();
      return;
    }

    // Handle eraser
    if (_currentTool == DrawingTool.eraser) return;

    // Save completed path
    if (_currentPath != null) {
      if (_pageDrawings[widget.currentPage] == null) {
        _pageDrawings[widget.currentPage] = [];
      }
      _pageDrawings[widget.currentPage]!.add(_currentPath!);
      _currentPath = null;
      setState(() {});
      _scheduleAutoSync();
    }
  }

  // ========================================
  // TOOL HELPERS
  // ========================================

  bool _shouldSkipTool(DrawingTool tool) {
    return tool == DrawingTool.selector ||
        tool == DrawingTool.text ||
        tool == DrawingTool.camera ||
        tool == DrawingTool.copy ||
        tool == DrawingTool.zoom ||
        tool == DrawingTool.imageUploader ||
        tool == DrawingTool.future;
  }

  DrawingPath? _createPathForTool(Offset position) {
    switch (_currentTool) {
      case DrawingTool.ballpen:
        return _penTool.onPanStart(position);
      case DrawingTool.pencil:
        return _pencilTool.onPanStart(position);
      case DrawingTool.marker:
        return _markerTool.onPanStart(position);
      default:
        return null;
    }
  }

  void _updatePathForTool(DrawingPath path, Offset position) {
    switch (_currentTool) {
      case DrawingTool.ballpen:
        _penTool.onPanUpdate(path, position);
        break;
      case DrawingTool.pencil:
        _pencilTool.onPanUpdate(path, position);
        break;
      case DrawingTool.marker:
        _markerTool.onPanUpdate(path, position);
        break;
      default:
        break;
    }
  }

  void _updateSelectedAnnotationPosition(Offset newPosition) {
    setState(() {
      final annotation = _selectorTool.selectedAnnotation;

      if (annotation is DrawingPath) {
        _updateDrawingPathPosition(annotation, newPosition);
      } else if (annotation is ShapeAnnotation) {
        _updateShapePosition(annotation, newPosition);
      } else if (annotation is ImageAnnotation) {
        _updateImagePosition(annotation, newPosition);
      } else if (annotation is TextAnnotation) {
        _updateTextPosition(annotation, newPosition);
      }
    });
    _scheduleAutoSync();
  }

  void _updateDrawingPathPosition(DrawingPath path, Offset newPosition) {
    final index = _currentPagePaths.indexOf(path);
    if (index != -1) {
      final offsetDelta = newPosition - path.points.first.offset;
      final newPoints = path.points.map((point) => DrawingPoint(
        offset: point.offset + offsetDelta,
        paint: point.paint,
      )).toList();

      _pageDrawings[widget.currentPage]![index] = DrawingPath(
        points: newPoints,
        paint: path.paint,
        tool: path.tool,
      );
    }
  }

  void _updateShapePosition(ShapeAnnotation shape, Offset newPosition) {
    final index = _currentPageShapeAnnotations.indexOf(shape);
    if (index != -1) {
      _pageShapeAnnotations[widget.currentPage]![index] = ShapeAnnotation(
        position: newPosition,
        shapeType: shape.shapeType,
        size: shape.size,
        color: shape.color,
        strokeWidth: shape.strokeWidth,
      );
    }
  }

  void _updateImagePosition(ImageAnnotation image, Offset newPosition) {
    final index = _currentPageImageAnnotations.indexOf(image);
    if (index != -1) {
      _pageImageAnnotations[widget.currentPage]![index] = ImageAnnotation(
        position: newPosition,
        imagePath: image.imagePath,
        size: image.size,
      );
    }
  }

  void _updateTextPosition(TextAnnotation text, Offset newPosition) {
    final index = _currentPageTextAnnotations.indexOf(text);
    if (index != -1) {
      _pageTextAnnotations[widget.currentPage]![index] = TextAnnotation(
        position: newPosition,
        text: text.text,
        style: text.style,
      );
    }
  }

  // ========================================
  // TOOL SELECTION AND CONFIGURATION
  // ========================================

  void _selectTool(DrawingTool tool) {
    setState(() {
      _currentTool = tool;
      _isTextMode = tool == DrawingTool.text;
      _showShapesDropdown = false;
      if (!_isTextMode) {
        _textTool.clearTextPosition();
      }
    });
  }

  void _updateToolColors(Color color) {
    _penTool.updateColor(color);
    _pencilTool.updateColor(color);
    _markerTool.updateColor(color);
    _textTool.updateColor(color);
    _shapeTool.updateColor(color);
  }

  void _updateToolStrokeWidths(double width) {
    _penTool.updateStrokeWidth(width);
    _pencilTool.updateStrokeWidth(width);
    _markerTool.updateStrokeWidth(width);
    _eraserTool.updateStrokeWidth(width);
    _shapeTool.updateStrokeWidth(width);
  }

  String _getToolName(DrawingTool tool) {
    const toolNames = {
      DrawingTool.selector: 'Selector',
      DrawingTool.ballpen: 'Ball Pen',
      DrawingTool.pencil: 'Pencil',
      DrawingTool.marker: 'Marker',
      DrawingTool.eraser: 'Eraser',
      DrawingTool.text: 'Text',
      DrawingTool.zoom: 'Zoom',
    };
    return toolNames[tool] ?? 'Tool';
  }

  // ========================================
  // SHAPES DROPDOWN
  // ========================================

  void _toggleShapesDropdown() {
    setState(() => _showShapesDropdown = !_showShapesDropdown);
  }

  Widget _buildShapesDropdown() {
    final RenderBox? renderBox = _cameraIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final position = renderBox.localToGlobal(Offset.zero);
    final iconSize = renderBox.size;

    return Positioned(
      left: position.dx + 20,
      top: position.dy + iconSize.height - 125,
      child: GestureDetector(
        onTap: () {},
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Select Shape',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildShapeItem(ShapeType.circle, 'Circle', Icons.circle_outlined),
                    _buildShapeItem(ShapeType.square, 'Square', Icons.square_outlined),
                    _buildShapeItem(ShapeType.triangle, 'Triangle', Icons.change_history),
                    _buildShapeItem(ShapeType.rectangle, 'Rectangle', Icons.rectangle_outlined),
                    _buildShapeItem(ShapeType.star, 'Star', Icons.star_outline),
                    _buildShapeItem(ShapeType.arrow, 'Arrow', Icons.arrow_forward),
                    _buildShapeItem(ShapeType.heart, 'Heart', Icons.favorite_border),
                    _buildShapeItem(ShapeType.pentagon, 'Pentagon', Icons.pentagon_outlined),
                    _buildShapeItem(ShapeType.hexagon, 'Hexagon', Icons.hexagon_outlined),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShapeItem(ShapeType shapeType, String label, IconData icon) {
    return InkWell(
      onTap: () => _onShapeSelected(shapeType),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF374151)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _onShapeSelected(ShapeType shapeType) {
    setState(() => _showShapesDropdown = false);
    _pushToUndoStack();

    final screenSize = MediaQuery.of(context).size;
    final shapeAnnotation = _shapeTool.createShape(shapeType, screenSize);

    if (_pageShapeAnnotations[widget.currentPage] == null) {
      _pageShapeAnnotations[widget.currentPage] = [];
    }

    _pageShapeAnnotations[widget.currentPage]!.add(shapeAnnotation);
    setState(() {});
    _scheduleAutoSync();
  }

  // ========================================
  // TEXT TOOL DIALOG
  // ========================================

  Widget _buildTextInputDialog() {
    return Positioned(
      left: _textTool.textPosition!.dx,
      top: _textTool.textPosition!.dy + 60,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter text...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _cancelTextInput,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addTextAnnotation,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTextAnnotation() {
    final textAnnotation = _textTool.createTextAnnotation(_textController.text);

    if (textAnnotation != null) {
      _pushToUndoStack();

      if (_pageTextAnnotations[widget.currentPage] == null) {
        _pageTextAnnotations[widget.currentPage] = [];
      }

      _pageTextAnnotations[widget.currentPage]!.add(textAnnotation);
      _textController.clear();

      setState(() {
        _textTool.clearTextPosition();
        _isTextMode = false;
      });

      _scheduleAutoSync();
    }
  }

  void _cancelTextInput() {
    setState(() {
      _textTool.clearTextPosition();
      _isTextMode = false;
    });
    _textController.clear();
  }

  // ========================================
  // IMAGE HANDLING
  // ========================================

  void _showImageOptions() {
    final screenWidth = MediaQuery.of(context).size.width;

    showMenu<String>(
      context: context,
      color: Colors.white,
      position: RelativeRect.fromLTRB(screenWidth * 0.58, 185, screenWidth * 0.58, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      items: [
        PopupMenuItem<String>(
          value: 'gallery',
          child: Row(
            children: [
              Icon(Icons.photo_library, color: Colors.black, size: 20),
              const SizedBox(width: 12),
              const Text('Select from Gallery', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'camera',
          child: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.black, size: 20),
              const SizedBox(width: 12),
              const Text('Capture Image', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'gallery') {
        _pickImageFromGallery();
      } else if (value == 'camera') {
        _captureImageFromCamera();
      }
    });
  }

  Future<void> _captureImageFromCamera() async {
    final imagePath = await _imageTool.captureImageFromCamera();
    if (imagePath != null) {
      await _addImageToCurrentPage(imagePath);
    } else {
      _showErrorSnackBar('Failed to capture image');
    }
  }

  Future<void> _pickImageFromGallery() async {
    final imagePath = await _imageTool.pickImageFromGallery();
    if (imagePath != null) {
      await _addImageToCurrentPage(imagePath);
    } else {
      _showErrorSnackBar('Failed to pick image');
    }
  }

  Future<void> _addImageToCurrentPage(String imagePath) async {
    try {
      final screenSize = MediaQuery.of(context).size;
      final imageAnnotation = await _imageTool.createImageAnnotation(imagePath, screenSize);

      if (imageAnnotation != null) {
        final image = await _imageTool.loadImageFromPath(imagePath);
        if (image != null) {
          _loadedImages[imagePath] = image;
        }

        _pushToUndoStack();

        if (_pageImageAnnotations[widget.currentPage] == null) {
          _pageImageAnnotations[widget.currentPage] = [];
        }

        _pageImageAnnotations[widget.currentPage]!.add(imageAnnotation);
        setState(() {});
        _scheduleAutoSync();
        _showSuccessSnackBar('Image added successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add image: $e');
    }
  }

  // ========================================
  // COLOR PICKER
  // ========================================

  void _showColorPicker() {
    final colors = [
      Colors.black, Colors.red, Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.yellow, Colors.brown, Colors.pink, Colors.cyan,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentColor = color;
                  _updateToolColors(color);
                });
                Navigator.of(context).pop();
                _scheduleAutoSync();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _currentColor == color ? Colors.blue : Colors.grey,
                    width: _currentColor == color ? 3 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ========================================
  // MORE OPTIONS
  // ========================================

  void _showFutureOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'More Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Stroke Settings'),
              onTap: () {
                Navigator.pop(context);
                _showStrokeSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Copy All'),
              onTap: () {
                Navigator.pop(context);
                _copySelectedContent();
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear Page'),
              onTap: () {
                Navigator.pop(context);
                _clearCurrentPage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export'),
              onTap: () {
                Navigator.pop(context);
                _exportDrawing();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStrokeSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stroke Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stroke Width: ${_strokeWidth.toInt()}px'),
            Slider(
              value: _strokeWidth,
              min: 1.0,
              max: 20.0,
              divisions: 19,
              onChanged: (value) {
                setState(() {
                  _strokeWidth = value;
                  _updateToolStrokeWidths(value);
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _copySelectedContent() {
    if (_currentPagePaths.isNotEmpty) {
      _copiedPaths = List<DrawingPath>.from(_currentPagePaths);
      _showSuccessSnackBar('Content copied');
    }
  }

  void _clearCurrentPage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Page'),
        content: const Text('Are you sure you want to clear all content on this page?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pushToUndoStack();
              setState(() {
                _pageDrawings[widget.currentPage] = [];
                _pageTextAnnotations[widget.currentPage] = [];
                _pageImageAnnotations[widget.currentPage] = [];
                _pageShapeAnnotations[widget.currentPage] = [];
              });
              _scheduleAutoSync();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportDrawing() {
    _showSuccessSnackBar('Export feature coming soon');
  }

  void _handleZoom(Offset position) {
    setState(() {
      _zoomLevel = _zoomLevel == 1.0 ? 1.5 : _zoomLevel == 1.5 ? 2.0 : 1.0;
    });
  }

  // ========================================
  // UNDO/REDO FUNCTIONALITY
  // ========================================

  void _pushToUndoStack() {
    final pageNum = widget.currentPage;
    if (_undoStacks[pageNum] == null) _undoStacks[pageNum] = [];

    _undoStacks[pageNum]!.add(List<DrawingPath>.from(_currentPagePaths));

    if (_undoStacks[pageNum]!.length > 50) {
      _undoStacks[pageNum]!.removeAt(0);
    }

    _redoStacks[pageNum] = [];
  }

  bool _canUndo() => _undoStacks[widget.currentPage]?.isNotEmpty ?? false;
  bool _canRedo() => _redoStacks[widget.currentPage]?.isNotEmpty ?? false;

  void _undo() {
    final pageNum = widget.currentPage;
    final undoStack = _undoStacks[pageNum];

    if (undoStack != null && undoStack.isNotEmpty) {
      if (_redoStacks[pageNum] == null) _redoStacks[pageNum] = [];
      _redoStacks[pageNum]!.add(List<DrawingPath>.from(_currentPagePaths));

      final previousState = undoStack.removeLast();
      _pageDrawings[pageNum] = List<DrawingPath>.from(previousState);

      setState(() {});
      _scheduleAutoSync();
    }
  }

  void _redo() {
    final pageNum = widget.currentPage;
    final redoStack = _redoStacks[pageNum];

    if (redoStack != null && redoStack.isNotEmpty) {
      if (_undoStacks[pageNum] == null) _undoStacks[pageNum] = [];
      _undoStacks[pageNum]!.add(List<DrawingPath>.from(_currentPagePaths));

      final nextState = redoStack.removeLast();
      _pageDrawings[pageNum] = List<DrawingPath>.from(nextState);

      setState(() {});
      _scheduleAutoSync();
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _scheduleAutoSync() {
    _hasUnsavedChanges = true;
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer(_autoSyncDelay, () {
      _saveDrawingStateToFirebase();
    });
  }

  // ========================================
  // FIREBASE AND LOCAL STORAGE
  // ========================================

  Future<void> _loadDrawingStateFromFirebase() async {
    try {
      setState(() => _isLoading = true);

      final note = await _noteService.getNote(widget.noteId);
      if (note != null && note.drawingData != null) {
        await _parseDrawingData(note.drawingData!);
        _lastSyncTime = DateTime.now();
      } else {
        await _loadDrawingStateLocally();
      }
    } catch (e) {
      print('Error loading drawing state from Firebase: $e');
      await _loadDrawingStateLocally();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _parseDrawingData(Map<String, dynamic> drawingData) async {
    try {
      // Parse drawings
      if (drawingData['drawings'] != null) {
        final drawingsMap = drawingData['drawings'] as Map<String, dynamic>;
        _pageDrawings.clear();

        drawingsMap.forEach((pageStr, pathsList) {
          final pageNum = int.parse(pageStr);
          final List<DrawingPath> paths = (pathsList as List)
              .map((p) => DrawingPath.fromJson(p))
              .toList();
          _pageDrawings[pageNum] = paths;
        });
      }

      // Parse text annotations
      if (drawingData['texts'] != null) {
        final textsMap = drawingData['texts'] as Map<String, dynamic>;
        _pageTextAnnotations.clear();

        textsMap.forEach((pageStr, textsList) {
          final pageNum = int.parse(pageStr);
          final List<TextAnnotation> texts = (textsList as List)
              .map((t) => TextAnnotation.fromJson(t))
              .toList();
          _pageTextAnnotations[pageNum] = texts;
        });
      }

      // Parse image annotations
      if (drawingData['images'] != null) {
        final imagesMap = drawingData['images'] as Map<String, dynamic>;
        _pageImageAnnotations.clear();

        imagesMap.forEach((pageStr, imagesList) {
          final pageNum = int.parse(pageStr);
          final List<ImageAnnotation> images = (imagesList as List)
              .map((i) => ImageAnnotation.fromJson(i))
              .toList();
          _pageImageAnnotations[pageNum] = images;
        });

        await _loadImagesFromAnnotations();
      }

      // Parse shape annotations
      if (drawingData['shapes'] != null) {
        final shapesMap = drawingData['shapes'] as Map<String, dynamic>;
        _pageShapeAnnotations.clear();

        shapesMap.forEach((pageStr, shapesList) {
          final pageNum = int.parse(pageStr);
          final List<ShapeAnnotation> shapes = (shapesList as List)
              .map((s) => ShapeAnnotation.fromJson(s))
              .toList();
          _pageShapeAnnotations[pageNum] = shapes;
        });
      }

      // Parse settings
      if (drawingData['settings'] != null) {
        final settings = drawingData['settings'] as Map<String, dynamic>;
        _currentColor = Color(settings['color'] ?? Colors.black.value);
        _strokeWidth = (settings['strokeWidth'] ?? 2.0).toDouble();
        _updateToolColors(_currentColor);
        _updateToolStrokeWidths(_strokeWidth);
      }
    } catch (e) {
      print('Error parsing drawing data: $e');
    }
  }

  Future<void> _loadImagesFromAnnotations() async {
    for (final imageAnnotations in _pageImageAnnotations.values) {
      for (final imageAnnotation in imageAnnotations) {
        final image = await _imageTool.loadImageFromPath(imageAnnotation.imagePath);
        if (image != null) {
          _loadedImages[imageAnnotation.imagePath] = image;
        }
      }
    }
  }

  Future<void> _saveDrawingStateToFirebase() async {
    if (_isSyncing || !_hasUnsavedChanges) return;

    try {
      setState(() => _isSyncing = true);

      final Map<String, dynamic> drawingData = _buildDrawingDataMap();
      await _noteService.saveDrawingData(widget.noteId, drawingData);
      await _saveDrawingStateLocally();

      _lastSyncTime = DateTime.now();
      _hasUnsavedChanges = false;

      if (widget.onDrawingChanged != null) {
        widget.onDrawingChanged!(drawingData);
      }
    } catch (e) {
      print('Error saving drawing state to Firebase: $e');
      await _saveDrawingStateLocally();
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Map<String, dynamic> _buildDrawingDataMap() {
    final Map<String, dynamic> drawingData = {
      'drawings': {},
      'texts': {},
      'images': {},
      'shapes': {},
      'settings': {
        'color': _currentColor.value,
        'strokeWidth': _strokeWidth,
      },
      'lastModified': DateTime.now().toIso8601String(),
    };

    // Add drawings
    _pageDrawings.forEach((pageNum, paths) {
      if (paths.isNotEmpty) {
        drawingData['drawings'][pageNum.toString()] =
            paths.map((p) => p.toJson()).toList();
      }
    });

    // Add text annotations
    _pageTextAnnotations.forEach((pageNum, texts) {
      if (texts.isNotEmpty) {
        drawingData['texts'][pageNum.toString()] =
            texts.map((t) => t.toJson()).toList();
      }
    });

    // Add image annotations
    _pageImageAnnotations.forEach((pageNum, images) {
      if (images.isNotEmpty) {
        drawingData['images'][pageNum.toString()] =
            images.map((i) => i.toJson()).toList();
      }
    });

    // Add shape annotations
    _pageShapeAnnotations.forEach((pageNum, shapes) {
      if (shapes.isNotEmpty) {
        drawingData['shapes'][pageNum.toString()] =
            shapes.map((s) => s.toJson()).toList();
      }
    });

    return drawingData;
  }

  Future<void> _loadDrawingStateLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'page_drawings_${widget.noteId}';
      final String textKey = 'page_texts_${widget.noteId}';
      final String imageKey = 'page_images_${widget.noteId}';
      final String shapeKey = 'page_shapes_${widget.noteId}';

      // Load drawings
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

      // Load text annotations
      final String? textsJson = prefs.getString(textKey);
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

      // Load image annotations
      final String? imagesJson = prefs.getString(imageKey);
      if (imagesJson != null) {
        final Map<String, dynamic> imagesMap = json.decode(imagesJson);
        _pageImageAnnotations.clear();

        imagesMap.forEach((pageStr, imagesList) {
          final pageNum = int.parse(pageStr);
          final List<ImageAnnotation> images = (imagesList as List)
              .map((i) => ImageAnnotation.fromJson(i))
              .toList();
          _pageImageAnnotations[pageNum] = images;
        });

        await _loadImagesFromAnnotations();
      }

      // Load shape annotations
      final String? shapesJson = prefs.getString(shapeKey);
      if (shapesJson != null) {
        final Map<String, dynamic> shapesMap = json.decode(shapesJson);
        _pageShapeAnnotations.clear();

        shapesMap.forEach((pageStr, shapesList) {
          final pageNum = int.parse(pageStr);
          final List<ShapeAnnotation> shapes = (shapesList as List)
              .map((s) => ShapeAnnotation.fromJson(s))
              .toList();
          _pageShapeAnnotations[pageNum] = shapes;
        });
      }

      // Load settings
      _currentColor = Color(prefs.getInt('drawing_color_${widget.noteId}') ?? Colors.black.value);
      _strokeWidth = prefs.getDouble('drawing_stroke_${widget.noteId}') ?? 2.0;
    } catch (e) {
      print('Error loading drawing state locally: $e');
    }
  }

  Future<void> _saveDrawingStateLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'page_drawings_${widget.noteId}';
      final String textKey = 'page_texts_${widget.noteId}';
      final String imageKey = 'page_images_${widget.noteId}';
      final String shapeKey = 'page_shapes_${widget.noteId}';

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

      // Save image annotations
      if (_pageImageAnnotations.isNotEmpty) {
        final Map<String, dynamic> imagesMap = {};
        _pageImageAnnotations.forEach((pageNum, images) {
          if (images.isNotEmpty) {
            imagesMap[pageNum.toString()] = images.map((i) => i.toJson()).toList();
          }
        });

        if (imagesMap.isNotEmpty) {
          await prefs.setString(imageKey, json.encode(imagesMap));
        } else {
          await prefs.remove(imageKey);
        }
      } else {
        await prefs.remove(imageKey);
      }

      // Save shape annotations
      if (_pageShapeAnnotations.isNotEmpty) {
        final Map<String, dynamic> shapesMap = {};
        _pageShapeAnnotations.forEach((pageNum, shapes) {
          if (shapes.isNotEmpty) {
            shapesMap[pageNum.toString()] = shapes.map((s) => s.toJson()).toList();
          }
        });

        if (shapesMap.isNotEmpty) {
          await prefs.setString(shapeKey, json.encode(shapesMap));
        } else {
          await prefs.remove(shapeKey);
        }
      } else {
        await prefs.remove(shapeKey);
      }

      // Save settings
      await prefs.setInt('drawing_color_${widget.noteId}', _currentColor.value);
      await prefs.setDouble('drawing_stroke_${widget.noteId}', _strokeWidth);
    } catch (e) {
      print('Error saving drawing state locally: $e');
    }
  }

  void _loadCurrentPageDrawing() {
    setState(() {});
  }

  void _saveCurrentPageDrawing(int pageNumber) {
    if (_pageDrawings[pageNumber]?.isNotEmpty == true ||
        _pageTextAnnotations[pageNumber]?.isNotEmpty == true ||
        _pageImageAnnotations[pageNumber]?.isNotEmpty == true ||
        _pageShapeAnnotations[pageNumber]?.isNotEmpty == true) {
      _scheduleAutoSync();
    }
  }
}