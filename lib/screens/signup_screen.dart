import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Live password validation state
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_validatePassword);
    confirmPasswordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final password = passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      _passwordsMatch =
          password == confirmPasswordController.text && password.isNotEmpty;
    });
  }

  bool _isPasswordValid(String password) {
    // Password must be at least 8 characters long
    // and contain at least one uppercase letter, one lowercase letter,
    // one number, and one special character
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  Future<void> signUp() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (!_isPasswordValid(passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Password must be at least 8 characters long and contain uppercase, lowercase, number, and special character',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      // Update the user's display name
      await userCredential.user?.updateDisplayName(nameController.text.trim());

      // Try to create user profile in Firestore
      try {
        await FirebaseFirestore.instance
            .collection('reporter')
            .doc(userCredential.user!.uid)
            .set({
              'name': nameController.text.trim(),
              'email': emailController.text.trim(),
              'phone': phoneController.text.trim(),
              'address': '',
              'uid': userCredential.user!.uid,
              'createdAt': FieldValue.serverTimestamp(),
              'role': 'user',
            });
        await userCredential.user?.sendEmailVerification();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Verification email sent. Please verify your email before logging in.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } catch (firestoreError) {
        // If Firestore write fails, delete the Auth user
        await userCredential.user!.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not complete signup. Please try again.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // Try to create/update user profile in Firestore
      try {
        await FirebaseFirestore.instance
            .collection('reporter')
            .doc(userCredential.user!.uid)
            .set({
              'name': userCredential.user?.displayName ?? '',
              'email': userCredential.user?.email ?? '',
              'phone': userCredential.user?.phoneNumber ?? '',
              'address': '',
              'uid': userCredential.user!.uid,
              'createdAt': FieldValue.serverTimestamp(),
              'role': 'user',
            }, SetOptions(merge: true));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In Successful'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } catch (firestoreError) {
        // If Firestore write fails, delete the Auth user
        await userCredential.user!.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not complete signup. Please try again.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In Failed: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ListView(
              children: [
                const SizedBox(height: 40),
                Text(
                  'Create Account',
                  style: AppTheme.headingStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign up to report municipal issues',
                  style: AppTheme.captionStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: nameController,
                  decoration: AppTheme.textFieldDecoration('Full Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: AppTheme.textFieldDecoration('Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: AppTheme.textFieldDecoration(
                    'Phone Number (Optional)',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: AppTheme.textFieldDecoration('Password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppTheme.textSecondaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildPasswordRequirements(),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: AppTheme.textFieldDecoration(
                    'Confirm Password',
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppTheme.textSecondaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildPasswordMatchRequirement(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading || !_allPasswordValid() ? null : signUp,
                  style: AppTheme.primaryButtonStyle,
                  child: const Text('Sign Up'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppTheme.textSecondaryColor.withOpacity(0.5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("OR", style: AppTheme.captionStyle),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppTheme.textSecondaryColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : signInWithGoogle,
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 24,
                  ),
                  label: Text(
                    'Sign up with Google',
                    style: TextStyle(color: AppTheme.textPrimaryColor),
                  ),
                  style: AppTheme.secondaryButtonStyle.copyWith(
                    side: MaterialStateProperty.all(
                      BorderSide(
                        color: AppTheme.textSecondaryColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: AppTheme.captionStyle,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all(
                          AppTheme.primaryColor,
                        ),
                        overlayColor: MaterialStateProperty.all(
                          Colors.transparent,
                        ),
                      ),
                      child: const Text('Log In'),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  bool _allPasswordValid() {
    return _hasMinLength &&
        _hasUppercase &&
        _hasLowercase &&
        _hasNumber &&
        _hasSpecial &&
        _passwordsMatch;
  }

  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirementRow(_hasMinLength, 'At least 8 characters'),
        _buildRequirementRow(_hasUppercase, 'Contains uppercase letter'),
        _buildRequirementRow(_hasLowercase, 'Contains lowercase letter'),
        _buildRequirementRow(_hasNumber, 'Contains number'),
        _buildRequirementRow(_hasSpecial, 'Contains special character'),
      ],
    );
  }

  Widget _buildPasswordMatchRequirement() {
    return Row(
      children: [
        Icon(
          _passwordsMatch ? Icons.check_circle : Icons.radio_button_unchecked,
          color: _passwordsMatch ? Colors.green : AppTheme.textSecondaryColor,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          _passwordsMatch ? 'Passwords match' : 'Passwords do not match',
          style: AppTheme.captionStyle.copyWith(
            color: _passwordsMatch ? Colors.green : AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementRow(bool met, String text) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          color: met ? Colors.green : AppTheme.textSecondaryColor,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTheme.captionStyle.copyWith(
            color: met ? Colors.green : AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
