import 'package:flutter/material.dart';
import '../drawing_models.dart';

class TextTool {
  Color color;
  Offset? textPosition;

  TextTool({this.color = Colors.black});

  void onTapDown(Offset position) {
    textPosition = position;
  }

  TextAnnotation? createTextAnnotation(String text) {
    if (text.trim().isEmpty || textPosition == null) return null;

    return TextAnnotation(
      position: textPosition!,
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 16.0,
      ),
    );
  }

  void clearTextPosition() {
    textPosition = null;
  }

  void updateColor(Color newColor) {
    color = newColor;
  }
}