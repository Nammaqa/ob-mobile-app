// components/document_privacy.dart
import 'package:flutter/material.dart';

class DocumentPrivacy extends StatefulWidget {
  final VoidCallback? onClose;

  const DocumentPrivacy({
    Key? key,
    this.onClose,
  }) : super(key: key);

  @override
  State<DocumentPrivacy> createState() => _DocumentPrivacyState();
}

class _DocumentPrivacyState extends State<DocumentPrivacy> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      height: 500,
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
                      'Document Privacy',
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Setup Password Protection Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Setup Password Protection',
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
                  const SizedBox(height: 12),
                  // Description text below the card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                          decoration: TextDecoration.none,
                          fontFamily: '.SF Pro Text',
                          height: 1.1,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Lock your documents with a unique password across all devices. ',
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () {
                                print('Learn more tapped');
                              },
                              child: const Text(
                                'Learn more',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                  decoration: TextDecoration.none,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                            ),
                          ),
                        ],
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

// Function to show Document Privacy
void showDocumentPrivacy(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: DocumentPrivacy(
        onClose: () {
          Navigator.of(dialogContext).pop();
        },
      ),
    ),
  );
}