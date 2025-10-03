// services/note_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note_model.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new note
  Future<String> createNote({
    required String name,
    required String description,
    String? templateUrl, // ADD THIS PARAMETER
  }) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      final now = DateTime.now();
      final noteRef = await _firestore.collection('notes').add({
        'name': name,
        'description': description,
        'userId': currentUserId,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'lastOpenedPage': 1,
        'zoomLevel': 1.0,
        'isFavorite': false,
        'templateUrl': templateUrl, // ADD THIS
      });

      return noteRef.id;
    } catch (e) {
      throw Exception('Failed to create note: $e');
    }
  }

  // Get all notes for current user
  Stream<List<Note>> getUserNotes() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Note.fromDocument(doc)).toList();
    });
  }

  // Get a single note with retry mechanism for newly created notes
  Future<Note?> getNote(String noteId) async {
    try {
      // First attempt
      var doc = await _firestore.collection('notes').doc(noteId).get();

      // If document doesn't exist or timestamps are null, retry a few times
      int retryCount = 0;
      const maxRetries = 5;
      const retryDelay = Duration(milliseconds: 200);

      while ((!doc.exists || _hasNullTimestamps(doc.data())) && retryCount < maxRetries) {
        await Future.delayed(retryDelay);
        doc = await _firestore.collection('notes').doc(noteId).get();
        retryCount++;
      }

      if (doc.exists) {
        return Note.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get note: $e');
    }
  }

  // Helper method to check if document has null timestamps
  bool _hasNullTimestamps(Map<String, dynamic>? data) {
    if (data == null) return true;
    return data['createdAt'] == null || data['updatedAt'] == null;
  }

  // Update note content
  Future<void> updateNote({
    required String noteId,
    String? name,
    String? description,
    Map<String, dynamic>? drawingData,
    int? lastOpenedPage,
    double? zoomLevel,
    String? templateUrl, // ADD THIS PARAMETER
  }) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (drawingData != null) updates['drawingData'] = drawingData;
      if (lastOpenedPage != null) updates['lastOpenedPage'] = lastOpenedPage;
      if (zoomLevel != null) updates['zoomLevel'] = zoomLevel;
      if (templateUrl != null) updates['templateUrl'] = templateUrl; // ADD THIS

      await _firestore.collection('notes').doc(noteId).update(updates);
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  // Save drawing data for a note
  Future<void> saveDrawingData(String noteId, Map<String, dynamic> drawingData) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      await _firestore.collection('notes').doc(noteId).update({
        'drawingData': drawingData,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to save drawing data: $e');
    }
  }

  // Delete a note
  Future<void> deleteNote(String noteId) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      await _firestore.collection('notes').doc(noteId).delete();
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String noteId, bool isFavorite) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      await _firestore.collection('notes').doc(noteId).update({
        'isFavorite': isFavorite,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  // Search notes
  Stream<List<Note>> searchNotes(String query) {
    if (currentUserId == null || query.isEmpty) {
      return Stream.value([]);
    }

    final lowercaseQuery = query.toLowerCase();

    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Note.fromDocument(doc))
          .where((note) =>
      note.name.toLowerCase().contains(lowercaseQuery) ||
          note.description.toLowerCase().contains(lowercaseQuery))
          .toList();
    });
  }
}