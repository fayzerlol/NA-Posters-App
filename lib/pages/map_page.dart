import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:na_posters_app/models/group.dart';
import 'package:na_posters_app/models/poi.dart';
import 'package:na_posters_app/models/poster.dart';
import 'package:na_posters_app/services/overpass_service.dart';
import 'package:na_posters_app/services/routing_service.dart';
import 'package:na_posters_app/helpers/database_helper.dart';
import 'package:na_posters_app/pages/poster_details_page.dart';

class MapPage extends StatefulWidget {
  final Group group;
  final LatLng center;
  final double radius;
  final int maxSuggestions;

  const MapPage({
    Key? key,
    required this.group,
    required this.center,
    required this.radius,
    required this.maxSuggestions,
  }) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final OverpassService _overpassService = OverpassService();
  final RoutingService _routingService = RoutingService();
  List<Poi> _suggestedPois = [];
  List<Poster> _savedPosters = [];
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  bool _isRouting = false;

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
      final savedPosters = await DatabaseHelper.instance.getPostersByGroup(widget.group.id!);

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
    final _formKey = GlobalKey<FormState>();
    final _addressController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_location_alt_outlined, color: Theme.of(context).primaryColor),
              const SizedBox(width: 10),
              const Text('Salvar Local'),
            ],
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deseja salvar "${poi.name}" para o grupo ${widget.group.name}?'),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Endereço',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira um endereço';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newPoster = Poster(
                    groupId: widget.group.id!,
                    poiId: poi.id,
                    lat: poi.lat,
                    lon: poi.lon,
                    name: poi.name,
                    amenity: poi.amenity,
                    addedDate: DateTime.now(),
                    address: _addressController.text,
                    description: poi.name,
                  );
                  await DatabaseHelper.instance.addPoster(newPoster);
                  Navigator.of(context).pop(true);
                }
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

  Future<void> _calculateRoute() async {
    if (_savedPosters.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('É necessário ter pelo menos 2 locais salvos para criar uma rota.')),
      );
      return;
    }

    setState(() {
      _isRouting = true;
      _routePoints = [];
    });

    try {
      final points = _savedPosters.map((p) => LatLng(p.lat, p.lon)).toList();
      final route = await _routingService.getRoute(points);
      setState(() {
        _routePoints = route;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao calcular a rota: $e')),
      );
    } finally {
      setState(() {
        _isRouting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Locais para ${widget.group.name}'),
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
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4.0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    ..._suggestedPois.map((poi) => _buildPoiMarker(poi)),
                    ..._savedPosters.map((poster) => _buildPosterMarker(poster)),
                  ],
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _calculateRoute,
        tooltip: 'Calcular Rota',
        child: _isRouting
            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : const Icon(Icons.route),
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
