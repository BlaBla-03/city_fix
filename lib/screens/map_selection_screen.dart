import 'dart:io';
import 'dart:async';
import 'package:city_fix/screens/incident_type_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';

import '../theme/app_theme.dart';
import '../utils/location_service.dart';

class MapSelectionScreen extends StatefulWidget {
  final List<File> selectedImages;

  const MapSelectionScreen({super.key, required this.selectedImages});

  @override
  _MapSelectionScreenState createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  String _address = '';
  String? _selectedPostcode;
  LatLng _initialCameraPosition = const LatLng(
    3.1390,
    101.6869,
  ); // default to KL
  final TextEditingController _searchController = TextEditingController();
  final GoogleMapsPlaces _places = GoogleMapsPlaces(
    apiKey: 'AIzaSyAEczD0FNOO7w2pQlZTuJ72i4Ec2P4w7c4',
  );
  bool _isLoading = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _setupLocationListener();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _setupLocationListener() {
    // Listen for location changes
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Only notify if moved at least 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      // When user clicks the location button, this will be triggered
      // and we'll pin the location
      final userLatLng = LatLng(position.latitude, position.longitude);
      _onTap(userLatLng);
    });
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First try to get the pre-fetched location
      Position? lastKnownPosition =
          await LocationService.getLastKnownLocation();

      if (lastKnownPosition != null) {
        final userLatLng = LatLng(
          lastKnownPosition.latitude,
          lastKnownPosition.longitude,
        );
        setState(() {
          _initialCameraPosition = userLatLng;
          _isLoading = false;
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(userLatLng, 15),
          );
        }

        // Automatically pin the current location
        _onTap(userLatLng);
        return;
      }

      // If no pre-fetched location, fall back to getting current position
      await _determinePosition();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      final userLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _initialCameraPosition = userLatLng;
        _isLoading = false;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(userLatLng, 15),
        );
      }

      // Automatically pin the current location
      _onTap(userLatLng);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get current location: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController!.moveCamera(
      CameraUpdate.newLatLngZoom(_initialCameraPosition, 15),
    );
  }

  void _onTap(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _address = 'Fetching address...';
      _selectedPostcode = null;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;

      final rawParts = [
        place.name,
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.postalCode,
        place.country,
      ];

      final seen = <String>{};
      final dedupedParts =
          rawParts
              .where((part) => part != null && part.isNotEmpty)
              .where((part) => seen.add(part!))
              .toList();

      final fullAddress = dedupedParts.join(', ');

      setState(() {
        _address = fullAddress;
        _selectedPostcode = place.postalCode;
      });
    } catch (e) {
      setState(() {
        _address = "Unable to fetch address.";
        _selectedPostcode = null;
      });
    }
  }

  void _searchLocation() async {
    final query = _searchController.text;
    if (query.isEmpty) return;

    final response = await _places.searchByText(query);
    if (response.status == 'OK' && response.results.isNotEmpty) {
      final location = response.results.first.geometry!.location;
      final target = LatLng(location.lat, location.lng);

      // Move the camera
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 15));

      // Update marker and address as if user tapped the map
      _onTap(target);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location not found. Please try another search.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _onNext() {
    if (_selectedLocation == null || _selectedPostcode == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => IncidentTypeScreen(
              selectedImages: widget.selectedImages,
              latitude: _selectedLocation!.latitude,
              longitude: _selectedLocation!.longitude,
              postcode: _selectedPostcode!,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLocation = _selectedLocation != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          "Select Location",
          style: AppTheme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: AppTheme.textFieldDecoration(
                    'Search location',
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search, color: AppTheme.primaryColor),
                      onPressed: _searchLocation,
                    ),
                  ),
                  onSubmitted: (_) => _searchLocation(),
                ),
              ),
              Expanded(
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _initialCameraPosition,
                    zoom: 14.0,
                  ),
                  onTap: _onTap,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  markers:
                      hasLocation
                          ? {
                            Marker(
                              markerId: const MarkerId("selected-location"),
                              position: _selectedLocation!,
                              icon: BitmapDescriptor.defaultMarker,
                            ),
                          }
                          : {},
                ),
              ),
              if (_address.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selected Location",
                        style: AppTheme.bodyStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_address, style: AppTheme.bodyStyle),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: ElevatedButton(
                  onPressed: hasLocation ? _onNext : null,
                  style:
                      hasLocation
                          ? AppTheme.primaryButtonStyle
                          : AppTheme.primaryButtonStyle.copyWith(
                            backgroundColor: MaterialStateProperty.all(
                              AppTheme.textSecondaryColor.withOpacity(0.3),
                            ),
                          ),
                  child: const Text("Next: Incident Type"),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}
