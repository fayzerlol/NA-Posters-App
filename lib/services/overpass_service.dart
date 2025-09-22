import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:na_posters_app/models/poi.dart';

class OverpassService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org/reverse';


  // Define a pontuação para cada tipo de POI
  static const Map<String, int> poiScores = {
    // Alta Prioridade
    'social_facility': 10,
    'hospital': 9,
    'clinic': 9,
    'doctors': 9,
    'pharmacy': 8,
    'place_of_worship': 8,

    // Média Prioridade
    'community_centre': 7,
    'bus_station': 6,
    'university': 5,
    'college': 5,
    'school': 5,

    // Baixa Prioridade
    'library': 4,
    'post_office': 3,
    'fire_station': 2,
  };

  // POIs a serem excluídos da busca
  static const List<String> excludedAmenities = [
    'bar',
    'pub',
    'nightclub',
    'police',
  ];

  Future<String> getAddressFromCoordinates(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('$_nominatimUrl?format=json&lat=$lat&lon=$lon'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['display_name'] ?? 'Endereço não encontrado';
    } else {
      throw Exception('Falha ao obter o endereço: ${response.statusCode}');
    }
  }

  Future<List<Poi>> getPois(double lat, double lon, double radius) async {
    // Constrói a query dinamicamente, buscando apenas os POIs com pontuação
    // e excluindo os que não queremos.
    final queryBuilder = StringBuffer();
    queryBuilder.writeln('[out:json][timeout:30];');
    queryBuilder.writeln('(');

    poiScores.keys.forEach((amenity) {
      if (!excludedAmenities.contains(amenity)) {
        queryBuilder.writeln(
            '  node["amenity"="$amenity"](around:$radius,$lat,$lon);');
      }
    });

    queryBuilder.writeln(');');
    queryBuilder.writeln('out body;');

    final String query = queryBuilder.toString();

    final response = await http.post(
      Uri.parse(_overpassUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'data=$query',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> elements = data['elements'];

      // Mapeia, pontua e filtra os POIs
      List<Poi> pois = elements.map((e) {
        final poi = Poi.fromJson(e);
        final amenity = e['tags']?['amenity'] ?? '';
        poi.score = poiScores[amenity] ?? 0; // Atribui a pontuação
        return poi;
      }).toList();

      // Filtra os POIs que acabaram vindo mas estão na lista de exclusão ou não têm score
      pois.removeWhere(
          (poi) => excludedAmenities.contains(poi.amenity) || poi.score == 0);

      // Ordena os POIs pelo score (maior para menor)
      pois.sort((a, b) => b.score.compareTo(a.score));

      return pois;
    } else {
      throw Exception(
          'Falha ao carregar os POIs: ${response.statusCode} ${response.body}');
    }
  }
}
