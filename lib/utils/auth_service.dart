import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/login_registration_screen.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user is logged in (not anonymous)
  static bool isLoggedIn() {
    final user = _auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  // Check if there is any user (including anonymous)
  static bool hasAnyUser() {
    return _auth.currentUser != null;
  }

  // Sign out and clear preferences
  static Future<void> signOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', false);
    await _auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginRegistrationScreen()),
        (route) => false,
      );
    }
  }
}
