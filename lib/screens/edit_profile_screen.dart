import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/auth_guard.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();

  // Static method to get a protected instance of EditProfileScreen
  static Widget protected() {
    return const AuthGuard(
      allowAnonymous: false,
      child: EditProfileScreen(), // Require authenticated user
    );
  }
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phoneNumber ?? '';
      _loadUserData(user.uid);
    }
  }

  void _loadUserData(String uid) async {
    try {
      // Only load from reporter collection
      final reporterDoc =
          await FirebaseFirestore.instance
              .collection('reporter')
              .doc(uid)
              .get();
      if (reporterDoc.exists) {
        final data = reporterDoc.data();
        setState(() {
          _nameController.text = data?['name'] ?? _nameController.text;
          _phoneController.text = data?['phone'] ?? _phoneController.text;
          _addressController.text = data?['address'] ?? '';
        });
      }
    } catch (e) {
      // Handle any errors
      print('Error loading user data: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
      _showSuccess = false;
    });

    try {
      // Update display name
      if (_nameController.text != user.displayName) {
        await user.updateDisplayName(_nameController.text);
      }

      // Update email if changed
      if (_emailController.text != user.email) {
        await user.updateEmail(_emailController.text);
      }

      // Save only to reporter collection
      await FirebaseFirestore.instance
          .collection('reporter')
          .doc(user.uid)
          .set({
            'name': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'address': _addressController.text,
            'uid': user.uid,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _showSuccess = true;
          _isSaving = false;
        });

        // Hide success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showSuccess = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update failed: ${e.toString()}"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile", style: AppTheme.appBarTheme.titleTextStyle),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: AppTheme.appBarTheme.iconTheme,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: AppTheme.textFieldDecoration('Full Name'),
                    validator:
                        (value) =>
                            value != null && value.isNotEmpty
                                ? null
                                : "Name cannot be empty",
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: AppTheme.textFieldDecoration('Email'),
                    validator:
                        (value) =>
                            value != null && value.contains('@')
                                ? null
                                : "Enter a valid email",
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: AppTheme.textFieldDecoration('Phone Number'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: AppTheme.textFieldDecoration('Address'),
                  ),
                  const Spacer(),
                  if (_showSuccess)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Profile updated successfully!",
                              style: AppTheme.bodyStyle.copyWith(
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: AppTheme.textSecondaryColor.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(color: AppTheme.textPrimaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: AppTheme.primaryButtonStyle,
                          child:
                              _isSaving
                                  ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text("Save Changes"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
