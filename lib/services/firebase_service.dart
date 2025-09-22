import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:na_posters_app/models/group.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Group>> getGroups() async {
    try {
      final snapshot = await _db.collection('groups').get();
      if (snapshot.docs.isEmpty) {
        print('Nenhum grupo encontrado no Firestore.');
        return [];
      }
      final groups = snapshot.docs.map((doc) => Group.fromMap(doc.data())).toList();
      return groups;
    } catch (e) {
      print('Erro ao buscar grupos: $e');
      // Retorna uma lista vazia em caso de erro para não quebrar a UI
      return [];
    }
  }
}
