// components/image_manager.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;

class ImageAnnotation {
  final Offset position;
  final String imagePath;
  final Size size;
  final double rotation;

  ImageAnnotation({
    required this.position,
    required this.imagePath,
    required this.size,
    this.rotation = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': position.dx,
      'y': position.dy,
      'imagePath': imagePath,
      'width': size.width,
      'height': size.height,
      'rotation': rotation,
    };
  }

  factory ImageAnnotation.fromJson(Map<String, dynamic> json) {
    return ImageAnnotation(
      position: Offset(json['x'], json['y']),
      imagePath: json['imagePath'],
      size: Size(json['width'], json['height']),
      rotation: json['rotation'] ?? 0.0,
    );
  }
}

class ImageManager {
  static final ImagePicker _imagePicker = ImagePicker();

  static Widget buildCameraToolSection({
    required bool isSelected,
    required Function() onTakePhoto,
    required Function() onPickFromGallery,
  }) {
    return PopupMenuButton<String>(
      child: _buildToolButton(
        icon: Icons.camera_alt,
        isSelected: isSelected,
        onTap: null, // Will be handled by PopupMenuButton
        tooltip: 'Camera',
      ),
      color: const Color(0xFF2C2C2C),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'camera',
          child: Row(
            children: const [
              Icon(Icons.camera_alt, size: 18, color: Color(0xFFE0E0E0)),
              SizedBox(width: 8),
              Text('Take Photo', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'gallery',
          child: Row(
            children: const [
              Icon(Icons.photo_library, size: 18, color: Color(0xFFE0E0E0)),
              SizedBox(width: 8),
              Text('From Gallery', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'camera') {
          onTakePhoto();
        } else {
          onPickFromGallery();
        }
      },
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

  static Future<String?> takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      return image?.path;
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  static Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      return image?.path;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  static Future<ui.Image?> loadImageFromPath(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      }
      return null;
    } catch (e) {
      print('Error loading image from path: $e');
      return null;
    }
  }

  static Future<ImageAnnotation?> createImageAnnotation(
      String imagePath,
      Size screenSize,
      {double toolbarHeight = 70}
      ) async {
    try {
      // Load the image to get its dimensions
      final bytes = await File(imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Calculate size to fit within reasonable bounds
      const maxSize = 200.0;
      double width = image.width.toDouble();
      double height = image.height.toDouble();

      if (width > maxSize || height > maxSize) {
        final ratio = math.min(maxSize / width, maxSize / height);
        width *= ratio;
        height *= ratio;
      }

      // Position at center of screen
      final position = Offset(
        (screenSize.width - width) / 2,
        (screenSize.height - height) / 2 - toolbarHeight,
      );

      return ImageAnnotation(
        position: position,
        imagePath: imagePath,
        size: Size(width, height),
      );
    } catch (e) {
      print('Error creating image annotation: $e');
      return null;
    }
  }

  static Future<Map<String, ui.Image>> loadImagesFromAnnotations(
      List<ImageAnnotation> imageAnnotations
      ) async {
    final Map<String, ui.Image> loadedImages = {};

    for (final imageAnnotation in imageAnnotations) {
      final image = await loadImageFromPath(imageAnnotation.imagePath);
      if (image != null) {
        loadedImages[imageAnnotation.imagePath] = image;
      }
    }

    return loadedImages;
  }
}

class ImagePainter {
  static void drawImage(
      Canvas canvas,
      ImageAnnotation imageAnnotation,
      Map<String, ui.Image> loadedImages
      ) {
    final image = loadedImages[imageAnnotation.imagePath];
    if (image != null) {
      final srcRect = Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble()
      );
      final dstRect = Rect.fromLTWH(
        imageAnnotation.position.dx,
        imageAnnotation.position.dy,
        imageAnnotation.size.width,
        imageAnnotation.size.height,
      );

      if (imageAnnotation.rotation != 0) {
        canvas.save();
        canvas.translate(dstRect.center.dx, dstRect.center.dy);
        canvas.rotate(imageAnnotation.rotation);
        canvas.translate(-dstRect.center.dx, -dstRect.center.dy);
      }

      canvas.drawImageRect(image, srcRect, dstRect, Paint());

      if (imageAnnotation.rotation != 0) {
        canvas.restore();
      }
    }
  }
}