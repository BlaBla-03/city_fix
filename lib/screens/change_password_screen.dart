import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/auth_guard.dart';
import '../theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();

  // Static method to get a protected instance of ChangePasswordScreen
  static Widget protected() {
    return const AuthGuard(
      child: ChangePasswordScreen(),
      allowAnonymous: false, // Require authenticated user
    );
  }
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPass = TextEditingController();
  final TextEditingController _newPass = TextEditingController();
  final TextEditingController _confirmPass = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Live password validation state
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    _newPass.addListener(_validatePassword);
  }

  void _validatePassword() {
    final password = _newPass.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    });
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    setState(() => _isLoading = true);

    try {
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPass.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPass.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully")),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message = "Something went wrong.";
      if (e.code == 'wrong-password') {
        message = "Current password is incorrect.";
      } else {
        message = e.message ?? message;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentPass.dispose();
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Change Password",
          style: AppTheme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: AppTheme.appBarTheme.iconTheme,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 40),
              TextFormField(
                controller: _currentPass,
                obscureText: _obscureCurrent,
                decoration: AppTheme.textFieldDecoration(
                  'Current Password',
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrent = !_obscureCurrent;
                      });
                    },
                  ),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Enter current password'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPass,
                obscureText: _obscureNew,
                decoration: AppTheme.textFieldDecoration(
                  'New Password',
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNew = !_obscureNew;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (!_hasMinLength ||
                      !_hasUppercase ||
                      !_hasLowercase ||
                      !_hasNumber ||
                      !_hasSpecial) {
                    return 'Password does not meet all requirements.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _buildPasswordRequirements(),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPass,
                obscureText: _obscureConfirm,
                decoration: AppTheme.textFieldDecoration(
                  'Confirm New Password',
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
                validator:
                    (value) =>
                        value == _newPass.text
                            ? null
                            : 'Passwords do not match',
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: AppTheme.primaryButtonStyle,
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text("Save Changes"),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
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
