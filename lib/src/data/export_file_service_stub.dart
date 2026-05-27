import 'dart:typed_data';

import 'export_file_result.dart';

Future<ExportFileResult> saveBytes({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  throw UnsupportedError('File exports are not supported on this platform.');
}
