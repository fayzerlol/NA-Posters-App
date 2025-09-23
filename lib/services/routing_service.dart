import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

class RoutingService {
  Future<List<LatLng>> getRoute(List<LatLng> points) async {
    if (points.length < 2) {
      return [];
    }

    // Correctly format the coordinates string
    final coordinates = points.map((p) => '${p.longitude},${p.latitude}').join(';');
    final url = 'http://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final geometry = routes[0]['geometry']['coordinates'] as List;
          return geometry.map((c) => LatLng(c[1], c[0])).toList();
        }
      }
    } catch (e) {
      // It's better to rethrow the exception or handle it more gracefully
      // For now, we'll just print it as it was.
      print('Error getting route: $e');
      rethrow; // Rethrowing the exception is often better for debugging.
    }

    return [];
  }
}
