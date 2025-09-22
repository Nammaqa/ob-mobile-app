// components/drawing_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/note_service.dart';
import 'shape_manager.dart';
import 'image_manager.dart';
import 'text_manager.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';

enum DrawingTool {
  none,
  select,
  pen,
  highlighter,
  eraser,
  shapes,  // Consolidated shapes tool
  text,
  note,
  camera,  // New camera tool
  magnifier,
  lasso,
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

class _DrawingOverlayState extends State<DrawingOverlay> with AutomaticKeepAliveClientMixin {
  DrawingTool _currentTool = DrawingTool.select;
  ShapeType _selectedShapeType = ShapeType.rectangle;
  Color _currentColor = Colors.black;
  double _strokeWidth = 2.0;
  double _magnification = 1.0;
  bool _isTextMode = false;

  // Store drawings, annotations and images per page
  Map<int, List<DrawingPath>> _pageDrawings = {};
  Map<int, List<TextAnnotation>> _pageTextAnnotations = {};
  Map<int, List<ImageAnnotation>> _pageImageAnnotations = {};
  DrawingPath? _currentPath;

  // Undo/Redo stacks per page
  Map<int, List<List<DrawingPath>>> _undoStacks = {};
  Map<int, List<List<DrawingPath>>> _redoStacks = {};

  final GlobalKey _drawingKey = GlobalKey();
  bool _isLoading = true;

  // Firestore integration
  final NoteService _noteService = NoteService();
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  Timer? _autoSyncTimer;
  bool _hasUnsavedChanges = false;

  // Text editing
  TextEditingController _textController = TextEditingController();
  Offset? _textPosition;

  // Image handling
  Map<String, ui.Image> _loadedImages = {};

  // Auto-sync delay
  static const Duration _autoSyncDelay = Duration(seconds: 3);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
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

  // Getters for current page content
  List<DrawingPath> get _currentPagePaths => _pageDrawings[widget.currentPage] ?? [];
  List<TextAnnotation> get _currentPageTextAnnotations => _pageTextAnnotations[widget.currentPage] ?? [];
  List<ImageAnnotation> get _currentPageImageAnnotations => _pageImageAnnotations[widget.currentPage] ?? [];

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
        // PDF Viewer (background)
        _buildPdfViewer(),

        // Drawing overlay
        if (_currentTool != DrawingTool.select) _buildDrawingOverlay(),

        // Always show existing drawings
        if (_currentTool == DrawingTool.select && _hasExistingContent()) _buildExistingContentOverlay(),

        // Toolbar
        _buildToolbar(),

        // Text input dialog
        if (_isTextMode && _textPosition != null) _buildTextInputDialog(),

