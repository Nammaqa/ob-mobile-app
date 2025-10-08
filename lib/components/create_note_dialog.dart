// components/create_note_dialog.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/note_service.dart';
import '../screens/note_editor_screen.dart';

class Template {
  final String id;
  final String name;
  final String description;
  final String previewUrl;
  final String url;
  final String visibility;
  final int price;
  final bool active;

  Template({
    required this.id,
    required this.name,
    required this.description,
    required this.previewUrl,
    required this.url,
    required this.visibility,
    required this.price,
    required this.active,
  });

  factory Template.fromJson(Map<String, dynamic> json) {
    final fields = json['fields'] as Map<String, dynamic>;
    return Template(
      id: json['name'].split('/').last,
      name: fields['name']['stringValue'] ?? '',
      description: fields['description']['stringValue'] ?? '',
      previewUrl: fields['previewUrl']['stringValue'] ?? '',
      url: fields['url']['stringValue'] ?? '',
      visibility: fields['visibility']['stringValue'] ?? 'public',
      price: int.parse(fields['price']['integerValue'] ?? '0'),
      active: fields['active']['booleanValue'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'previewUrl': previewUrl,
      'url': url,
      'visibility': visibility,
      'price': price,
      'active': active,
    };
  }

  factory Template.fromCachedJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      previewUrl: json['previewUrl'] ?? '',
      url: json['url'] ?? '',
      visibility: json['visibility'] ?? 'public',
      price: json['price'] ?? 0,
      active: json['active'] ?? false,
    );
  }
}

class CreateNoteDialog extends StatefulWidget {
  final Function(String name, String description) onCreateNote;

  const CreateNoteDialog({
    Key? key,
    required this.onCreateNote,
  }) : super(key: key);

  @override
  State<CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<CreateNoteDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final NoteService _noteService = NoteService();

  bool _isCreating = false;
  bool _isLoading = false;
  bool _isRefreshing = false;
  List<Template> _templates = [];
  Template? _selectedTemplate;
  bool _showCover = true;
  String _selectedColor = 'Black';

  static const String _cacheKey = 'cached_templates';
  static const String _cacheTimeKey = 'cached_templates_time';
  static const Duration _cacheValidDuration = Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    _loadTemplatesFromCache();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplatesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cacheTimeStr = prefs.getString(_cacheTimeKey);

      if (cachedData != null && cacheTimeStr != null) {
        final cacheTime = DateTime.parse(cacheTimeStr);
        final now = DateTime.now();

        // Load from cache
        final List<dynamic> jsonList = json.decode(cachedData);
        final cachedTemplates = jsonList
            .map((json) => Template.fromCachedJson(json))
            .where((template) => template.active)
            .toList();

        setState(() {
          _templates = cachedTemplates;
        });

        // Check if cache is still valid
        if (now.difference(cacheTime) < _cacheValidDuration) {
          // Cache is still valid, no need to fetch
          return;
        }
      }

