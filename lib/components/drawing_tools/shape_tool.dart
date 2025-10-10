import 'package:flutter/material.dart';
import '../drawing_models.dart';

class ShapeTool {
  Color color;
  double strokeWidth;

  ShapeTool({
    this.color = Colors.black,
    this.strokeWidth = 2.0,
  });

  ShapeAnnotation createShape(ShapeType shapeType, Size screenSize) {
    final shapeSize = const Size(100, 100);
    final position = Offset(
      (screenSize.width - shapeSize.width) / 2,
      (screenSize.height - shapeSize.height) / 2 - 60,
    );

    return ShapeAnnotation(
      position: position,
      shapeType: shapeType,
      size: shapeSize,
      color: color,
      strokeWidth: strokeWidth,
    );
  }

  void updateColor(Color newColor) {
    color = newColor;
  }

  void updateStrokeWidth(double newWidth) {
    strokeWidth = newWidth;
  }
}