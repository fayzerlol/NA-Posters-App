import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:na_posters_app/helpers/database_helper.dart'; // Corrected import path
import 'package:path_provider/path_provider.dart';

class ExportService {
  Future<String?> exportData() async {
    try {
      final db = DatabaseHelper.instance;
      final posters = await db.getPosters();
      if (posters.isEmpty) {
        return null; // Nothing to export
      }

      final archive = Archive();

      // GeoJSON structure
      final geoJson = {
        'type': 'FeatureCollection',
        'features': [],
      };

      for (var poster in posters) {
        // Use the correct method to get logs for a poster
        final logs = await db.readAllMaintenanceLogs(poster.id!);
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
            'timestamp': log.timestamp.toIso8601String(),
            'status': log.status,
            'notes': log.notes,
            'responsible_name': log.responsibleName, // Add responsible name
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
            'group_id': poster.groupId, // Add group_id
            'poi_id': poster.poiId,     // Add poi_id
            'name': poster.name,
            'amenity': poster.amenity,
            'added_date': poster.addedDate.toIso8601String(),
            'description': poster.description, // Add description
            'maintenance_logs': logEntries,
          },
        });
      }

      // Add the GeoJSON file to the ZIP
      final geoJsonString = jsonEncode(geoJson);
      archive.addFile(ArchiveFile('posters.geojson', utf8.encode(geoJsonString).length, utf8.encode(geoJsonString)));

      // Save the ZIP file
      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/na_posters_backup.zip';
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      for (var file in archive) {
        encoder.addArchiveFile(file); // Use addArchiveFile
      }
      encoder.close();

      return zipPath;
    } catch (e) {
      debugPrint('Error exporting data: $e');
      return null;
    }
  }
}
