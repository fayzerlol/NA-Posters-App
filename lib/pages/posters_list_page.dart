import 'package:flutter/material.dart';
import 'package:na_posters_app/models/poster.dart';
import 'package:na_posters_app/pages/map_page.dart';
import 'package:na_posters_app/pages/poster_details_page.dart';
import 'package:na_posters_app/utils/database_helper.dart';

class PostersListPage extends StatefulWidget {
  const PostersListPage({Key? key}) : super(key: key);

  @override
  _PostersListPageState createState() => _PostersListPageState();
}

class _PostersListPageState extends State<PostersListPage> {
  late Future<List<Poster>> _postersFuture;

  @override
  void initState() {
    super.initState();
    _refreshPosters();
  }

  void _refreshPosters() {
    setState(() {
      _postersFuture = DatabaseHelper.instance.getPosters();
    });
  }

  void _deletePoster(int id) async {
    await DatabaseHelper.instance.deletePoster(id);
    _refreshPosters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cartazes de NA')),
      body: FutureBuilder<List<Poster>>(
        future: _postersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhum cartaz adicionado ainda.'));
          }
          final posters = snapshot.data!;
          return ListView.builder(
            itemCount: posters.length,
            itemBuilder: (context, index) {
              final poster = posters[index];
              return ListTile(
                title: Text(poster.name),
                subtitle: Text('Adicionado em: ${poster.addedDate}'),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PosterDetailsPage(poster: poster),
                    ),
                  );
                  _refreshPosters();
                },
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePoster(poster.id!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => MapPage()),
          );
          if (result == true) {
            _refreshPosters();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
