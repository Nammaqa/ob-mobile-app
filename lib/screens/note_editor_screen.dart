import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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

  // Your single template path
  static const String _templatePath = 'assets/templates/apple_planner.pdf';

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _checkAssetExists();
  }

  Future<void> _checkAssetExists() async {
    try {
      // Try to load the asset to check if it exists
      await DefaultAssetBundle.of(context).load(_templatePath);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Apple Planner template not found. Please make sure "assets/templates/apple_planner.pdf" exists in your assets folder.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(),
      // Floating action button for page navigation
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
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading Apple Planner...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.noteName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _checkAssetExists();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    // PDF Viewer with Apple Planner template
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SfPdfViewer.asset(
        _templatePath,
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
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          setState(() {
            _totalPages = details.document.pages.count;
          });
        },
        onPageChanged: (PdfPageChangedDetails details) {
          setState(() {
            _currentPageNumber = details.newPageNumber;
          });
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          setState(() {
            _errorMessage = 'Failed to load Apple Planner: ${details.error}';
          });
        },
      ),
    );
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
    }
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
            _buildInfoRow('Template', 'Apple Planner'),
            _buildInfoRow('Total Pages', '$_totalPages'),
            _buildInfoRow('Current Page', '$_currentPageNumber'),
            _buildInfoRow('Zoom Level', '${(_pdfViewerController.zoomLevel * 100).toInt()}%'),
            _buildInfoRow('Created', DateTime.now().toString().split('.')[0]),
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
      // Load asset data
      final ByteData data = await DefaultAssetBundle.of(context).load(_templatePath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Get documents directory (works on both Android and iOS)
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final String fileName = '${widget.noteName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final String path = '${directory.path}/$fileName';

        // Write file
        final File file = File(path);
        await file.writeAsBytes(bytes);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note saved: $fileName\nLocation: ${directory.path}'),
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
    // Show export options
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
              _saveCopy(); // Save as PDF
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }
}