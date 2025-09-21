import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:na_posters_app/helpers/database_helper.dart';
import 'package:na_posters_app/models/maintenance_log.dart';
import 'package:na_posters_app/models/poster.dart';

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
      _logsFuture = DatabaseHelper.instance.readAllMaintenanceLogs(widget.poster.id!);
    });
  }

  void _showAddLogDialog() {
    final statusController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Manutenção'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: statusController,
                decoration: const InputDecoration(labelText: 'Status (Ex: OK, Rasgado, Ausente)'),
                autofocus: true,
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notas'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final newLog = MaintenanceLog(
                  posterId: widget.poster.id!,
                  timestamp: DateTime.now(),
                  status: statusController.text,
                  notes: notesController.text,
                );
                await DatabaseHelper.instance.createMaintenanceLog(newLog);
                Navigator.of(context).pop();
                _refreshLogs();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.poster.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.poster.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(widget.poster.description),
            const SizedBox(height: 24),
            Text(
              'Histórico de Manutenção',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<MaintenanceLog>>(
                future: _logsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nenhum registro de manutenção.'));
                  }
                  final logs = snapshot.data!;
                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return ListTile(
                        title: Text('${log.status} - ${DateFormat.yMd().add_jm().format(log.timestamp)}'),
                        subtitle: Text(log.notes),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog,
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Manutenção',
      ),
    );
  }
}
