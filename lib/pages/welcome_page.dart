import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:na_posters_app/models/group.dart';
import 'package:na_posters_app/pages/posters_list_page.dart';
import 'package:na_posters_app/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  Group? _selectedGroup;
  List<Group> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });
    final groups = await _firebaseService.getGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    }
  }

  Future<void> _seedGroups() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verificando e adicionando grupos...')),
    );

    final List<String> groupNames = [
      'Barreiro',
      'Betânia',
      'Centro',
      'Cidade Nova',
      'Concórdia',
      'Floresta',
      'Grajaú',
      'Pampulha',
      'Sagrada Família',
      'Serra'
    ];

    final collectionRef = FirebaseFirestore.instance.collection('groups');
    final snapshot = await collectionRef.get();
    final existingGroupNames = snapshot.docs.map((doc) => doc.data()['name'] as String).toSet();

    int addedCount = 0;
    final batch = FirebaseFirestore.instance.batch();

    for (final name in groupNames) {
      if (!existingGroupNames.contains(name)) {
        final newDocRef = collectionRef.doc();
        batch.set(newDocRef, {'name': name, 'id': newDocRef.id});
        addedCount++;
      }
    }

    if (addedCount > 0) {
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$addedCount grupos novos foram adicionados!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todos os grupos padrão já existem.')),
        );
      }
    }

    // Recarrega os grupos no dropdown
    await _loadGroups();
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nameController.text);
      await prefs.setString('userGroupName', _selectedGroup!.name); // Salva o nome do grupo

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PostersListPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bem-vindo(a) ao App de Cartazes NA'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Para começar, por favor, identifique-se e selecione o seu grupo base.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Seu Nome',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_groups.isNotEmpty)
                      DropdownButtonFormField<Group>(
                        value: _selectedGroup,
                        items: _groups.map((group) {
                          return DropdownMenuItem<Group>(
                            value: group,
                            child: Text(group.name),
                          );
                        }).toList(),
                        onChanged: (Group? newValue) {
                          setState(() {
                            _selectedGroup = newValue;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Seu Grupo de NA',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null ? 'Por favor, selecione um grupo' : null,
                      )
                    else
                      const Text(
                        'Nenhum grupo encontrado no Firestore.',
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _groups.isEmpty ? null : _saveAndContinue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Continuar'),
                    ),
                    const SizedBox(height: 16),
                    // --- BOTÃO TEMPORÁRIO ---
                    TextButton(
                      onPressed: _seedGroups,
                      child: const Text('Adicionar Grupos Padrão'),
                    ),
                    // --------------------------
                  ],
                ),
              ),
            ),
    );
  }
}
