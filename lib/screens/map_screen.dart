import 'dart:io';

import 'package:disney_secret/models/marker_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/filter_button.dart';
import '../widgets/marker_detail_dialog.dart';
import '../utils/photo_storage.dart';
import '../utils/marker_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends StatefulWidget {
    const MapScreen({super.key});

    @override
    _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
    Set<Marker> _allMarkers = {};
    Set<Marker> _filteredMarkers = {};
    Map<String, String> _markerTypes = {};
    final Map<String, String> _photoPaths = {};
    String _selectedFilter = "all";

    @override
    void initState() {
        super.initState();
        _loadMarkers();
        _loadPhotoPaths();
    }

    Future<void> _loadMarkers() async {
        List<MarkerModel> markers = await loadMarkers();
        Set<Marker> markerSet = {};
        Map<String, String> markerTypes = {};

        for (var markerData in markers) {
            BitmapDescriptor markerIcon = getMarkerIcon(markerData.type);
            Marker marker = Marker(
                markerId: MarkerId(markerData.name),
                position: LatLng(markerData.latitude, markerData.longitude),
                infoWindow: InfoWindow(
                    title: markerData.name,
                    snippet: "Cliquez pour plus de détails",
                    onTap: () => _showMarkerDetail(markerData),
                ),
                icon: markerIcon,
            );
            markerSet.add(marker);
            markerTypes[markerData.name] = markerData.type;
        }

        setState(() {
            _allMarkers = markerSet;
            _filteredMarkers = markerSet;
            _markerTypes = markerTypes;
        });
    }

    BitmapDescriptor getMarkerIcon(String type) {
        switch (type.toLowerCase()) {
            case 'secret_main_street':
                return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
            case 'secret_frontierland':
                return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
            case 'secret_adventureland':
                return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
            case 'secret_fantasyland':
                return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
            case 'secret_discoveryland':
                return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
            case 'secret_studios':
                return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
            default:
                return BitmapDescriptor.defaultMarker;
        }
    }

    Future<void> _loadPhotoPaths() async {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
            _photoPaths.clear();
            List<String>? photoPathsList = prefs.getStringList('photoPaths');
            if (photoPathsList != null) {
                for (var path in photoPathsList) {
                    var parts = path.split('::');
                    if (parts.length == 2) {
                        _photoPaths[parts[0]] = parts[1];
                    }
                }
            }
        });
    }

    Future<void> _savePhotoPath(String title, String path) async {
        final prefs = await SharedPreferences.getInstance();
        _photoPaths[title] = path;

        List<String> pathsList = _photoPaths.entries.map((e) => '${e.key}::${e.value}').toList();
        await prefs.setStringList('photoPaths', pathsList);
    }

    void _filterMarkers(String type) {
        setState(() {
            _selectedFilter = type;
            if (type == "all") {
                _filteredMarkers = _allMarkers;
            } else {
                _filteredMarkers = _allMarkers.where((marker) => _markerTypes[marker.markerId.value] == type).toSet();
            }
        });
    }

    void _showMarkerDetail(MarkerModel markerData) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
                return MarkerDetailDialog(
                    title: markerData.name,
                    detail: markerData.detail,
                    photoPath: _photoPaths[markerData.name],
                    onTakePhoto: () => _takePhoto(markerData.name),
                    onViewPhoto: () => _viewPhoto(markerData.name),
                );
            },
        );
    }

    Future<void> _takePhoto(String title) async {
        final photoPath = await takePhoto(title);
        if (photoPath != null) {
            setState(() {
                _photoPaths[title] = photoPath;
            });
            _savePhotoPath(title, photoPath);
            Navigator.of(context).pop();
        }
    }

    void _viewPhoto(String title) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
                return AlertDialog(
                    title: Text('Photo de $title'),
                    content: Image.file(File(_photoPaths[title]!)),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text("Fermer"),
                        ),
                    ],
                );
            },
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text('Carte du parc - Secrets'),
                actions: [
                    Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Image.asset(
                            "assets/logo.png",
                            height: 100,
                        ),
                    ),
                ],
            ),
            body: Column(
                children: [
                    SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                                FilterButton(
                                    label: "Tous",
                                    type: "all",
                                    selectedFilter: _selectedFilter,
                                    onPressed: _filterMarkers,
                                ),
                                FilterButton(
                                    label: "Royaume Victorien",
                                    type: "secret_main_street",
                                    selectedFilter: _selectedFilter,
                                    onPressed: _filterMarkers,
                                ),
                                FilterButton(
                                    label: "Terre des Pionniers",
                                    type: "secret_frontierland",
                                    selectedFilter: _selectedFilter,
                                    onPressed: _filterMarkers,
                                ),
                                FilterButton(
                                    label: "Jungle Mystérieuse",
                                    type: "secret_adventureland",
                                    selectedFilter: _selectedFilter,
                                    onPressed: _filterMarkers,
                                ),
                                FilterButton(
                                    label: "Royaume Féérique",
                                    type: "secret_fantasyland",
                                    selectedFilter: _selectedFilter,
                                    onPressed: _filterMarkers,
                                ),
                                FilterButton(
                                    label: "Zone Galactique",
                                    type: "secret_discoveryland",
                                    selectedFilter: _selectedFilter,
                                    onPressed: _filterMarkers,
                                ),
                                FilterButton(
                                    label: "2ème Parc",
                                    type: "secret_studios",
                                    selectedFilter: _selectedFilter,
                                    onPressed: _filterMarkers,
                                ),
                            ],
                        ),
                    ),
                    Expanded(
                        child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                                target: LatLng(48.871234, 2.776808),
                                zoom: 15.5,
                            ),
                            markers: _filteredMarkers,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            zoomControlsEnabled: true,
                            zoomGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            compassEnabled: true,
                        ),
                    ),
                ],
            ),
        );
    }
}
