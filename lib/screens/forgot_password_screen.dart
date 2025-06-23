import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _sendPasswordReset() async {
    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Forgot Password",
          style: TextStyle(color: AppTheme.textPrimaryColor),
        ),
        backgroundColor: AppTheme.backgroundColor,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Forgot your password?",
                  style: AppTheme.headingStyle,
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 16),
                Text(
                  "Enter your email to reset your password:",
                  style: AppTheme.bodyStyle,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  decoration: AppTheme.textFieldDecoration("Email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _sendPasswordReset,
                  style: AppTheme.primaryButtonStyle,
                  child: const Text("Send Reset Email"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
