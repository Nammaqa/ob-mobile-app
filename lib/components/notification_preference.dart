// components/notification_preference.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class NotificationPreferencePopup extends StatefulWidget {
  const NotificationPreferencePopup({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencePopup> createState() => _NotificationPreferencePopupState();
}

class _NotificationPreferencePopupState extends State<NotificationPreferencePopup> {
  bool personalizePromotionMessages = false;

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
                  'Notification Preference',
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
                  // EMAIL section
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 12, bottom: 6),
                    child: Text(
                      'EMAIL',
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

                  // Personalize Promotion Messages toggle
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
                            personalizePromotionMessages = !personalizePromotionMessages;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Personalize Promotion Massages(or Contents)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                    decoration: TextDecoration.none,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              CupertinoSwitch(
                                value: personalizePromotionMessages,
                                onChanged: (value) {
                                  setState(() {
                                    personalizePromotionMessages = value;
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

                  // Footer text below the card
                  Padding(
                    padding: const EdgeInsets.only(left: 28, right: 28, top: 8, bottom: 20),
                    child: Text(
                      'By enabling notifications, you can be the first to receive local promotional offers, new features, and educational recommendations.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withOpacity(0.6),
                        decoration: TextDecoration.none,
                        fontFamily: '.SF Pro Text',
                        height: 1.3,
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

// Function to show the Notification Preference popup
void showNotificationPreference(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: const Center(
        child: NotificationPreferencePopup(),
      ),
    ),
  );
}