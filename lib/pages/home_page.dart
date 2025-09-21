import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

import 'map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _radius = 3.0; // km
  double _maxSuggestions = 20;
  LatLng? _currentLocation;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Serviços de localização estão desativados.')));
      setState(() => _loadingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('As permissões de localização foram negadas.')));
        setState(() => _loadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'As permissões de localização foram permanentemente negadas, não podemos solicitar permissões.')));
      setState(() => _loadingLocation = false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _loadingLocation = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao obter a localização: $e')),
      );
      setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Definir Área de Busca'),
      ),
      body: _loadingLocation
          ? const Center(child: CircularProgressIndicator())
          : _currentLocation == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Não foi possível obter a localização. Verifique as permissões e tente novamente.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _determinePosition,
                        child: const Text('Tentar Novamente'),
                      )
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Ajuste os parâmetros da busca',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      Text('Raio da Busca: ${_radius.toStringAsFixed(1)} km'),
                      Slider(
                        value: _radius,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _radius.toStringAsFixed(1),
                        onChanged: (double value) {
                          setState(() {
                            _radius = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Text('Máximo de Sugestões: ${_maxSuggestions.toInt()}'),
                      Slider(
                        value: _maxSuggestions,
                        min: 10,
                        max: 100,
                        divisions: 9,
                        label: _maxSuggestions.toInt().toString(),
                        onChanged: (double value) {
                          setState(() {
                            _maxSuggestions = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: _currentLocation!,
                              initialZoom: 14.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              ),
                              CurrentLocationLayer(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          textStyle: const TextStyle(fontSize: 18)
                        ),
                        onPressed: () async {
                          final result = await Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => MapPage(
                              center: _currentLocation!,
                              radius: _radius,
                              maxSuggestions: _maxSuggestions.toInt(),
                            ),
                          ));
                           if (result == true) {
                            Navigator.of(context).pop(true); // Retorna true para PostersListPage
                          }
                        },
                        child: const Text('Buscar Locais'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
