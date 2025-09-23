import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class RoutingService {
  Future<List<LatLng>> getRoute(List<LatLng> points) async {
    if (points.length < 2) {
      return [];
    }

    final coordinates = points.map((p) => '${p.longitude},${p.latitude}').join(';');
    // OSRM now returns a polyline encoded geometry. Update the geometries parameter
    final url = 'http://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=polyline';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final geometry = routes[0]['geometry'] as String;
          final List<PointLatLng> decodedPoints = PolylinePoints.decodePolyline(geometry);
          return decodedPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
      rethrow;
    }

    return [];
  }
}
