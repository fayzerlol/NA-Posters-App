import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:na_posters_app/models/group.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Group>> getGroups() async {
    try {
      final snapshot = await _db.collection('groups').get();
      if (snapshot.docs.isEmpty) {
        debugPrint('Nenhum grupo encontrado no Firestore.');
        return [];
      }
      
      // Corrigido: Mapeia os documentos para incluir o ID do documento.
      final groups = snapshot.docs.map((doc) {
        // Pega os dados do documento
        Map<String, dynamic> data = doc.data();
        // Adiciona o ID do documento ao mapa
        data['id'] = doc.id;
        // Cria a instância de Group a partir do mapa atualizado
        return Group.fromMap(data);
      }).toList();
      
      return groups;
    } catch (e) {
      debugPrint('Erro ao buscar grupos: $e');
      // Retorna uma lista vazia em caso de erro para não quebrar a UI
      return [];
    }
  }
}
