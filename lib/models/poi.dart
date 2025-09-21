class Poi {
  final int id;
  final double lat;
  final double lon;
  final Map<String, dynamic> tags;
  final String amenity;
  int score; // Score can be updated

  Poi({
    required this.id,
    required this.lat,
    required this.lon,
    required this.tags,
    required this.amenity,
    this.score = 0,
  });

  factory Poi.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'] ?? {};
    return Poi(
      id: json['id',
      lat: json['lat'],
      lon: json['lon'],
      tags: tags,
      amenity: tags['amenity'] ?? 'unknown',
    );
  }

  String get name => tags['name'] ?? 'Nome desconhecido';
}
