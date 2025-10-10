import 'package:flutter/material.dart';
import '../drawing_models.dart';

class MarkerTool {
  Color color;
  double strokeWidth;

  MarkerTool({
    this.color = Colors.black,
    this.strokeWidth = 2.0,
  });

  Paint createPaint() {
    return Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = strokeWidth * 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
  }

  DrawingPath? onPanStart(Offset position) {
    final paint = createPaint();
    return DrawingPath(
      points: [DrawingPoint(offset: position, paint: paint)],
      paint: paint,
      tool: DrawingTool.marker,
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