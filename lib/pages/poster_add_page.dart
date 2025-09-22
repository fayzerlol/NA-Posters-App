import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:na_posters_app/helpers/database_helper.dart';
import 'package:na_posters_app/models/poster.dart';
import 'package:na_posters_app/services/overpass_service.dart';

class AddPosterPage extends StatefulWidget {
  final String groupId;

  const AddPosterPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _AddPosterPageState createState() => _AddPosterPageState();
}

class _AddPosterPageState extends State<AddPosterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  Position? _currentPosition;
  bool _isLoading = false;
  File? _image;
  final OverpassService _overpassService = OverpassService();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      final position = await Geolocator.getCurrentPosition();
      final address = await _overpassService.getAddressFromCoordinates(position.latitude, position.longitude);

      setState(() {
        _currentPosition = position;
        _addressController.text = address;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria de Fotos'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Câmera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addPoster() async {
    if ((_formKey.currentState?.validate() ?? false) && _currentPosition != null) {
      final newPoster = Poster(
        groupId: widget.groupId, // Using the String groupId from the widget
        poiId: 0, // Placeholder, as we might not need OSM POI ID anymore
        lat: _currentPosition!.latitude,
        lon: _currentPosition!.longitude,
        name: _nameController.text,
        amenity: 'poster_na', // Default amenity
        addedDate: DateTime.now(),
        description: _descriptionController.text,
        address: _addressController.text,
      );

      await DatabaseHelper.instance.addPoster(newPoster);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cartaz adicionado com sucesso!')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Novo Cartaz'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Local / Ponto de Referência',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição Adicional',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Endereço',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    if (_currentPosition != null)
                      Text(
                        'Localização: Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(5)}',
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),
                    _image == null
                        ? const Text(
                            'Nenhuma imagem selecionada.',
                            textAlign: TextAlign.center,
                          )
                        : Image.file(_image!),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showPicker(context),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Adicionar Foto'),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _addPoster,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text('Salvar Cartaz'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
