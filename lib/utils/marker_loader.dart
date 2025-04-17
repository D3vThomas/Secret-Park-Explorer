import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/marker_model.dart';

Future<List<MarkerModel>> loadMarkers() async {
    try {
        String jsonString = await rootBundle.loadString('assets/markers.json');
        List<dynamic> jsonResponse = json.decode(jsonString);

        List<MarkerModel> markers = jsonResponse.map((json) => MarkerModel.fromJson(json)).toList();
        return markers;
    } catch (e) {
        print('Erreur lors du chargement des marqueurs : $e');
        return [];
    }
}
