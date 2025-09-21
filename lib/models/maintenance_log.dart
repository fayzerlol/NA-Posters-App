class MaintenanceLog {
  final int? id;
  final int posterId;
  final DateTime timestamp;
  final String status;
  final String notes;
  final String? imagePath;
  final String? signaturePath;

  MaintenanceLog({
    this.id,
    required this.posterId,
    required this.timestamp,
    required this.status,
    required this.notes,
    this.imagePath,
    this.signaturePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'poster_id': posterId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      'notes': notes,
      'image_path': imagePath,
      'signature_path': signaturePath,
    };
  }

  factory MaintenanceLog.fromMap(Map<String, dynamic> map) {
    return MaintenanceLog(
      id: map['id'],
      posterId: map['poster_id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      status: map['status'],
      notes: map['notes'],
      imagePath: map['image_path'],
      signaturePath: map['signature_path'],
    );
  }
}
