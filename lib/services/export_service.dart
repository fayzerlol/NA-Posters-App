import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:na_posters_app/utils/database_helper.dart';
import 'package:path_provider/path_provider.dart';

class ExportService {
  Future<String?> exportData() async {
    try {
      final db = DatabaseHelper.instance;
      final posters = await db.getPosters();
      if (posters.isEmpty) {
        return null; // Nada para exportar
      }

      final archive = Archive();

      // Estrutura GeoJSON
      final geoJson = {
        'type': 'FeatureCollection',
        'features': [],
      };

      for (var poster in posters) {
        final logs = await db.getLogsForPoster(poster.id!);
        final logEntries = [];

        for (var log in logs) {
          String? imageFileName;
          if (log.imagePath != null && File(log.imagePath!).existsSync()) {
            final file = File(log.imagePath!);
            imageFileName = 'media/${Uri.file(log.imagePath!).pathSegments.last}';
            archive.addFile(ArchiveFile(imageFileName, file.lengthSync(), file.readAsBytesSync()));
          }

          String? signatureFileName;
          if (log.signaturePath != null && File(log.signaturePath!).existsSync()) {
            final file = File(log.signaturePath!);
            signatureFileName = 'media/${Uri.file(log.signaturePath!).pathSegments.last}';
            archive.addFile(ArchiveFile(signatureFileName, file.lengthSync(), file.readAsBytesSync()));
          }

          logEntries.add({
            'timestamp': log.timestamp.toIso8601String(), // Corrigido
            'status': log.status,
            'notes': log.notes,
            'image': imageFileName,
            'signature': signatureFileName,
          });
        }

        (geoJson['features'] as List).add({
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [poster.lon, poster.lat],
          },
          'properties': {
            'id': poster.id,
            'name': poster.name,
            'amenity': poster.amenity,
            'added_date': poster.addedDate.toIso8601String(),
            'maintenance_logs': logEntries,
          },
        });
      }

      // Adiciona o arquivo GeoJSON ao ZIP
      final geoJsonString = jsonEncode(geoJson);
      archive.addFile(ArchiveFile('posters.geojson', geoJsonString.length, utf8.encode(geoJsonString)));

      // Salva o arquivo ZIP
      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/na_posters_backup.zip';
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      for (var file in archive) {
        encoder.addArchiveFile(file); // Correção: addArchiveFile em vez de addFile
      }
      encoder.close();

      return zipPath;
    } catch (e) {
      print('Erro ao exportar dados: $e');
      return null;
    }
  }
}
