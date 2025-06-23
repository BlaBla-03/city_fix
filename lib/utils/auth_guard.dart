import 'package:flutter/material.dart';
import '../screens/login_registration_screen.dart';
import 'auth_service.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool allowAnonymous;

  const AuthGuard({Key? key, required this.child, this.allowAnonymous = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Allow anonymous users if flag is set, otherwise require logged in user
    if ((allowAnonymous && AuthService.hasAnyUser()) ||
        (!allowAnonymous && AuthService.isLoggedIn())) {
      return child;
    } else {
      // Redirect to login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginRegistrationScreen(),
          ),
        );
      });

      // Return loading screen while redirecting
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
