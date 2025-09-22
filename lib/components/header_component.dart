// components/header_component.dart
import 'package:flutter/material.dart';
import '../service/note_service.dart';
import '../models/note_model.dart';
import 'settings_dropdown.dart'; // Add this import

class HeaderComponent extends StatefulWidget {
  final String title;
  final NoteService? noteService; // Optional for pages that don't need note count

  const HeaderComponent({
    Key? key,
    required this.title,
    this.noteService,
  }) : super(key: key);

  @override
  State<HeaderComponent> createState() => _HeaderComponentState();
}

class _HeaderComponentState extends State<HeaderComponent> {
  bool _isDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isDropdownOpen = false;
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible barrier to close dropdown when clicked outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // Dropdown positioned relative to the settings button
          Positioned(
            width: 240,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-216, 50), // Moved down from 40 to 50
              child: SettingsDropdown(
                onClose: _closeDropdown,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),

          // Note count (only show if noteService is provided)
          if (widget.noteService != null)
            StreamBuilder<List<Note>>(
              stream: widget.noteService!.getUserNotes(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count notes',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),

          const Spacer(),

          // Action buttons
          Row(
            children: [
              // Upgrade button - bigger
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF000000),
                        Color(0xFFA2A2A2),
                        Color(0xFFC4C4C4),
                        Color(0xFF202020),
                        Color(0xFF6F6F6F),
                        Color(0xFF999999),
                        Color(0xFFB1B1B1),
                        Color(0xFFD9D9D9),
                      ],
                      stops: [
                        0.0,
                        0.0,
                        0.0,
                        0.0001,
                        0.0002,
                        0.0003,
                        0.0004,
                        1.0,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Upgrade',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Notification icon - bigger
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/icons/notification.png',
                    width: 24,
                    height: 24,
                    color: Colors.grey[600], // optional tint
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Settings icon with dropdown - bigger
              CompositedTransformTarget(
                link: _layerLink,
                child: InkWell(
                  onTap: _toggleDropdown,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isDropdownOpen ? Colors.grey[100] : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      size: 24,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}