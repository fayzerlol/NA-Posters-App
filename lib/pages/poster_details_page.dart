import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:na_posters_app/models/maintenance_log.dart';
import 'package:na_posters_app/models/poster.dart';
import 'package:na_posters_app/utils/database_helper.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PosterDetailsPage extends StatefulWidget {
  final Poster poster;

  const PosterDetailsPage({Key? key, required this.poster}) : super(key: key);

  @override
  _PosterDetailsPageState createState() => _PosterDetailsPageState();
}

class _PosterDetailsPageState extends State<PosterDetailsPage> {
  late Future<List<MaintenanceLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      _logsFuture = DatabaseHelper.instance.getLogsForPoster(widget.poster.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.poster.name)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPosterInfoCard(),
          SizedBox(height: 20),
          _buildAddLogCard(),
          SizedBox(height: 20),
          _buildLogsHistory(),
        ],
      ),
    );
  }

  Widget _buildPosterInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.poster.name, style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(child: Text('Lat: ${widget.poster.lat.toStringAsFixed(5)}, Lon: ${widget.poster.lon.toStringAsFixed(5)}')),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.business, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text('Tipo: ${widget.poster.amenity}'),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text('Adicionado em: ${DateFormat.yMd().format(widget.poster.addedDate)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddLogCard() {
    return Card(
      elevation: 4,
      child: ExpansionTile(
        title: Text('Adicionar Novo Registro', style: Theme.of(context).textTheme.titleLarge),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AddLogForm(
              posterId: widget.poster.id!,
              onLogAdded: _refreshLogs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Histórico de Manutenção', style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 10),
        FutureBuilder<List<MaintenanceLog>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Nenhum registro de manutenção encontrado.'));
            }
            final logs = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${log.status} - ${DateFormat.yMd().add_jm().format(log.timestamp)}', style: Theme.of(context).textTheme.titleMedium),
                        SizedBox(height: 4),
                        Text(log.notes),
                        if (log.imagePath != null || log.signaturePath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                if (log.imagePath != null)
                                  GestureDetector(
                                    onTap: () => _showFullScreenImage(context, log.imagePath!),
                                    child: Image.file(File(log.imagePath!), height: 50, width: 50, fit: BoxFit.cover),
                                  ),
                                if (log.imagePath != null && log.signaturePath != null)
                                  SizedBox(width: 10),
                                if (log.signaturePath != null)
                                  GestureDetector(
                                    onTap: () => _showFullScreenImage(context, log.signaturePath!),
                                    child: Image.file(File(log.signaturePath!), height: 50, width: 100, fit: BoxFit.contain),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Image.file(File(path))),
        ),
      ),
    );
  }
}

class AddLogForm extends StatefulWidget {
  final int posterId;
  final VoidCallback onLogAdded;

  const AddLogForm({Key? key, required this.posterId, required this.onLogAdded}) : super(key: key);

  @override
  _AddLogFormState createState() => _AddLogFormState();
}

class _AddLogFormState extends State<AddLogForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String _selectedStatus = 'OK';
  XFile? _imageFile;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.grey[200],
  );

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<String?> _saveSignature() async {
    if (_signatureController.isNotEmpty) {
      final signature = await _signatureController.toPngBytes();
      if (signature != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'sig_${DateTime.now().millisecondsSinceEpoch}.png';
        final path = '${directory.path}/$fileName';
        final file = File(path);
        await file.writeAsBytes(signature);
        return path;
      }
    }
    return null;
  }

  void _addLog() async {
    if (_formKey.currentState!.validate()) {
      String? imagePath;
      if (_imageFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imagePath = '${directory.path}/$fileName';
        await _imageFile!.saveTo(imagePath);
      }

      final signaturePath = await _saveSignature();

      final newLog = MaintenanceLog(
        posterId: widget.posterId,
        timestamp: DateTime.now(),
        status: _selectedStatus,
        notes: _notesController.text,
        imagePath: imagePath,
        signaturePath: signaturePath,
      );

      await DatabaseHelper.instance.addLog(newLog);

      _notesController.clear();
      _signatureController.clear();
      setState(() {
        _imageFile = null;
      });

      widget.onLogAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            items: ['OK', 'Rasgado', 'Removido'].map((status) {
              return DropdownMenuItem(value: status, child: Text(status));
            }).toList(),
            onChanged: (value) => setState(() => _selectedStatus = value!),
            decoration: InputDecoration(labelText: 'Status'),
          ),
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(labelText: 'Notas'),
            validator: (value) => value!.isEmpty ? 'Por favor, adicione uma nota' : null,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: Icon(Icons.camera_alt), label: Text('Câmera')),
              TextButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: Icon(Icons.photo_library), label: Text('Galeria')),
            ],
          ),
          if (_imageFile != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Image.file(File(_imageFile!.path), height: 100),
            ),
          SizedBox(height: 20),
          Text('Assinatura:', style: Theme.of(context).textTheme.bodyMedium),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: Signature(controller: _signatureController, height: 100, backgroundColor: Colors.grey[200]!),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => _signatureController.clear(), child: Text('Limpar')),
          ),
          ElevatedButton(onPressed: _addLog, child: Text('Adicionar Registro')),
        ],
      ),
    );
  }
}
