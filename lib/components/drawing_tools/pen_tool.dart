import 'package:flutter/material.dart';
import '../drawing_models.dart';

class PenTool {
  Color color;
  double strokeWidth;

  PenTool({
    this.color = Colors.black,
    this.strokeWidth = 2.0,
  });

  Paint createPaint() {
    return Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
  }

  DrawingPath? onPanStart(Offset position) {
    final paint = createPaint();
    return DrawingPath(
      points: [DrawingPoint(offset: position, paint: paint)],
      paint: paint,
      tool: DrawingTool.ballpen,
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