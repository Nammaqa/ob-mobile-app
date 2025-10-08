// components/document_language.dart
import 'package:flutter/material.dart';

class DocumentLanguage extends StatefulWidget {
  final VoidCallback? onClose;

  const DocumentLanguage({
    Key? key,
    this.onClose,
  }) : super(key: key);

  @override
  State<DocumentLanguage> createState() => _DocumentLanguageState();
}

class _DocumentLanguageState extends State<DocumentLanguage> {
  String selectedLanguage = 'English (UK)';

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
                      'Document Language',
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
                    // Installed Languages Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'INSTALLED LANGUAGES',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                          decoration: TextDecoration.none,
                          fontFamily: '.SF Pro Text',
                          letterSpacing: -0.08,
                        ),
                      ),
                    ),

                    // Language List Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            _buildLanguageItem('English (US)', true),
                            _buildDivider(),
                            _buildLanguageItem('English (UK)', false),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Recognition Language Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        'RECOGNITION LANGUAGE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                          decoration: TextDecoration.none,
                          fontFamily: '.SF Pro Text',
                          letterSpacing: -0.08,
                        ),
                      ),
                    ),

                    // Default Language Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () => _showLanguageSelectionDialog(context),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Default Language for New Documents',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                      decoration: TextDecoration.none,
                                      fontFamily: '.SF Pro Text',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  children: [
                                    Text(
                                      selectedLanguage,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey[500],
                                        decoration: TextDecoration.none,
                                        fontFamily: '.SF Pro Text',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Subtitle below card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text(
                        'Automatically sets the language for new documents',
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

  Widget _buildLanguageItem(String language, bool isFirst) {
    bool isSelected = selectedLanguage == language;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLanguage = language;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isFirst
              ? const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          )
              : const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.check,
                  size: 24,
                  color: Color(0xFF007AFF),
                ),
              ),
            Text(
              language,
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

  void _showLanguageSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
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
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 28,
                        color: Colors.black,
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Document Language',
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
              // Body - Language List
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'INSTALLED LANGUAGES',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                              decoration: TextDecoration.none,
                              fontFamily: '.SF Pro Text',
                              letterSpacing: -0.08,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                _buildSelectionLanguageItem(dialogContext, 'English (US)', true),
                                _buildDivider(),
                                _buildSelectionLanguageItem(dialogContext, 'English (UK)', false),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionLanguageItem(BuildContext dialogContext, String language, bool isFirst) {
    bool isSelected = selectedLanguage == language;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLanguage = language;
        });
        Navigator.of(dialogContext).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isFirst
              ? const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          )
              : const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: Text(
          language,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: Colors.black,
            decoration: TextDecoration.none,
            fontFamily: '.SF Pro Text',
          ),
        ),
      ),
    );
  }
}

// Function to show Document Language
void showDocumentLanguage(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: DocumentLanguage(
        onClose: () {
          Navigator.of(dialogContext).pop();
        },
      ),
    ),
  );
}