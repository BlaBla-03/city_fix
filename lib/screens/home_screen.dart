import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_theme.dart';
import '../utils/auth_guard.dart';
import 'image_upload_screen.dart';
import 'user_settings_screen.dart';
import 'incident_details_screen.dart';
import 'completed_issues_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  // Static method to get a protected instance of HomeScreen
  static Widget protected() {
    return const AuthGuard(
      allowAnonymous: false,
      child: HomeScreen(), // Require authenticated (non-anonymous) user
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _reportStream;

  // Cache for incident type icon URLs
  final Map<String, String> _incidentTypeIconUrls = {};

  @override
  void initState() {
    super.initState();
    _refreshReports();
  }

  void _refreshReports() {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _reportStream = const Stream.empty();
      });
      return;
    }

    setState(() {
      _reportStream =
          FirebaseFirestore.instance
              .collection('reports')
              .where('uid', isEqualTo: user.uid)
              .where('reportState', isNotEqualTo: 'Completed')
              .orderBy('reportState')
              .orderBy('timestamp', descending: true)
              .snapshots();
    });
  }

  void _navigateTo(int index) {
    switch (index) {
      case 0:
        break; // Home
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ImageUploadScreen()),
        ).then((_) => _refreshReports());
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserSettingsScreen.protected(),
          ),
        );
        break;
    }
  }

  Future<String> _getIncidentIconUrl(String incidentType) async {
    if (_incidentTypeIconUrls.containsKey(incidentType)) {
      return _incidentTypeIconUrls[incidentType]!;
    }
    final query =
        await FirebaseFirestore.instance
            .collection('incidentTypes')
            .where('name', isEqualTo: incidentType)
            .get();
    String url = '';
    if (query.docs.isNotEmpty) {
      url = query.docs.first['iconUrl'] ?? '';
    }
    setState(() {
      _incidentTypeIconUrls[incidentType] = url;
    });
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_city,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text('CityFix', style: AppTheme.headingStyle),
            ],
          ),
          centerTitle: true,
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          automaticallyImplyLeading: false, // No back button
          actions: [
            IconButton(
              icon: const Icon(
                Icons.settings,
                color: AppTheme.textPrimaryColor,
              ),
              onPressed: () => _navigateTo(2),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Active Issues', style: AppTheme.subheadingStyle),
              const SizedBox(height: 10),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _refreshReports(),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _reportStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No reports found.",
                            style: AppTheme.bodyStyle,
                          ),
                        );
                      }

                      final reports = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index].data();
                          final timestamp =
                              (report['timestamp'] as Timestamp).toDate();
                          final formattedDate = DateFormat(
                            'd MMM y',
                          ).format(timestamp);
                          final status = report['reportState'] ?? "Pending";
                          final type =
                              report['incidentType'] ?? "Unknown Issue";

                          return FutureBuilder<String>(
                            future: _getIncidentIconUrl(type),
                            builder: (context, snapshot) {
                              final iconUrl = snapshot.data ?? '';
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => IncidentDetailsScreen(
                                            reportId: reports[index].id,
                                            reportData: report,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  decoration: AppTheme.cardDecoration,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                type,
                                                style: AppTheme.bodyStyle
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                formattedDate,
                                                style: AppTheme.captionStyle,
                                              ),
                                              Text(
                                                "Status: $status",
                                                style: AppTheme.captionStyle,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (iconUrl.isNotEmpty)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: iconUrl,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              placeholder:
                                                  (
                                                    context,
                                                    url,
                                                  ) => const SizedBox(
                                                    width: 40,
                                                    height: 40,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                              errorWidget:
                                                  (
                                                    context,
                                                    url,
                                                    error,
                                                  ) => Image.asset(
                                                    'assets/images/error.png',
                                                    width: 40,
                                                    height: 40,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CompletedIssuesScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Completed Issues",
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _navigateTo(1),
                style: AppTheme.primaryButtonStyle.copyWith(
                  backgroundColor: WidgetStateProperty.all(
                    AppTheme.secondaryColor,
                  ),
                ),
                child: const Text('Create New Report'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          onTap: _navigateTo,
          currentIndex: 0,
          selectedItemColor: AppTheme.primaryColor,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle, size: 32),
              label: 'Report',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
