import 'package:flutter/material.dart';
import '../drawing_models.dart';

class SelectorTool {
  dynamic selectedAnnotation;
  Offset? dragStartPosition;
  Offset? initialAnnotationPosition;

  dynamic selectAnnotation(
      Offset position,
      List<DrawingPath> paths,
      List<ShapeAnnotation> shapes,
      List<ImageAnnotation> images,
      List<TextAnnotation> texts,
      ) {
    selectedAnnotation = null;

    // Check for drawing paths
    for (final path in paths) {
      for (final point in path.points) {
        if ((point.offset - position).distance < 20.0) {
          selectedAnnotation = path;
          initialAnnotationPosition = path.points.first.offset;
          return selectedAnnotation;
        }
      }
    }

    // Check for shape annotations
    for (final shape in shapes) {
      final rect = Rect.fromLTWH(
        shape.position.dx,
        shape.position.dy,
        shape.size.width,
        shape.size.height,
      );
      if (rect.contains(position)) {
        selectedAnnotation = shape;
        initialAnnotationPosition = shape.position;
        return selectedAnnotation;
      }
    }

    // Check for image annotations
    for (final image in images) {
      final rect = Rect.fromLTWH(
        image.position.dx,
        image.position.dy,
        image.size.width,
        image.size.height,
      );
      if (rect.contains(position)) {
        selectedAnnotation = image;
        initialAnnotationPosition = image.position;
        return selectedAnnotation;
      }
    }

    // Check for text annotations
    for (final text in texts) {
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
        selectedAnnotation = text;
        initialAnnotationPosition = text.position;
        return selectedAnnotation;
      }
    }

    return null;
  }

  void onPanStart(Offset position) {
    if (selectedAnnotation != null) {
      dragStartPosition = position;
    }
  }

  Offset? onPanUpdate(Offset position) {
    if (selectedAnnotation != null && dragStartPosition != null && initialAnnotationPosition != null) {
      final delta = position - dragStartPosition!;
      return initialAnnotationPosition! + delta;
    }
    return null;
  }

  void onPanEnd() {
    dragStartPosition = null;
    initialAnnotationPosition = null;
  }

  void clearSelection() {
    selectedAnnotation = null;
    dragStartPosition = null;
    initialAnnotationPosition = null;
  }
}