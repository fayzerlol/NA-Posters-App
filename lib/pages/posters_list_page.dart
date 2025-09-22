import 'package:flutter/material.dart';
import 'package:na_posters_app/helpers/database_helper.dart';
import 'package:na_posters_app/models/poster.dart';
import 'package:na_posters_app/pages/poster_add_page.dart';
import 'package:na_posters_app/pages/poster_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostersListPage extends StatefulWidget {
  const PostersListPage({super.key});

  @override
  State<PostersListPage> createState() => _PostersListPageState();
}

class _PostersListPageState extends State<PostersListPage> {
  late Future<List<Poster>> _postersFuture;
  String? _userGroupId;
  String _userGroupName = 'Seu Grupo'; // Default value
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetchPosters();
  }

  Future<void> _loadUserDataAndFetchPosters() async {
    final prefs = await SharedPreferences.getInstance();
    // Fetching the group ID (String) and group name
    final groupId = prefs.getString('userGroupId');
    final groupName = prefs.getString('userGroupName') ?? 'Grupo Desconhecido';

    if (groupId == null || groupId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID do Grupo não encontrado. Por favor, reinicie o app.')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _userGroupId = groupId;
        _userGroupName = groupName;
        _postersFuture = DatabaseHelper.instance.getPostersByGroup(groupId);
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPosters() async {
    if (_userGroupId != null) {
      setState(() {
        _postersFuture = DatabaseHelper.instance.getPostersByGroup(_userGroupId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cartazes - $_userGroupName'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userGroupId == null
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Não foi possível carregar os cartazes. ID do grupo não definido.',
                    textAlign: TextAlign.center,
                  ),
                ))
              : RefreshIndicator(
                  onRefresh: _refreshPosters,
                  child: FutureBuilder<List<Poster>>(
                    future: _postersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Nenhum cartaz encontrado para este grupo.'));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Erro: ${snapshot.error}'));
                      }

                      final posters = snapshot.data!;

                      return ListView.builder(
                        itemCount: posters.length,
                        itemBuilder: (context, index) {
                          final poster = posters[index];
                          return ListTile(
                            title: Text(poster.name),
                            subtitle: Text(poster.address),
                            onTap: () async {
                              // Navigate to details and wait for a potential update
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PosterDetailsPage(poster: poster),
                                ),
                              );

                              // If a poster was deleted on the details page, refresh the list
                              if (result == 'deleted') {
                                _refreshPosters();
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_userGroupId != null) {
            // Wait for the add page to close, then refresh the list
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddPosterPage(groupId: _userGroupId!),
              ),
            );
            _refreshPosters(); // Refresh after coming back
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Cartaz',
      ),
    );
  }
}
