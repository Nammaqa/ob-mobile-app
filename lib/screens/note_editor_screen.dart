// screens/note_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/drawing_editor.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final String noteName;
  final String noteDescription;

  const NoteEditorScreen({
    Key? key,
    required this.noteName,
    required this.noteDescription,
  }) : super(key: key);

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  bool _isFavorited = false;

  Future<void> _saveDrawing(Uint8List bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Drawing saved to ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save drawing'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Navigation Bar
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),

                // Note Title
                Expanded(
                  child: Text(
                    widget.noteName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Top Right Actions
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isFavorited ? Icons.star : Icons.star_border,
                        color: _isFavorited ? Colors.amber : Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _isFavorited = !_isFavorited;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.share_outlined, color: Colors.grey[600]),
                      onPressed: () {
                        // Handle share
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                      onPressed: () {
                        _showMoreOptions();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Drawing Editor - Full Screen
          Expanded(
            child: DrawingEditor(
              width: double.infinity,
              height: double.infinity,
              onSave: _saveDrawing,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('Save Drawing'),
              onTap: () {
                Navigator.pop(context);
                _saveDrawing;
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportAsPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Note'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Note Info'),
              onTap: () {
                Navigator.pop(context);
                _showNoteInfo();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportAsPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF export functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNoteInfo() {
    final now = DateTime.now();
    final dateString = now.toString().split('.')[0];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${widget.noteName}'),
            const SizedBox(height: 8),
            if (widget.noteDescription.isNotEmpty) ...[
              Text('Description: ${widget.noteDescription}'),
              const SizedBox(height: 8),
            ],
            Text('Created: $dateString'),
            const SizedBox(height: 8),
            Text('Last Modified: $dateString'),
            const SizedBox(height: 8),
            const Text('Type: Drawing Note'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}