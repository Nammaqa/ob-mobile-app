import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../drawing_models.dart';

class ImageTool {
  final ImagePicker _imagePicker = ImagePicker();

  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return image?.path;
    } catch (e) {
      print('Failed to pick image: $e');
      return null;
    }
  }

  Future<String?> captureImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return image?.path;
    } catch (e) {
      print('Failed to capture image: $e');
      return null;
    }
  }

  Future<ImageAnnotation?> createImageAnnotation(
      String imagePath,
      Size screenSize,
      ) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      const maxSize = 200.0;
      double width = image.width.toDouble();
      double height = image.height.toDouble();

      if (width > maxSize || height > maxSize) {
        final ratio = math.min(maxSize / width, maxSize / height);
        width *= ratio;
        height *= ratio;
      }

      final position = Offset(
        (screenSize.width - width) / 2,
        (screenSize.height - height) / 2 - 60,
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

  Future<ui.Image?> loadImageFromPath(String imagePath) async {
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
}