import 'package:na_posters_app/models/poi.dart';

class Poster {
  final int? id;
  final int groupId;
  final int poiId;
  final double lat;
  final double lon;
  final String name;
  final String amenity;
  final DateTime addedDate;
  final String description;
  final String address; 

  Poster({
    this.id,
    required this.groupId,
    required this.poiId,
    required this.lat,
    required this.lon,
    required this.name,
    required this.amenity,
    required this.addedDate,
    this.description = "",
    this.address = "", 
  });

  factory Poster.fromPoi(Poi poi, int groupId) {
    return Poster(
      groupId: groupId,
      poiId: poi.id,
      lat: poi.lat,
      lon: poi.lon,
      name: poi.name,
      amenity: poi.amenity,
      addedDate: DateTime.now(),
      description: poi.name,
      address: "", 
    );
  }

  Poster copyWith({
    int? id,
    int? groupId,
    int? poiId,
    double? lat,
    double? lon,
    String? name,
    String? amenity,
    DateTime? addedDate,
    String? description,
    String? address,
  }) {
    return Poster(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      poiId: poiId ?? this.poiId,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      name: name ?? this.name,
      amenity: amenity ?? this.amenity,
      addedDate: addedDate ?? this.addedDate,
      description: description ?? this.description,
      address: address ?? this.address, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'poi_id': poiId,
      'lat': lat,
      'lon': lon,
      'name': name,
      'amenity': amenity,
      'added_date': addedDate.toIso8601String(),
      'description': description,
      'address': address, 
    };
  }

  factory Poster.fromMap(Map<String, dynamic> map) {
    return Poster(
      id: map['id'],
      groupId: map['group_id'],
      poiId: map['poi_id'],
      lat: map['lat'],
      lon: map['lon'],
      name: map['name'],
      amenity: map['amenity'],
      addedDate: DateTime.parse(map['added_date']),
      description: map['description'] ?? '',
      address: map['address'] ?? '', 
    );
  }
}
