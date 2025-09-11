// components/drawing_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';

enum DrawingTool {
  pencil,
  pen,
  brush,
  eraser,
  text,
  shapes,
  image,
  zoom,
}

enum ShapeType {
  rectangle,
  circle,
  line,
  arrow,
  triangle,
}

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  final DrawingTool tool;

  DrawingPoint({
    required this.offset,
    required this.paint,
    required this.tool,
  });
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
}

class DrawingShape {
  final ShapeType type;
  final Offset startPoint;
  final Offset endPoint;
  final Paint paint;

  DrawingShape({
    required this.type,
    required this.startPoint,
    required this.endPoint,
    required this.paint,
  });
}

class DrawingText {
  final String text;
  final Offset position;
  final TextStyle style;

  DrawingText({
    required this.text,
    required this.position,
    required this.style,
  });
}

class DrawingImage {
  final ui.Image image;
  final Offset position;
  final Size size;

  DrawingImage({
    required this.image,
    required this.position,
    required this.size,
  });
}

class DrawingEditor extends StatefulWidget {
  final double width;
  final double height;
  final Function(Uint8List)? onSave;

  const DrawingEditor({
    Key? key,
    this.width = double.infinity,
    this.height = 400,
    this.onSave,
  }) : super(key: key);

  @override
  State<DrawingEditor> createState() => _DrawingEditorState();
}

class _DrawingEditorState extends State<DrawingEditor> {
  DrawingTool _currentTool = DrawingTool.pen;
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 2.0;
  ShapeType _currentShapeType = ShapeType.rectangle;

  List<DrawingPath> _paths = [];
  List<DrawingShape> _shapes = [];
  List<DrawingText> _texts = [];
  List<DrawingImage> _images = [];

  DrawingPath? _currentPath;
  DrawingShape? _currentDrawingShape;
  Offset? _shapeStartPoint;

  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;

