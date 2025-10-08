// components/troubleshooting.dart
import 'package:flutter/material.dart';

class TroubleshootingPopup extends StatelessWidget {
  const TroubleshootingPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header with back button, title and Done button
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
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Icon(
                    Icons.chevron_left,
                    size: 28,
                    color: Color(0xFF007AFF),
                  ),
                ),
                const Text(
                  'Trubleshooting',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DEFAULT TEMPLATES section
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 12, bottom: 6),
                    child: Text(
                      'DEFAULT TEMPLATES',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withOpacity(0.6),
                        decoration: TextDecoration.none,
                        fontFamily: '.SF Pro Text',
                        letterSpacing: -0.08,
                      ),
                    ),
                  ),

                  // Restore Default Templates button
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Handle restore default templates
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: const Center(
                            child: Text(
                              'Restore Default Templates',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                decoration: TextDecoration.none,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Footer text below the first card
                  Padding(
                    padding: const EdgeInsets.only(left: 28, right: 28, top: 8, bottom: 20),
                    child: Text(
                      'Templates and groups you have imported and created will remain unchanged',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withOpacity(0.6),
                        decoration: TextDecoration.none,
                        fontFamily: '.SF Pro Text',
                        height: 1.3,
                        letterSpacing: -0.08,
                      ),
                    ),
                  ),

                  // Regenerate Missing Thumbnails button
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Handle regenerate missing thumbnails
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: const Center(
                            child: Text(
                              'Regenerate Missing Thumbnails',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                decoration: TextDecoration.none,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Restore Lessons button
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Handle restore lessons
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: const Center(
                            child: Text(
                              'Restore Lessons',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                decoration: TextDecoration.none,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Function to show the Troubleshooting popup
void showTroubleshooting(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: const Center(
        child: TroubleshootingPopup(),
      ),
    ),
  );
}