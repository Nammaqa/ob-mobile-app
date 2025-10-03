// models/note_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String name;
  final String description;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final int lastOpenedPage;
  final double zoomLevel;
  final Map<String, dynamic>? drawingData;
  final String? templateUrl; // ADD THIS FIELD

  Note({
    required this.id,
    required this.name,
    required this.description,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.lastOpenedPage = 1,
    this.zoomLevel = 1.0,
    this.drawingData,
    this.templateUrl, // ADD THIS
  });

  factory Note.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle timestamp fields that might be null initially
    DateTime createdAt = DateTime.now();
    DateTime updatedAt = DateTime.now();

    try {
      final createdTimestamp = data['createdAt'];
      if (createdTimestamp is Timestamp) {
        createdAt = createdTimestamp.toDate();
      } else if (createdTimestamp != null) {
        createdAt = DateTime.now();
      }

      final updatedTimestamp = data['updatedAt'];
      if (updatedTimestamp is Timestamp) {
        updatedAt = updatedTimestamp.toDate();
      } else if (updatedTimestamp != null) {
        updatedAt = DateTime.now();
      }
    } catch (e) {
      print('Error parsing timestamps: $e');
      createdAt = DateTime.now();
      updatedAt = DateTime.now();
    }

    return Note(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      isFavorite: data['isFavorite'] ?? false,
      lastOpenedPage: data['lastOpenedPage'] ?? 1,
      zoomLevel: (data['zoomLevel'] ?? 1.0).toDouble(),
      drawingData: data['drawingData'],
      templateUrl: data['templateUrl'], // ADD THIS
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isFavorite': isFavorite,
      'lastOpenedPage': lastOpenedPage,
      'zoomLevel': zoomLevel,
      'drawingData': drawingData,
      'templateUrl': templateUrl, // ADD THIS
    };
  }

  Note copyWith({
    String? name,
    String? description,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    int? lastOpenedPage,
    double? zoomLevel,
    Map<String, dynamic>? drawingData,
    String? templateUrl, // ADD THIS
  }) {
    return Note(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      lastOpenedPage: lastOpenedPage ?? this.lastOpenedPage,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      drawingData: drawingData ?? this.drawingData,
      templateUrl: templateUrl ?? this.templateUrl, // ADD THIS
    );
  }
}