  final GlobalKey _repaintKey = GlobalKey();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              color: Colors.white,
            ),
            child: ClipRect(
              child: Transform.scale(
                scale: _zoomLevel,
                child: Transform.translate(
                  offset: _panOffset,
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    onTapDown: _onTapDown,
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: CustomPaint(
                        painter: DrawingPainter(
                          paths: _paths,
                          shapes: _shapes,
                          texts: _texts,
                          images: _images,
                          currentPath: _currentPath,
                          currentShape: _currentDrawingShape,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolButton(
              icon: Icons.edit,
              tool: DrawingTool.pencil,
              tooltip: 'Pencil',
            ),
            _buildToolButton(
              icon: Icons.create,
              tool: DrawingTool.pen,
              tooltip: 'Pen',
            ),
            _buildToolButton(
              icon: Icons.brush,
              tool: DrawingTool.brush,
              tooltip: 'Brush',
            ),
            _buildToolButton(
              icon: Icons.cleaning_services,
              tool: DrawingTool.eraser,
              tooltip: 'Eraser',
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey[300],
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
            _buildToolButton(
              icon: Icons.text_fields,
              tool: DrawingTool.text,
              tooltip: 'Text',
            ),
            _buildToolButton(
              icon: Icons.image,
              tool: DrawingTool.image,
              tooltip: 'Image',
            ),
            _buildToolButton(
              icon: Icons.crop_square,
              tool: DrawingTool.shapes,
              tooltip: 'Shapes',
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey[300],
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
            _buildToolButton(
              icon: Icons.zoom_in,
              tool: DrawingTool.zoom,
              tooltip: 'Zoom',
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey[300],
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
            _buildColorPicker(),
            const SizedBox(width: 8),
            _buildStrokeWidthSlider(),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey[300],
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required DrawingTool tool,
    required String tooltip,
  }) {
    final isSelected = _currentTool == tool;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          setState(() {
            _currentTool = tool;
          });
          if (tool == DrawingTool.shapes) {
            _showShapePicker();
          } else if (tool == DrawingTool.image) {
            _pickImage();
          }
        },
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isSelected ? Border.all(color: Colors.blue) : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.blue : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return GestureDetector(
      onTap: _showColorPicker,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: _currentColor,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildStrokeWidthSlider() {
    return Container(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_currentStrokeWidth.toInt()}px',
            style: const TextStyle(fontSize: 10),
          ),
          Slider(
            value: _currentStrokeWidth,
            min: 1.0,
            max: 10.0,
            divisions: 9,
            onChanged: (value) {
              setState(() {
                _currentStrokeWidth = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        IconButton(
          onPressed: _undo,
          icon: const Icon(Icons.undo),
          tooltip: 'Undo',
        ),
        IconButton(
          onPressed: _redo,
          icon: const Icon(Icons.redo),
          tooltip: 'Redo',
        ),
        IconButton(
          onPressed: _clear,
          icon: const Icon(Icons.clear),
          tooltip: 'Clear All',
        ),
        IconButton(
          onPressed: _save,
          icon: const Icon(Icons.save),
          tooltip: 'Save',
        ),
      ],
    );
  }

  void _onPanStart(DragStartDetails details) {
    final point = details.localPosition;

    if (_currentTool == DrawingTool.shapes) {
      _shapeStartPoint = point;
      return;
    }

    if (_currentTool == DrawingTool.zoom) {
      return;
    }

    final paint = Paint()
      ..color = _currentTool == DrawingTool.eraser ? Colors.white : _currentColor
      ..strokeWidth = _currentStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (_currentTool == DrawingTool.brush) {
      paint.strokeWidth *= 2;
    }

    _currentPath = DrawingPath(
      points: [DrawingPoint(offset: point, paint: paint, tool: _currentTool)],
      paint: paint,
      tool: _currentTool,
    );

    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final point = details.localPosition;

    if (_currentTool == DrawingTool.shapes && _shapeStartPoint != null) {
      final paint = Paint()
        ..color = _currentColor
        ..strokeWidth = _currentStrokeWidth
        ..style = PaintingStyle.stroke;

      _currentDrawingShape = DrawingShape(
        type: _currentShapeType,
        startPoint: _shapeStartPoint!,
        endPoint: point,
        paint: paint,
      );
      setState(() {});
      return;
    }

    if (_currentPath != null) {
      final paint = Paint()
        ..color = _currentTool == DrawingTool.eraser ? Colors.white : _currentColor
        ..strokeWidth = _currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      if (_currentTool == DrawingTool.brush) {
        paint.strokeWidth *= 2;
      }

      _currentPath!.points.add(
        DrawingPoint(offset: point, paint: paint, tool: _currentTool),
      );
      setState(() {});
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPath != null) {
      _paths.add(_currentPath!);
      _currentPath = null;
    }

    if (_currentDrawingShape != null) {
      _shapes.add(_currentDrawingShape!);
      _currentDrawingShape = null;
      _shapeStartPoint = null;
    }

    setState(() {});
  }

  void _onTapDown(TapDownDetails details) {
    if (_currentTool == DrawingTool.text) {
      _showTextDialog(details.localPosition);
    } else if (_currentTool == DrawingTool.zoom) {
      setState(() {
        _zoomLevel = _zoomLevel == 1.0 ? 2.0 : 1.0;
      });
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _currentColor,
            onColorChanged: (color) {
              setState(() {
                _currentColor = color;
              });
            },
          ),
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

  void _showShapePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Shape', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShapeOption(ShapeType.rectangle, Icons.crop_square),
                _buildShapeOption(ShapeType.circle, Icons.circle_outlined),
                _buildShapeOption(ShapeType.line, Icons.remove),
                _buildShapeOption(ShapeType.arrow, Icons.arrow_forward),
                _buildShapeOption(ShapeType.triangle, Icons.change_history),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShapeOption(ShapeType shape, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentShapeType = shape;
        });
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }

  void _showTextDialog(Offset position) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Text'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Enter text'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                _texts.add(DrawingText(
                  text: textController.text,
                  position: position,
                  style: TextStyle(
                    color: _currentColor,
                    fontSize: _currentStrokeWidth * 8,
                  ),
                ));
                setState(() {});
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final ui.Image img = await decodeImageFromList(bytes);

      _images.add(DrawingImage(
        image: img,
        position: const Offset(50, 50),
        size: Size(img.width.toDouble() / 2, img.height.toDouble() / 2),
      ));
      setState(() {});
    }
  }

  void _undo() {
    if (_paths.isNotEmpty) {
      setState(() {
        _paths.removeLast();
      });
    } else if (_shapes.isNotEmpty) {
      setState(() {
        _shapes.removeLast();
      });
    } else if (_texts.isNotEmpty) {
      setState(() {
        _texts.removeLast();
      });
    } else if (_images.isNotEmpty) {
      setState(() {
        _images.removeLast();
      });
    }
  }

  void _redo() {
    // Implement redo functionality with history stack
  }

  void _clear() {
    setState(() {
      _paths.clear();
      _shapes.clear();
      _texts.clear();
      _images.clear();
    });
  }

  Future<void> _save() async {
    try {
      final RenderObject? renderObject = _repaintKey.currentContext?.findRenderObject();
      if (renderObject is RenderRepaintBoundary) {
        final image = await renderObject.toImage();
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();

        if (widget.onSave != null) {
          widget.onSave!(bytes);
        }
      }
    } catch (e) {
      print('Error saving drawing: $e');
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPath> paths;
  final List<DrawingShape> shapes;
  final List<DrawingText> texts;
  final List<DrawingImage> images;
  final DrawingPath? currentPath;
  final DrawingShape? currentShape;

  DrawingPainter({
    required this.paths,
    required this.shapes,
    required this.texts,
    required this.images,
    this.currentPath,
    this.currentShape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw paths
    for (final path in paths) {
      _drawPath(canvas, path);
    }

    // Draw current path
    if (currentPath != null) {
      _drawPath(canvas, currentPath!);
    }

    // Draw shapes
    for (final shape in shapes) {
      _drawShape(canvas, shape);
    }

    // Draw current shape
    if (currentShape != null) {
      _drawShape(canvas, currentShape!);
    }

    // Draw texts
    for (final text in texts) {
      _drawText(canvas, text);
    }

    // Draw images
    for (final image in images) {
      _drawImage(canvas, image);
    }
  }

  void _drawPath(Canvas canvas, DrawingPath drawingPath) {
    if (drawingPath.points.isEmpty) return;

    final path = Path();
    path.moveTo(drawingPath.points.first.offset.dx, drawingPath.points.first.offset.dy);

    for (int i = 1; i < drawingPath.points.length; i++) {
      path.lineTo(drawingPath.points[i].offset.dx, drawingPath.points[i].offset.dy);
    }

    canvas.drawPath(path, drawingPath.paint);
  }

  void _drawShape(Canvas canvas, DrawingShape shape) {
    switch (shape.type) {
      case ShapeType.rectangle:
        canvas.drawRect(
          Rect.fromPoints(shape.startPoint, shape.endPoint),
          shape.paint,
        );
        break;
      case ShapeType.circle:
        final radius = (shape.endPoint - shape.startPoint).distance / 2;
        final center = (shape.startPoint + shape.endPoint) / 2;
        canvas.drawCircle(center, radius, shape.paint);
        break;
      case ShapeType.line:
        canvas.drawLine(shape.startPoint, shape.endPoint, shape.paint);
        break;
      case ShapeType.arrow:
        _drawArrow(canvas, shape.startPoint, shape.endPoint, shape.paint);
        break;
      case ShapeType.triangle:
        _drawTriangle(canvas, shape.startPoint, shape.endPoint, shape.paint);
        break;
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);

    final arrowSize = 20.0;
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);

    final arrowP1 = Offset(
      end.dx - arrowSize * cos(angle - pi / 6),
      end.dy - arrowSize * sin(angle - pi / 6),
    );

    final arrowP2 = Offset(
      end.dx - arrowSize * cos(angle + pi / 6),
      end.dy - arrowSize * sin(angle + pi / 6),
    );

    canvas.drawLine(end, arrowP1, paint);
    canvas.drawLine(end, arrowP2, paint);
  }

  void _drawTriangle(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    final center = (start + end) / 2;
    final width = (end.dx - start.dx).abs();
    final height = (end.dy - start.dy).abs();

    path.moveTo(center.dx, start.dy);
    path.lineTo(start.dx, end.dy);
    path.lineTo(end.dx, end.dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawText(Canvas canvas, DrawingText drawingText) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: drawingText.text,
        style: drawingText.style,
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, drawingText.position);
  }

  void _drawImage(Canvas canvas, DrawingImage drawingImage) {
    canvas.drawImageRect(
      drawingImage.image,
      Rect.fromLTWH(0, 0, drawingImage.image.width.toDouble(), drawingImage.image.height.toDouble()),
      Rect.fromLTWH(
        drawingImage.position.dx,
        drawingImage.position.dy,
        drawingImage.size.width,
        drawingImage.size.height,
      ),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}