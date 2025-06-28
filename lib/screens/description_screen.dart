import 'dart:io';
import 'package:city_fix/screens/reporter_info_screen.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DescriptionScreen extends StatefulWidget {
  final String incidentType;
  final List<File> selectedImages;
  final double latitude;
  final double longitude;
  final String municipal;

  const DescriptionScreen({
    super.key,
    required this.incidentType,
    required this.selectedImages,
    required this.latitude,
    required this.longitude,
    required this.municipal,
  });

  @override
  _DescriptionScreenState createState() => _DescriptionScreenState();
}

class _DescriptionScreenState extends State<DescriptionScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  bool isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(() {
      setState(() {
        isButtonEnabled = _descriptionController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ReporterInfoScreen(
              incidentType: widget.incidentType,
              description: _descriptionController.text.trim(),
              selectedImages: widget.selectedImages,
              latitude: widget.latitude,
              longitude: widget.longitude,
              municipal: widget.municipal,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          "Describe the Issue",
          style: AppTheme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppTheme.backgroundColor,
        iconTheme: AppTheme.appBarTheme.iconTheme,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Please provide details about the ${widget.incidentType}",
              style: AppTheme.bodyStyle,
            ),
            const SizedBox(height: 8),
            Text(
              "Include any relevant information that would help municipal staff understand and address the issue.",
              style: AppTheme.captionStyle,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: TextField(
                controller: _descriptionController,
                maxLines: 7,
                style: AppTheme.bodyStyle,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Describe the issue in detail...",
                  hintStyle: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
            ),
            const Spacer(),
            SafeArea(
              child: ElevatedButton(
                onPressed: isButtonEnabled ? _onNext : null,
                style:
                    isButtonEnabled
                        ? AppTheme.primaryButtonStyle
                        : AppTheme.primaryButtonStyle.copyWith(
                          backgroundColor: WidgetStateProperty.all(
                            AppTheme.textSecondaryColor.withOpacity(0.3),
                          ),
                        ),
                child: const Text("Next: Your Information"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
