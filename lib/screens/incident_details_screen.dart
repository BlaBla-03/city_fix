import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import 'incident_chat_screen.dart';

class IncidentDetailsScreen extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> reportData;

  const IncidentDetailsScreen({
    super.key,
    required this.reportId,
    required this.reportData,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime timestamp = (reportData['timestamp'] as Timestamp).toDate();
    final String formattedDate = DateFormat(
      'd MMM y, h:mm a',
    ).format(timestamp);
    final bool isAnonymous = reportData['isAnonymous'] ?? true;
    final List<String> mediaUrls = List<String>.from(
      reportData['mediaUrls'] ?? [],
    );
    final String status = reportData['reportState'] ?? "New";

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          "Incident Details",
          style: AppTheme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppTheme.backgroundColor,
        iconTheme: AppTheme.appBarTheme.iconTheme,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusChip(status),
              const SizedBox(height: 20),

              // Incident Details Group
              Text("Incident Details", style: AppTheme.subheadingStyle),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      "Incident Type",
                      reportData['incidentType'] ?? "Unknown",
                    ),
                    const Divider(height: 20),
                    _buildDetailItem(
                      "Location",
                      reportData['locationInfo'] ?? "Not specified",
                    ),
                    const Divider(height: 20),
                    _buildDetailItem(
                      "Municipal",
                      reportData['municipal'] ?? "Unknown",
                    ),
                    const Divider(height: 20),
                    _buildDetailItem(
                      "Description",
                      reportData['description'] ?? "No description provided",
                    ),
                    const Divider(height: 20),
                    _buildDetailItem("Reported On", formattedDate),
                  ],
                ),
              ),

              if (!isAnonymous) ...[
                const SizedBox(height: 25),
                Text("Reporter's Information", style: AppTheme.subheadingStyle),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(
                        "Name",
                        reportData['reporterName'] ?? "Not provided",
                      ),
                      const Divider(height: 20),
                      _buildDetailItem(
                        "Phone",
                        reportData['reporterPhone'] ?? "Not provided",
                      ),
                      const Divider(height: 20),
                      _buildDetailItem(
                        "Email",
                        reportData['reporterEmail'] ?? "Not provided",
                      ),
                    ],
                  ),
                ),
              ],

              if (mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text("Photos", style: AppTheme.subheadingStyle),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: mediaUrls.length,
                    itemBuilder:
                        (context, index) => GestureDetector(
                          onTap:
                              () => _showFullImage(
                                context,
                                mediaUrls[index],
                                index,
                                mediaUrls,
                              ),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(mediaUrls[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                  ),
                ),
              ],
              // Add bottom padding to ensure content isn't hidden behind FAB
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => IncidentChatScreen(
                    reportId: reportId,
                    reportData: reportData,
                  ),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text("Chat with Staff"),
      ),
    );
  }

  void _showFullImage(
    BuildContext context,
    String imageUrl,
    int initialIndex,
    List<String> allImages,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FullScreenImageView(
              imageUrls: allImages,
              initialIndex: initialIndex,
            ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'new':
        statusColor = Colors.blue;
        statusIcon = Icons.fiber_new;
        break;
      case 'in progress':
        statusColor = Colors.orange;
        statusIcon = Icons.engineering;
        break;
      case 'resolved':
        statusColor = AppTheme.secondaryColor;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = AppTheme.textSecondaryColor;
        statusIcon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.captionStyle.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(content, style: AppTheme.bodyStyle),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(content, style: AppTheme.bodyStyle),
        ],
      ),
    );
  }
}

class FullScreenImageView extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageView({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Photo ${_currentIndex + 1} of ${widget.imageUrls.length}",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  widget.imageUrls[index],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