        // Tool indicator
        if (_currentTool != DrawingTool.select) _buildToolIndicator(),
      ],
    );
  }

  Widget _buildPdfViewer() {
    return Positioned(
      top: 70, // Height of toolbar
      left: 0,
      right: 0,
      bottom: 0,
      child: Transform.scale(
        scale: _magnification,
        child: widget.child,
      ),
    );
  }

  Widget _buildDrawingOverlay() {
    return Positioned(
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
                paths: _currentPagePaths,
                textAnnotations: _currentPageTextAnnotations,
                imageAnnotations: _currentPageImageAnnotations,
                loadedImages: _loadedImages,
                currentPath: _currentPath,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }

  bool _hasExistingContent() {
    return _currentPagePaths.isNotEmpty ||
        _currentPageTextAnnotations.isNotEmpty ||
        _currentPageImageAnnotations.isNotEmpty;
  }

  Widget _buildExistingContentOverlay() {
    return Positioned(
      top: 70,
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: CustomPaint(
          painter: DrawingPainter(
            paths: _currentPagePaths,
            textAnnotations: _currentPageTextAnnotations,
            imageAnnotations: _currentPageImageAnnotations,
            loadedImages: _loadedImages,
            currentPath: null,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
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
                // Sync indicator on the left
                _buildSyncIndicator(),

                // Center all the tools
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Basic tools
                      _buildBasicToolsSection(),
                      _buildSeparator(),

                      // Shape tools
                      _buildShapeToolSection(),
                      _buildSeparator(),

                      // Annotation tools
                      _buildAnnotationToolsSection(),
                      _buildSeparator(),

                      // Camera tools
                      _buildCameraToolSection(),
                      _buildSeparator(),

                      // Utility tools
                      _buildUtilityToolsSection(),
                      _buildSeparator(),

                      // Action tools (undo, redo, etc.)
                      _buildActionToolsSection(),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInputDialog() {
    return Positioned(
      left: _textPosition!.dx,
      top: _textPosition!.dy + 70,
      child: TextInputDialog(
        controller: _textController,
        onAdd: _addTextAnnotation,
        onCancel: _cancelTextInput,
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
            if (_isSyncing || _hasUnsavedChanges) ...[
              const SizedBox(width: 6),
              _buildSyncStatusIcon(),
            ],
          ],
        ),
      ),
    );
  }

  // Toolbar sections
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

  Widget _buildShapeToolSection() {
    return ShapeManager.buildShapeSelector(
      selectedShapeType: _selectedShapeType,
      isSelected: _currentTool == DrawingTool.shapes,
      onShapeSelected: (shapeType) {
        setState(() {
          _selectedShapeType = shapeType;
          _currentTool = DrawingTool.shapes;
        });
        _scheduleAutoSync();
      },
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

  Widget _buildCameraToolSection() {
    return ImageManager.buildCameraToolSection(
      isSelected: _currentTool == DrawingTool.camera,
      onTakePhoto: _takePicture,
      onPickFromGallery: _pickImageFromGallery,
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
          icon: Icons.sync,
          onTap: _hasUnsavedChanges ? () => _saveDrawingStateToFirebase() : null,
          tooltip: 'Sync Now',
        ),
        _buildToolButton(
          icon: Icons.more_horiz,
          onTap: _showMoreOptions,
          tooltip: 'More Options',
        ),
      ],
    );
  }

  // Helper widgets
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
              color: isSelected ? const Color(0xFF4A9EFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSelected ? Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.5)) : null,
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
      Colors.black, Colors.red, Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.yellow, Colors.brown, Colors.pink, Colors.cyan,
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
        _scheduleAutoSync();
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

  Widget _buildSyncIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSyncing)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else if (_hasUnsavedChanges)
            const Icon(Icons.cloud_upload, size: 12, color: Colors.orange)
          else
            Icon(Icons.cloud_done, size: 12, color: _lastSyncTime != null ? Colors.green : Colors.grey),
          const SizedBox(width: 4),
          Text(
            _isSyncing ? 'Syncing...' : (_hasUnsavedChanges ? 'Saving...' : 'Synced'),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusIcon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSyncing)
            const SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else if (_hasUnsavedChanges)
            const Icon(Icons.cloud_upload, size: 8, color: Colors.orange)
          else
            Icon(Icons.cloud_done, size: 8, color: _lastSyncTime != null ? Colors.green : Colors.grey),
          const SizedBox(width: 2),
          Text(
            _isSyncing ? 'Sync' : (_hasUnsavedChanges ? 'Save' : 'OK'),
            style: const TextStyle(color: Colors.white, fontSize: 8),
          ),
        ],
      ),
    );
  }

  // Event handlers
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
    if (_currentTool == DrawingTool.select || _currentTool == DrawingTool.text || _currentTool == DrawingTool.camera) return;

    _pushToUndoStack();
    final paint = _createPaintForTool(_currentTool);

    _currentPath = DrawingPath(
      points: [DrawingPoint(offset: details.localPosition, paint: paint)],
      paint: paint,
      tool: _currentTool,
      shapeType: _currentTool == DrawingTool.shapes ? _selectedShapeType : null,
    );

    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentPath == null) return;

    if (_currentTool == DrawingTool.shapes) {
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
      _scheduleAutoSync();
    }
  }

  Paint _createPaintForTool(DrawingTool tool) {
    final paint = Paint()
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (tool) {
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
      case DrawingTool.shapes:
        paint.color = _currentColor;
        paint.style = PaintingStyle.stroke;
        break;
      default:
        paint.color = _currentColor;
    }

    return paint;
  }

  // Tool management
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
      case DrawingTool.shapes: return 'Shapes';
      case DrawingTool.text: return 'Text';
      case DrawingTool.note: return 'Note';
      case DrawingTool.camera: return 'Camera';
      case DrawingTool.magnifier: return 'Magnifier';
      case DrawingTool.lasso: return 'Lasso';
      default: return 'Tool';
    }
  }

  // Text management
  void _addTextAnnotation() {
    if (TextManager.validateTextInput(_textController.text) && _textPosition != null) {
      _pushToUndoStack();

      if (_pageTextAnnotations[widget.currentPage] == null) {
        _pageTextAnnotations[widget.currentPage] = [];
      }

      final textAnnotation = TextManager.createTextAnnotation(
        position: _textPosition!,
        text: _textController.text,
        color: _currentColor,
      );

      _pageTextAnnotations[widget.currentPage]!.add(textAnnotation);

      _textController.clear();
      setState(() {
        _textPosition = null;
        _isTextMode = false;
      });

      _scheduleAutoSync();
    }
  }

  void _cancelTextInput() {
    setState(() {
      _textPosition = null;
      _isTextMode = false;
    });
    _textController.clear();
  }

  // Image management
  Future<void> _takePicture() async {
    final imagePath = await ImageManager.takePicture();
    if (imagePath != null) {
      await _addImageToCurrentPage(imagePath);
    } else {
      _showErrorSnackBar('Failed to take picture');
    }
  }

  Future<void> _pickImageFromGallery() async {
    final imagePath = await ImageManager.pickImageFromGallery();
    if (imagePath != null) {
      await _addImageToCurrentPage(imagePath);
    } else {
      _showErrorSnackBar('Failed to pick image from gallery');
    }
  }

  Future<void> _addImageToCurrentPage(String imagePath) async {
    try {
      final screenSize = MediaQuery.of(context).size;
      final imageAnnotation = await ImageManager.createImageAnnotation(imagePath, screenSize);

      if (imageAnnotation != null) {
        // Load and store the image
        final image = await ImageManager.loadImageFromPath(imagePath);
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

  // Undo/Redo functionality
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

  // Other handlers
  void _handleMagnification(Offset position) {
    setState(() {
      _magnification = _magnification == 1.0 ? 1.5 : 1.0;
    });
  }

  void _showStrokeWidthPicker() {
    // Implementation for stroke width picker dialog
  }

  void _showMoreOptions() {
    // Implementation for more options dialog
  }

  // Utility methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 2)),
    );
  }

  void _scheduleAutoSync() {
    _hasUnsavedChanges = true;
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer(_autoSyncDelay, () {
      _saveDrawingStateToFirebase();
    });
  }

  // Data persistence methods - now properly implemented
  Future<void> _loadDrawingStateFromFirebase() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // First try to load from Firebase
      final note = await _noteService.getNote(widget.noteId);
      if (note != null && note.drawingData != null) {
        await _parseDrawingData(note.drawingData!);
        _lastSyncTime = DateTime.now();
      } else {
        // Fall back to local storage if Firebase has no data
        await _loadDrawingStateLocally();
      }

    } catch (e) {
      print('Error loading drawing state from Firebase: $e');
      // Fall back to local storage if Firebase fails
      await _loadDrawingStateLocally();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

        // Load images
        await _loadImagesFromAnnotations();
      }

      // Parse drawing settings
      if (drawingData['settings'] != null) {
        final settings = drawingData['settings'] as Map<String, dynamic>;
        _currentColor = Color(settings['color'] ?? Colors.black.value);
        _strokeWidth = (settings['strokeWidth'] ?? 2.0).toDouble();
        _selectedShapeType = ShapeType.values[settings['selectedShapeType'] ?? 0];
      }
    } catch (e) {
      print('Error parsing drawing data: $e');
    }
  }

  Future<void> _loadImagesFromAnnotations() async {
    for (final imageAnnotations in _pageImageAnnotations.values) {
      for (final imageAnnotation in imageAnnotations) {
        final image = await ImageManager.loadImageFromPath(imageAnnotation.imagePath);
        if (image != null) {
          _loadedImages[imageAnnotation.imagePath] = image;
        }
      }
    }
  }

  Future<void> _saveDrawingStateToFirebase() async {
    if (_isSyncing || !_hasUnsavedChanges) return;

    try {
      setState(() {
        _isSyncing = true;
      });

      final Map<String, dynamic> drawingData = _buildDrawingDataMap();

      // Save to Firebase
      await _noteService.saveDrawingData(widget.noteId, drawingData);

      // Also save locally as backup
      await _saveDrawingStateLocally();

      _lastSyncTime = DateTime.now();
      _hasUnsavedChanges = false;

      // Notify parent widget
      if (widget.onDrawingChanged != null) {
        widget.onDrawingChanged!(drawingData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drawing synced'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      print('Error saving drawing state to Firebase: $e');
      // Fall back to local storage
      await _saveDrawingStateLocally();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed, saved locally: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildDrawingDataMap() {
    final Map<String, dynamic> drawingData = {
      'drawings': {},
      'texts': {},
      'images': {},
      'settings': {
        'color': _currentColor.value,
        'strokeWidth': _strokeWidth,
        'selectedShapeType': _selectedShapeType.index,
      },
      'lastModified': DateTime.now().toIso8601String(),
    };

    // Convert drawings
    _pageDrawings.forEach((pageNum, paths) {
      if (paths.isNotEmpty) {
        drawingData['drawings'][pageNum.toString()] =
            paths.map((p) => p.toJson()).toList();
      }
    });

    // Convert text annotations
    _pageTextAnnotations.forEach((pageNum, texts) {
      if (texts.isNotEmpty) {
        drawingData['texts'][pageNum.toString()] =
            texts.map((t) => t.toJson()).toList();
      }
    });

    // Convert image annotations
    _pageImageAnnotations.forEach((pageNum, images) {
      if (images.isNotEmpty) {
        drawingData['images'][pageNum.toString()] =
            images.map((i) => i.toJson()).toList();
      }
    });

    return drawingData;
  }

  // Keep local storage methods as backup
  Future<void> _loadDrawingStateLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'page_drawings_${widget.noteId}';
      final String textKey = 'page_texts_${widget.noteId}';
      final String imageKey = 'page_images_${widget.noteId}';
      final String? drawingsJson = prefs.getString(key);
      final String? textsJson = prefs.getString(textKey);
      final String? imagesJson = prefs.getString(imageKey);

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

      _currentColor = Color(prefs.getInt('drawing_color_${widget.noteId}') ?? Colors.black.value);
      _strokeWidth = prefs.getDouble('drawing_stroke_${widget.noteId}') ?? 2.0;
      _selectedShapeType = ShapeType.values[prefs.getInt('selected_shape_${widget.noteId}') ?? 0];

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

      await prefs.setInt('drawing_color_${widget.noteId}', _currentColor.value);
      await prefs.setDouble('drawing_stroke_${widget.noteId}', _strokeWidth);
      await prefs.setInt('selected_shape_${widget.noteId}', _selectedShapeType.index);

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
        _pageImageAnnotations[pageNumber]?.isNotEmpty == true) {
      _scheduleAutoSync();
    }
  }
}

// Custom painter for drawing all content
class DrawingPainter extends CustomPainter {
  final List<DrawingPath> paths;
  final List<TextAnnotation> textAnnotations;
  final List<ImageAnnotation> imageAnnotations;
  final Map<String, ui.Image> loadedImages;
  final DrawingPath? currentPath;

  DrawingPainter({
    required this.paths,
    required this.textAnnotations,
    required this.imageAnnotations,
    required this.loadedImages,
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

    // Draw images
    for (final imageAnnotation in imageAnnotations) {
      ImagePainter.drawImage(canvas, imageAnnotation, loadedImages);
    }

    // Draw text
    for (final textAnnotation in textAnnotations) {
      TextRenderer.drawText(canvas, textAnnotation);
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

    if (drawingPath.shapeType != null) {
      final points = drawingPath.points.map((p) => p.offset).toList();
      ShapePainter.drawShape(canvas, points, drawingPath.paint, drawingPath.shapeType!);
    } else {
      _drawFreeForm(canvas, drawingPath);
    }
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}