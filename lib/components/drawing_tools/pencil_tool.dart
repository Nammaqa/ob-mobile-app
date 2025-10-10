import 'package:flutter/material.dart';
import '../drawing_models.dart';

class PencilTool {
  Color color;
  double strokeWidth;

  PencilTool({
    this.color = Colors.black,
    this.strokeWidth = 2.0,
  });

  Paint createPaint() {
    return Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = strokeWidth * 0.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
  }

  DrawingPath? onPanStart(Offset position) {
    final paint = createPaint();
    return DrawingPath(
      points: [DrawingPoint(offset: position, paint: paint)],
      paint: paint,
      tool: DrawingTool.pencil,
    );
  }

  void onPanUpdate(DrawingPath currentPath, Offset position) {
    currentPath.points.add(
      DrawingPoint(offset: position, paint: currentPath.paint),
    );
  }

  DrawingPath? onPanEnd(DrawingPath? currentPath) {
    return currentPath;
  }

  void updateColor(Color newColor) {
    color = newColor;
  }

  void updateStrokeWidth(double newWidth) {
    strokeWidth = newWidth;
  }
}