import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import 'image_upload_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class LoginRegistrationScreen extends StatelessWidget {
  const LoginRegistrationScreen({super.key});

  Future<void> _signInAsGuest(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ImageUploadScreen()),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Guest login failed: $e"),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable Android back button
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Welcome to CityFix", style: AppTheme.headingStyle),
                  const SizedBox(height: 16),
                  Text(
                    "Report and track municipal issues in your community",
                    textAlign: TextAlign.center,
                    style: AppTheme.captionStyle,
                  ),
                  const SizedBox(height: 40),
                  Image.asset('assets/images/welcome_image.png', height: 180),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: AppTheme.primaryButtonStyle,
                    child: const Text("Log In"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    style: AppTheme.primaryButtonStyle.copyWith(
                      backgroundColor: WidgetStateProperty.all(
                        AppTheme.primaryColor.withOpacity(0.8),
                      ),
                    ),
                    child: const Text("Sign Up"),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => _signInAsGuest(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: BorderSide(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Continue as Guest",
                      style: TextStyle(color: AppTheme.textPrimaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
