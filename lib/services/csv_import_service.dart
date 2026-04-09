import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../models/card.dart';

class CsvImportService {
  /// Abre el selector de archivos del sistema y retorna las cards parseadas.
  /// Espera un CSV con encabezado: front,back (mínimo dos columnas).
  Future<List<FlashCard>> pickAndParseCsv({required int deckId}) async {
    // 1. Abrir selector nativo (solo .csv)
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return [];

    final path = result.files.single.path;
    if (path == null) return [];

    // 2. Leer contenido del archivo
    final file = File(path);
    final rawContent = await file.readAsString();

    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(rawContent);

    if (rows.isEmpty) return [];

    // 4. Construir cards directamente por posición (sin encabezado)
    final cards = <FlashCard>[];
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];

      if (row.length < 2) continue;

      final front = row[0].toString().trim();
      final back = row[1].toString().trim();

      if (front.isEmpty || back.isEmpty) continue;

      cards.add(FlashCard(deckId: deckId, front: front, back: back));
    }

    return cards;
  }
}
