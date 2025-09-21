import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:na_posters_app/models/poi.dart';
import 'package:na_posters_app/models/poster.dart';
import 'package:na_posters_app/utils/database_helper.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<Poi> _pois = [];
  Poi? _selectedPoi;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(_currentLocation!, 15.0);
      _fetchPois(_currentLocation!);
    });
  }

  Future<void> _fetchPois(LatLng location) async {
    final query = '''
      [out:json];
      node(around:1000,${location.latitude},${location.longitude})["amenity"="place_of_worship"];
      out body;
    ''';
    final response = await http.post(
      Uri.parse('https://overpass-api.de/api/interpreter'),
      body: query,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _pois = (data['elements'] as List).map((e) => Poi.fromJson(e)).toList();
      });
    }
  }

  void _onPoiSelected(Poi poi) {
    setState(() {
      _selectedPoi = poi;
    });
  }

  void _addPoster() async {
    if (_selectedPoi != null) {
      final newPoster = Poster.fromPoi(_selectedPoi!);
      await DatabaseHelper.instance.addPoster(newPoster);
      Navigator.of(context).pop(true); // Retorna true para indicar que um poster foi adicionado
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selecionar Local no Mapa'),
        actions: [
          if (_selectedPoi != null)
            IconButton(icon: Icon(Icons.check), onPressed: _addPoster),
        ],
      ),
      body: _currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(center: _currentLocation!, zoom: 15.0),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: _pois.map((poi) {
                    return Marker(
                      width: 80.0,
                      height: 80.0,
                      point: LatLng(poi.lat, poi.lon),
                      builder: (ctx) => GestureDetector(
                        onTap: () => _onPoiSelected(poi),
                        child: Column(
                          children: [
                            Icon(Icons.location_pin,
                                color: _selectedPoi?.id == poi.id ? Colors.blue : Colors.red),
                            Text(poi.name, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}
