// components/writing_aids.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class WritingAidsPopup extends StatefulWidget {
  const WritingAidsPopup({Key? key}) : super(key: key);

  @override
  State<WritingAidsPopup> createState() => _WritingAidsPopupState();
}

class _WritingAidsPopupState extends State<WritingAidsPopup> {
  bool languageDirection = true;

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
          // Header with back button and title
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
                const Expanded(
                  child: Center(
                    child: Text(
                      'Writing Aids',
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
                const SizedBox(width: 28), // Balance the back button
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SPELLCHECK section
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 12, bottom: 6),
                    child: Text(
                      'SPELLCHECK',
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

                  // Language Direction toggle
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
                          setState(() {
                            languageDirection = !languageDirection;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Language Direction',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                  decoration: TextDecoration.none,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                              CupertinoSwitch(
                                value: languageDirection,
                                onChanged: (value) {
                                  setState(() {
                                    languageDirection = value;
                                  });
                                },
                                activeColor: const Color(0xFF000000),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // PERSONAL DIRECTION section
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 20, bottom: 6),
                    child: Text(
                      'PERSONAL DIRECTION',
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

                  // Custom words option
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
                          // Handle custom words navigation
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Custom words',
                                style: TextStyle(
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
                                color: Color(0xFFC7C7CC),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Footer text
                  Padding(
                    padding: const EdgeInsets.only(left: 28, right: 28, top: 8, bottom: 20),
                    child: Text(
                      'Handwrite or point to alternative',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Function to show the Writing Aids popup
void showWritingAids(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: const Center(
        child: WritingAidsPopup(),
      ),
    ),
  );
}