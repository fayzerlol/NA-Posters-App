class MaintenanceLog {
  final int? id;
  final int posterId;
  final DateTime timestamp;
  final String status;
  final String notes;
  final String responsibleName; // Adicionado
  final String? imagePath;
  final String? signaturePath;

  MaintenanceLog({
    this.id,
    required this.posterId,
    required this.timestamp,
    required this.status,
    required this.notes,
    required this.responsibleName, // Adicionado
    this.imagePath,
    this.signaturePath,
  });

  MaintenanceLog copyWith({
    int? id,
    int? posterId,
    DateTime? timestamp,
    String? status,
    String? notes,
    String? responsibleName, // Adicionado
    String? imagePath,
    String? signaturePath,
  }) {
    return MaintenanceLog(
      id: id ?? this.id,
      posterId: posterId ?? this.posterId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      responsibleName: responsibleName ?? this.responsibleName, // Adicionado
      imagePath: imagePath ?? this.imagePath,
      signaturePath: signaturePath ?? this.signaturePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'poster_id': posterId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      'notes': notes,
      'responsible_name': responsibleName, // Adicionado
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
      responsibleName: map['responsible_name'], // Adicionado
      imagePath: map['image_path'],
      signaturePath: map['signature_path'],
    );
  }
}
