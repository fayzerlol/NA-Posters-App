class Group {
  final int? id;
  final String name;

  const Group({this.id, required this.name});

  Group copyWith({int? id, String? name}) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
    );
  }
}
