import 'package:flutter/material.dart';

enum ToolbarOption { editor, keyboard, voice }

class NoteEditorToolbar extends StatelessWidget {
  final ToolbarOption? selectedOption;
  final Function(ToolbarOption) onOptionSelected;

  const NoteEditorToolbar({
    Key? key,
    this.selectedOption,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Colors.black, // Toolbar background
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center all icons
        children: [
          _buildToolbarIcon(
            option: ToolbarOption.editor,
            icon: Icons.brush,
            isSelected: selectedOption == ToolbarOption.editor,
          ),
          const SizedBox(width: 30),
          _buildToolbarIcon(
            option: ToolbarOption.keyboard,
            icon: Icons.keyboard,
            isSelected: selectedOption == ToolbarOption.keyboard,
          ),
          const SizedBox(width: 30),
          _buildToolbarIcon(
            option: ToolbarOption.voice,
            icon: Icons.mic,
            isSelected: selectedOption == ToolbarOption.voice,
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
}