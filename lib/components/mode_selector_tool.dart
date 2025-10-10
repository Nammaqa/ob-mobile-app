import 'package:flutter/material.dart';


enum ToolbarOption {
  apps,        // Grid icon (left)
  search,      // Search/magnifying glass
  editor,      // Pen/edit icon
  keyboard,    // Keyboard icon
  voice,       // Microphone icon
  copy,        // Copy/duplicate icon (second from right)
  bookmark,    // Bookmark icon
  more         // Three dots menu (right)
}

class NoteEditorToolbar extends StatelessWidget {
  final ToolbarOption? selectedOption;
  final Function(ToolbarOption) onOptionSelected;

  // Add image paths as parameters with default values
  final String editorIconPath;
  final String keyboardIconPath;
  final String voiceIconPath;

  const NoteEditorToolbar({
    Key? key,
    this.selectedOption,
    required this.onOptionSelected,
    this.editorIconPath = 'assets/icons/editor_icon.png',
    this.keyboardIconPath = 'assets/icons/keyboard_icon.png',
    this.voiceIconPath = 'assets/icons/voice_icon.png',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Colors.black, // Toolbar background
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side icons
          Row(
            children: [
              const SizedBox(width: 16),
              _buildToolbarIcon(
                option: ToolbarOption.apps,
                icon: Icons.apps,
                isSelected: selectedOption == ToolbarOption.apps,
              ),
              const SizedBox(width: 20),
              _buildToolbarIcon(
                option: ToolbarOption.search,
                icon: Icons.search,
                isSelected: selectedOption == ToolbarOption.search,
              ),
            ],
          ),

          // Center icons (with custom PNG images)
          Row(
            children: [
              _buildToolbarImageIcon(
                option: ToolbarOption.editor,
                imagePath: editorIconPath,
                isSelected: selectedOption == ToolbarOption.editor,
              ),
              const SizedBox(width: 30),
              _buildToolbarImageIcon(
                option: ToolbarOption.keyboard,
                imagePath: keyboardIconPath,
                isSelected: selectedOption == ToolbarOption.keyboard,
              ),
              const SizedBox(width: 30),
              _buildToolbarImageIcon(
                option: ToolbarOption.voice,
                imagePath: voiceIconPath,
                isSelected: selectedOption == ToolbarOption.voice,
              ),
            ],
          ),

          // Right side icons
          Row(
            children: [
              _buildToolbarIcon(
                option: ToolbarOption.copy,
                icon: Icons.content_copy,
                isSelected: selectedOption == ToolbarOption.copy,
              ),
              const SizedBox(width: 20),
              _buildToolbarIcon(
                option: ToolbarOption.bookmark,
                icon: Icons.bookmark_border,
                isSelected: selectedOption == ToolbarOption.bookmark,
              ),
              const SizedBox(width: 20),
              _buildToolbarIcon(
                option: ToolbarOption.more,
                icon: Icons.more_vert,
                isSelected: selectedOption == ToolbarOption.more,
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarIcon({
    required ToolbarOption option,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onOptionSelected(option),
      child: Icon(
        icon,
        size: 28,
        color: isSelected ? Colors.blue : Colors.white,
      ),
    );
  }

  Widget _buildToolbarImageIcon({
    required ToolbarOption option,
    required String imagePath,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onOptionSelected(option),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          isSelected ? Colors.blue : Colors.white,
          BlendMode.srcIn,
        ),
        child: Image.asset(
          imagePath,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}