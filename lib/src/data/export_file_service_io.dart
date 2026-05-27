import 'dart:io';
import 'dart:typed_data';

import 'export_file_result.dart';

Future<ExportFileResult> saveBytes({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final exportDirectory = Directory(
    '${Directory.systemTemp.path}${Platform.pathSeparator}ivra_exports',
  );
  if (!exportDirectory.existsSync()) {
    exportDirectory.createSync(recursive: true);
  }

  final safeName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  final file = File(
    '${exportDirectory.path}${Platform.pathSeparator}$safeName',
  );
  await file.writeAsBytes(bytes, flush: true);

  return ExportFileResult(
    fileName: safeName,
    path: file.path,
    message: 'Saved $safeName to ${file.path}',
  );
}
