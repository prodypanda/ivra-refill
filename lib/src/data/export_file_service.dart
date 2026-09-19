import 'dart:typed_data';

import 'package:ivra_refill/src/data/export_file_result.dart';
import 'package:ivra_refill/src/data/export_file_service_stub.dart'
    if (dart.library.html) 'export_file_service_web.dart'
    if (dart.library.io) 'export_file_service_io.dart' as platform;

/// A class representing ExportFileService.
///
/// Provides data structure and operations for ExportFileService.
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
