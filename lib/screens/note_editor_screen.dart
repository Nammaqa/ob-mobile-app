import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../components/drawing_editor.dart';
import 'package:organize/components/mode_selector_tool.dart';
import '../service/note_service.dart';
import 'dart:async';
import 'dart:convert';

class NoteEditorScreen extends StatefulWidget {
  final String noteId;
  final String noteName;
  final String noteDescription;

  const NoteEditorScreen({
    Key? key,
    required this.noteId,
    required this.noteName,
    required this.noteDescription,
  }) : super(key: key);

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> with WidgetsBindingObserver {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final NoteService _noteService = NoteService();
  late PdfViewerController _pdfViewerController;
  bool _canShowPaginationDialog = true;
  int _currentPageNumber = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;
  String? _cachedPdfPath;
  bool _isSaving = false;
  DateTime? _lastSaveTime;
  bool _isEditorActive = true;

  ToolbarOption? _selectedToolbarOption = ToolbarOption.editor;

  String? _templateUrl;
  String _cacheKey = '';
  String _cacheVersionKey = '';

  static const Duration _autoSaveDelay = Duration(seconds: 5);
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pdfViewerController = PdfViewerController();
    _initializePdfFromTemplate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveNoteState();
    _autoSaveTimer?.cancel();
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveNoteState();
    }
  }

  void _handleToolbarOptionSelected(ToolbarOption option) {
    setState(() {
      _selectedToolbarOption = option;
      switch (option) {
        case ToolbarOption.editor:
          _isEditorActive = true;
          break;
        case ToolbarOption.keyboard:
          _isEditorActive = false;
          _handleKeyboardOption();
          break;
        case ToolbarOption.voice:
          _isEditorActive = false;
          _handleVoiceOption();
          break;
      }
    });
  }

  void _handleKeyboardOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keyboard Input'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Add text note',
                hintText: 'Type your note here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Text note saved'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleVoiceOption() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.mic, color: Colors.white),
            SizedBox(width: 8),
            Text('Voice recording feature coming soon...'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _initializePdfFromTemplate() async {
    try {
      print('🚀 Initializing PDF for note: ${widget.noteId}');

      // Fetch note details to get template URL
      final note = await _noteService.getNote(widget.noteId);

      if (note == null) {
        print('❌ Note not found');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Note not found';
        });
        return;
      }

      print('📝 Note loaded: ${note.name}');
      print('🔗 Template URL: ${note.templateUrl}');

      // Get template URL from note
      _templateUrl = note.templateUrl;

      if (_templateUrl == null || _templateUrl!.isEmpty) {
        print('❌ No template URL found');
        setState(() {
          _isLoading = false;
          _errorMessage = 'No template URL found for this note. This note may have been created before the template system was implemented.';
        });
        return;
      }

      _cacheKey = 'pdf_cache_${widget.noteId}';
      _cacheVersionKey = 'pdf_cache_version_${widget.noteId}';

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cachedPath = prefs.getString(_cacheKey);
      final String? cachedUrl = prefs.getString('${_cacheKey}_url');

      print('💾 Cached path: $cachedPath');
      print('🔗 Cached URL: $cachedUrl');

      // Check if cached PDF exists and matches current template URL
      if (cachedPath != null &&
          cachedUrl == _templateUrl &&
          await File(cachedPath).exists()) {
        print('✅ Using cached PDF');
        _cachedPdfPath = cachedPath;
        setState(() {
          _isLoading = false;
        });
        _loadNoteState();
      } else {
        print('⬇️ Downloading fresh PDF');
        await _downloadAndCachePdf(prefs);
      }
    } catch (e, stackTrace) {
      print('❌ Error in _initializePdfFromTemplate: $e');
      print('📚 Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize PDF: $e';
      });
    }
  }

  Future<void> _downloadAndCachePdf(SharedPreferences prefs) async {
    try {
      print('📥 Attempting to download PDF from: $_templateUrl');

      // Download PDF from URL
      final response = await http.get(Uri.parse(_templateUrl!));

      print('📡 HTTP Response Status: ${response.statusCode}');
      print('📄 Content-Type: ${response.headers['content-type']}');
      print('📦 Content Length: ${response.bodyBytes.length} bytes');

      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }

      final Uint8List bytes = response.bodyBytes;

      // Check if the response is actually a PDF
      if (bytes.length < 5 ||
          bytes[0] != 0x25 || // %
          bytes[1] != 0x50 || // P
          bytes[2] != 0x44 || // D
          bytes[3] != 0x46) { // F
        // Not a valid PDF file
        print('❌ Downloaded file is not a valid PDF. First bytes: ${bytes.take(20).toList()}');

        // Try to decode as text to see what we got
        try {
          final text = String.fromCharCodes(bytes.take(200));
          print('📝 Content preview: $text');
        } catch (e) {
          print('⚠️ Could not decode content as text');
        }

        throw Exception('Downloaded file is not a valid PDF format. Check the template URL.');
      }

      print('✅ PDF validation passed');

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String cacheDir = '${appDir.path}/pdf_cache';

      await Directory(cacheDir).create(recursive: true);

      final String cachedPath = '$cacheDir/note_${widget.noteId}.pdf';
      final File cachedFile = File(cachedPath);
      await cachedFile.writeAsBytes(bytes);

      print('💾 PDF cached at: $cachedPath');

      await prefs.setString(_cacheKey, cachedPath);
      await prefs.setString('${_cacheKey}_url', _templateUrl!);

      _cachedPdfPath = cachedPath;
      setState(() {
        _isLoading = false;
      });
      _loadNoteState();
    } catch (e, stackTrace) {
      print('❌ Error downloading PDF: $e');
      print('📚 Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to download PDF: $e\n\nURL: $_templateUrl';
      });
    }
  }

  Future<void> _loadNoteState() async {
    try {
      final note = await _noteService.getNote(widget.noteId);
      if (note != null && note.lastOpenedPage > 0) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _totalPages > 0) {
            _pdfViewerController.jumpToPage(note.lastOpenedPage);
            if (note.zoomLevel > 0) {
              _pdfViewerController.zoomLevel = note.zoomLevel;
            }
          }
        });
      }
    } catch (e) {
      print('Error loading note state: $e');
    }
  }

  Future<void> _saveNoteState() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _noteService.updateNote(
        noteId: widget.noteId,
        lastOpenedPage: _currentPageNumber,
        zoomLevel: _pdfViewerController.zoomLevel,
      );

      _lastSaveTime = DateTime.now();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-saved'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving note state: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      _saveNoteState();
    });
  }

  Future<void> clearPdfCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cachedPath = prefs.getString(_cacheKey);

      if (cachedPath != null) {
        final File cachedFile = File(cachedPath);
        if (await cachedFile.exists()) {
          await cachedFile.delete();
        }
      }

      await prefs.remove(_cacheKey);
      await prefs.remove('${_cacheKey}_url');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveNoteState();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.noteName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isSaving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  if (!_isSaving && _lastSaveTime != null)
                    Icon(
                      Icons.cloud_done,
                      size: 16,
                      color: Colors.green[600],
                    ),
                ],
              ),
              if (widget.noteDescription.isNotEmpty)
                Text(
                  widget.noteDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.1),
          actions: _buildAppBarActions(),
        ),
        body: Column(
          children: [
            NoteEditorToolbar(
              selectedOption: _selectedToolbarOption,
              onOptionSelected: _handleToolbarOptionSelected,
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isLoading || _errorMessage != null) return [];

    return [
      IconButton(
        icon: const Icon(Icons.keyboard_arrow_up),
        onPressed: _currentPageNumber > 1 ? _previousPage : null,
        tooltip: 'Previous Page',
      ),
      IconButton(
        icon: const Icon(Icons.keyboard_arrow_down),
        onPressed: _currentPageNumber < _totalPages ? _nextPage : null,
        tooltip: 'Next Page',
      ),
      IconButton(
        icon: const Icon(Icons.pageview),
        onPressed: _showGoToPageDialog,
        tooltip: 'Go to Page',
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.zoom_in),
        tooltip: 'Zoom Options',
        onSelected: (value) => _handleZoomAction(value),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'fit_width', child: Text('Fit Width')),
          const PopupMenuItem(value: 'fit_page', child: Text('Fit Page')),
          const PopupMenuItem(value: 'zoom_in', child: Text('Zoom In')),
          const PopupMenuItem(value: 'zoom_out', child: Text('Zoom Out')),
        ],
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: 'More Options',
        onSelected: (value) => _handleMoreActions(value),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'save', child: Text('Save Now')),
          const PopupMenuItem(value: 'info', child: Text('Note Info')),
          const PopupMenuItem(value: 'export', child: Text('Export Note')),
          const PopupMenuItem(value: 'clear_cache', child: Text('Clear Cache')),
        ],
      ),
    ];
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: [
              _buildPdfView(),
              if (_isEditorActive)
                Positioned.fill(
                  child: DrawingOverlay(
                    noteId: widget.noteId,
                    currentPage: _currentPageNumber,
                    onSave: _handleDrawingSave,
                    onDrawingChanged: _onDrawingChanged,
                    child: Container(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: Opacity(
                  opacity: 0.6 + (value * 0.4),
                  child: Image.asset(
                    'assets/images/organize_splash.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.description,
                        size: 120,
                        color: Colors.blue,
                      );
                    },
                  ),
                ),
              );
            },
            onEnd: () {
              if (mounted && _isLoading) {
                setState(() {}); // Restart animation
              }
            },
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your note...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.noteName,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load note',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  await clearPdfCache();
                  await _initializePdfFromTemplate();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPdfView() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 60),
      child: SfPdfViewer.file(
        File(_cachedPdfPath!),
        key: _pdfViewerKey,
        controller: _pdfViewerController,
        canShowPaginationDialog: _canShowPaginationDialog,
        interactionMode: _isEditorActive
            ? PdfInteractionMode.pan
            : PdfInteractionMode.selection,
        scrollDirection: PdfScrollDirection.vertical,
        pageLayoutMode: PdfPageLayoutMode.single,
        initialZoomLevel: 1.0,
        onDocumentLoaded: (details) {
          setState(() {
            _totalPages = details.document.pages.count;
          });
          _loadNoteState();
        },
        onPageChanged: (details) {
          setState(() {
            _currentPageNumber = details.newPageNumber;
          });
          _scheduleAutoSave();
        },
        onDocumentLoadFailed: (details) {
          setState(() {
            _errorMessage = 'Failed to load PDF: ${details.error}';
          });
        },
      ),
    );
  }

  void _onDrawingChanged(Map<String, dynamic> drawingData) {
    _noteService.saveDrawingData(widget.noteId, drawingData).catchError((error) {
      print('Error saving drawing data: $error');
    });
  }

  Future<void> _handleDrawingSave(Uint8List drawingBytes) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final String fileName =
            '${widget.noteName.replaceAll(' ', '_')}_drawing_page_${_currentPageNumber}_${DateTime.now().millisecondsSinceEpoch}.png';
        final String path = '${directory.path}/$fileName';

        final File file = File(path);
        await file.writeAsBytes(drawingBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Drawing saved: $fileName'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save drawing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _previousPage() {
    if (_currentPageNumber > 1) {
      _pdfViewerController.previousPage();
    }
  }

  void _nextPage() {
    if (_currentPageNumber < _totalPages) {
      _pdfViewerController.nextPage();
    }
  }

  void _showGoToPageDialog() {
    if (_totalPages == 0) return;

    final TextEditingController pageController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Go to Page'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter page number (1 - $_totalPages):'),
              const SizedBox(height: 16),
              TextField(
                controller: pageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Page number',
                  border: const OutlineInputBorder(),
                  suffixText: '/ $_totalPages',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final pageNumber = int.tryParse(pageController.text);
                if (pageNumber != null && pageNumber >= 1 && pageNumber <= _totalPages) {
                  _pdfViewerController.jumpToPage(pageNumber);
                  Navigator.pop(context);
                }
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }

  void _handleZoomAction(String action) {
    switch (action) {
      case 'fit_page':
        _pdfViewerController.zoomLevel = 1.0;
        break;
      case 'fit_width':
        _pdfViewerController.zoomLevel = 1.25;
        break;
      case 'zoom_in':
        final currentZoom = _pdfViewerController.zoomLevel;
        _pdfViewerController.zoomLevel = (currentZoom * 1.25).clamp(1.0, 3.0);
        break;
      case 'zoom_out':
        final currentZoom = _pdfViewerController.zoomLevel;
        _pdfViewerController.zoomLevel = (currentZoom * 0.8).clamp(1.0, 3.0);
        break;
    }
    _scheduleAutoSave();
  }

  void _handleMoreActions(String action) {
    switch (action) {
      case 'save':
        _saveNoteState();
        break;
      case 'info':
        _showNoteInfo();
        break;
      case 'export':
        _exportNote();
        break;
      case 'clear_cache':
        _clearCacheDialog();
        break;
    }
  }

  void _clearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear the cached PDF and free up storage space.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await clearPdfCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showNoteInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Note Name', widget.noteName),
            _buildInfoRow('Description', widget.noteDescription.isEmpty ? 'No description' : widget.noteDescription),
            _buildInfoRow('Note ID', widget.noteId),
            _buildInfoRow('Total Pages', '$_totalPages'),
            _buildInfoRow('Current Page', '$_currentPageNumber'),
            _buildInfoRow('Zoom Level', '${(_pdfViewerController.zoomLevel * 100).toInt()}%'),
            _buildInfoRow('Last Saved', _lastSaveTime != null ? _lastSaveTime.toString().split('.')[0] : 'Not saved yet'),
            _buildInfoRow('Cache Status', _cachedPdfPath != null ? 'Cached' : 'Not Cached'),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportNote() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Note'),
        content: const Text('Export your note as PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveCopy();
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCopy() async {
    try {
      if (_cachedPdfPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF not loaded yet'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final File cachedFile = File(_cachedPdfPath!);
      final Uint8List bytes = await cachedFile.readAsBytes();

      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final String fileName =
            '${widget.noteName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final String path = '${directory.path}/$fileName';

        final File file = File(path);
        await file.writeAsBytes(bytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note saved: $fileName'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save note: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}