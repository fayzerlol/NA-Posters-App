import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:na_posters_app/helpers/database_helper.dart';
import 'package:na_posters_app/models/group.dart';
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
  bool _loadingGroups = true;

  List<Group> _groups = [];
  Group? _selectedGroup;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Start both initialization tasks concurrently
    _initializePage();
  }

  Future<void> _initializePage() async {
    // Load groups and location in parallel
    await Future.wait([
      _determinePosition(),
      _loadGroups(),
    ]);
  }

  Future<void> _loadGroups() async {
    // Ensure the loading state is set at the beginning
    if (mounted) {
      setState(() { _loadingGroups = true; });
    }
    
    try {
      final groups = await DatabaseHelper.instance.readAllGroups();
      if (!mounted) return; // Check if the widget is still in the tree

      setState(() {
        _groups = groups;
        if (_groups.isNotEmpty) {
          _selectedGroup = _groups.first;
        }
        _loadingGroups = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar os grupos: $e')),
      );
      setState(() { _loadingGroups = false; });
    }
  }

  Future<void> _determinePosition() async {
    if (mounted) {
      setState(() => _loadingLocation = true);
    }

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Serviços de localização estão desativados.')));
      setState(() => _loadingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;

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
      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao obter a localização: $e')),
      );
      setState(() => _loadingLocation = false);
    }
  }
  
  void _showAddGroupDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Novo Grupo'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Nome do Grupo'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await DatabaseHelper.instance.createGroup(Group(name: nameController.text));
                Navigator.of(context).pop();
                _loadGroups(); // Refresh the list of groups
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _navigateToMapPage() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => MapPage(
          group: _selectedGroup!,
          center: _currentLocation!,
          radius: _radius,
          maxSuggestions: _maxSuggestions.toInt(),
        ),
      ));
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
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGroupSelector(),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
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
                      // Fix for the OSM User-Agent warning
                      userAgentPackageName: 'com.example.na_posters_app',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _currentLocation!,
                          radius: _radius * 1000, // Radius in meters
                          useRadiusInMeter: true,
                          color: Colors.blue.withAlpha(26),
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGroupSelector() {
    if (_loadingGroups) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groups.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Text('Nenhum grupo encontrado.'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showAddGroupDialog,
              icon: const Icon(Icons.add), 
              label: const Text('Criar Grupo'),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<Group>(
            // Using a key to reset the dropdown when groups change
            key: ValueKey(_groups.hashCode),
            value: _selectedGroup,
            items: _groups.map((group) {
              return DropdownMenuItem<Group>(
                value: group,
                child: Text(group.name),
              );
            }).toList(),
            onChanged: (Group? newValue) {
              setState(() {
                _selectedGroup = newValue;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Grupo de NA',
              border: OutlineInputBorder(),
            ),
             validator: (value) => value == null ? 'Selecione um grupo' : null,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _showAddGroupDialog,
          tooltip: 'Adicionar Novo Grupo',
        ),
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
              onPressed: _initializePage, // Retry the whole initialization
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    if (_loadingLocation || _currentLocation == null) {
      return const SizedBox.shrink(); // Don't show button if there is no location
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50), 
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: _selectedGroup != null ? _navigateToMapPage : null,
        child: const Text('Buscar Locais'),
      ),
    );
  }
}
