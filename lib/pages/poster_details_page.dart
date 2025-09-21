import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:na_posters_app/models/maintenance_log.dart';
import 'package:na_posters_app/models/poster.dart';
import 'package:na_posters_app/utils/database_helper.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart'; // Importa para formatação de data

class PosterDetailsPage extends StatefulWidget {
  final Poster poster;

  const PosterDetailsPage({Key? key, required this.poster}) : super(key: key);

  @override
  _PosterDetailsPageState createState() => _PosterDetailsPageState();
}

class _PosterDetailsPageState extends State<PosterDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String _selectedStatus = 'OK';
  XFile? _imageFile;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  late Future<List<MaintenanceLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = DatabaseHelper.instance.getLogsForPoster(widget.poster.id!);
  }

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
        posterId: widget.poster.id!,
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
        _logsFuture = DatabaseHelper.instance.getLogsForPoster(widget.poster.id!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.poster.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Localização: (${widget.poster.lat}, ${widget.poster.lon})'),
            Text(
              'Adicionado em: ${DateFormat.yMd().add_jm().format(widget.poster.addedDate)}',
            ),
            SizedBox(height: 20),
            Text(
              'Novo Registro de Manutenção',
              style: Theme.of(context).textTheme.titleLarge, // Alterado de headline6
            ),
            Form(
              key: _formKey,
              child: Column(
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
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: Icon(Icons.camera_alt),
                        label: Text('Câmera'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: Icon(Icons.photo_library),
                        label: Text('Galeria'),
                      ),
                    ],
                  ),
                  if (_imageFile != null) ...[
                    SizedBox(height: 10),
                    Image.file(File(_imageFile!.path), height: 100),
                  ],
                  SizedBox(height: 10),
                  Text('Assinatura:'),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                    child: Signature(
                      controller: _signatureController,
                      height: 150,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _signatureController.clear(),
                        child: Text('Limpar Assinatura'),
                      ),
                    ],
                  ),
                  ElevatedButton(onPressed: _addLog, child: Text('Adicionar Registro')),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Histórico de Manutenção',
              style: Theme.of(context).textTheme.titleLarge, // Alterado de headline6
            ),
            Expanded(
              child: FutureBuilder<List<MaintenanceLog>>(
                future: _logsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('Nenhum registro de manutenção encontrado.');
                  }
                  final logs = snapshot.data!;
                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            '${log.status} - ${DateFormat.yMd().add_jm().format(log.timestamp)}',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.notes),
                              if (log.imagePath != null) ...[
                                SizedBox(height: 8),
                                Image.file(File(log.imagePath!), height: 100),
                              ],
                              if (log.signaturePath != null) ...[
                                SizedBox(height: 8),
                                Text('Assinatura:'),
                                Image.file(File(log.signaturePath!), height: 50),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
