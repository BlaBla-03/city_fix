import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';
import 'submission_success_screen.dart';

class SubmissionScreen extends StatefulWidget {
  final String? firstName;
  final String? phoneNumber;
  final String? email;
  final bool isAnonymous;

  final String incidentType;
  final String locationInfo;
  final String description;
  final String municipal;
  final List<File> selectedImages;

  final double latitude;
  final double longitude;

  const SubmissionScreen({
    super.key,
    this.firstName,
    this.phoneNumber,
    this.email,
    required this.isAnonymous,
    required this.incidentType,
    required this.locationInfo,
    required this.description,
    required this.municipal,
    required this.selectedImages,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  String _address = '';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  void _fetchAddress() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.latitude,
        widget.longitude,
      );
      Placemark place = placemarks.first;
      setState(() {
        _address =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      });
    } catch (e) {
      setState(() {
        _address = "Unable to fetch address";
      });
    }
  }

  // Helper method to check if a file is a video
  bool _isVideoFile(File file) {
    final ext = path.extension(file.path).toLowerCase();
    return ext == '.mp4' ||
        ext == '.mov' ||
        ext == '.avi' ||
        ext == '.wmv' ||
        ext == '.3gp' ||
        ext == '.webm' ||
        ext == '.mkv';
  }

  Future<List<String>> _uploadMedia(List<File> files) async {
    List<String> urls = [];

    for (var file in files) {
      if (_isVideoFile(file)) {
        // Upload video file directly
        final filename = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = FirebaseStorage.instance.ref().child(
          'report_videos/$filename${path.extension(file.path)}',
        );
        final uploadTask = await ref.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        urls.add(downloadUrl);
      } else {
        // Compress and upload image
        final targetPath = '${file.path}_compressed.jpg';

        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 75,
        );

        if (compressedFile != null) {
          final filename = DateTime.now().millisecondsSinceEpoch.toString();
          final ref = FirebaseStorage.instance.ref().child(
            'report_images/$filename.jpg',
          );
          final uploadTask = await ref.putFile(File(compressedFile.path));
          final downloadUrl = await uploadTask.ref.getDownloadURL();
          urls.add(downloadUrl);
        }
      }
    }

    return urls;
  }

  void _submitReport(BuildContext context) async {
    setState(() => _isUploading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      final uploadedMediaUrls = await _uploadMedia(widget.selectedImages);

      final reportData = {
        'incidentType': widget.incidentType,
        'locationInfo': _address,
        'description': widget.description,
        'municipal': widget.municipal,
        'timestamp': Timestamp.now(),
        'uid': user?.uid,
        'isAnonymous': widget.isAnonymous,
        'reporterName':
            widget.isAnonymous ? 'Anonymous' : widget.firstName?.trim(),
        'reporterPhone':
            widget.isAnonymous ? 'Not provided' : widget.phoneNumber,
        'reporterEmail': widget.isAnonymous ? 'Not provided' : widget.email,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'mediaUrls': uploadedMediaUrls,
        'reportState': 'New',
      };

      await FirebaseFirestore.instance.collection('reports').add(reportData);

      if (!mounted) return;

      // Navigate all users to success screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const SubmissionSuccessScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Submission failed: ${e.toString()}"),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _cancelReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Cancel Report?", style: AppTheme.subheadingStyle),
            content: Text(
              "Are you sure you want to cancel this report? All your input will be lost.",
              style: AppTheme.bodyStyle,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  "No",
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  "Yes, Cancel",
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder:
              (context) =>
                  widget.isAnonymous
                      ? const WelcomeScreen()
                      : HomeScreen.protected(),
        ),
        (route) => false,
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.bodyStyle),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withOpacity(0.2), accentColor.withOpacity(0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppTheme.headingStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Submission", style: AppTheme.appBarTheme.titleTextStyle),
        backgroundColor: AppTheme.backgroundColor,
        iconTheme: AppTheme.appBarTheme.iconTheme,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isAnonymous) ...[
                  _buildSectionTitle(
                    "Reporter's Information",
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 10),
                  Text(widget.firstName ?? "-", style: AppTheme.captionStyle),
                  Text(widget.phoneNumber ?? "-", style: AppTheme.captionStyle),
                  Text(widget.email ?? "-", style: AppTheme.captionStyle),
                  const SizedBox(height: 20),
                ],
                _buildSectionTitle("Report Info", AppTheme.secondaryColor),
                const SizedBox(height: 10),
                _buildInfoRow("Incident Type", widget.incidentType),
                _buildInfoRow("Incident Address", _address),
                _buildInfoRow("Issue Description", widget.description),
                _buildInfoRow("Municipal Reported To", widget.municipal),
                if (widget.selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildSectionTitle("Selected Media", AppTheme.primaryColor),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.selectedImages.length,
                      itemBuilder: (context, index) {
                        final file = widget.selectedImages[index];
                        final isVideo = _isVideoFile(file);

                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(file),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            if (isVideo)
                              Positioned.fill(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.play_circle_outline,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : () => _cancelReport(),
                        style: AppTheme.secondaryButtonStyle,
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: AppTheme.textPrimaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _isUploading ? null : () => _submitReport(context),
                        style: AppTheme.primaryButtonStyle,
                        child: const Text("Submit"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      "Uploading report...",
                      style: AppTheme.bodyStyle.copyWith(color: Colors.white),
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
