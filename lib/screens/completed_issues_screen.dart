import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import 'completed_incident_details_screen.dart';

class CompletedIssuesScreen extends StatefulWidget {
  const CompletedIssuesScreen({super.key});

  @override
  State<CompletedIssuesScreen> createState() => _CompletedIssuesScreenState();
}

class _CompletedIssuesScreenState extends State<CompletedIssuesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _reportStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedReports();
  }

  void _loadCompletedReports() {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _reportStream = const Stream.empty();
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _reportStream =
          FirebaseFirestore.instance
              .collection('reports')
              .where('uid', isEqualTo: user.uid)
              .where('reportState', isEqualTo: 'Completed')
              .orderBy('timestamp', descending: true)
              .snapshots();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          "Completed Issues",
          style: AppTheme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppTheme.backgroundColor,
        iconTheme: AppTheme.appBarTheme.iconTheme,
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Completed Reports',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These issues have been successfully resolved by municipal staff',
                      style: AppTheme.captionStyle,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _reportStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: AppTheme.textSecondaryColor,
                                    size: 60,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No completed reports yet",
                                    style: AppTheme.bodyStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Your completed reports will appear here once resolved by municipal staff",
                                    style: AppTheme.captionStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
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
                              final type =
                                  report['incidentType'] ?? "Unknown Issue";
                              final resolvedDate =
                                  report['completedTimestamp'] != null
                                      ? DateFormat('d MMM y').format(
                                        (report['completedTimestamp']
                                                as Timestamp)
                                            .toDate(),
                                      )
                                      : "Unknown date";

                              final icon =
                                  type.contains("Pothole")
                                      ? 'assets/images/pothole.png'
                                      : type.contains("Street")
                                      ? 'assets/images/streetlight.png'
                                      : type.contains("Garbage")
                                      ? 'assets/images/garbage.png'
                                      : null;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => CompletedIncidentDetailsScreen(
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
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    size: 16,
                                                    color:
                                                        AppTheme.secondaryColor,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    type,
                                                    style: AppTheme.bodyStyle
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Reported: $formattedDate",
                                                style: AppTheme.captionStyle,
                                              ),
                                              Text(
                                                "Resolved: $resolvedDate",
                                                style: AppTheme.captionStyle
                                                    .copyWith(
                                                      color:
                                                          AppTheme
                                                              .secondaryColor,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (icon != null)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.asset(
                                              icon,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
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
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
