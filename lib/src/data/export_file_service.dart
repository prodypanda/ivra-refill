import 'dart:typed_data';

import 'export_file_result.dart';
import 'export_file_service_stub.dart'
    if (dart.library.html) 'export_file_service_web.dart'
    if (dart.library.io) 'export_file_service_io.dart' as platform;

class ExportFileService {
  Future<ExportFileResult> saveBytes({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) {
    return platform.saveBytes(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
  }
}
