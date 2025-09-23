import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:na_posters_app/helpers/database_helper.dart';
import 'package:na_posters_app/models/maintenance_log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:path/path.dart' as p;

class AddMaintenanceLogPage extends StatefulWidget {
  final int posterId;

  const AddMaintenanceLogPage({super.key, required this.posterId});

  @override
  AddMaintenanceLogPageState createState() => AddMaintenanceLogPageState();
}

class AddMaintenanceLogPageState extends State<AddMaintenanceLogPage> {
  final _formKey = GlobalKey<FormState>();
  final _responsibleNameController = TextEditingController();
  final _notesController = TextEditingController();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  String _selectedStatus = 'Colado';
  final List<String> _statusOptions = ['Colado', 'Verificado', 'Danificado', 'Removido'];
  XFile? _imageFile;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
      setState(() {
        _imageFile = pickedFile;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao capturar imagem: $e')),
      );
    }
  }

  Future<String?> _saveFile(Uint8List data, String extension) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final filePath = p.join(directory.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(data);
    return filePath;
  }

  Future<void> _saveLog() async {
    if (_formKey.currentState!.validate()) {
      if (_signatureController.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A assinatura do responsável é obrigatória.')),
        );
        return;
      }

      setState(() { _isSaving = true; });

      try {
        String? imagePath;
        if (_imageFile != null) {
          final imageBytes = await _imageFile!.readAsBytes();
          imagePath = await _saveFile(imageBytes, 'jpg');
        }

        String? signaturePath;
        final signatureBytes = await _signatureController.toPngBytes();
        if (signatureBytes != null) {
          signaturePath = await _saveFile(signatureBytes, 'png');
        }

        final newLog = MaintenanceLog(
          posterId: widget.posterId,
          timestamp: DateTime.now(),
          status: _selectedStatus,
          notes: _notesController.text,
          responsibleName: _responsibleNameController.text,
          imagePath: imagePath,
          signaturePath: signaturePath,
        );

        await DatabaseHelper.instance.createMaintenanceLog(newLog);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro de manutenção salvo com sucesso!')),
        );
        Navigator.of(context).pop(true); // Retorna true para indicar sucesso
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao salvar o registro: $e')),
        );
      } finally {
        if (mounted) {
          setState(() { _isSaving = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Manutenção'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildStatusDropdown(),
              const SizedBox(height: 16),
              _buildResponsibleNameField(),
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 24),
              _buildSignaturePad(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _imageFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                )
              : const Center(child: Text('Nenhuma imagem selecionada')),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Tirar Foto do Cartaz'),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedStatus,
      items: _statusOptions.map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(status),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _selectedStatus = newValue;
          });
        }
      },
      decoration: const InputDecoration(
        labelText: 'Status da Manutenção',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildResponsibleNameField() {
    return TextFormField(
      controller: _responsibleNameController,
      decoration: const InputDecoration(
        labelText: 'Nome do Responsável',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'O nome do responsável é obrigatório';
        }
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notas Adicionais',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
    );
  }

  Widget _buildSignaturePad() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Assinatura do Responsável:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Signature(
            controller: _signatureController,
            height: 150,
            backgroundColor: Colors.grey[200]!,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => _signatureController.clear(),
              child: const Text('Limpar'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _isSaving ? null : _saveLog,
      icon: _isSaving
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.save),
      label: Text(_isSaving ? 'Salvando...' : 'Salvar Manutenção'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
