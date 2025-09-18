// models/note_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String name;
  final String description;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? pdfContent; // Base64 encoded PDF if needed
  final Map<String, dynamic>? drawingData; // Drawing annotations
  final int lastOpenedPage;
  final double zoomLevel;

  Note({
    required this.id,
    required this.name,
    required this.description,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.pdfContent,
    this.drawingData,
    this.lastOpenedPage = 1,
    this.zoomLevel = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'pdfContent': pdfContent,
      'drawingData': drawingData,
      'lastOpenedPage': lastOpenedPage,
      'zoomLevel': zoomLevel,
    };
  }

  factory Note.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      pdfContent: data['pdfContent'],
      drawingData: data['drawingData'],
      lastOpenedPage: data['lastOpenedPage'] ?? 1,
      zoomLevel: data['zoomLevel'] ?? 1.0,
    );
  }
}