      // Cache is invalid or doesn't exist, fetch new data
      await _fetchTemplatesFromServer();
    } catch (e) {
      // If cache loading fails, fetch from server
      await _fetchTemplatesFromServer();
    }
  }

  Future<void> _fetchTemplatesFromServer() async {
    setState(() {
      _isLoading = _templates.isEmpty;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://firestore.googleapis.com/v1/projects/organize-application/databases/(default)/documents/templates'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final documents = data['documents'] as List<dynamic>? ?? [];

        final newTemplates = documents
            .map((doc) => Template.fromJson(doc))
            .where((template) => template.active)
            .toList();

        // Check if templates have changed
        if (_hasTemplatesChanged(newTemplates)) {
          setState(() {
            _templates = newTemplates;
          });

          // Save to cache
          await _saveTemplatesToCache(newTemplates);
        }

        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  bool _hasTemplatesChanged(List<Template> newTemplates) {
    if (_templates.length != newTemplates.length) return true;

    // Compare template IDs and names
    final oldIds = _templates.map((t) => '${t.id}_${t.name}').toSet();
    final newIds = newTemplates.map((t) => '${t.id}_${t.name}').toSet();

    return !oldIds.containsAll(newIds) || !newIds.containsAll(oldIds);
  }

  Future<void> _saveTemplatesToCache(List<Template> templates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = templates.map((t) => t.toJson()).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
      await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Silently fail cache save
      debugPrint('Failed to save templates to cache: $e');
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchTemplatesFromServer();
  }

  Future<void> _createNote() async {
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a template first'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isCreating) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final name = _nameController.text
          .trim()
          .isEmpty
          ? _selectedTemplate!.name
          : _nameController.text.trim();
      final description = _descriptionController.text
          .trim()
          .isEmpty
          ? _selectedTemplate!.description
          : _descriptionController.text.trim();

      final noteId = await _noteService.createNote(
        name: name,
        description: description,
        templateUrl: _selectedTemplate!.url,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      final note = await _noteService.getNote(noteId);

      if (note != null && mounted) {
        Navigator.of(context).pop();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                NoteEditorScreen(
                  noteId: note.id,
                  noteName: note.name,
                  noteDescription: note.description,
                ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Note created but failed to open. Please try opening it from the list.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create note: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  List<Template> get _essentialTemplates {
    return _templates
        .where((template) => template.visibility == 'public')
        .toList();
  }

  List<Template> get _plannerTemplates {
    return _templates
        .where((template) => template.visibility == 'premium')
        .toList();
  }

  Widget _buildTemplateCard(Template template, {double width = 100}) {
    final isSelected = _selectedTemplate?.id == template.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTemplate = template;
        });
      },
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                ),
                color: Colors.grey[100],
              ),
              child: template.previewUrl.isNotEmpty
                  ? ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                ),
                child: Image.network(
                  template.previewUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 40,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
              )
                  : Icon(
                Icons.description,
                color: Colors.grey[400],
                size: 40,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (template.visibility == 'premium') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '₹${template.price}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else
                    ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FREE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        height: 600,
        decoration: BoxDecoration(
          color: const Color(0xFFE7E7E7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isCreating ? null : () =>
                        Navigator.of(context).pop(),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const Text(
                    'Create Note',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: _isRefreshing
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.refresh),
                    onPressed: _isRefreshing ? null : _onRefresh,
                    tooltip: 'Refresh templates',
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover/Paper section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 150,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Text(
                                          'COVER',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius
                                                  .circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius
                                                  .circular(7),
                                              child: Image.asset(
                                                'assets/images/Cover.png',
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    color: Colors.brown[100],
                                                    child: const Center(
                                                      child: Text(
                                                        'COVER',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight
                                                              .bold,
                                                          color: Colors.brown,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Text(
                                          'PAPER',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius
                                                  .circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius
                                                  .circular(7),
                                              child: Image.asset(
                                                'assets/images/paper.png',
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    color: Colors.pink[50],
                                                    child: Center(
                                                      child: Text(
                                                        'PAPER',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight
                                                              .bold,
                                                          color: Colors
                                                              .pink[300],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Cover',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Switch(
                                  value: _showCover,
                                  onChanged: (value) {
                                    setState(() {
                                      _showCover = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Custom Details
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          title: const Text(
                            'Custom Details (Optional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          initiallyExpanded: false,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Note Name',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _nameController,
                                      enabled: !_isCreating,
                                      decoration: InputDecoration(
                                        hintText: 'Enter custom note name (optional)',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              8),
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              8),
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              8),
                                          borderSide: const BorderSide(
                                              color: Colors.blue, width: 2),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              8),
                                          borderSide: BorderSide(
                                              color: Colors.grey[200]!),
                                        ),
                                        contentPadding: const EdgeInsets
                                            .symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        filled: _isCreating,
                                        fillColor: _isCreating
                                            ? Colors.grey[50]
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Description',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _descriptionController,
                                      enabled: !_isCreating,
                                      maxLines: 3,
                                      maxLength: 200,
                                      decoration: InputDecoration(
                                        hintText: 'Enter custom description (optional)',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              8),
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              8),
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              8),
                                          borderSide: const BorderSide(
                                              color: Colors.blue, width: 2),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              8),
                                          borderSide: BorderSide(
                                              color: Colors.grey[200]!),
                                        ),
                                        contentPadding: const EdgeInsets
                                            .symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        filled: _isCreating,
                                        fillColor: _isCreating
                                            ? Colors.grey[50]
                                            : null,
                                        counterStyle: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Size and Color
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('Size'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {},
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            ListTile(
                              title: const Text('Color'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedColor,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Paper Templates
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Paper Templates',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _isLoading
                                ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(),
                              ),
                            )
                                : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_essentialTemplates.isNotEmpty) ...[
                                  const Text(
                                    'Essentials',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 200,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: _essentialTemplates.length,
                                      itemBuilder: (context, index) {
                                        return _buildTemplateCard(
                                            _essentialTemplates[index]);
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (_plannerTemplates.isNotEmpty) ...[
                                  const Text(
                                    'Planners',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 200,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: _plannerTemplates.length,
                                      itemBuilder: (context, index) {
                                        return _buildTemplateCard(
                                            _plannerTemplates[index],
                                            width: 140);
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isCreating) ...[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton(
                    onPressed: _isCreating ? null : _createNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCreating ? Colors.grey[300] : Colors
                          .grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      elevation: _isCreating ? 0 : 2,
                    ),
                    child: _isCreating
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey[600]!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Creating...'),
                      ],
                    )
                        : const Text('Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}