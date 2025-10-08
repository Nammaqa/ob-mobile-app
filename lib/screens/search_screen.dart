// screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/sidebar_component.dart';
import '../service/note_service.dart';
import '../models/note_model.dart';
import 'homepage_screen.dart';
import 'favourites_screen.dart';
import 'planner_screen.dart';
import 'note_editor_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NoteService _noteService = NoteService();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Note> _filterNotes(List<Note> notes) {
    if (_searchQuery.isEmpty) {
      return notes;
    }

    return notes.where((note) {
      final nameLower = note.name.toLowerCase();
      final descLower = note.description.toLowerCase();
      return nameLower.contains(_searchQuery) || descLower.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar
          SidebarComponent(
            selectedIndex: 1, // Search is selected
            onNavigationTap: (index) => _handleNavigation(context, index),
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(32.0, 24.0, 32.0, 20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Search Bar
                      Container(
                        width: 280,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey[400], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: _performSearch,
                                decoration: InputDecoration(
                                  hintText: 'Search',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.clear, size: 18, color: Colors.grey[400]),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Area
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
                            ],
                          ),
                        );
                      }

                      final allNotes = snapshot.data ?? [];
                      final filteredNotes = _filterNotes(allNotes);

                      return _buildSearchContent(allNotes, filteredNotes);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent(List<Note> allNotes, List<Note> filteredNotes) {
    // If searching, show filtered results
    if (_searchQuery.isNotEmpty) {
      if (filteredNotes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No notes match "${_searchController.text}"',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      // Show search results
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  '${filteredNotes.length} result${filteredNotes.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: filteredNotes.length,
                itemBuilder: (context, index) {
                  return _buildNoteCard(filteredNotes[index]);
                },
              ),
            ),
          ],
        ),
      );
    }

    // No search query - show Recent Files
    if (allNotes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No notes yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first note to get started',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Get recent notes (last 6 notes)
    final recentNotes = allNotes.take(6).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Files',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Could navigate to show all notes or clear recent
                  },
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Horizontal scrollable row of recent notes
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentNotes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: index < recentNotes.length - 1 ? 16 : 0),
                    child: _buildRecentNoteCard(recentNotes[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentNoteCard(Note note) {
    // Same color scheme as homepage
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
      onTap: () => _openNote(note),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                note.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
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
    );
  }

  Widget _buildNoteCard(Note note) {
    // Same color scheme as homepage
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
      onTap: () => _openNote(note),
      onLongPress: () => _showNoteOptions(note),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
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
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () => _showNoteOptions(note),
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
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  void _openNote(Note note) {
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

  void _showNoteOptions(Note note) {
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
              title: const Text('Open'),
              onTap: () {
                Navigator.pop(context);
                _openNote(note);
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
                _deleteNote(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteNote(Note note) {
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

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note deleted'),
                  ),
                );
              }
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomepageScreen()),
        );
        break;
      case 1:
      // Current screen - do nothing
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