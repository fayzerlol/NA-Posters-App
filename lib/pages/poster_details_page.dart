import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:na_posters_app/helpers/database_helper.dart';
import 'package:na_posters_app/models/maintenance_log.dart';
import 'package:na_posters_app/pages/add_maintenance_log_page.dart';
import '../models/poster.dart';

class PosterDetailsPage extends StatefulWidget {
  final Poster poster;

  const PosterDetailsPage({super.key, required this.poster});

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

  void _navigateToAddMaintenanceLog() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddMaintenanceLogPage(posterId: widget.poster.id!),
      ),
    );

    if (result == true) {
      _refreshLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.poster.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPosterInfoCard(),
            const SizedBox(height: 24),
            Text(
              'Histórico de Manutenção',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildMaintenanceLogsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddMaintenanceLog,
        tooltip: 'Adicionar Manutenção',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPosterInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Detalhes do Local', style: Theme.of(context).textTheme.titleLarge), 
            const SizedBox(height: 16),
            Text('Nome: ${widget.poster.name}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Endereço: ${widget.poster.address}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Descrição: ${widget.poster.description}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Coordenadas: (${widget.poster.lat.toStringAsFixed(6)}, ${widget.poster.lon.toStringAsFixed(6)})', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Adicionado em: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.poster.addedDate)}', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceLogsList() {
    return FutureBuilder<List<MaintenanceLog>>(
      future: _logsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar o histórico: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Text(
                'Nenhum registro de manutenção encontrado. Adicione o primeiro!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
          );
        } else {
          final logs = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true, // Para funcionar dentro de SingleChildScrollView
            physics: const NeverScrollableScrollPhysics(), // Desabilita o scroll do ListView
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: Icon(_getIconForStatus(log.status)),
                  title: Text('${log.status} por ${log.responsibleName}'),
                  subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navegar para a página de detalhes do log (a ser criada)
                    print('Visualizar detalhes do log ${log.id}');
                  },
                ),
              );
            },
          );
        }
      },
    );
  }

  IconData _getIconForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'colado':
        return Icons.check_circle;
      case 'verificado':
        return Icons.visibility;
      case 'danificado':
        return Icons.warning;
      case 'removido':
        return Icons.delete_forever;
      default:
        return Icons.help_outline;
    }
  }
}
