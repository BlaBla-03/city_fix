import 'package:city_fix/screens/description_screen.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_theme.dart';

class IncidentTypeScreen extends StatefulWidget {
  final List<File> selectedImages;
  final double latitude;
  final double longitude;
  final String postcode;

  const IncidentTypeScreen({
    super.key,
    required this.selectedImages,
    required this.latitude,
    required this.longitude,
    required this.postcode,
  });

  @override
  _IncidentTypeScreenState createState() => _IncidentTypeScreenState();
}

class _IncidentTypeScreenState extends State<IncidentTypeScreen> {
  final List<String> _selectedIncidents = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<String> _incidentTypes = [];
  String? _municipalName;
  bool _isLoading = true;
  bool _noMunicipalFound = false;

  Map<String, String> _incidentTypeIconUrls = {};

  @override
  void initState() {
    super.initState();
    _fetchMunicipalAndIncidents();
  }

  Future<void> _fetchMunicipalAndIncidents() async {
    setState(() {
      _isLoading = true;
      _noMunicipalFound = false;
    });
    try {
      final postcodeInt = int.tryParse(widget.postcode);
      if (postcodeInt == null) {
        setState(() {
          _municipalName = null;
          _incidentTypes = [];
          _incidentTypeIconUrls = {};
          _isLoading = false;
          _noMunicipalFound = true;
        });
        return;
      }
      final snapshot =
          await FirebaseFirestore.instance.collection('municipals').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final List<dynamic> postcodeRanges = data['postcodeRanges'] ?? [];
        for (var range in postcodeRanges) {
          int start = range['start'];
          int end = range['end'];
          if (postcodeInt >= start && postcodeInt <= end) {
            final List<String> incidentTypes = List<String>.from(
              data['incidentTypes'] ?? [],
            );
            // Fetch iconUrls for each incident type from Firestore
            Map<String, String> iconUrls = {};
            for (String incident in incidentTypes) {
              final incidentDoc =
                  await FirebaseFirestore.instance
                      .collection('incidentTypes')
                      .where('name', isEqualTo: incident)
                      .get();
              if (incidentDoc.docs.isNotEmpty) {
                iconUrls[incident] = incidentDoc.docs.first['iconUrl'] ?? '';
              } else {
                iconUrls[incident] = '';
              }
            }
            setState(() {
              _municipalName = data['name'] ?? '';
              _incidentTypes = incidentTypes;
              _incidentTypeIconUrls = iconUrls;
              _isLoading = false;
              _noMunicipalFound = false;
            });
            return;
          }
        }
      }
      setState(() {
        _municipalName = null;
        _incidentTypes = [];
        _incidentTypeIconUrls = {};
        _isLoading = false;
        _noMunicipalFound = true;
      });
    } catch (e) {
      setState(() {
        _municipalName = null;
        _incidentTypes = [];
        _incidentTypeIconUrls = {};
        _isLoading = false;
        _noMunicipalFound = true;
      });
    }
  }

  void _toggleIncident(String title) {
    setState(() {
      if (_selectedIncidents.contains(title)) {
        _selectedIncidents.remove(title);
      } else {
        // Check if already at the limit of 3 selections
        if (_selectedIncidents.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("You can select up to 3 incident types only"),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        _selectedIncidents.add(title);
      }
    });
  }

  void _onNext() {
    if (_selectedIncidents.isEmpty) return;

    final String combinedIncidentTypes = _selectedIncidents.join(', ');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DescriptionScreen(
              incidentType: combinedIncidentTypes,
              selectedImages: widget.selectedImages,
              latitude: widget.latitude,
              longitude: widget.longitude,
              municipal: _municipalName ?? 'Unknown',
            ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> filteredIncidents =
        _incidentTypes
            .where(
              (incident) =>
                  incident.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar:
          _isLoading || _noMunicipalFound
              ? null
              : AppBar(
                title: Text(
                  "Select Incident Types",
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
              : _noMunicipalFound
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        color: AppTheme.errorColor,
                        size: 60,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Sorry, reporting is currently available for Selangor only.',
                        textAlign: TextAlign.center,
                        style: AppTheme.subheadingStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please select a different location within our supported area.',
                        textAlign: TextAlign.center,
                        style: AppTheme.captionStyle,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: AppTheme.primaryButtonStyle,
                        child: const Text('Change Location'),
                      ),
                    ],
                  ),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_municipalName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_city,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Municipal Authority",
                                    style: AppTheme.bodyStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _municipalName!,
                                    style: AppTheme.bodyStyle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      "What issues would you like to report?",
                      style: AppTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You can select up to 3 issues if needed",
                      style: AppTheme.captionStyle,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: AppTheme.textFieldDecoration(
                        "Search incident types",
                      ).copyWith(
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child:
                          filteredIncidents.isEmpty
                              ? Center(
                                child: Text(
                                  "No incident types found for your search.",
                                  style: AppTheme.captionStyle,
                                ),
                              )
                              : ListView.builder(
                                itemCount: filteredIncidents.length,
                                itemBuilder: (context, index) {
                                  final incident = filteredIncidents[index];
                                  final isSelected = _selectedIncidents
                                      .contains(incident);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? AppTheme.primaryColor
                                                  .withOpacity(0.1)
                                              : AppTheme.surfaceColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? AppTheme.primaryColor
                                                : Colors.transparent,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: CachedNetworkImage(
                                        imageUrl:
                                            _incidentTypeIconUrls[incident] ??
                                            '',
                                        width: 40,
                                        height: 40,
                                        placeholder:
                                            (context, url) => const SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                        errorWidget:
                                            (context, url, error) =>
                                                Image.asset(
                                                  'assets/images/error.png',
                                                  width: 40,
                                                  height: 40,
                                                ),
                                      ),
                                      title: Text(
                                        incident,
                                        style: AppTheme.bodyStyle.copyWith(
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                      trailing:
                                          isSelected
                                              ? Icon(
                                                Icons.check_circle,
                                                color: AppTheme.primaryColor,
                                              )
                                              : Icon(
                                                Icons.circle_outlined,
                                                color:
                                                    AppTheme.textSecondaryColor,
                                              ),
                                      onTap: () => _toggleIncident(incident),
                                    ),
                                  );
                                },
                              ),
                    ),
                    if (_selectedIncidents.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Selected Issues:",
                              style: AppTheme.bodyStyle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _selectedIncidents.map((incident) {
                                    return Chip(
                                      label: Text(incident),
                                      backgroundColor: AppTheme.primaryColor
                                          .withOpacity(0.2),
                                      deleteIcon: const Icon(
                                        Icons.close,
                                        size: 18,
                                      ),
                                      onDeleted:
                                          () => _toggleIncident(incident),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _selectedIncidents.isNotEmpty ? _onNext : null,
                      style:
                          _selectedIncidents.isNotEmpty
                              ? AppTheme.primaryButtonStyle
                              : AppTheme.primaryButtonStyle.copyWith(
                                backgroundColor: WidgetStateProperty.all(
                                  AppTheme.textSecondaryColor.withOpacity(0.3),
                                ),
                              ),
                      child: const Text("Next: Description"),
                    ),
                  ],
                ),
              ),
    );
  }
}
