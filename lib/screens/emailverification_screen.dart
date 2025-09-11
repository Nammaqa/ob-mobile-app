import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:organize/screens/newpassword_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _isLoading = false;
  int _remainingTime = 90; // 1:30 minutes
  late String _displayTime;

  @override
  void initState() {
    super.initState();
    _updateDisplayTime();
    _startCountdown();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _remainingTime > 0) {
        setState(() {
          _remainingTime--;
          _updateDisplayTime();
        });
        _startCountdown();
      }
    });
  }

  void _updateDisplayTime() {
    int minutes = _remainingTime ~/ 60;
    int seconds = _remainingTime % 60;
    _displayTime = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background circles (matching your design)
          Positioned(
            left: 260,
            top: -10,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF545454),
                    const Color(0xFF999999),
                    const Color(0xFFFFFFFF),
                  ],
                  stops: const [0.0, 0.0001, 0.0002, 0.976],
                ),
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: -20,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF545454),
                    const Color(0xFF999999),
                    const Color(0xFFFFFFFF),
                  ],
                  stops: const [0.0, 0.0001, 0.0002, 0.976],
                ),
              ),
            ),
          ),
          Positioned(
            right: 200,
            top: 350,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF545454),
                    const Color(0xFF999999),
                    const Color(0xFFFFFFFF),
                  ],
                  stops: const [0.0, 0.0001, 0.0002, 0.976],
                ),
              ),
            ),
          ),
          Positioned(
            right: 400,
            top: 200,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF545454),
                    const Color(0xFF999999),
                    const Color(0xFFFFFFFF),
                  ],
                  stops: const [0.0, 0.0001, 0.0002, 0.976],
                ),
              ),
            ),
          ),
          Positioned(
            right: 190,
            bottom: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF545454),
                    const Color(0xFF999999),
                    const Color(0xFFFFFFFF),
                  ],
                  stops: const [0.0, 0.0001, 0.0002, 0.976],
                ),
              ),
            ),
          ),
          Positioned(
            left: 260,
            bottom: 330,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF545454),
                    const Color(0xFF999999),
                    const Color(0xFFFFFFFF),
                  ],
                  stops: const [0.0, 0.0001, 0.0002, 0.976],
                ),
              ),
            ),
          ),
          Positioned(
            left: 280,
            bottom: 130,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF545454),
                    const Color(0xFF999999),
                    const Color(0xFFFFFFFF),
                  ],
                  stops: const [0.0, 0.0001, 0.0002, 0.976],
                ),
              ),
            ),
          ),
          Positioned(
            left: -60,
            bottom: 10,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF545454),
                    const Color(0xFF999999),
                    const Color(0xFFFFFFFF),
                  ],
                  stops: const [0.0, 0.0001, 0.0002, 0.976],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // App bar with back button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFF1A1A1A),
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                          decoration: BoxDecoration(
                            color: const Color(0xB8F2F2F2),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title
                              const Text(
                                'Verify email address',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Subtitle with email
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                    height: 1.5,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Verification code sent to '),
                                    TextSpan(
                                      text: widget.email,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),

                              // OTP Input Fields
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(4, (index) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    child: TextFormField(
                                      controller: _controllers[index],
                                      focusNode: _focusNodes[index],
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(1),
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0),
                                            width: 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0),
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF1A1A1A),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.all(16),
                                      ),
                                      onChanged: (value) {
                                        if (value.isNotEmpty && index < 3) {
                                          _focusNodes[index + 1].requestFocus();
                                        } else if (value.isEmpty && index > 0) {
                                          _focusNodes[index - 1].requestFocus();
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 40),

                              // Confirm Code button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleConfirmCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A1A1A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Text(
                                    'Confirm Code',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Timer and resend option
                              Text(
                                _displayTime,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _remainingTime == 0 ? _handleResendCode : null,
                                child: Text(
                                  'Resend confirmation code',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _remainingTime == 0
                                        ? const Color(0xFF1A1A1A)
                                        : const Color(0xFF999999),
                                    fontWeight: FontWeight.w500,
                                    decoration: _remainingTime == 0
                                        ? TextDecoration.underline
                                        : TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirmCode() async {
    // Get the complete code from all input fields
    String code = _controllers.map((controller) => controller.text).join();

    if (code.length != 4) {
      _showSnackBar('Please enter the complete verification code', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call (bypassing actual verification for random OTP)
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Navigate to NewPasswordScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewPasswordScreen(email: widget.email),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('An error occurred. Please try again.', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResendCode() async {
    setState(() {
      _remainingTime = 90; // Reset timer
      _updateDisplayTime();
    });
    _startCountdown();

    // Clear all input fields
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();

    try {
      // Simulate resend logic
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        _showSnackBar('Verification code sent successfully!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to resend code. Please try again.', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}