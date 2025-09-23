import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  final Completer<GoogleMapController> _controller = Completer();
  final OverpassService _overpassService = OverpassService();
  final RoutingService _routingService = RoutingService();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<Poi> _suggestedPois = [];
  List<Poster> _savedPosters = [];

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

      if (mounted) {
        setState(() {
          _suggestedPois = filteredPois.take(widget.maxSuggestions).toList();
          _savedPosters = savedPosters;
          _updateMarkers();
        });
      }
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar os locais: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateMarkers() {
    final Set<Marker> markers = {};

    // Marcadores para POIs sugeridos
    for (final poi in _suggestedPois) {
      markers.add(Marker(
        markerId: MarkerId('poi_${poi.id}'),
        position: LatLng(poi.lat, poi.lon),
        infoWindow: InfoWindow(title: 'Sugestão: ${poi.name}', snippet: 'Toque para salvar'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () => _showSavePoiDialog(poi),
      ));
    }

    // Marcadores para cartazes salvos
    for (final poster in _savedPosters) {
      markers.add(Marker(
        markerId: MarkerId('poster_${poster.id}'),
        position: LatLng(poster.lat, poster.lon),
        infoWindow: InfoWindow(title: 'Salvo: ${poster.name}', snippet: 'Toque para ver detalhes'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () => _navigateToDetails(poster),
      ));
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _showSavePoiDialog(Poi poi) async {
    final address = await _overpassService.getAddressFromCoordinates(poi.lat, poi.lon);
    final localContext = context;

    if (!mounted) return;
    // ignore: use_build_context_synchronously
    final result = await showDialog<bool>(
      context: localContext,
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
                await DatabaseHelper.instance.addPoster(newPoster);
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(true);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _loadData(); // Recarrega os dados e atualiza os marcadores
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${poi.name}" salvo com sucesso!')),
      );
    }
  }

    Future<Poster?> _showAddManualMarkerDialog(LatLng point) async {
    final address = await _overpassService.getAddressFromCoordinates(point.latitude, point.longitude);
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final localContext = context;

    if (!mounted) return null;
    // ignore: use_build_context_synchronously
    return showDialog<Poster>(
      context: localContext,
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
                 // ignore: use_build_context_synchronously
                 if (mounted) Navigator.of(context).pop(createdPoster);
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
      _loadData(); // Recarrega os dados ao voltar da tela de detalhes
    });
  }

  Future<void> _calculateRoute() async {
    if (_savedPosters.length < 2) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('É necessário ter pelo menos 2 locais salvos para criar uma rota.')),
      );
      return;
    }

    setState(() {
      _isRouting = true;
      _polylines = {};
    });

    try {
      final points = _savedPosters.map((p) => LatLng(p.lat, p.lon)).toList();
      final routePoints = await _routingService.getRoute(points);
      
      if (mounted) {
        setState(() {
            _polylines.add(Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList(),
            color: Colors.blue,
            width: 5,
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao calcular a rota: $e')),
      );
    } finally {
      if (mounted) {
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
          : GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: widget.center,
                zoom: 14.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              markers: _markers,
              polylines: _polylines,
              onLongPress: (LatLng point) {
                 _showAddManualMarkerDialog(point).then((newPoster) {
                    if (newPoster != null) {
                      _navigateToDetails(newPoster);
                    }
                  });
              },
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
}
