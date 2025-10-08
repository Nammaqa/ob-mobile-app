// components/feedback_surveys.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class FeedbackSurveysPopup extends StatefulWidget {
  const FeedbackSurveysPopup({Key? key}) : super(key: key);

  @override
  State<FeedbackSurveysPopup> createState() => _FeedbackSurveysPopupState();
}

class _FeedbackSurveysPopupState extends State<FeedbackSurveysPopup> {
  bool enableInAppSurvey = true;

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
                  'Feedback & Surveys',
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
                  // IN-APP SURVEYS section
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 12, bottom: 6),
                    child: Text(
                      'IN-APP SURVEYS',
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

                  // Enable In-App Survey toggle
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
                            enableInAppSurvey = !enableInAppSurvey;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Enable In-App Survey',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                  decoration: TextDecoration.none,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                              CupertinoSwitch(
                                value: enableInAppSurvey,
                                onChanged: (value) {
                                  setState(() {
                                    enableInAppSurvey = value;
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
                      'Participate in user surveys to improve the usability and user experience of the service.',
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

                  // Additional description text
                  Padding(
                    padding: const EdgeInsets.only(left: 28, right: 28, top: 4, bottom: 20),
                    child: Text(
                      'I think surveys were filled when I participated by participating in app user surveys, you may earn on our rating. Inaccurate or anomalous data may be removed.',
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

// Function to show the Feedback & Surveys popup
void showFeedbackSurveys(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: const Center(
        child: FeedbackSurveysPopup(),
      ),
    ),
  );
}