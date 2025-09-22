import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:na_posters_app/models/poster.dart';
import 'package:na_posters_app/pages/home_page.dart';
import 'package:na_posters_app/pages/poster_details_page.dart';
import 'package:na_posters_app/services/export_service.dart';
import 'package:na_posters_app/helpers/database_helper.dart';
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

    var status = await Permission.storage.request();

    if (status.isGranted) {
      final path = await _exportService.exportData();
      if (path != null) {
        await Share.shareXFiles([XFile(path)], text: 'Backup de Cartazes de NA');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum dado para exportar.')),
        );
      }
    } else if (status.isPermanentlyDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão negada permanentemente. Abra as configurações para permitir o acesso.'),
        ),
      );
      await openAppSettings();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão de armazenamento negada.')),
      );
    }

    if (mounted) {
      setState(() {
        _isExporting = false;
      });
    }
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
        title: const Text('Cartazes de NA'),
        actions: [
          if (_isExporting)
            const Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _exportData,
              tooltip: 'Exportar Dados',
            ),
        ],
      ),
      body: FutureBuilder<List<Poster>>(
        future: _postersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
            padding: const EdgeInsets.all(8.0),
            itemCount: posters.length,
            itemBuilder: (context, index) {
              final poster = posters[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(_getIconForAmenity(poster.amenity)),
                  ),
                  title: Text(poster.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Adicionado em: ${DateFormat.yMd().format(poster.addedDate)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
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
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
          if (result == true) {
            _refreshPosters();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Novo Cartaz',
      ),
    );
  }
}
