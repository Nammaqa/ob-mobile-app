// screens/note_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/drawing_editor.dart';
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

  static const String _templatePath = 'assets/templates/apple_planner.pdf';
  static const String _cacheKey = 'apple_planner_cache_path';
  static const String _cacheVersionKey = 'apple_planner_cache_version';
  static const String _currentVersion = '1.0.0';

  // Auto-save timer
  static const Duration _autoSaveDelay = Duration(seconds: 5);
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pdfViewerController = PdfViewerController();
    _initializePdfCache();
    _loadNoteState();
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

  Future<void> _initializePdfCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cachedPath = prefs.getString(_cacheKey);
      final String? cachedVersion = prefs.getString(_cacheVersionKey);

      if (cachedPath != null &&
          cachedVersion == _currentVersion &&
          await File(cachedPath).exists()) {
        _cachedPdfPath = cachedPath;
        setState(() {
          _isLoading = false;
        });
      } else {
        await _cachePdfToLocalStorage(prefs);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize PDF cache: $e';
      });
    }
  }

  Future<void> _cachePdfToLocalStorage(SharedPreferences prefs) async {
    try {
      final ByteData data = await DefaultAssetBundle.of(context).load(_templatePath);
      final Uint8List bytes = data.buffer.asUint8List();

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String cacheDir = '${appDir.path}/pdf_cache';

      await Directory(cacheDir).create(recursive: true);

      final String cachedPath = '$cacheDir/apple_planner_cached.pdf';
      final File cachedFile = File(cachedPath);
      await cachedFile.writeAsBytes(bytes);

      await prefs.setString(_cacheKey, cachedPath);
      await prefs.setString(_cacheVersionKey, _currentVersion);

      _cachedPdfPath = cachedPath;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to cache PDF: $e';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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

  static Future<void> clearPdfCache() async {
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
      await prefs.remove(_cacheVersionKey);
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
          actions: [
            if (!_isLoading && _errorMessage == null) ...[
              // Page navigation buttons
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
              // Go to page
              IconButton(
                icon: const Icon(Icons.pageview),
                onPressed: _showGoToPageDialog,
                tooltip: 'Go to Page',
              ),
              // Zoom controls
              PopupMenuButton<String>(
                icon: const Icon(Icons.zoom_in),
                tooltip: 'Zoom Options',
                onSelected: (value) => _handleZoomAction(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'fit_width',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 18),
                        SizedBox(width: 8),
                        Text('Fit Width'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'fit_page',
                    child: Row(
                      children: [
                        Icon(Icons.fit_screen, size: 18),
                        SizedBox(width: 8),
                        Text('Fit Page'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'zoom_in',
                    child: Row(
                      children: [
                        Icon(Icons.zoom_in, size: 18),
                        SizedBox(width: 8),
                        Text('Zoom In'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'zoom_out',
                    child: Row(
                      children: [
                        Icon(Icons.zoom_out, size: 18),
                        SizedBox(width: 8),
                        Text('Zoom Out'),
                      ],
                    ),
                  ),
                ],
              ),
              // More options
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More Options',
                onSelected: (value) => _handleMoreActions(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'save',
                    child: Row(
                      children: [
                        Icon(Icons.save, size: 18),
                        SizedBox(width: 8),
                        Text('Save Now'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Note Info'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 18),
                        SizedBox(width: 8),
                        Text('Export Note'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_cache',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, size: 18),
                        SizedBox(width: 8),
                        Text('Clear Cache'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        body: Container(
          color: Colors.white,
          child: _buildBody(),
        ),
        bottomNavigationBar: (!_isLoading && _errorMessage == null && _totalPages > 1)
            ? Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Page $_currentPageNumber of $_totalPages',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPageNumber > 1
                    ? () => _pdfViewerController.jumpToPage(1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPageNumber > 1 ? _previousPage : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPageNumber < _totalPages ? _nextPage : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPageNumber < _totalPages
                    ? () => _pdfViewerController.jumpToPage(_totalPages)
                    : null,
              ),
            ],
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _cachedPdfPath == null
                  ? 'Preparing Apple Planner...'
                  : 'Loading from cache...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
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
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load Apple Planner',
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
                    await _initializePdfCache();
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

    // PDF with drawing overlay
    return Container(
      color: Colors.white,
      child: DrawingOverlay(
        noteId: widget.noteId,
        currentPage: _currentPageNumber,
        onSave: _handleDrawingSave,
        onDrawingChanged: _onDrawingChanged,
        child: _buildPdfView(),
      ),
    );
  }

  Widget _buildPdfView() {
    return Container(
      color: Colors.white,
      child: SfPdfViewer.file(
        File(_cachedPdfPath!),
        key: _pdfViewerKey,
        controller: _pdfViewerController,
        canShowPaginationDialog: _canShowPaginationDialog,
        canShowPasswordDialog: false,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        interactionMode: PdfInteractionMode.selection,
        scrollDirection: PdfScrollDirection.vertical,
        pageLayoutMode: PdfPageLayoutMode.single,
        initialZoomLevel: 1.0,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          setState(() {
            _totalPages = details.document.pages.count;
          });
          _loadNoteState();
        },
        onPageChanged: (PdfPageChangedDetails details) {
          if (mounted) {
            setState(() {
              _currentPageNumber = details.newPageNumber;
            });
            _scheduleAutoSave();
          }
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to load Apple Planner: ${details.error}';
            });
          }
        },
      ),
    );
  }

  void _onDrawingChanged(Map<String, dynamic> drawingData) {
    // Save drawing data to Firestore
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
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save drawing: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Page number',
                  hintText: '1',
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
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid page number between 1 and $_totalPages'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
        content: const Text(
            'This will clear the cached PDF and free up storage space. The PDF will be re-cached on next load.'),
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
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNoteInfo() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Note Name', widget.noteName),
            _buildInfoRow('Description',
                widget.noteDescription.isEmpty ? 'No description' : widget.noteDescription),
            _buildInfoRow('Note ID', widget.noteId),
            _buildInfoRow('Template', 'Apple Planner'),
            _buildInfoRow('Total Pages', '$_totalPages'),
            _buildInfoRow('Current Page', '$_currentPageNumber'),
            _buildInfoRow('Zoom Level', '${(_pdfViewerController.zoomLevel * 100).toInt()}%'),
            _buildInfoRow('Last Saved',
                _lastSaveTime != null ? _lastSaveTime.toString().split('.')[0] : 'Not saved yet'),
            _buildInfoRow('Cache Status', _cachedPdfPath != null ? 'Cached' : 'Not Cached'),
            _buildInfoRow('Auto-save', 'Enabled'),
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
        content: const Text('Export your Apple Planner note as PDF?'),
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
