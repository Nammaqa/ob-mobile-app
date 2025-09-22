// components/header_component.dart
import 'package:flutter/material.dart';
import '../service/note_service.dart';
import '../models/note_model.dart';

class HeaderComponent extends StatelessWidget {
  final String title;
  final NoteService? noteService; // Optional for pages that don't need note count

  const HeaderComponent({
    Key? key,
    required this.title,
    this.noteService,
  }) : super(key: key);

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
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),

          // Note count (only show if noteService is provided)
          if (noteService != null)
            StreamBuilder<List<Note>>(
              stream: noteService!.getUserNotes(),
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

              // Settings icon - bigger
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 24,
                    color: Colors.grey[600],
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