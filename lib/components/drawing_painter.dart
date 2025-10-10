import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'drawing_models.dart';

class DrawingPainter extends CustomPainter {
  final List<DrawingPath> paths;
  final List<TextAnnotation> textAnnotations;
  final List<ImageAnnotation> imageAnnotations;
  final List<ShapeAnnotation> shapeAnnotations;
  final Map<String, ui.Image> loadedImages;
  final DrawingPath? currentPath;
  final dynamic selectedAnnotation;

  DrawingPainter({
    required this.paths,
    required this.textAnnotations,
    required this.imageAnnotations,
    required this.shapeAnnotations,
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

    // Draw current path being drawn
    if (currentPath != null && currentPath!.tool != DrawingTool.eraser) {
      _drawPath(canvas, currentPath!, false);
    }

    // Draw shapes
    for (final shapeAnnotation in shapeAnnotations) {
      _drawShape(canvas, shapeAnnotation, shapeAnnotation == selectedAnnotation);
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

  void _drawShape(Canvas canvas, ShapeAnnotation shapeAnnotation, bool isSelected) {
    final paint = Paint()
      ..color = shapeAnnotation.color
      ..strokeWidth = shapeAnnotation.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(
      shapeAnnotation.position.dx + shapeAnnotation.size.width / 2,
      shapeAnnotation.position.dy + shapeAnnotation.size.height / 2,
    );

    if (isSelected) {
      final highlightPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = shapeAnnotation.strokeWidth + 4;

      final rect = Rect.fromLTWH(
        shapeAnnotation.position.dx,
        shapeAnnotation.position.dy,
        shapeAnnotation.size.width,
        shapeAnnotation.size.height,
      );
      canvas.drawRect(rect, highlightPaint);
    }

    switch (shapeAnnotation.shapeType) {
      case ShapeType.circle:
        canvas.drawCircle(center, shapeAnnotation.size.width / 2, paint);
        break;
      case ShapeType.square:
      case ShapeType.rectangle:
        final rect = Rect.fromLTWH(
          shapeAnnotation.position.dx,
          shapeAnnotation.position.dy,
          shapeAnnotation.size.width,
          shapeAnnotation.size.height,
        );
        canvas.drawRect(rect, paint);
        break;
      case ShapeType.triangle:
        _drawTriangle(canvas, shapeAnnotation.position, shapeAnnotation.size, paint);
        break;
      case ShapeType.star:
        _drawStar(canvas, center, shapeAnnotation.size.width / 2, paint);
        break;
      case ShapeType.arrow:
        _drawArrow(canvas, shapeAnnotation.position, shapeAnnotation.size, paint);
        break;
      case ShapeType.heart:
        _drawHeart(canvas, center, shapeAnnotation.size.width / 2, paint);
        break;
      case ShapeType.pentagon:
        _drawPolygon(canvas, center, shapeAnnotation.size.width / 2, 5, paint);
        break;
      case ShapeType.hexagon:
        _drawPolygon(canvas, center, shapeAnnotation.size.width / 2, 6, paint);
        break;
    }
  }

  void _drawTriangle(Canvas canvas, Offset position, Size size, Paint paint) {
    final path = Path();
    final center = Offset(position.dx + size.width / 2, position.dy);
    path.moveTo(center.dx, center.dy);
    path.lineTo(position.dx, position.dy + size.height);
    path.lineTo(position.dx + size.width, position.dy + size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final points = 5;
    final angle = math.pi / points;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius / 2;
      final x = center.dx + r * math.cos(i * angle - math.pi / 2);
      final y = center.dy + r * math.sin(i * angle - math.pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawArrow(Canvas canvas, Offset position, Size size, Paint paint) {
    final path = Path();
    final tipX = position.dx + size.width;
    final tipY = position.dy + size.height / 2;

    path.moveTo(position.dx, tipY);
    path.lineTo(tipX - size.width * 0.3, tipY);
    path.lineTo(tipX - size.width * 0.3, position.dy);
    path.lineTo(tipX, tipY);
    path.lineTo(tipX - size.width * 0.3, position.dy + size.height);
    path.lineTo(tipX - size.width * 0.3, tipY);

    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + radius * 0.3);

    path.cubicTo(
      center.dx - radius * 0.5, center.dy - radius * 0.5,
      center.dx - radius, center.dy - radius * 0.2,
      center.dx - radius, center.dy + radius * 0.3,
    );

    path.cubicTo(
      center.dx - radius, center.dy + radius * 0.8,
      center.dx, center.dy + radius,
      center.dx, center.dy + radius,
    );

    path.cubicTo(
      center.dx, center.dy + radius,
      center.dx + radius, center.dy + radius * 0.8,
      center.dx + radius, center.dy + radius * 0.3,
    );

    path.cubicTo(
      center.dx + radius, center.dy - radius * 0.2,
      center.dx + radius * 0.5, center.dy - radius * 0.5,
      center.dx, center.dy + radius * 0.3,
    );

    canvas.drawPath(path, paint);
  }

  void _drawPolygon(Canvas canvas, Offset center, double radius, int sides, Paint paint) {
    final path = Path();
    final angle = (math.pi * 2) / sides;

    for (int i = 0; i < sides; i++) {
      final x = center.dx + radius * math.cos(i * angle - math.pi / 2);
      final y = center.dy + radius * math.sin(i * angle - math.pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
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