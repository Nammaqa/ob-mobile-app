// components/toolbar_customization.dart
import 'package:flutter/material.dart';

class ToolbarCustomization extends StatefulWidget {
  final VoidCallback? onClose;

  const ToolbarCustomization({
    Key? key,
    this.onClose,
  }) : super(key: key);

  @override
  State<ToolbarCustomization> createState() => _ToolbarCustomizationState();
}

class _ToolbarCustomizationState extends State<ToolbarCustomization> {
  // Track visibility state for each tool
  Map<String, bool> toolVisibility = {
    'Lasso Tool': true,
    'Pen': true,
    'Pencil': true,
    'Eraser': true,
    'Highlighter': true,
    'Tape': true,
    'Shape': true,
    'Images': true,
    'Text Box': true,
    'Ruler': true,
    'Time Keeper': true,
  };

  String? selectedTool;

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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Row(
                    children: const [
                      Icon(
                        Icons.chevron_left,
                        size: 28,
                        color: Color(0xFF007AFF),
                      ),
                    ],
                  ),
                ),
                // Title
                const Text(
                  'Toolbar Customization',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                // Done button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF007AFF),
                      decoration: TextDecoration.none,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // VISIBLE IN TOOLBAR Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 16, 8),
                    child: Text(
                      'VISIBLE IN TOOLBAR',
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
                    child: ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final keys = toolVisibility.keys.toList();
                          final item = keys.removeAt(oldIndex);
                          keys.insert(newIndex, item);

                          final newMap = <String, bool>{};
                          for (var key in keys) {
                            newMap[key] = toolVisibility[key]!;
                          }
                          toolVisibility = newMap;
                        });
                      },
                      children: toolVisibility.entries.map((entry) {
                        final index = toolVisibility.keys.toList().indexOf(entry.key);
                        final isLast = index == toolVisibility.length - 1;

                        return _buildToolItem(
                          key: ValueKey(entry.key),
                          title: entry.key,
                          isVisible: entry.value,
                          isSelected: selectedTool == entry.key,
                          onTap: () {
                            setState(() {
                              if (selectedTool == entry.key) {
                                selectedTool = null;
                              } else {
                                selectedTool = entry.key;
                              }
                            });
                          },
                          onVisibilityToggle: () {
                            setState(() {
                              toolVisibility[entry.key] = !entry.value;
                            });
                          },
                          onRemove: () {
                            setState(() {
                              toolVisibility[entry.key] = false;
                              selectedTool = null;
                            });
                          },
                          isLast: isLast,
                        );
                      }).toList(),
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

  Widget _buildToolItem({
    required Key key,
    required String title,
    required bool isVisible,
    required bool isSelected,
    required VoidCallback onTap,
    required VoidCallback onVisibilityToggle,
    required VoidCallback onRemove,
    bool isLast = false,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : const Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Visibility toggle button
            GestureDetector(
              onTap: onVisibilityToggle,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isVisible ? Colors.black : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isVisible ? Colors.black : Colors.grey[400]!,
                    width: 1.5,
                  ),
                ),
                child: isVisible
                    ? const Icon(
                  Icons.remove,
                  size: 16,
                  color: Colors.white,
                )
                    : null,
              ),
            ),

            const SizedBox(width: 16),

            // Tool name
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

            // Show drag handle or Remove button based on selection
            if (isSelected)
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              )
            else
              Icon(
                Icons.menu,
                size: 22,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}

// Function to show Toolbar Customization
void showToolbarCustomization(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ToolbarCustomization(
        onClose: () {
          Navigator.of(dialogContext).pop();
        },
      ),
    ),
  );
}