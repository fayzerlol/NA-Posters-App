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
    // ... (código de permissão de localização - sem alterações)
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
              'As permissões de localização foram permanentemente negadas.')));
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
              ? _buildLocationErrorWidget()
              : _buildContent(),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: <Widget>[
        Card(
          margin: EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Raio da Busca: ${_radius.toStringAsFixed(1)} km', style: Theme.of(context).textTheme.titleMedium),
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
                SizedBox(height: 16),
                Text('Máximo de Sugestões: ${_maxSuggestions.toInt()}', style: Theme.of(context).textTheme.titleMedium),
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
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _currentLocation!,
                  initialZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _currentLocation!,
                        radius: _radius * 1000, // Raio em metros
                        useRadiusInMeter: true,
                        color: Colors.blue.withOpacity(0.1),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  CurrentLocationLayer(),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLocationErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Não foi possível obter a localização. Verifique as permissões e tente novamente.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _determinePosition,
              icon: Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    if (_loadingLocation || _currentLocation == null) {
      return SizedBox.shrink(); // Não mostra o botão se não houver localização
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 50), // Botão largo
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    );
  }
}
