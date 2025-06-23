import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import 'submission_screen.dart';

class ReporterInfoScreen extends StatefulWidget {
  final String incidentType;
  final String description;
  final List<File> selectedImages;
  final double latitude;
  final double longitude;
  final String municipal;

  const ReporterInfoScreen({
    super.key,
    required this.incidentType,
    required this.description,
    required this.selectedImages,
    required this.latitude,
    required this.longitude,
    required this.municipal,
  });

  @override
  State<ReporterInfoScreen> createState() => _ReporterInfoScreenState();
}

class _ReporterInfoScreenState extends State<ReporterInfoScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _loadUserDataIfAvailable();
  }

  void _loadUserDataIfAvailable() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final nameParts = (user.displayName ?? "").split(" ");
      _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : "";
      _lastNameController.text =
          nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";
      _emailController.text = user.email ?? "";
      _phoneController.text = user.phoneNumber ?? "";
    }
  }

  void _onAnonymousChanged(bool? value) {
    setState(() {
      isAnonymous = value ?? false;
      if (isAnonymous) {
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _phoneController.clear();
      } else {
        _loadUserDataIfAvailable();
      }
    });
  }

  void _onNextPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SubmissionScreen(
              firstName:
                  "${_firstNameController.text} ${_lastNameController.text}"
                      .trim(),
              phoneNumber: _phoneController.text,
              email: _emailController.text,
              isAnonymous: isAnonymous,
              incidentType: widget.incidentType,
              locationInfo: "Reported via map",
              description: widget.description,
              municipal: widget.municipal,
              selectedImages: widget.selectedImages,
              latitude: widget.latitude,
              longitude: widget.longitude,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          "Reporter Information",
          style: AppTheme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppTheme.backgroundColor,
        iconTheme: AppTheme.appBarTheme.iconTheme,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Contact Information",
                        style: AppTheme.subheadingStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "This information helps municipal staff contact you about your report.",
                        style: AppTheme.captionStyle,
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        "First name",
                        _firstNameController,
                        enabled: !isAnonymous,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Last name",
                        _lastNameController,
                        enabled: !isAnonymous,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Phone Number",
                        _phoneController,
                        enabled: !isAnonymous,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Email Address",
                        _emailController,
                        enabled: !isAnonymous,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: Text(
                          "Submit Anonymously",
                          style: AppTheme.bodyStyle,
                        ),
                        subtitle: Text(
                          "Your personal information will not be visible to municipal staff",
                          style: AppTheme.captionStyle,
                        ),
                        value: isAnonymous,
                        onChanged: _onAnonymousChanged,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _onNextPressed,
                style: AppTheme.primaryButtonStyle,
                child: const Text("Next: Review & Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: AppTheme.bodyStyle,
      decoration: AppTheme.textFieldDecoration(label).copyWith(
        fillColor:
            enabled
                ? AppTheme.surfaceColor
                : AppTheme.surfaceColor.withOpacity(0.5),
        hintStyle: AppTheme.captionStyle,
      ),
    );
  }
}
