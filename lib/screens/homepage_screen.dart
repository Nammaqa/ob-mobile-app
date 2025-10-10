// screens/homepage_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/sidebar_component.dart';
import '../components/header_component.dart';
import '../components/create_note_dialog.dart';
import '../service/note_service.dart';
import '../models/note_model.dart';
import 'search_screen.dart';
import 'favourites_screen.dart';
import 'planner_screen.dart';
import 'note_editor_screen.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({Key? key}) : super(key: key);

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  final NoteService _noteService = NoteService();
  String _sortOption = 'recent';
  String _viewMode = 'grid'; // grid or list
  String _filterOption = 'all'; // all, recent, favorites, etc.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar
          SidebarComponent(
            selectedIndex: 0,
            onNavigationTap: (index) => _handleNavigation(context, index),
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Header Component
                HeaderComponent(
                  title: 'Home',
                  noteService: _noteService,
                ),

                // Content Area
                Expanded(
                  child: _buildHomeContent(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter/View Options
          Row(
            children: [
              // Filter dropdown with icon
              PopupMenuButton<String>(
                onSelected: (String value) {
                  setState(() {
                    _filterOption = value;
                  });
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'all',
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/icons/menu.png',
                          width: 16,
                          height: 16,
                        ),
                        SizedBox(width: 8),
                        Text('All'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'recent',
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16),
                        SizedBox(width: 8),
                        Text('Recent'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'favorites',
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 16),
                        SizedBox(width: 8),
                        Text('Favorites'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _filterOption == 'all'
                          ? Image.asset(
                        'assets/icons/menu.png',
                        width: 16,
                        height: 16,
                        color: Colors.grey[600],
                      )
                          : Icon(
                        _filterOption == 'recent' ? Icons.access_time : Icons.star,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _filterOption == 'all' ? 'All' :
                        _filterOption == 'recent' ? 'Recent' : 'Favorites',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  // Sort/Filter toggle
                  IconButton(
                    onPressed: () {
                      // Add sort functionality
                    },
                    icon: const Icon(
                      Icons.import_export, // Up/Down arrows
                      color: Colors.grey,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 6),
                  // Grid view button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
                      });
                    },
                    icon: Icon(
                      _viewMode == 'grid' ? Icons.grid_view : Icons.view_list,
                      color: Colors.grey,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 6),
                  // More options button (three dots horizontal)
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.more_horiz, // Three horizontal dots
                      color: Colors.grey,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 6),
                  // Cloud button
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.cloud_outlined, // Cloud icon
                      color: Colors.grey,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Notes Grid/List
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: _noteService.getUserNotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text('Error loading notes: ${snapshot.error}'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final notes = snapshot.data ?? [];

                // Filter notes based on selected filter option
                List<Note> filteredNotes = notes;
                switch (_filterOption) {
                  case 'recent':
                    filteredNotes = notes.where((note) {
                      final difference = DateTime.now().difference(note.updatedAt);
                      return difference.inDays <= 7; // Show notes from last 7 days
                    }).toList();
                    break;
                  case 'favorites':
                  // Assuming you have a favorites field in your Note model
                  // filteredNotes = notes.where((note) => note.isFavorite).toList();
                    filteredNotes = notes; // For now, show all notes
                    break;
                  case 'all':
                  default:
                    filteredNotes = notes;
                    break;
                }

                // Sort notes based on selected option
                final sortedNotes = List<Note>.from(filteredNotes);
                sortedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                // Always show the grid/list view with "New Note" card at the beginning
                if (_viewMode == 'list') {
                  return ListView.builder(
                    itemCount: sortedNotes.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildNewNoteListItem(context);
                      }
                      return _buildNoteListItem(context, sortedNotes[index - 1]);
                    },
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6, // Increased from 4 to 6 for narrower cards
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8, // Square-ish aspect ratio
                  ),
                  itemCount: sortedNotes.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildNewNoteCard(context);
                    }
                    return _buildNoteCard(context, sortedNotes[index - 1]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildNewNoteCard(BuildContext context) {
    return InkWell(
      onTap: () => _showCreateNoteDialog(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'New',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    // Define card colors similar to the image
    final colors = [
      const Color(0xFF4A3728), // Dark brown
      const Color(0xFF6B5B95), // Purple
      const Color(0xFFB19CD9), // Light purple
      const Color(0xFF8B4513), // Saddle brown
      const Color(0xFF9370DB), // Medium purple
      const Color(0xFFDDA0DD), // Plum
    ];

    final colorIndex = note.name.hashCode % colors.length;
    final color = colors[colorIndex];

    return InkWell(
      onTap: () => _openNote(context, note),
      onLongPress: () => _showNoteOptions(context, note),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    // Title
                    Text(
                      note.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(note.updatedAt),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // More options button (star icon like in the image)
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () => _showNoteOptions(context, note),
                borderRadius: BorderRadius.circular(12),
                child: Icon(
                  Icons.star_border,
                  color: Colors.white.withOpacity(0.8),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewNoteListItem(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.add, color: Colors.grey[600]),
        ),
        title: Text(
          'Create New Note',
          style: TextStyle(color: Colors.grey[700]),
        ),
        onTap: () => _showCreateNoteDialog(context),
      ),
    );
  }

  Widget _buildNoteListItem(BuildContext context, Note note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.description, color: Colors.blue[600]),
        ),
        title: Text(note.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.description.isNotEmpty)
              Text(
                note.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              _formatDate(note.updatedAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showNoteOptions(context, note),
        ),
        onTap: () => _openNote(context, note),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  // UPDATED: Simplified method that uses the new self-contained dialog
  void _showCreateNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while creating
      builder: (BuildContext context) {
        return CreateNoteDialog(
          onCreateNote: (String name, String description) async {
            // This callback is kept for backward compatibility
            // but the actual creation is now handled inside the dialog
          },
        );
      },
    );
  }

  void _openNote(BuildContext context, Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          noteId: note.id,
          noteName: note.name,
          noteDescription: note.description,
        ),
      ),
    );
  }

  void _showNoteOptions(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _renameNote(context, note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                _duplicateNote(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // Implement share functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red[400]),
              title: Text('Delete', style: TextStyle(color: Colors.red[400])),
              onTap: () {
                Navigator.pop(context);
                _deleteNote(context, note);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _renameNote(BuildContext context, Note note) {
    final nameController = TextEditingController(text: note.name);
    final descController = TextEditingController(text: note.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _noteService.updateNote(
                noteId: note.id,
                name: nameController.text,
                description: descController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _duplicateNote(Note note) async {
    try {
      await _noteService.createNote(
        name: '${note.name} (Copy)',
        description: note.description,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note duplicated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to duplicate: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteNote(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _noteService.deleteNote(note.id);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note deleted'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
      // Current screen - do nothing
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FavouritesScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PlannerScreen()),
        );
        break;
    }
  }
}