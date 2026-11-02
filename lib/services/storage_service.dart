import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/expense.dart';

class StorageService {
  const StorageService();

  /// Directory where exported CSV files are written
  /// (`<app documents>/spendwise_exports`).
  Future<Directory> exportDirectory() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${docs.path}${ Platform.pathSeparator }spendwise_exports');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Exports [expenses] to a CSV file with a stable header row.
  /// Returns the absolute file path on success; throws on IO errors so
  /// callers can surface a failure snackbar.
  Future<String> exportToCsv(List<Expense> expenses) async {
    final Directory dir = await exportDirectory();
    final DateTime now = DateTime.now();
    final String stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final String path = '${dir.path}${Platform.pathSeparator}spendwise_expenses_$stamp.csv';

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Id,Type,Amount,Category,Date,Time,Payment Method,Description');
    for (final Expense e in expenses) {
      buffer.writeln(<String>[
        '${e.id ?? ''}',
        e.type.key,
        e.amount.toStringAsFixed(2),
        _csvField(e.category),
        _ddMmYyyy(e.date),
        _hhMm(e.date),
        _csvField(e.paymentMethod),
        _csvField(e.description ?? ''),
      ].join(','));
    }

    final File file = File(path);
    await file.writeAsString(buffer.toString(), flush: true);
    return path;
  }

  /// Escapes a value for RFC-4180-style CSV output.
  String _csvField(String value) {
    final bool needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final String escaped = value.replaceAll('"', '""');
    if (needsQuotes) return '"$escaped"';
    return escaped;
  }

  String _ddMmYyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _hhMm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
