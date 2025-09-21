import 'package:na_posters_app/models/poi.dart';

class Poster {
  final int? id;
  final int poiId;
  final double lat;
  final double lon;
  final String name;
  final String amenity;
  final DateTime addedDate;

  Poster({
    this.id,
    required this.poiId,
    required this.lat,
    required this.lon,
    required this.name,
    required this.amenity,
    required this.addedDate,
  });

  // Construtor para criar um Poster a partir de um POI
  factory Poster.fromPoi(Poi poi) {
    return Poster(
      poiId: poi.id,
      lat: poi.lat,
      lon: poi.lon,
      name: poi.name,
      amenity: poi.amenity,
      addedDate: DateTime.now(),
    );
  }

  Poster copyWith({
    int? id,
    int? poiId,
    double? lat,
    double? lon,
    String? name,
    String? amenity,
    DateTime? addedDate,
  }) {
    return Poster(
      id: id ?? this.id,
      poiId: poiId ?? this.poiId,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      name: name ?? this.name,
      amenity: amenity ?? this.amenity,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'poi_id': poiId,
      'lat': lat,
      'lon': lon,
      'name': name,
      'amenity': amenity,
      'added_date': addedDate.toIso8601String(),
    };
  }

  factory Poster.fromMap(Map<String, dynamic> map) {
    return Poster(
      id: map['id'],
      poiId: map['poi_id'],
      lat: map['lat'],
      lon: map['lon'],
      name: map['name'],
      amenity: map['amenity'],
      addedDate: DateTime.parse(map['added_date']),

    );
  }
}
