import 'package:secret_park_explorer/models/marker_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/filter_button.dart';
import '../widgets/marker_detail_dialog.dart';
import '../utils/marker_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';


class MapScreen extends StatefulWidget {
    const MapScreen({super.key});

    @override
    MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
    Set<Marker> _allMarkers = {};
    Set<Marker> _filteredMarkers = {};
    Map<String, String> _markerTypes = {};
    final Map<String, List<String>> _photoPaths = {};
    String _selectedFilter = "all";
    GoogleMapController? _mapController;
    bool _isLocationEnabled = false;

    @override
    void initState() {
        super.initState();
        _loadMarkers();
        _loadPhotoPaths();
        _checkAndShowPrivacyDialog();
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
                for (var entry in photoPathsList) {
                    var parts = entry.split('::');
                    if (parts.length == 2) {
                        String title = parts[0];
                        List<String> paths = parts[1].split('|'); // liste séparée par |
                        _photoPaths[title] = paths;
                    }
                }
            }
        });
    }

    Future<void> _savePhotoPath(String title, List<String> paths) async {
        final prefs = await SharedPreferences.getInstance();
        _photoPaths[title] = paths;

        List<String> allEntries = _photoPaths.entries
            .map((e) => '${e.key}::${e.value.join('|')}')
            .toList();
        await prefs.setStringList('photoPaths', allEntries);
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

    void _showMarkerDetail(MarkerModel markerData) async {
        final updatedPhotos = await showDialog<List<String>>(
            context: context,
            builder: (BuildContext context) {
                return MarkerDetailDialog(
                    title: markerData.name,
                    detail: markerData.detail,
                    initialPhotoPaths: _photoPaths[markerData.name] ?? [],
                );
            },
        );

        // mettre à jour les photos dans MapScreen si l'utilisateur a pris de nouvelles photos
        if (updatedPhotos != null) {
            setState(() {
                _photoPaths[markerData.name] = updatedPhotos;
            });
            _savePhotoPath(markerData.name, updatedPhotos);
        }

        setState(() {
            _isLocationEnabled = true;
        });

        if (!mounted) return;

        // Recentrer la caméra sur l'utilisateur
        _centerMapOnUser();
    }

    Future<void> _enableUserLocation() async {
        // Vérifier si le service de localisation est activé
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Le service de localisation est désactivé. Veuillez l\'activer.'
                    )
                ),
            );
            return;
        }

        // Vérifier la permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permission de localisation refusée')),
            );
            return;
        }

        // Tout est OK → activer la localisation
        setState(() {
            _isLocationEnabled = true;
        });

        if (!mounted) return;

        // Recentrer la caméra sur l'utilisateur
        await _centerMapOnUser();
    }

    Future<void> _centerMapOnUser() async {
        try {
            // Créer des settings pour Android/iOS
            LocationSettings locationSettings = const LocationSettings(
                accuracy: LocationAccuracy.best, // équivalent de desiredAccuracy
                distanceFilter: 0,
            );

            // Récupérer la position actuelle
            Position position = await Geolocator.getCurrentPosition(
                locationSettings: locationSettings,
            );

            // Recentrer la caméra
            if (_mapController != null) {
                _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(
                        LatLng(position.latitude, position.longitude),
                        17.0,
                    ),
                );
            }
        } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Impossible de récupérer la position : $e')),
            );
        }
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
                            onMapCreated: (controller) => _mapController = controller,
                            initialCameraPosition: const CameraPosition(
                                target: LatLng(48.871234, 2.776808),
                                zoom: 15.5,
                            ),
                            markers: _filteredMarkers,
                            myLocationEnabled: _isLocationEnabled,
                            myLocationButtonEnabled: false, // on utilise notre bouton
                            zoomControlsEnabled: true,
                            zoomGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            compassEnabled: true,
                        )
                    ),
                ],
            ),
            floatingActionButton: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: FloatingActionButton(
                onPressed: _enableUserLocation,
                tooltip: 'Afficher ma position',
                child: const Icon(Icons.my_location),
                ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.startFloat, 
        );
    }

    Future<void> _checkAndShowPrivacyDialog() async {
        final prefs = await SharedPreferences.getInstance();
        bool? accepted = prefs.getBool('privacyAccepted');

        if (accepted != true) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
                _showPrivacyDialog();
            });
        }
    }

    void _showPrivacyDialog() {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
                return AlertDialog(
                    title: const Text(
                        'Politique de confidentialité',
                        style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: SingleChildScrollView(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    const Text(
                                        'Secret Park Explorer ne collecte ni ne stocke aucune donnée personnelle. '
                                        'L\'application peut utiliser la localisation de l\'utilisateur uniquement '
                                        'pour afficher sa position sur la carte et calculer des distances, '
                                        'sans stockage, sans transmission et sans utilisation en arrière-plan. '
                                        'L\'accès à la localisation est optionnel.',
                                        style: TextStyle(fontSize: 14),
                                    ),

                                    const SizedBox(height: 16),

                                    const Text(
                                        'La localisation n\'est utilisée qu\'après action volontaire de l\'utilisateur.',
                                        style: TextStyle(fontSize: 14),
                                    ),

                                    const SizedBox(height: 16),

                                    const Text(
                                        'En utilisant cette application, vous acceptez les conditions de Google.',
                                        style: TextStyle(fontSize: 14),
                                    ),

                                    const SizedBox(height: 20),

                                    GestureDetector(
                                        onTap: _launchGooglePrivacyPolicy,
                                        child: const Text(
                                            'Voir la politique de confidentialité de Google',
                                            style: TextStyle(
                                                color: Colors.blue,
                                                decoration: TextDecoration.underline,
                                                fontWeight: FontWeight.w600,
                                            ),
                                        ),
                                    ),

                                    const SizedBox(height: 12),

                                    GestureDetector(
                                        onTap: _launchPrivacyPolicy,
                                        child: const Text(
                                            'Voir notre politique de confidentialité',
                                            style: TextStyle(
                                                color: Colors.blue,
                                                decoration: TextDecoration.underline,
                                                fontWeight: FontWeight.w600,
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ),
                    actions: [
                        Padding(
                            padding: const EdgeInsets.only(right: 8.0, bottom: 8),
                            child: ElevatedButton(
                                onPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setBool('privacyAccepted', true);

                                    if (!context.mounted) return;
                                    Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text("J'accepte"),
                            ),
                        ),
                    ],
                );
            },
        );
    }

    void _launchGooglePrivacyPolicy() async {
        const url = 'https://policies.google.com/privacy';
        final uri = Uri.parse(url);

        try {
            final launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
            if (!launched) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Impossible d\'ouvrir le lien dans WebView')),
                );
            }
        } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
            );
        }
    }

    void _launchPrivacyPolicy() async {
        const url = 'https://github.com/D3vThomas/Secret-Park-Explorer/blob/main/PRIVACY_POLICY.md';
        final uri = Uri.parse(url);

        try {
            final launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
            if (!launched) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Impossible d\'ouvrir le lien dans WebView')),
                );
            }
        } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
            );
        }
    }

}
