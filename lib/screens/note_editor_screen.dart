// screens/note_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/drawing_editor.dart';

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
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  late PdfViewerController _pdfViewerController;
  bool _canShowPaginationDialog = true;
  int _currentPageNumber = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;
  String? _cachedPdfPath;

  static const String _templatePath = 'assets/templates/apple_planner.pdf';
  static const String _cacheKey = 'apple_planner_cache_path';
  static const String _cacheVersionKey = 'apple_planner_cache_version';
  static const String _currentVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _initializePdfCache();
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

  Future<void> _saveUserState() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${widget.noteName}_current_page', _currentPageNumber);
      await prefs.setDouble('${widget.noteName}_zoom_level', _pdfViewerController.zoomLevel);
      await prefs.setString('${widget.noteName}_last_opened', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving user state: $e');
    }
  }

  Future<void> _loadUserState() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? savedPage = prefs.getInt('${widget.noteName}_current_page');
      final double? savedZoom = prefs.getDouble('${widget.noteName}_zoom_level');

      if (savedPage != null && savedPage > 0 && savedPage <= _totalPages) {
        _pdfViewerController.jumpToPage(savedPage);
      }

      if (savedZoom != null && savedZoom > 0) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _pdfViewerController.zoomLevel = savedZoom;
          }
        });
      }
    } catch (e) {
      print('Error loading user state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.noteName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
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
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.save_alt, size: 18),
                      SizedBox(width: 8),
                      Text('Save Copy'),
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
      floatingActionButton: (!_isLoading && _errorMessage == null && _totalPages > 1)
          ? FloatingActionButton.extended(
        onPressed: _showGoToPageDialog,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.pageview, size: 18),
        label: Text('$_currentPageNumber / $_totalPages'),
      )
          : null,
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
            const SizedBox(height: 16),
            Text(
              _cachedPdfPath == null
                  ? 'First time setup - caching for faster future loads...'
                  : 'Loading cached planner...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
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
      color: Colors.white, // Ensure white background
      child: DrawingOverlay(
        noteId: widget.noteName,
        currentPage: _currentPageNumber, // Add this line
        onSave: _handleDrawingSave,
        child: _buildPdfView(),
      ),
    );
  }

  Widget _buildPdfView() {
    return Container(
        color: Colors.white, // Add white background
        child: SfPdfViewer.file(
          File(_cachedPdfPath!),
          key: _pdfViewerKey,
          controller: _pdfViewerController,
          // ... rest of the properties
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
        _loadUserState();
      },
      onPageChanged: (PdfPageChangedDetails details) {
        if (mounted) {
          setState(() {
            _currentPageNumber = details.newPageNumber;
          });
          _saveUserState();
        }
      },
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load Apple Planner: ${details.error}';
          });
        }
      },
    ));
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
        final String fileName = '${widget.noteName.replaceAll(' ', '_')}_drawing_page_${_currentPageNumber}_${DateTime.now().millisecondsSinceEpoch}.png';
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
    _saveUserState();
  }

  void _handleMoreActions(String action) {
    switch (action) {
      case 'info':
        _showNoteInfo();
        break;
      case 'save':
        _saveCopy();
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
        content: const Text('This will clear the cached PDF and free up storage space. The PDF will be re-cached on next load.'),
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastOpened = prefs.getString('${widget.noteName}_last_opened');

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
            _buildInfoRow('Template', 'Apple Planner'),
            _buildInfoRow('Total Pages', '$_totalPages'),
            _buildInfoRow('Current Page', '$_currentPageNumber'),
            _buildInfoRow('Zoom Level', '${(_pdfViewerController.zoomLevel * 100).toInt()}%'),
            _buildInfoRow('Last Opened', lastOpened != null
                ? DateTime.parse(lastOpened).toString().split('.')[0]
                : 'Never'),
            _buildInfoRow('Cache Status', _cachedPdfPath != null ? 'Cached' : 'Not Cached'),
            _buildInfoRow('Drawing', 'Available - Use toolbar at top'),
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
        final String fileName = '${widget.noteName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

  @override
  void dispose() {
    _saveUserState();
    _pdfViewerController.dispose();
    super.dispose();
  }
}