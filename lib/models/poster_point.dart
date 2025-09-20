//import 'package:flutter/foundation.dart';

class PosterPoint {
  final int? id;
  final double latitude;
  final double longitude;
  final int groupId;
  final String address;
  final String status;

  const PosterPoint({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.groupId,
    required this.address,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'group_id': groupId,
      'address': address,
      'status': status,
    };
  }

  factory PosterPoint.fromMap(Map<String, dynamic> map) {
    return PosterPoint(
      id: map['id'] as int?,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      groupId: map['group_id'] as int,
      address: map['address'] as String,
      status: map['status'] as String,
    );
  }
}
