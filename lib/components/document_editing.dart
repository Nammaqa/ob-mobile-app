// components/document_editing.dart
import 'package:flutter/material.dart';
import 'toolbar_customization.dart';

class DocumentEditing extends StatefulWidget {
  final VoidCallback? onClose;

  const DocumentEditing({
    Key? key,
    this.onClose,
  }) : super(key: key);

  @override
  State<DocumentEditing> createState() => _DocumentEditingState();
}

class _DocumentEditingState extends State<DocumentEditing> {
  bool pullToAddPage = true;
  bool showPageNumber = true;
  String scrollingDirection = 'Vertical';
  bool userID = true;
  bool automaticallyOpenNewImportedDocument = true;
  bool openDocumentAsNewTabs = true;
  String undoRedoPosition = 'Left';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with back button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.chevron_left,
                        size: 28,
                        color: const Color(0xFF007AFF),
                      ),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF007AFF),
                          decoration: TextDecoration.none,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: const Text(
                      'Document Editing',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        decoration: TextDecoration.none,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                ),
                // Spacer to balance the back button width
                const SizedBox(width: 80),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DOCUMENT EDITING Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 16, 8),
                    child: Text(
                      'DOCUMENT EDITING',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                        decoration: TextDecoration.none,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildToggleItem(
                          title: 'Pull to Add Page',
                          value: pullToAddPage,
                          onChanged: (val) => setState(() => pullToAddPage = val),
                          isFirst: true,
                        ),
                        _buildToggleItem(
                          title: 'Show Page Number',
                          value: showPageNumber,
                          onChanged: (val) => setState(() => showPageNumber = val),
                        ),
                        _buildSelectionItem(
                          title: 'Scrolling Direction',
                          value: scrollingDirection,
                          onTap: () {
                            _showScrollingDirectionPicker();
                          },
                        ),
                        _buildToggleItem(
                          title: 'User ID',
                          value: userID,
                          onChanged: (val) => setState(() => userID = val),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  // TOOLBAR Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 16, 8),
                    child: Text(
                      'TOOLBAR',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                        decoration: TextDecoration.none,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildNavigationItem(
                          title: 'Toolbar Customization',
                          onTap: () {
                            showToolbarCustomization(context);
                          },
                          isFirst: true,
                        ),
                        _buildSelectionItem(
                          title: 'Undo and Redo Position',
                          value: undoRedoPosition,
                          onTap: () {
                            _showUndoRedoPositionPicker();
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  // DOCUMENT OPENING Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 16, 8),
                    child: Text(
                      'DOCUMENT OPENING',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                        decoration: TextDecoration.none,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildToggleItem(
                          title: 'Automatically Open New Imported Document',
                          value: automaticallyOpenNewImportedDocument,
                          onChanged: (val) => setState(
                                  () => automaticallyOpenNewImportedDocument = val),
                          isFirst: true,
                        ),
                        _buildToggleItem(
                          title: 'Open Document as New Tabs',
                          value: openDocumentAsNewTabs,
                          onChanged: (val) =>
                              setState(() => openDocumentAsNewTabs = val),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                decoration: TextDecoration.none,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFFFFFFFF),
              activeTrackColor: const Color(0xFF000000).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionItem({
    required String title,
    required String value,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isLast ? Colors.transparent : const Color(0xFFE5E5EA),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  decoration: TextDecoration.none,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                      decoration: TextDecoration.none,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: const Color(0xFFC7C7CC),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required String title,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isLast ? Colors.transparent : const Color(0xFFE5E5EA),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  decoration: TextDecoration.none,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 22,
                color: const Color(0xFFC7C7CC),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScrollingDirectionPicker() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPickerOption(
                'Horizontal',
                scrollingDirection == 'Horizontal',
                    () {
                  setState(() => scrollingDirection = 'Horizontal');
                  Navigator.pop(context);
                },
                true,
              ),
              _buildPickerOption(
                'Vertical',
                scrollingDirection == 'Vertical',
                    () {
                  setState(() => scrollingDirection = 'Vertical');
                  Navigator.pop(context);
                },
                false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUndoRedoPositionPicker() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPickerOption(
                'Left',
                undoRedoPosition == 'Left',
                    () {
                  setState(() => undoRedoPosition = 'Left');
                  Navigator.pop(context);
                },
                true,
              ),
              _buildPickerOption(
                'Right',
                undoRedoPosition == 'Right',
                    () {
                  setState(() => undoRedoPosition = 'Right');
                  Navigator.pop(context);
                },
                false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption(
      String title, bool isSelected, VoidCallback onTap, bool isFirst) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isFirst ? const Color(0xFFE5E5EA) : Colors.transparent,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 22,
                color: isSelected ? const Color(0xFF007AFF) : Colors.grey[400],
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  decoration: TextDecoration.none,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Function to show Document Editing
void showDocumentEditing(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: DocumentEditing(
        onClose: () {
          Navigator.of(dialogContext).pop();
        },
      ),
    ),
  );
}