import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/note_service.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math' as math;

enum DrawingTool {
  none,
  undo,
  redo,
  selector,
  ballpen,
  pencil,
  marker,
  eraser,
  camera,
  copy,
  text,
  zoom,
  imageUploader,
  ruler,
  future,
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

  DrawingPath({
    required this.points,
    required this.paint,
    required this.tool,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p.toJson()).toList(),
      'color': paint.color.value,
      'strokeWidth': paint.strokeWidth,
      'blendMode': paint.blendMode.index,
      'tool': tool.index,
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

class ImageAnnotation {
  final Offset position;
  final String imagePath;
  final Size size;

  ImageAnnotation({
    required this.position,
    required this.imagePath,
    required this.size,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': position.dx,
      'y': position.dy,
      'imagePath': imagePath,
      'width': size.width,
      'height': size.height,
    };
  }

  factory ImageAnnotation.fromJson(Map<String, dynamic> json) {
    return ImageAnnotation(
      position: Offset(json['x'], json['y']),
      imagePath: json['imagePath'],
      size: Size(json['width'], json['height']),
    );
  }
}

// Custom icon paths for your PNG icons
class ToolbarIcons {
  static const String undo = 'assets/icons/undo.png';
  static const String redo = 'assets/icons/redo.png';
  static const String selector = 'assets/icons/selection_tool.png';
  static const String ballpen = 'assets/icons/ball_point_pen.png';
  static const String pencil = 'assets/icons/pencil.png';
  static const String marker = 'assets/icons/marker_pen.png';
  static const String eraser = 'assets/icons/eraser.png';
  static const String camera = 'assets/icons/camera.png';
  static const String copy = 'assets/icons/copy.png';
  static const String text = 'assets/icons/text.png';
  static const String zoom = 'assets/icons/zoom_in.png';
  static const String imageUploader = 'assets/icons/image.png';
  static const String ruler = 'assets/icons/ruler.png';
  static const String future = 'assets/icons/future.png';
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
  DrawingTool _currentTool = DrawingTool.selector;
  Color _currentColor = Colors.black;
  double _strokeWidth = 2.0;
  double _zoomLevel = 1.0;
  bool _isTextMode = false;

  Map<int, List<DrawingPath>> _pageDrawings = {};
  Map<int, List<TextAnnotation>> _pageTextAnnotations = {};
  Map<int, List<ImageAnnotation>> _pageImageAnnotations = {};
  DrawingPath? _currentPath;

  Map<int, List<List<DrawingPath>>> _undoStacks = {};
  Map<int, List<List<DrawingPath>>> _redoStacks = {};

  dynamic _selectedAnnotation; // Can be DrawingPath, ImageAnnotation, or TextAnnotation
  Offset? _dragStartPosition;
  Offset? _initialAnnotationPosition;

  final GlobalKey _drawingKey = GlobalKey();
  bool _isLoading = true;

  final NoteService _noteService = NoteService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  Timer? _autoSyncTimer;
  bool _hasUnsavedChanges = false;

  TextEditingController _textController = TextEditingController();
  Offset? _textPosition;

  Map<String, ui.Image> _loadedImages = {};
  List<DrawingPath> _copiedPaths = [];

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
        _buildPdfViewer(),
        _buildOverlay(),
        _buildStreamlinedToolbar(),
        if (_isTextMode && _textPosition != null) _buildTextInputDialog(),
        if (_currentTool != DrawingTool.selector) _buildToolIndicator(),
      ],
    );
  }

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
    // When selector tool is active and no annotation is selected, allow PDF navigation
    final shouldIgnoreGestures = _currentTool == DrawingTool.selector && _selectedAnnotation == null;

    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: shouldIgnoreGestures, // Ignore gestures to allow PDF navigation
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
                  selectedAnnotation: _selectedAnnotation,
                ),
                size: Size.infinite,
              ),
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

  Widget _buildStreamlinedToolbar() {
    return Stack(
      children: [
        // Main centered toolbar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    // Left spacer to push center content to middle
                    const SizedBox(width: 100),

                    // Center section: All main tools in a continuous row
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildToolButton(
                            iconPath: ToolbarIcons.selector,
                            icon: Icons.touch_app,
                            isSelected: _currentTool == DrawingTool.selector,
                            onTap: () => _selectTool(DrawingTool.selector),
                            tooltip: 'Selector',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            iconPath: ToolbarIcons.ballpen,
                            icon: Icons.edit,
                            isSelected: _currentTool == DrawingTool.ballpen,
                            onTap: () => _selectTool(DrawingTool.ballpen),
                            tooltip: 'Ball Pen',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            iconPath: ToolbarIcons.pencil,
                            icon: Icons.create,
                            isSelected: _currentTool == DrawingTool.pencil,
                            onTap: () => _selectTool(DrawingTool.pencil),
                            tooltip: 'Pencil',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            iconPath: ToolbarIcons.marker,
                            icon: Icons.brush,
                            isSelected: _currentTool == DrawingTool.marker,
                            onTap: () => _selectTool(DrawingTool.marker),
                            tooltip: 'Marker',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            iconPath: ToolbarIcons.eraser,
                            icon: Icons.clear,
                            isSelected: _currentTool == DrawingTool.eraser,
                            onTap: () => _selectTool(DrawingTool.eraser),
                            tooltip: 'Eraser',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            iconPath: ToolbarIcons.text,
                            icon: Icons.text_fields,
                            isSelected: _currentTool == DrawingTool.text,
                            onTap: () => _selectTool(DrawingTool.text),
                            tooltip: 'Text',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            iconPath: ToolbarIcons.camera,
                            icon: Icons.camera_alt,
                            onTap: _takePicture,
                            tooltip: 'Camera',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            iconPath: ToolbarIcons.imageUploader,
                            icon: Icons.image,
                            onTap: _pickImageFromGallery,
                            tooltip: 'Upload Image',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            iconPath: ToolbarIcons.zoom,
                            icon: Icons.zoom_in,
                            isSelected: _currentTool == DrawingTool.zoom,
                            onTap: () => _selectTool(DrawingTool.zoom),
                            tooltip: 'Zoom',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            iconPath: ToolbarIcons.future,
                            icon: Icons.more_vert,
                            onTap: _showFutureOptions,
                            tooltip: 'More Options',
                          ),
                        ],
                      ),
                    ),

                    // Right section: Color and status only
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        _buildColorIndicator(),
                        const SizedBox(width: 8),
                        _buildSyncStatus(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Separate Undo/Redo buttons in top-left corner
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCompactToolButton(
                  iconPath: ToolbarIcons.undo,
                  icon: Icons.undo,
                  onTap: _canUndo() ? _undo : null,
                  tooltip: 'Undo',
                  isEnabled: _canUndo(),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: const Color(0xFFE5E7EB),
                ),
                _buildCompactToolButton(
                  iconPath: ToolbarIcons.redo,
                  icon: Icons.redo,
                  onTap: _canRedo() ? _redo : null,
                  tooltip: 'Redo',
                  isEnabled: _canRedo(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactToolButton({
    required String iconPath,
    IconData? icon,
    required VoidCallback? onTap,
    required String tooltip,
    bool isEnabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(6),
            child: _buildIcon(iconPath, icon, false, isEnabled),
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required String iconPath,
    IconData? icon,
    bool isSelected = false,
    required VoidCallback? onTap,
    required String tooltip,
    bool isEnabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSelected ? null : Border.all(
                color: Colors.transparent,
                width: 1,
              ),
            ),
            child: _buildIcon(iconPath, icon, isSelected, isEnabled),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String iconPath, IconData? fallbackIcon, bool isSelected, bool isEnabled) {
    // Try to load the asset image first, fallback to Material icon
    return FutureBuilder<bool>(
      future: _checkAssetExists(iconPath),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          // Asset exists, use it
          return Image.asset(
            iconPath,
            width: 24,
            height: 24,
            color: !isEnabled
                ? const Color(0xFF9CA3AF)
                : isSelected
                ? Colors.white
                : const Color(0xFF374151),
            errorBuilder: (context, error, stackTrace) {
              // If asset fails to load, use fallback icon
              return Icon(
                fallbackIcon ?? Icons.help_outline,
                size: 24,
                color: !isEnabled
                    ? const Color(0xFF9CA3AF)
                    : isSelected
                    ? Colors.white
                    : const Color(0xFF374151),
              );
            },
          );
        } else {
          // Use fallback icon
          return Icon(
            fallbackIcon ?? Icons.help_outline,
            size: 24,
            color: !isEnabled
                ? const Color(0xFF9CA3AF)
                : isSelected
                ? Colors.white
                : const Color(0xFF374151),
          );
        }
      },
    );
  }

  Future<bool> _checkAssetExists(String assetPath) async {
    try {
      await DefaultAssetBundle.of(context).load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildColorIndicator() {
    return GestureDetector(
      onTap: _showColorPicker,
      child: Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _currentColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _isSyncing
            ? const Color(0xFF3B82F6).withOpacity(0.1)
            : _hasUnsavedChanges
            ? const Color(0xFFF59E0B).withOpacity(0.1)
            : const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _isSyncing
              ? const Color(0xFF3B82F6).withOpacity(0.3)
              : _hasUnsavedChanges
              ? const Color(0xFFF59E0B).withOpacity(0.3)
              : const Color(0xFF10B981).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSyncing)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF3B82F6)),
              ),
            )
          else
            Icon(
              _hasUnsavedChanges ? Icons.cloud_upload : Icons.cloud_done,
              size: 12,
              color: _hasUnsavedChanges
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981),
            ),
          const SizedBox(width: 4),
          Text(
            _isSyncing ? 'Syncing' : (_hasUnsavedChanges ? 'Saving' : 'Synced'),
            style: TextStyle(
              color: _isSyncing
                  ? const Color(0xFF3B82F6)
                  : _hasUnsavedChanges
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputDialog() {
    return Positioned(
      left: _textPosition!.dx,
      top: _textPosition!.dy + 60,
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

  // Tool functionality methods
  void _onTapDown(TapDownDetails details) {
    switch (_currentTool) {
      case DrawingTool.text:
        setState(() {
          _textPosition = details.localPosition;
          _isTextMode = true;
        });
        break;
      case DrawingTool.zoom:
        _handleZoom(details.localPosition);
        break;
      case DrawingTool.selector:
        _selectAnnotation(details.localPosition);
        break;
      default:
        break;
    }
  }

  void _selectAnnotation(Offset position) {
    setState(() {
      _selectedAnnotation = null;

      // Check for drawing paths
      for (final path in _currentPagePaths) {
        for (final point in path.points) {
          if ((point.offset - position).distance < 20.0) { // Hit-test radius
            _selectedAnnotation = path;
            _initialAnnotationPosition = path.points.first.offset; // Store initial position
            break;
          }
        }
        if (_selectedAnnotation != null) break;
      }

      // Check for image annotations
      if (_selectedAnnotation == null) {
        for (final image in _currentPageImageAnnotations) {
          final rect = Rect.fromLTWH(
            image.position.dx,
            image.position.dy,
            image.size.width,
            image.size.height,
          );
          if (rect.contains(position)) {
            _selectedAnnotation = image;
            _initialAnnotationPosition = image.position;
            break;
          }
        }
      }

      // Check for text annotations
      if (_selectedAnnotation == null) {
        for (final text in _currentPageTextAnnotations) {
          final textPainter = TextPainter(
            text: TextSpan(text: text.text, style: text.style),
            textDirection: TextDirection.ltr,
          )..layout();
          final rect = Rect.fromLTWH(
            text.position.dx,
            text.position.dy,
            textPainter.width,
            textPainter.height,
          );
          if (rect.contains(position)) {
            _selectedAnnotation = text;
            _initialAnnotationPosition = text.position;
            break;
          }
        }
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (_currentTool == DrawingTool.selector && _selectedAnnotation != null) {
      _dragStartPosition = details.localPosition;
      _pushToUndoStack();
      return;
    }

    if (_currentTool == DrawingTool.selector ||
        _currentTool == DrawingTool.text ||
        _currentTool == DrawingTool.camera ||
        _currentTool == DrawingTool.copy ||
        _currentTool == DrawingTool.zoom ||
        _currentTool == DrawingTool.imageUploader ||
        _currentTool == DrawingTool.future) return;

    _pushToUndoStack();

    if (_currentTool == DrawingTool.eraser) {
      _performErasure(details.localPosition);
      return;
    }

    final paint = _createPaintForTool(_currentTool);

    _currentPath = DrawingPath(
      points: [DrawingPoint(offset: details.localPosition, paint: paint)],
      paint: paint,
      tool: _currentTool,
    );

    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentTool == DrawingTool.selector && _selectedAnnotation != null && _dragStartPosition != null) {
      final delta = details.localPosition - _dragStartPosition!;
      final newPosition = _initialAnnotationPosition! + delta;

      setState(() {
        if (_selectedAnnotation is DrawingPath) {
          final index = _currentPagePaths.indexOf(_selectedAnnotation);
          if (index != -1) {
            final path = _currentPagePaths[index];
            final offsetDelta = newPosition - path.points.first.offset;
            final newPoints = path.points
                .map((point) => DrawingPoint(
              offset: point.offset + offsetDelta,
              paint: point.paint,
            ))
                .toList();
            _pageDrawings[widget.currentPage]![index] = DrawingPath(
              points: newPoints,
              paint: path.paint,
              tool: path.tool,
            );
          }
        } else if (_selectedAnnotation is ImageAnnotation) {
          final index = _currentPageImageAnnotations.indexOf(_selectedAnnotation);
          if (index != -1) {
            _pageImageAnnotations[widget.currentPage]![index] = ImageAnnotation(
              position: newPosition,
              imagePath: (_selectedAnnotation as ImageAnnotation).imagePath,
              size: (_selectedAnnotation as ImageAnnotation).size,
            );
          }
        } else if (_selectedAnnotation is TextAnnotation) {
          final index = _currentPageTextAnnotations.indexOf(_selectedAnnotation);
          if (index != -1) {
            _pageTextAnnotations[widget.currentPage]![index] = TextAnnotation(
              position: newPosition,
              text: (_selectedAnnotation as TextAnnotation).text,
              style: (_selectedAnnotation as TextAnnotation).style,
            );
          }
        }
      });
      _scheduleAutoSync();
      return;
    }

    if (_currentTool == DrawingTool.eraser) {
      _performErasure(details.localPosition);
      return;
    }

    if (_currentPath == null) return;

    _currentPath!.points.add(
      DrawingPoint(offset: details.localPosition, paint: _currentPath!.paint),
    );

    setState(() {});
  }

  void _performErasure(Offset position) {
    final eraserRadius = _strokeWidth * 3; // Increase eraser radius
    final pathsToRemove = <DrawingPath>[];

    for (final path in _currentPagePaths) {
      for (final point in path.points) {
        if ((point.offset - position).distance < eraserRadius) {
          pathsToRemove.add(path);
          break;
        }
      }
    }

    if (pathsToRemove.isNotEmpty) {
      setState(() {
        _pageDrawings[widget.currentPage]!.removeWhere((path) => pathsToRemove.contains(path));
      });
      _scheduleAutoSync();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentTool == DrawingTool.selector && _selectedAnnotation != null) {
      _selectedAnnotation = null;
      _dragStartPosition = null;
      _initialAnnotationPosition = null;
      _scheduleAutoSync();
      return;
    }

    // Don't create paths for eraser tool
    if (_currentTool == DrawingTool.eraser) {
      return;
    }

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
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (tool) {
      case DrawingTool.ballpen:
        paint.color = _currentColor;
        paint.strokeWidth = _strokeWidth;
        break;
      case DrawingTool.pencil:
        paint.color = _currentColor.withOpacity(0.7);
        paint.strokeWidth = _strokeWidth * 0.8;
        break;
      case DrawingTool.marker:
        paint.color = _currentColor.withOpacity(0.4);
        paint.strokeWidth = _strokeWidth * 3;
        break;
      case DrawingTool.eraser:
      // This shouldn't be used since eraser doesn't create paths
        paint.color = Colors.transparent;
        paint.strokeWidth = _strokeWidth * 2;
        break;
      case DrawingTool.ruler:
        paint.color = _currentColor;
        paint.strokeWidth = 1.0;
        break;
      default:
        paint.color = _currentColor;
        paint.strokeWidth = _strokeWidth;
    }

    return paint;
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
      case DrawingTool.selector:
        return 'Selector';
      case DrawingTool.ballpen:
        return 'Ball Pen';
      case DrawingTool.pencil:
        return 'Pencil';
      case DrawingTool.marker:
        return 'Marker';
      case DrawingTool.eraser:
        return 'Eraser';
      case DrawingTool.camera:
        return 'Camera';
      case DrawingTool.copy:
        return 'Copy';
      case DrawingTool.text:
        return 'Text';
      case DrawingTool.zoom:
        return 'Zoom';
      case DrawingTool.imageUploader:
        return 'Image Upload';
      case DrawingTool.ruler:
        return 'Ruler';
      case DrawingTool.future:
        return 'Future';
      default:
        return 'Tool';
    }
  }

  // Action methods
  Future<void> _takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        await _addImageToCurrentPage(image.path);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take picture: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        await _addImageToCurrentPage(image.path);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _addImageToCurrentPage(String imagePath) async {
    try {
      final screenSize = MediaQuery.of(context).size;
      final imageAnnotation = await _createImageAnnotation(imagePath, screenSize);

      if (imageAnnotation != null) {
        final image = await _loadImageFromPath(imagePath);
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

  Future<ImageAnnotation?> _createImageAnnotation(String imagePath, Size screenSize) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      const maxSize = 200.0;
      double width = image.width.toDouble();
      double height = image.height.toDouble();

      if (width > maxSize || height > maxSize) {
        final ratio = math.min(maxSize / width, maxSize / height);
        width *= ratio;
        height *= ratio;
      }

      final position = Offset(
        (screenSize.width - width) / 2,
        (screenSize.height - height) / 2 - 60,
      );

      return ImageAnnotation(
        position: position,
        imagePath: imagePath,
        size: Size(width, height),
      );
    } catch (e) {
      print('Error creating image annotation: $e');
      return null;
    }
  }

  Future<ui.Image?> _loadImageFromPath(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      }
      return null;
    } catch (e) {
      print('Error loading image from path: $e');
      return null;
    }
  }

  void _copySelectedContent() {
    if (_currentPagePaths.isNotEmpty) {
      _copiedPaths = List<DrawingPath>.from(_currentPagePaths);
      _showSuccessSnackBar('Content copied');
    }
  }

  void _handleZoom(Offset position) {
    setState(() {
      _zoomLevel = _zoomLevel == 1.0 ? 1.5 : _zoomLevel == 1.5 ? 2.0 : 1.0;
    });
  }

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

  void _addTextAnnotation() {
    if (_textController.text.trim().isNotEmpty && _textPosition != null) {
      _pushToUndoStack();

      if (_pageTextAnnotations[widget.currentPage] == null) {
        _pageTextAnnotations[widget.currentPage] = [];
      }

      final textAnnotation = TextAnnotation(
        position: _textPosition!,
        text: _textController.text,
        style: TextStyle(
          color: _currentColor,
          fontSize: 16.0,
        ),
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

  // Utility methods
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

  // Firebase and local storage methods
  Future<void> _loadDrawingStateFromFirebase() async {
    try {
      setState(() {
        _isLoading = true;
      });

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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _parseDrawingData(Map<String, dynamic> drawingData) async {
    try {
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

      if (drawingData['settings'] != null) {
        final settings = drawingData['settings'] as Map<String, dynamic>;
        _currentColor = Color(settings['color'] ?? Colors.black.value);
        _strokeWidth = (settings['strokeWidth'] ?? 2.0).toDouble();
      }
    } catch (e) {
      print('Error parsing drawing data: $e');
    }
  }

  Future<void> _loadImagesFromAnnotations() async {
    for (final imageAnnotations in _pageImageAnnotations.values) {
      for (final imageAnnotation in imageAnnotations) {
        final image = await _loadImageFromPath(imageAnnotation.imagePath);
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
      },
      'lastModified': DateTime.now().toIso8601String(),
    };

    _pageDrawings.forEach((pageNum, paths) {
      if (paths.isNotEmpty) {
        drawingData['drawings'][pageNum.toString()] = paths.map((p) => p.toJson()).toList();
      }
    });

    _pageTextAnnotations.forEach((pageNum, texts) {
      if (texts.isNotEmpty) {
        drawingData['texts'][pageNum.toString()] = texts.map((t) => t.toJson()).toList();
      }
    });

    _pageImageAnnotations.forEach((pageNum, images) {
      if (images.isNotEmpty) {
        drawingData['images'][pageNum.toString()] = images.map((i) => i.toJson()).toList();
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
  final dynamic selectedAnnotation; // Add selectedAnnotation

  DrawingPainter({
    required this.paths,
    required this.textAnnotations,
    required this.imageAnnotations,
    required this.loadedImages,
    this.currentPath,
    this.selectedAnnotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw existing paths
    for (final drawingPath in paths) {
      _drawPath(canvas, drawingPath, drawingPath == selectedAnnotation);
    }

    // Draw current path being drawn (not for eraser)
    if (currentPath != null && currentPath!.tool != DrawingTool.eraser) {
      _drawPath(canvas, currentPath!, false);
    }

    // Draw images
    for (final imageAnnotation in imageAnnotations) {
      _drawImage(canvas, imageAnnotation, imageAnnotation == selectedAnnotation);
    }

    // Draw text annotations
    for (final textAnnotation in textAnnotations) {
      _drawText(canvas, textAnnotation, textAnnotation == selectedAnnotation);
    }
  }

  void _drawPath(Canvas canvas, DrawingPath drawingPath, bool isSelected) {
    if (drawingPath.points.isEmpty) return;

    if (isSelected) {
      // Draw a highlight outline for selected paths
      final highlightPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = drawingPath.paint.strokeWidth + 4;
      final highlightPath = Path();
      highlightPath.moveTo(
        drawingPath.points.first.offset.dx,
        drawingPath.points.first.offset.dy,
      );
      for (int i = 1; i < drawingPath.points.length; i++) {
        highlightPath.lineTo(
          drawingPath.points[i].offset.dx,
          drawingPath.points[i].offset.dy,
        );
      }
      canvas.drawPath(highlightPath, highlightPaint);
    }

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

  void _drawImage(Canvas canvas, ImageAnnotation imageAnnotation, bool isSelected) {
    final image = loadedImages[imageAnnotation.imagePath];
    if (image != null) {
      final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final dstRect = Rect.fromLTWH(
        imageAnnotation.position.dx,
        imageAnnotation.position.dy,
        imageAnnotation.size.width,
        imageAnnotation.size.height,
      );

      if (isSelected) {
        // Draw a highlight border for selected images
        final highlightPaint = Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawRect(dstRect, highlightPaint);
      }

      canvas.drawImageRect(image, srcRect, dstRect, Paint());
    }
  }

  void _drawText(Canvas canvas, TextAnnotation textAnnotation, bool isSelected) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: textAnnotation.text,
        style: textAnnotation.style,
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    if (isSelected) {
      // Draw a highlight background for selected text
      final highlightPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3);
      final rect = Rect.fromLTWH(
        textAnnotation.position.dx - 2,
        textAnnotation.position.dy - 2,
        textPainter.width + 4,
        textPainter.height + 4,
      );
      canvas.drawRect(rect, highlightPaint);
    }

    textPainter.paint(canvas, textAnnotation.position);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}