import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// IO implementation: writes [content] as [filename] under
/// `<app documents>/spendwise_exports` and returns the absolute path.
Future<String> saveTextFile(String filename, String content) async {
  final Directory docs = await getApplicationDocumentsDirectory();
  final Directory dir =
      Directory('${docs.path}${Platform.pathSeparator}spendwise_exports');
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  final File file = File('${dir.path}${Platform.pathSeparator}$filename');
  await file.writeAsString(content, flush: true);
  return file.path;
}
