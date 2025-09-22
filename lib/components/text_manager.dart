// components/text_manager.dart
import 'package:flutter/material.dart';

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

class TextInputDialog extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  const TextInputDialog({
    Key? key,
    required this.controller,
    required this.onAdd,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter text...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: onAdd,
                  child: const Text('Add'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TextManager {
  static TextAnnotation createTextAnnotation({
    required Offset position,
    required String text,
    required Color color,
    double fontSize = 16.0,
  }) {
    return TextAnnotation(
      position: position,
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
      ),
    );
  }

  static bool validateTextInput(String text) {
    return text.trim().isNotEmpty;
  }
}

class TextRenderer {
  static void drawText(Canvas canvas, TextAnnotation textAnnotation) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: textAnnotation.text,
        style: textAnnotation.style,
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, textAnnotation.position);
  }
}