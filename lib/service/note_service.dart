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
  }) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      final noteRef = await _firestore.collection('notes').add({
        'name': name,
        'description': description,
        'userId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastOpenedPage': 1,
        'zoomLevel': 1.0,
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

  // Get a single note
  Future<Note?> getNote(String noteId) async {
    try {
      final doc = await _firestore.collection('notes').doc(noteId).get();
      if (doc.exists) {
        return Note.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get note: $e');
    }
  }

  // Update note content
  Future<void> updateNote({
    required String noteId,
    String? name,
    String? description,
    Map<String, dynamic>? drawingData,
    int? lastOpenedPage,
    double? zoomLevel,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (drawingData != null) updates['drawingData'] = drawingData;
      if (lastOpenedPage != null) updates['lastOpenedPage'] = lastOpenedPage;
      if (zoomLevel != null) updates['zoomLevel'] = zoomLevel;

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
        'updatedAt': FieldValue.serverTimestamp(),
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
        'updatedAt': FieldValue.serverTimestamp(),
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