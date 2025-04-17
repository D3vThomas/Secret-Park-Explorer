import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _allMarkers = {};
  Set<Marker> _filteredMarkers = {};
  Map<String, String> _markerTypes = {};
  final Map<String, File?> _photoFiles = {};  // Dictionnaire pour stocker les photos liées aux marqueurs

  final LatLng _disneyLocation = const LatLng(48.871234, 2.776808);
  String _selectedFilter = "all";

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    try {
      String jsonString = await rootBundle.loadString('assets/markers.json');
      List<dynamic> jsonResponse = json.decode(jsonString);

      Set<Marker> markers = {};
      Map<String, String> markerTypes = {};

      for (var markerData in jsonResponse) {
        BitmapDescriptor markerIcon;

        switch (markerData['type'].toLowerCase()) {
          case 'secret_main_street':
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
            break;
          case 'secret_frontierland':
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
            break;
          case 'secret_adventureland':
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
            break;
          case 'secret_fantasyland':
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
            break;
          case 'secret_discoveryland':
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
            break;
          case 'secret_studios':
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
            break;
          default:
            markerIcon = BitmapDescriptor.defaultMarker;
        }

        Marker marker = Marker(
          markerId: MarkerId(markerData['name']),
          position: LatLng(markerData['latitude'], markerData['longitude']),
          infoWindow: InfoWindow(
            title: markerData['name'],
            snippet: "Cliquez pour plus de détails",
            onTap: () => _showMarkerDetail(
              markerData['name'],
              markerData['detail'],
              markerData['latitude'],
              markerData['longitude'],
            ),
          ),
          icon: markerIcon,
        );

        markers.add(marker);
        markerTypes[markerData['name']] = markerData['type'];
      }

      setState(() {
        _allMarkers = markers;
        _filteredMarkers = markers;
        _markerTypes = markerTypes;
      });
    } catch (e) {
      print('Erreur lors du chargement des marqueurs : $e');
    }
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

  void _showMarkerDetail(String title, String detail, double latitude, double longitude) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(detail),
              // Si une photo a été prise, on affiche le bouton "Voir la photo"
              if (_photoFiles.containsKey(title) && _photoFiles[title] != null)
                ElevatedButton(
                  onPressed: () => _viewPhoto(title),
                  child: Text("Voir la photo"),
                )
              else
                ElevatedButton(
                  onPressed: () => _takePhoto(title),  // Passage du titre pour l'associer à la photo
                  child: Text("Prendre une photo"),
                ),
            ],
          ),
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

  Future<void> _takePhoto(String title) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _photoFiles[title] = File(photo.path);  // Associe la photo au marqueur par son titre
      });

      // Une fois la photo prise, on ferme la fenêtre du marqueur
      Navigator.of(context).pop();
    }
  }

  void _viewPhoto(String title) {
    // Affiche une pop-up avec l'image prise pour ce marqueur
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Photo de $title'),
          content: Image.file(_photoFiles[title]!),
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

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
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
                _filterButton("Tous", "all"),
                _filterButton("Royaume Victorien", "secret_main_street"),
                _filterButton("Terre des Pionniers", "secret_frontierland"),
                _filterButton("Jungle Mystérieuse", "secret_adventureland"),
                _filterButton("Royaume Féérique", "secret_fantasyland"),
                _filterButton("Zone Galactique", "secret_discoveryland"),
                _filterButton("2ème Parc", "secret_studios"),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _disneyLocation,
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

  Widget _filterButton(String label, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () => _filterMarkers(type),
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedFilter == type ? Colors.blue : Colors.grey,
        ),
        child: Text(label, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
