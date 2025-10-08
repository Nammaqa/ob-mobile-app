// components/settings_popup.dart
import 'package:flutter/material.dart';
import 'package:organize/components/document_editing.dart';
import 'document_privacy.dart';
import 'document_language.dart';
import 'handwriting_recognition.dart';
import 'writing_aids.dart';
import 'notification_preference.dart';
import 'feedback_survey.dart';
import 'trouble_shooting.dart';

class SettingsPopup extends StatelessWidget {
  final VoidCallback? onClose;

  const SettingsPopup({
    Key? key,
    this.onClose,
  }) : super(key: key);

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
          // Header with title and close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
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

          // Settings items
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // First group
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          title: 'Document Editing',
                          onTap: () {
                            showDocumentEditing(context);
                          },
                          isFirst: true,
                        ),
                        _buildSettingsItem(
                          title: 'Document Privacy',
                          onTap: () {
                            showDocumentPrivacy(context);
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  // Second group
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          title: 'Document Language',
                          onTap: () {
                            showDocumentLanguage(context);
                          },
                          isFirst: true,
                        ),
                        _buildSettingsItem(
                          title: 'Handwriting Recognition',
                          onTap: () {
                            // Handle handwriting recognition
                            showHandwritingRecognition(context);
                          },
                        ),
                        _buildSettingsItem(
                          title: 'Writing Aids',
                          onTap: () {
                            // Handle writing aids
                            showWritingAids(context);
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  // Third group
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          title: 'Notification Preferences',
                          onTap: () {
                            // Handle notification preferences
                            showNotificationPreference(context);
                          },
                          isFirst: true,
                        ),
                        _buildSettingsItem(
                          title: 'Feedback & Surveys',
                          onTap: () {
                            // Handle feedback & surveys
                            showFeedbackSurveys(context);
                          },
                        ),
                        _buildSettingsItem(
                          title: 'Troubleshooting',
                          onTap: () {
                            // Handle troubleshooting
                            showTroubleshooting(context);
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required String title,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isLast ? Colors.transparent : const Color(0xFFE5E5EA),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
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
                color: const Color(0xFFC7C7CC),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Usage example - how to show the popup
// You can show it as a dialog in the center of the screen:
void showSettingsPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Center(
        child: SettingsPopup(
          onClose: () {
            Navigator.of(dialogContext).pop();
          },
        ),
      ),
    ),
  );
}