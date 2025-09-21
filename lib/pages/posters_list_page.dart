import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:na_posters_app/models/poster.dart';
import 'package:na_posters_app/pages/home_page.dart';
import 'package:na_posters_app/pages/poster_details_page.dart';
import 'package:na_posters_app/services/export_service.dart';
import 'package:na_posters_app/utils/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class PostersListPage extends StatefulWidget {
  const PostersListPage({Key? key}) : super(key: key);

  @override
  _PostersListPageState createState() => _PostersListPageState();
}

class _PostersListPageState extends State<PostersListPage> {
  late Future<List<Poster>> _postersFuture;
  final ExportService _exportService = ExportService();
  bool _isExporting = false;

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

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    // Solicita permissão de armazenamento
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      final path = await _exportService.exportData();
      if (path != null) {
        Share.shareXFiles([XFile(path)], text: 'Backup de Cartazes de NA');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nenhum dado para exportar.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permissão de armazenamento negada.')),
      );
    }

    setState(() {
      _isExporting = false;
    });
  }

  IconData _getIconForAmenity(String amenity) {
    switch (amenity) {
      case 'place_of_worship':
        return Icons.church;
      case 'hospital':
      case 'clinic':
      case 'doctors':
        return Icons.local_hospital;
      case 'pharmacy':
        return Icons.medical_services;
      case 'school':
      case 'university':
      case 'college':
        return Icons.school;
      case 'community_centre':
      case 'social_facility':
        return Icons.people;
      case 'bus_station':
        return Icons.directions_bus;
      default:
        return Icons.location_pin;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cartazes de NA'),
        actions: [
          if (_isExporting)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            IconButton(
              icon: Icon(Icons.share),
              onPressed: _exportData,
              tooltip: 'Exportar Dados',
            ),
        ],
      ),
      body: FutureBuilder<List<Poster>>(
        future: _postersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Nenhum cartaz adicionado ainda.\n\nClique no botão "+" para começar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            );
          }
          final posters = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(8.0),
            itemCount: posters.length,
            itemBuilder: (context, index) {
              final poster = posters[index];
              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(_getIconForAmenity(poster.amenity)),
                  ),
                  title: Text(poster.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Adicionado em: ${DateFormat.yMd().format(poster.addedDate)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deletePoster(poster.id!),
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PosterDetailsPage(poster: poster),
                      ),
                    );
                    _refreshPosters();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => HomePage()),
          );
          if (result == true) {
            _refreshPosters();
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Adicionar Novo Cartaz',
      ),
    );
  }
}
