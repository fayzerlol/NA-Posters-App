class Group {
  final String id;
  final String name;

  Group({required this.id, required this.name});

  // Fábrica atualizada para lidar com dados potencialmente nulos do Firestore
  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      // Garante que o ID nunca seja nulo, usando '' como padrão.
      id: map['id']?.toString() ?? '',
      // Oferece um nome padrão se 'name' for nulo.
      name: map['name'] ?? 'Nome Indisponível',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}
