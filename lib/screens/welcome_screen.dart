import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import 'login_registration_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _handleGetStarted(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginRegistrationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_city,
                size: 120,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 40),
              Text(
                'CityFix',
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Report municipal issues with ease.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyStyle,
              ),
              const SizedBox(height: 16),
              Text(
                'Connect with your local government to improve your community',
                textAlign: TextAlign.center,
                style: AppTheme.captionStyle,
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                style: AppTheme.primaryButtonStyle,
                onPressed: () => _handleGetStarted(context),
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
