import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:na_posters_app/models/poi.dart';
import 'package:na_posters_app/models/poster.dart';
import 'package:na_posters_app/services/overpass_service.dart';
import 'package:na_posters_app/utils/database_helper.dart';
import 'package:na_posters_app/pages/poster_details_page.dart'; // Import PosterDetailsPage

class MapPage extends StatefulWidget {
  final LatLng center;
  final double radius;
  final int maxSuggestions;

  const MapPage({
    Key? key,
    required this.center,
    required this.radius,
    required this.maxSuggestions,
  }) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final OverpassService _overpassService = OverpassService();
  List<Poi> _suggestedPois = [];
  List<Poster> _savedPosters = [];
  bool _isLoading = true;
  Poi? _selectedPoi;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final pois = await _overpassService.getPois(
        widget.center.latitude,
        widget.center.longitude,
        widget.radius * 1000, // Convert km to meters
      );
      final savedPosters = await DatabaseHelper.instance.getPosters();

      setState(() {
        _suggestedPois = pois.take(widget.maxSuggestions).toList();
        _savedPosters = savedPosters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar os locais: $e')),
      );
    }
  }

  void _showSavePoiDialog(Poi poi) async {
    final nameController = TextEditingController(text: poi.name);
    final descriptionController = TextEditingController(text: poi.tags['description'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salvar Local'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                autofocus: true,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Retorna false se cancelar
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final newPoster = Poster(
                  lat: poi.lat,
                  lon: poi.lon,
                  name: nameController.text,
                  amenity: poi.amenity,
                  poiId: poi.id,
                  addedDate: DateTime.now(),
                );
                await DatabaseHelper.instance.addPoster(newPoster);
                Navigator.of(context).pop(true); // Retorna true se salvar com sucesso
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _refreshData(); // Atualiza os dados se o poster foi salvo
    }
  }

  void _navigateToDetails(Poster poster) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PosterDetailsPage(poster: poster),
      ),
    );
    _refreshData(); // Refresh data when returning from details page
  }

  @override
  Widget build(BuildContext context) {
    final allMarkers = <Marker>[
      // Marcadores de POIs sugeridos (Vermelho)
      ..._suggestedPois.map((poi) {
        return Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(poi.lat, poi.lon),
          child: GestureDetector( // child em vez de builder
            onTap: () => _showSavePoiDialog(poi),
            child: Tooltip(
              message: 'Sugestão: ${poi.name}\nTipo: ${poi.amenity}\nPontuação: ${poi.score}\nToque para salvar',
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          ),
        );
      }),
      // Marcadores de Posters salvos (Azul)
      ..._savedPosters.map((poster) {
        return Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(poster.lat, poster.lon),
          child: GestureDetector( // child em vez de builder
            onTap: () => _navigateToDetails(poster),
            child: Tooltip(
              message: '${poster.name}\nToque para ver detalhes',
              child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
            ),
          ),
        );
      }),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locais para Colagem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Recarregar Locais',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: widget.center,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(markers: allMarkers),
              ],
            ),
    );
  }
}
