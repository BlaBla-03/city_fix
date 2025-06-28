import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../utils/auth_guard.dart';
import '../utils/auth_service.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();

  // Static method to get a protected instance of UserSettingsScreen
  static Widget protected() {
    return const AuthGuard(
      allowAnonymous: false,
      child: UserSettingsScreen(), // Require authenticated (non-anonymous) user
    );
  }
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  String _address = "Not saved";
  String _phone = "Not provided";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Only load from reporter collection
      final reporterDoc =
          await FirebaseFirestore.instance
              .collection('reporter')
              .doc(user.uid)
              .get();

      if (reporterDoc.exists) {
        final data = reporterDoc.data();
        setState(() {
          _phone = data?['phone'] ?? _phone;
          _address = data?['address'] ?? _address;
          _isLoading = false;
        });
      } else {
        // Create an empty document in the reporter collection for this user
        await FirebaseFirestore.instance
            .collection('reporter')
            .doc(user.uid)
            .set({
              'name': user.displayName ?? '',
              'email': user.email ?? '',
              'phone': '',
              'address': '',
              'uid': user.uid,
              'createdAt': FieldValue.serverTimestamp(),
            });

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logoutAndClearSession(BuildContext context) async {
    await AuthService.signOut(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGoogleUser =
        user?.providerData.any(
          (provider) => provider.providerId == 'google.com',
        ) ??
        false;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Profile", style: AppTheme.appBarTheme.titleTextStyle),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: AppTheme.appBarTheme.iconTheme,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
              : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        "assets/images/profile_placeholder.png",
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? "Unknown User",
                      style: AppTheme.headingStyle,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email: ${user?.email ?? "-"}',
                            style: AppTheme.bodyStyle,
                          ),
                          const SizedBox(height: 8),
                          Text('Phone: $_phone', style: AppTheme.bodyStyle),
                          const SizedBox(height: 8),
                          Text("Address: $_address", style: AppTheme.bodyStyle),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen.protected(),
                            ),
                          ).then((_) => _loadUserData()),
                      style: AppTheme.primaryButtonStyle,
                      child: const Text("Edit Profile"),
                    ),
                    const SizedBox(height: 16),
                    if (!isGoogleUser)
                      ElevatedButton(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ChangePasswordScreen.protected(),
                              ),
                            ),
                        style: AppTheme.primaryButtonStyle.copyWith(
                          backgroundColor: WidgetStateProperty.all(
                            AppTheme.primaryColor.withOpacity(0.8),
                          ),
                        ),
                        child: const Text("Change Password"),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _logoutAndClearSession(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              ),
    );
  }
}
