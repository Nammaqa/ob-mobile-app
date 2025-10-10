import 'package:flutter/material.dart';

// Enums
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

enum ShapeType {
  circle,
  square,
  triangle,
  rectangle,
  star,
  arrow,
  heart,
  pentagon,
  hexagon,
}

// Drawing Point Model
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

// Drawing Path Model
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

// Text Annotation Model
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

// Image Annotation Model
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

// Shape Annotation Model
class ShapeAnnotation {
  final Offset position;
  final ShapeType shapeType;
  final Size size;
  final Color color;
  final double strokeWidth;

  ShapeAnnotation({
    required this.position,
    required this.shapeType,
    required this.size,
    required this.color,
    required this.strokeWidth,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': position.dx,
      'y': position.dy,
      'shapeType': shapeType.index,
      'width': size.width,
      'height': size.height,
      'color': color.value,
      'strokeWidth': strokeWidth,
    };
  }

  factory ShapeAnnotation.fromJson(Map<String, dynamic> json) {
    return ShapeAnnotation(
      position: Offset(json['x'], json['y']),
      shapeType: ShapeType.values[json['shapeType']],
      size: Size(json['width'], json['height']),
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
    );
  }
}

// Toolbar Icons
class ToolbarIcons {
  static const String undo = 'assets/icons/undo.png';
  static const String redo = 'assets/icons/redo.png';
  static const String selector = 'assets/icons/selection_tool.png';
  static const String ballpen = 'assets/icons/ball_point_pen.png';
  static const String pencil = 'assets/icons/pencil.png';
  static const String marker = 'assets/icons/marker_pen.png';
  static const String eraser = 'assets/icons/eraser.png';
  static const String camera = 'assets/icons/shapes.png';
  static const String copy = 'assets/icons/copy.png';
  static const String text = 'assets/icons/text.png';
  static const String zoom = 'assets/icons/zoom_in.png';
  static const String imageUploader = 'assets/icons/image.png';
  static const String ruler = 'assets/icons/ruler.png';
  static const String future = 'assets/icons/future.png';
}