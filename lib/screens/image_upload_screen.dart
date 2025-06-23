import 'dart:io';
import 'package:city_fix/screens/map_selection_screen.dart';
import 'package:city_fix/screens/login_registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../theme/app_theme.dart';
import '../utils/permissions.dart';

class MediaFile {
  final File file;
  final bool isVideo;
  File? thumbnail; // For videos

  MediaFile({required this.file, required this.isVideo, this.thumbnail});
}

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<MediaFile> _selectedMedia = [];
  bool _isSnackbarVisible = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    AppPermissions.requestAllPermissions();
  }

  Future<void> _pickMedia() async {
    if (_selectedMedia.length >= 3) {
      _showSnackbar("You can only select up to 3 media files.");
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: AppTheme.backgroundColor,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppTheme.primaryColor,
                ),
                title: Text('Take Photo', style: AppTheme.bodyStyle),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImageFrom(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppTheme.primaryColor,
                ),
                title: Text('Choose from Gallery', style: AppTheme.bodyStyle),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImageFrom(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.videocam,
                  color: AppTheme.primaryColor,
                ),
                title: Text('Take Video', style: AppTheme.bodyStyle),
                onTap: () async {
                  Navigator.pop(context);
                  await _getVideoFrom(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.video_library,
                  color: AppTheme.primaryColor,
                ),
                title: Text(
                  'Choose Video from Gallery',
                  style: AppTheme.bodyStyle,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _getVideoFrom(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImageFrom(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      File? compressed = await _compressImage(file);
      if (compressed != null) {
        setState(() {
          _selectedMedia.add(MediaFile(file: compressed, isVideo: false));
        });
      }
    }
  }

  Future<void> _getVideoFrom(ImageSource source) async {
    setState(() {
      _isProcessing = true;
    });

    final pickedFile = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 30),
    );

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      // Generate thumbnail
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        quality: 50,
      );

      // Compress video
      final MediaInfo? compressedInfo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
      );

      if (compressedInfo != null &&
          compressedInfo.file != null &&
          thumbnailPath != null) {
        setState(() {
          _selectedMedia.add(
            MediaFile(
              file: compressedInfo.file!,
              isVideo: true,
              thumbnail: File(thumbnailPath),
            ),
          );
          _isProcessing = false;
        });
      } else {
        setState(() {
          _isProcessing = false;
        });
        _showSnackbar("Failed to process video");
      }
    } else {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<File?> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${const Uuid().v4()}.jpg';

    final XFile? compressedXFile =
        await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 70,
        );

    return compressedXFile != null ? File(compressedXFile.path) : null;
  }

  void _onNext() {
    if (_selectedMedia.isEmpty) {
      _showSnackbar("Please upload at least one image or video.");
      return;
    }

    if (_isSnackbarVisible) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    final List<File> mediaFiles =
        _selectedMedia.map((media) => media.file).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(selectedImages: mediaFiles),
      ),
    );
  }

  void _showSnackbar(String message) {
    if (!_isSnackbarVisible) {
      _isSnackbarVisible = true;

      final snackBar = SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.errorColor,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
        duration: const Duration(seconds: 2),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((_) {
        _isSnackbarVisible = false;
      });
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  @override
  void dispose() {
    ScaffoldMessenger.of(context).clearSnackBars();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasMedia = _selectedMedia.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null && user.isAnonymous) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginRegistrationScreen(),
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Text(
                "Upload Media for Report",
                style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Photos and videos help municipal staff understand the issue better",
                style: AppTheme.captionStyle,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _isProcessing ? null : _pickMedia,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.textSecondaryColor.withOpacity(0.3),
                  ),
                  color: AppTheme.surfaceColor,
                ),
                child:
                    _selectedMedia.isEmpty
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 50,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text("Upload Media", style: AppTheme.bodyStyle),
                            Text(
                              "You may select up to 3 images or videos",
                              style: AppTheme.captionStyle,
                            ),
                          ],
                        )
                        : _isProcessing
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Processing media...",
                                style: AppTheme.captionStyle,
                              ),
                            ],
                          ),
                        )
                        : GridView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: _selectedMedia.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemBuilder: (context, index) {
                            final mediaItem = _selectedMedia[index];

                            return Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(
                                        mediaItem.isVideo &&
                                                mediaItem.thumbnail != null
                                            ? mediaItem.thumbnail!
                                            : mediaItem.file,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (mediaItem.isVideo)
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _removeMedia(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.errorColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Tips:",
              style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "• Make sure the issue is clearly visible\n• Include context around the issue\n• Videos should be under 30 seconds",
              style: AppTheme.captionStyle,
            ),
            const Spacer(),
            SafeArea(
              child: ElevatedButton(
                onPressed: (_isProcessing || !hasMedia) ? null : _onNext,
                style:
                    (hasMedia && !_isProcessing)
                        ? AppTheme.primaryButtonStyle
                        : AppTheme.primaryButtonStyle.copyWith(
                          backgroundColor: MaterialStateProperty.all(
                            AppTheme.textSecondaryColor.withOpacity(0.3),
                          ),
                        ),
                child: const Text("Next: Select Location"),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
