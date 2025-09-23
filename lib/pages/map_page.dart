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
    super.key,
    required this.group,
    required this.center,
    required this.radius,
    required this.maxSuggestions,
  });

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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pois = await _overpassService.getPois(
        widget.center.latitude,
        widget.center.longitude,
        widget.radius * 1000,
      );
      final savedPosters = await DatabaseHelper.instance.getPostersByGroup(widget.group.id);

      final savedPoiIds = savedPosters.map((p) => p.poiId).toSet();
      final filteredPois = pois.where((poi) => !savedPoiIds.contains(poi.id)).toList();

      if(mounted){
        setState(() {
          _suggestedPois = filteredPois.take(widget.maxSuggestions).toList();
          _savedPosters = savedPosters;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar os locais: $e')),
      );
    } finally {
       if(mounted){
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showSavePoiDialog(Poi poi) async {
    final address = await _overpassService.getAddressFromCoordinates(poi.lat, poi.lon);

    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salvar Local Sugerido'),
          content: Text('Deseja salvar "${poi.name}" no endereço: \n$address?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                  final newPoster = Poster(
                    groupId: widget.group.id,
                    poiId: poi.id,
                    lat: poi.lat,
                    lon: poi.lon,
                    name: poi.name,
                    amenity: poi.amenity,
                    addedDate: DateTime.now(),
                    address: address,
                    description: poi.name,
                  );
                  // Ensure context is still valid after async operation
                  if (!mounted) return;

                  await DatabaseHelper.instance.addPoster(newPoster);
                  if (!mounted) return;
                  // Use the context from the State, not the dialog builder
                  Navigator.of(this.context).pop(true);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${poi.name}" salvo com sucesso!')),
      );
    }
  }

  Future<Poster?> _showAddManualMarkerDialog(LatLng point) async {
    final address = await _overpassService.getAddressFromCoordinates(point.latitude, point.longitude);
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (!mounted) return null;
    return showDialog<Poster>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Novo Cartaz'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Endereço: $address'),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome do Local'),
                validator: (value) => (value?.isEmpty ?? true) ? 'Dê um nome ao local' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                 final newPoster = Poster(
                    groupId: widget.group.id,
                    poiId: 0,
                    lat: point.latitude,
                    lon: point.longitude,
                    name: nameController.text,
                    amenity: 'manual',
                    addedDate: DateTime.now(),
                    address: address,
                    description: nameController.text,
                  );
                final createdPoster = await DatabaseHelper.instance.addPoster(newPoster);
 Navigator.of(mounted ? context : this.context).pop(createdPoster);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(Poster poster) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PosterDetailsPage(poster: poster)),
    ).then((_) {
      _loadData();
    });
  }

  Future<void> _calculateRoute() async {
    if (_savedPosters.length < 2) {
      if (!mounted) return;
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
      if(mounted){
        setState(() {
          _routePoints = route;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao calcular a rota: $e')),
      );
    } finally {
      if(mounted){
        setState(() {
          _isRouting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Locais para ${widget.group.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: widget.center,
                initialZoom: 14.0,
                onLongPress: (tapPosition, point) {
                  _showAddManualMarkerDialog(point).then((newPoster) {
                    if (newPoster != null) {
                      _navigateToDetails(newPoster);
                    }
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.na_posters_app',
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
