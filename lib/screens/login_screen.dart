import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  String emailInput = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo/Header Section
                _buildHeaderSection(),

                const SizedBox(height: 40),

                // Login Form Section
                _buildLoginForm(),

                const SizedBox(height: 30),

                // Social Login Section
                _buildSocialLoginSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        // App Logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[100],
          ),
          child: const Icon(
            Icons.login,
            size: 60,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 20),

        // Title
        const Text(
          "Login",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        const Text(
          "Enter your email to sign up for this app",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Email Input Field
          _buildEmailField(),

          const SizedBox(height: 20),

          // Continue Button
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: TextField(
        controller: _emailController,
        onChanged: (value) {
          setState(() {
            emailInput = value;
          });
        },
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: "email@domain.com",
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (emailInput.isNotEmpty) {
            print('Continue with email: $emailInput');
            // Add your login logic here
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text(
          "Continue",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        // Divider with "or" text
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: Colors.grey[300],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "or",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.grey[300],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Social Login Buttons
        _buildSocialButton(
          icon: Icons.email_outlined,
          text: "Continue with email",
          onPressed: () {
            print('Continue with email pressed');
          },
        ),

        const SizedBox(height: 12),

        _buildSocialButton(
          icon: Icons.apple,
          text: "Continue with Apple",
          onPressed: () {
            print('Continue with Apple pressed');
          },
        ),

        const SizedBox(height: 12),

        _buildSocialButton(
          icon: Icons.g_mobiledata,
          text: "Continue with Google",
          onPressed: () {
            print('Continue with Google pressed');
          },
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
          color: Colors.black87,
        ),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}