import 'package:flutter/material.dart';
import '../drawing_models.dart';

class EraserTool {
  double strokeWidth;

  EraserTool({this.strokeWidth = 2.0});

  void performErasure(Offset position, List<DrawingPath> paths) {
    final eraserRadius = strokeWidth * 3;
    final pathsToRemove = <DrawingPath>[];

    for (final path in paths) {
      for (final point in path.points) {
        if ((point.offset - position).distance < eraserRadius) {
          pathsToRemove.add(path);
          break;
        }
      }
    }

    paths.removeWhere((path) => pathsToRemove.contains(path));
  }

  void onPanStart(Offset position, List<DrawingPath> paths) {
    performErasure(position, paths);
  }

  void onPanUpdate(Offset position, List<DrawingPath> paths) {
    performErasure(position, paths);
  }

  void updateStrokeWidth(double newWidth) {
    strokeWidth = newWidth;
  }
}