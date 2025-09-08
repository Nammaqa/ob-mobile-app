import 'package:flutter/material.dart';
import 'package:organize/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: Color(0xFFFFFFFF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: Color(0xFFFFFFFF),
                  width: double.infinity,
                  height: double.infinity,
                  child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IntrinsicHeight(
                            child: Container(
                              margin: const EdgeInsets.only(
                                  top: 35, bottom: 35, left: 41, right: 41),
                              width: double.infinity,
                              child: Row(
                                  children: [
                                    Container(
                                        margin: const EdgeInsets.only(right: 10),
                                        width: 630,
                                        height: 680,
                                        child: Image.asset(
                                          "assets/images/ipad.png",
                                          fit: BoxFit.fill,
                                        )
                                    ),
                                    Expanded(
                                      child: IntrinsicHeight(
                                        child: Container(
                                          width: double.infinity,
                                          child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.only(bottom: 200),
                                                  child: Text(
                                                    "Write It Track It Live It",
                                                    style: TextStyle(
                                                      color: Color(0xFF000000),
                                                      fontSize: 24,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                    margin: const EdgeInsets.only(
                                                        top: 40,
                                                        bottom: 150, left: 55, right: 55),
                                                    height: 113,
                                                    width: double.infinity,
                                                    child: Image.asset(
                                                      "assets/images/organize_splash.png",
                                                      fit: BoxFit.fill,
                                                    )
                                                ),
                                                IntrinsicHeight(
                                                  child: Container(
                                                    width: double.infinity,
                                                    child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                          IntrinsicHeight(
                                                            child: GestureDetector(
                                                              onTap: () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(builder: (context) => const LoginPage()),
                                                                );
                                                              },
                                                              child: Container(
                                                                decoration: BoxDecoration(
                                                                  border: Border.all(
                                                                    color: Color(0x00000000),
                                                                    width: 1,
                                                                  ),
                                                                  borderRadius: BorderRadius.circular(10),
                                                                  color: Color(0x00000000),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Color(0x40000000),
                                                                      blurRadius: 4,
                                                                      offset: Offset(0, 4),
                                                                    ),
                                                                  ],
                                                                ),
                                                                padding: const EdgeInsets.symmetric(vertical: 9),
                                                                width: 105,
                                                                child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Container(
                                                                        margin: const EdgeInsets.symmetric(horizontal: 32),
                                                                        width: double.infinity,
                                                                        child: Text(
                                                                          "NEXT",
                                                                          style: TextStyle(
                                                                            color: Color(0xFF000000),
                                                                            fontSize: 15,
                                                                            fontWeight: FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ]
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ]
                                                    ),
                                                  ),
                                                ),
                                              ]
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]
                              ),
                            ),
                          ),
                        ],
                      )
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}