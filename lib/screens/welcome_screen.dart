import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:organize/screens/login_screen.dart';
import 'package:organize/screens/signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // Large circle - top left (partially visible)
            Positioned(
              left: 260,
              top:40,
              child: Container(
                width: 250,
                height: 250,
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

            // Medium circle - top right
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

            // Small circle - middle right
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
              right: 330,
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

            // Large circle - bottom right
            Positioned(
              right: 240,
              bottom: -20,
              child: Container(
                width: 250,
                height: 250,
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

            // Small circle - bottom left
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

            // Medium circle - left middle
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
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480), // Reduced maxWidth from 480 to 400
                      padding: const EdgeInsets.all(24), // Reduced padding from 32 to 24
                      decoration: BoxDecoration(
                        color: Color(0xB8F2F2F2),

                        borderRadius: BorderRadius.circular(20), // Slightly smaller border radius
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30, // Reduced blur radius
                            offset: const Offset(0, 6), // Reduced offset
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo - Welcome logo image
                          Container(
                            width: 64, // Reduced from 80
                            height: 64, // Reduced from 80
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12), // Reduced from 16
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8, // Reduced from 10
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12), // Reduced from 16
                              child: Image.asset(
                                'assets/images/Welcome_logo.png',
                                width: 64, // Reduced from 80
                                height: 64, // Reduced from 80
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: CustomPaint(
                                      painter: WavyMPainter(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16), // Reduced from 20

                          // Title
                          const Text(
                            'Welcome',
                            style: TextStyle(
                              fontSize: 24, // Reduced from 28
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4), // Reduced from 6

                          // Subtitle
                          const Text(
                            'Here you log in securely',
                            style: TextStyle(
                              fontSize: 14, // Reduced from 15
                              color: Color(0xFF666666),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24), // Reduced from 32

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _showLoginDialog(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1A1A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12), // Reduced from 16
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10), // Reduced from 12
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 15, // Reduced from 16
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8), // Reduced from 12

                          // Sign Up button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _showSignUpDialog(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1A1A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12), // Reduced from 16
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10), // Reduced from 12
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 15, // Reduced from 16
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16), // Reduced from 24

                          // OR divider
                          const Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Color(0xFFE0E0E0),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12), // Reduced from 16
                                child: Text(
                                  'or',
                                  style: TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 13, // Reduced from 14
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Color(0xFFE0E0E0),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // Reduced from 24

                          // Social login buttons
                          _buildSocialButton(
                            icon: Icons.apple,
                            text: 'Continue with Apple',
                            onPressed: () {},
                          ),
                          const SizedBox(height: 8), // Reduced from 12
                          _buildSocialButton(
                            iconWidget: Container(
                              width: 18, // Reduced from 20
                              height: 18, // Reduced from 20
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                              ),
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 14, // Reduced from 16
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4285F4),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            text: 'Continue with Google',
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/HomeScreen');
                            },
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthOptionButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(
            color: Color(0xFFE8E8E8),
            width: 1,
          ),
          backgroundColor: const Color(0xFFFAFAFA),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF666666),
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSSODialog(BuildContext context) {
    final TextEditingController domainController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Single Sign-On (SSO)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your organization domain to continue with SSO.',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: domainController,
              decoration: const InputDecoration(
                hintText: 'company.com',
                labelText: 'Organization Domain',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.domain),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle SSO login logic here
              Navigator.pop(context);
              _showErrorSnackBar(context, 'SSO login functionality not implemented yet');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showMFADialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Multi-Factor Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                hintText: 'Authentication Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle MFA login logic here
              Navigator.pop(context);
              _showErrorSnackBar(context, 'MFA login functionality not implemented yet');
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _showSignUpDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  void _showEmailLoginDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Continue with Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _handleEmailLogin(context, emailController.text, passwordController.text);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context, String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar(context, 'Please fill in all fields');
      return;
    }

    try {
      _showLoadingDialog(context);
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      Navigator.of(context).pop(); // Close loading
      Navigator.of(context).pop(); // Close dialog
      Navigator.pushReplacementNamed(context, '/homepage');
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // Close loading
      Navigator.of(context).pop(); // Close dialog
      _handleFirebaseError(context, e);
    }
  }

  Future<void> _handleSignUp(BuildContext context, String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar(context, 'Please fill in all fields');
      return;
    }

    try {
      _showLoadingDialog(context);
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      Navigator.of(context).pop(); // Close loading
      Navigator.of(context).pop(); // Close dialog
      Navigator.pushReplacementNamed(context, '/homepage');
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // Close loading
      Navigator.of(context).pop(); // Close dialog
      _handleFirebaseError(context, e);
    }
  }

  Future<void> _handleEmailLogin(BuildContext context, String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar(context, 'Please fill in all fields');
      return;
    }

    try {
      _showLoadingDialog(context);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
        } else {
          throw e;
        }
      }
      Navigator.of(context).pop(); // Close loading
      Navigator.of(context).pop(); // Close dialog
      Navigator.pushReplacementNamed(context, '/homepage');
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // Close loading
      Navigator.of(context).pop(); // Close dialog
      _handleFirebaseError(context, e);
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleFirebaseError(BuildContext context, FirebaseAuthException e) {
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
      case 'user-not-found':
        errorMessage = 'No user found for that email.';
        break;
      default:
        errorMessage = 'An error occurred: ${e.message}';
    }
    _showErrorSnackBar(context, errorMessage);
  }
}

class WavyMPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Create wavy M shape
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final width = size.width * 0.7;
    final height = size.height * 0.5;

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