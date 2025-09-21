import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:na_posters_app/models/poi.dart';
import 'package:na_posters_app/models/poster.dart';
import 'package:na_posters_app/services/overpass_service.dart';
import 'package:na_posters_app/utils/database_helper.dart';
import 'package:na_posters_app/pages/poster_details_page.dart';

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

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() { _isLoading = true; });
    try {
      final pois = await _overpassService.getPois(
        widget.center.latitude,
        widget.center.longitude,
        widget.radius * 1000,
      );
      final savedPosters = await DatabaseHelper.instance.getPosters();

      // Filtra POIs que já foram salvos
      final savedPoiIds = savedPosters.map((p) => p.poiId).toSet();
      final filteredPois = pois.where((poi) => !savedPoiIds.contains(poi.id)).toList();

      setState(() {
        _suggestedPois = filteredPois.take(widget.maxSuggestions).toList();
        _savedPosters = savedPosters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar os locais: $e')),
      );
    }
  }

  void _showSavePoiDialog(Poi poi) async {
    final nameController = TextEditingController(text: poi.name);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_location_alt_outlined, color: Theme.of(context).primaryColor),
              SizedBox(width: 10),
              Text('Salvar Local'),
            ],
          ),
          content: Text('Deseja salvar "${poi.name}" como um novo local de cartaz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPoster = Poster.fromPoi(poi);
                await DatabaseHelper.instance.addPoster(newPoster);
                Navigator.of(context).pop(true);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${poi.name}" salvo com sucesso!')),
      );
    }
  }

  void _navigateToDetails(Poster poster) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PosterDetailsPage(poster: poster)),
    );
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
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
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(
                  markers: [
                    ..._suggestedPois.map((poi) => _buildPoiMarker(poi)),
                    ..._savedPosters.map((poster) => _buildPosterMarker(poster)),
                  ],
                ),
              ],
            ),
    );
  }

  Marker _buildPoiMarker(Poi poi) {
    return Marker(
      width: 40.0,
      height: 40.0,
      point: LatLng(poi.lat, poi.lon),
      child: GestureDetector(
        onTap: () => _showSavePoiDialog(poi),
        child: Tooltip(
          message: 'Sugestão: ${poi.name}\nPontuação: ${poi.score}\nToque para salvar',
          child: Icon(Icons.add_location_outlined, color: Colors.redAccent, size: 40),
        ),
      ),
    );
  }

  Marker _buildPosterMarker(Poster poster) {
    return Marker(
      width: 40.0,
      height: 40.0,
      point: LatLng(poster.lat, poster.lon),
      child: GestureDetector(
        onTap: () => _navigateToDetails(poster),
        child: Tooltip(
          message: 'Salvo: ${poster.name}\nToque para ver detalhes',
          child: Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 40),
        ),
      ),
    );
  }
}
