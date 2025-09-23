class Poster {
  final int? id; // ID local do SQflite
  final String groupId; // ID do grupo do Firestore (String)
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
    required this.description,
    required this.address,
  });

  Poster copyWith({
    int? id,
    String? groupId,
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
      id: map['id'] as int?,
      // The group_id from the database is now a TEXT field
      groupId: map['group_id'].toString(),
      poiId: map['poi_id'] as int,
      lat: map['lat'] as double,
      lon: map['lon'] as double,
      name: map['name'] as String,
      amenity: map['amenity'] as String,
      addedDate: DateTime.parse(map['added_date'] as String),
      description: map['description'] as String,
      address: map['address'] as String,
    );
  }
}
