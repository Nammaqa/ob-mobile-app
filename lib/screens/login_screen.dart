import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Stack(
        children: [
          // Background circles - positioned to match design
          Positioned(
            top: -120,
            right: -120,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/Ellipse.png',
                width: 280,
                height: 280,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: -20,
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/Ellipse.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/images/Ellipse.png',
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Opacity(
              opacity: 0.18,
              child: Image.asset(
                'assets/images/Ellipse.png',
                width: 220,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            left: -30,
            top: 200,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/images/Ellipse.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
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
                        // Logo - wavy M design
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: CustomPaint(
                            painter: WavyMPainter(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        const Text(
                          'Log in or sign up',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        const Text(
                          'Enter your email to sign up for this app',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Email input field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1A1A1A),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'email@domain.com',
                              hintStyle: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Password input field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1A1A1A),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Basic validation
                              if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill in all fields'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              try {
                                // Show loading
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                // Try to sign in first
                                try {
                                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                  );
                                } on FirebaseAuthException catch (e) {
                                  if (e.code == 'user-not-found') {
                                    // User doesn't exist, create account
                                    await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text,
                                    );
                                  } else {
                                    throw e;
                                  }
                                }

                                // Hide loading
                                Navigator.of(context).pop();

                                // Navigate to homepage
                                Navigator.pushReplacementNamed(context, '/homepage');

                              } on FirebaseAuthException catch (e) {
                                // Hide loading
                                Navigator.of(context).pop();

                                String errorMessage;
                                switch (e.code) {
                                  case 'weak-password':
                                    errorMessage = 'The password provided is too weak.';
                                    break;
                                  case 'email-already-in-use':
                                    errorMessage = 'The account already exists for that email.';
                                    break;
                                  case 'wrong-password':
                                    errorMessage = 'Wrong password provided.';
                                    break;
                                  case 'invalid-email':
                                    errorMessage = 'The email address is not valid.';
                                    break;
                                  case 'invalid-credential':
                                    errorMessage = 'Invalid email or password.';
                                    break;
                                  default:
                                    errorMessage = 'An error occurred: ${e.message}';
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } catch (e) {
                                // Hide loading
                                Navigator.of(context).pop();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('An unexpected error occurred: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A1A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // OR divider
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(0xFFE0E0E0),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(0xFFE0E0E0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Social login buttons (removed email option)
                        _buildSocialButton(
                          icon: Icons.apple,
                          text: 'Continue with Apple',
                          onPressed: () {},
                        ),
                        const SizedBox(height: 10),
                        _buildSocialButton(
                          iconWidget: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4285F4),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          text: 'Continue with Google',
                          onPressed: () {},
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
    );
  }

  Widget _buildSocialButton({
    IconData? icon,
    Widget? iconWidget,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget ?? Icon(
              icon,
              color: const Color(0xFF1A1A1A),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WavyMPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Create wavy M shape
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final width = size.width * 0.6;
    final height = size.height * 0.4;

    // Start point (left)
    path.moveTo(centerX - width/2, centerY + height/2);

    // First curve up
    path.quadraticBezierTo(
        centerX - width/4, centerY - height/2,
        centerX, centerY
    );

    // Second curve up
    path.quadraticBezierTo(
        centerX + width/4, centerY - height/2,
        centerX + width/2, centerY + height/2
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}