// components/shape_manager.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

enum ShapeType {
  rectangle,
  circle,
  line,
  arrow,
  triangle,
  star,
  polygon,
}

class ShapeManager {
  static IconData getShapeIcon(ShapeType shapeType) {
    switch (shapeType) {
      case ShapeType.rectangle:
        return Icons.crop_square;
      case ShapeType.circle:
        return Icons.circle_outlined;
      case ShapeType.line:
        return Icons.horizontal_rule;
      case ShapeType.arrow:
        return Icons.arrow_forward;
      case ShapeType.triangle:
        return Icons.change_history;
      case ShapeType.star:
        return Icons.star_outline;
      case ShapeType.polygon:
        return Icons.pentagon_outlined;
    }
  }

  static Widget buildShapeMenuItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFE0E0E0)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  static Widget buildShapeSelector({
    required ShapeType selectedShapeType,
    required bool isSelected,
    required Function(ShapeType) onShapeSelected,
  }) {
    return PopupMenuButton<ShapeType>(
      child: _buildToolButton(
        icon: getShapeIcon(selectedShapeType),
        isSelected: isSelected,
        onTap: null, // Will be handled by PopupMenuButton
        tooltip: 'Shapes',
      ),
      color: const Color(0xFF2C2C2C),
      itemBuilder: (context) => [
        PopupMenuItem<ShapeType>(
          value: ShapeType.rectangle,
          child: buildShapeMenuItem(Icons.crop_square, 'Rectangle'),
        ),
        PopupMenuItem<ShapeType>(
          value: ShapeType.circle,
          child: buildShapeMenuItem(Icons.circle_outlined, 'Circle'),
        ),
        PopupMenuItem<ShapeType>(
          value: ShapeType.line,
          child: buildShapeMenuItem(Icons.horizontal_rule, 'Line'),
        ),
        PopupMenuItem<ShapeType>(
          value: ShapeType.arrow,
          child: buildShapeMenuItem(Icons.arrow_forward, 'Arrow'),
        ),
        PopupMenuItem<ShapeType>(
          value: ShapeType.triangle,
          child: buildShapeMenuItem(Icons.change_history, 'Triangle'),
        ),
        PopupMenuItem<ShapeType>(
          value: ShapeType.star,
          child: buildShapeMenuItem(Icons.star_outline, 'Star'),
        ),
        PopupMenuItem<ShapeType>(
          value: ShapeType.polygon,
          child: buildShapeMenuItem(Icons.pentagon_outlined, 'Polygon'),
        ),
      ],
      onSelected: onShapeSelected,
    );
  }

  static Widget _buildToolButton({
    required IconData icon,
    bool isSelected = false,
    required VoidCallback? onTap,
    required String tooltip,
    Color? customColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4A9EFF)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.5))
                  : null,
            ),
            child: Icon(
              icon,
              size: 18,
              color: onTap != null
                  ? (isSelected ? Colors.white : (customColor ?? const Color(0xFFE0E0E0)))
                  : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}

class ShapePainter {
  static void drawShape(Canvas canvas, List<Offset> points, Paint paint, ShapeType shapeType) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      canvas.drawCircle(
        points.first,
        paint.strokeWidth / 2,
        paint,
      );
      return;
    }

    switch (shapeType) {
      case ShapeType.rectangle:
        _drawRectangle(canvas, points, paint);
        break;
      case ShapeType.circle:
        _drawCircle(canvas, points, paint);
        break;
      case ShapeType.line:
        _drawLine(canvas, points, paint);
        break;
      case ShapeType.arrow:
        _drawArrow(canvas, points, paint);
        break;
      case ShapeType.triangle:
        _drawTriangle(canvas, points, paint);
        break;
      case ShapeType.star:
        _drawStar(canvas, points, paint);
        break;
      case ShapeType.polygon:
        _drawPolygon(canvas, points, paint);
        break;
    }
  }

  static void _drawRectangle(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;

    final start = points.first;
    final end = points.last;
    final rect = Rect.fromPoints(start, end);
    canvas.drawRect(rect, paint);
  }

  static void _drawCircle(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;

    final start = points.first;
    final end = points.last;
    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
    final radius = (end - start).distance / 2;
    canvas.drawCircle(center, radius, paint);
  }

  static void _drawLine(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;

    final start = points.first;
    final end = points.last;
    canvas.drawLine(start, end, paint);
  }

  static void _drawArrow(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;

    final start = points.first;
    final end = points.last;

    // Draw line
    canvas.drawLine(start, end, paint);

    // Draw arrowhead
    const arrowLength = 20.0;
    const arrowAngle = math.pi / 6; // 30 degrees

    final direction = (end - start).direction;
    final arrowPoint1 = end + Offset(
      arrowLength * math.cos(direction + math.pi - arrowAngle),
      arrowLength * math.sin(direction + math.pi - arrowAngle),
    );
    final arrowPoint2 = end + Offset(
      arrowLength * math.cos(direction + math.pi + arrowAngle),
      arrowLength * math.sin(direction + math.pi + arrowAngle),
    );

    canvas.drawLine(end, arrowPoint1, paint);
    canvas.drawLine(end, arrowPoint2, paint);
  }

  static void _drawTriangle(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;

    final start = points.first;
    final end = points.last;
    final path = Path();
    final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final size = (end - start).distance / 2;

    // Draw equilateral triangle
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx - size * math.cos(math.pi / 6), center.dy + size * math.sin(math.pi / 6));
    path.lineTo(center.dx + size * math.cos(math.pi / 6), center.dy + size * math.sin(math.pi / 6));
    path.close();

    canvas.drawPath(path, paint);
  }

  static void _drawStar(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;

    final start = points.first;
    final end = points.last;
    final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final outerRadius = (end - start).distance / 2;
    final innerRadius = outerRadius * 0.4;

    final path = Path();
    const numPoints = 5;

    for (int i = 0; i < numPoints * 2; i++) {
      final angle = (i * math.pi) / numPoints - math.pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  static void _drawPolygon(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;

    final start = points.first;
    final end = points.last;
    final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final radius = (end - start).distance / 2;

    final path = Path();
    const numSides = 6; // Hexagon

    for (int i = 0; i < numSides; i++) {
      final angle = (i * 2 * math.pi) / numSides;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }
}