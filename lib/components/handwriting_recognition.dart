// components/handwriting_recognition.dart
import 'package:flutter/material.dart';

class HandwritingRecognition extends StatefulWidget {
  final VoidCallback? onClose;

  const HandwritingRecognition({
    Key? key,
    this.onClose,
  }) : super(key: key);

  @override
  State<HandwritingRecognition> createState() => _HandwritingRecognitionState();
}

class _HandwritingRecognitionState extends State<HandwritingRecognition> {
  bool languageDirection = false;
  bool indexPdfAndHandwriting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      height: 560,
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
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.chevron_left,
                    size: 28,
                    color: Colors.black,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Handwriting Recognition',
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
                const SizedBox(width: 28),
              ],
            ),
          ),

          // Body content
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Options Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            _buildToggleItem(
                              title: 'Language Direction',
                              value: languageDirection,
                              onChanged: (value) {
                                setState(() {
                                  languageDirection = value;
                                });
                              },
                              isFirst: true,
                            ),
                            _buildDivider(),
                            _buildToggleItem(
                              title: 'Index PDF and Handwriting Notes',
                              value: indexPdfAndHandwriting,
                              onChanged: (value) {
                                setState(() {
                                  indexPdfAndHandwriting = value;
                                });
                              },
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Description text below card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text(
                        'Improves the experience when searching documents',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                          decoration: TextDecoration.none,
                          fontFamily: '.SF Pro Text',
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
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
        color: Colors.white,
        borderRadius: isFirst
            ? const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        )
            : isLast
            ? const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        )
            : null,
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
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF000000),
            activeTrackColor: const Color(0xFF34C759).withOpacity(0.5),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE5E5EA),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(
        height: 0.5,
        color: Colors.grey[300],
      ),
    );
  }
}

// Function to show Handwriting Recognition
void showHandwritingRecognition(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: HandwritingRecognition(
        onClose: () {
          Navigator.of(dialogContext).pop();
        },
      ),
    ),
  );
}