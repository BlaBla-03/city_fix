import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class CompletedIncidentDetailsScreen extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> reportData;

  const CompletedIncidentDetailsScreen({
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

    final DateTime? completedTimestamp =
        reportData['completedTimestamp'] != null
            ? (reportData['completedTimestamp'] as Timestamp).toDate()
            : null;
    final String? completedDate =
        completedTimestamp != null
            ? DateFormat('d MMM y, h:mm a').format(completedTimestamp)
            : null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          "Completed Issue",
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
              _buildResolvedBanner(completedDate),
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
              const SizedBox(height: 20),
              // Chat History Section
              _buildChatHistorySection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResolvedBanner(String? completedDate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.secondaryColor),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.secondaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "RESOLVED",
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (completedDate != null)
                  Text(
                    "This issue was resolved on $completedDate",
                    style: AppTheme.captionStyle.copyWith(
                      color: AppTheme.secondaryColor.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHistorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Conversation History", style: AppTheme.subheadingStyle),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _showChatHistory(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surfaceColor,
            foregroundColor: AppTheme.primaryColor,
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text("View Conversation History"),
            ],
          ),
        ),
      ],
    );
  }

  void _showChatHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              appBar: AppBar(
                title: Text(
                  "Conversation History",
                  style: AppTheme.appBarTheme.titleTextStyle,
                ),
                backgroundColor: AppTheme.backgroundColor,
                iconTheme: AppTheme.appBarTheme.iconTheme,
                centerTitle: true,
                elevation: 0,
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "This issue has been resolved. The conversation history is available for reference only.",
                      style: AppTheme.captionStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('reports')
                              .doc(reportId)
                              .collection('messages')
                              .orderBy('timestamp', descending: false)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              "No conversation history available",
                              style: AppTheme.bodyStyle,
                            ),
                          );
                        }

                        final messages = snapshot.data!.docs;

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index].data();
                            final isStaff =
                                message['isStaff'] as bool? ?? false;
                            final timestamp =
                                (message['timestamp'] as Timestamp?)
                                    ?.toDate() ??
                                DateTime.now();
                            final formattedTime = DateFormat(
                              'h:mm a, d MMM y',
                            ).format(timestamp);

                            return Align(
                              alignment:
                                  isStaff
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      isStaff
                                          ? AppTheme.surfaceColor
                                          : AppTheme.primaryColor.withOpacity(
                                            0.2,
                                          ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isStaff
                                            ? Colors.grey.withOpacity(0.2)
                                            : AppTheme.primaryColor.withOpacity(
                                              0.2,
                                            ),
                                  ),
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isStaff
                                          ? 'Staff: ${message['senderName']}'
                                          : 'You',
                                      style: AppTheme.captionStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message['text'],
                                      style: AppTheme.bodyStyle,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formattedTime,
                                      style: AppTheme.captionStyle.copyWith(
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      border: Border(
                        top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                    child: Text(
                      "This conversation is archived and read-only",
                      textAlign: TextAlign.center,
                      style: AppTheme.captionStyle.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
      body: PageView.builder(
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
    );
  }
}
