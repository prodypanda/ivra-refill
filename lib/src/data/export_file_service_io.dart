import 'dart:io';
import 'dart:typed_data';

import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'export_file_result.dart';

final _invalidFilenameCharsRegex = RegExp(r'[<>:"/\\|?*]');

/// Hands the exported bytes off to the OS share sheet on mobile/desktop.
///
/// Writing directly to `Directory.systemTemp` (the previous behaviour) on
/// Android landed exports inside the app's private cache
/// (`/data/data/com.ivra.refill/cache/`), where users could not browse to
/// the file or open it from their downloads/file manager. Using the
/// platform share sheet via `printing` (for PDFs) and `share_plus`
/// (for other types) lets the user route the export to Drive, email,
/// Downloads, or any other handler they have installed.
Future<ExportFileResult> saveBytes({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final safeName = fileName.replaceAll(_invalidFilenameCharsRegex, '_');

  if (mimeType == 'application/pdf' ||
      safeName.toLowerCase().endsWith('.pdf')) {
    await Printing.sharePdf(bytes: bytes, filename: safeName);
    return ExportFileResult(
      fileName: safeName,
      path: null,
      message: '$safeName ready to share',
    );
  }

  // share_plus requires an on-disk file path. Stage the bytes in the
  // app's cache directory; the file is short-lived because the share
  // sheet copies/forwards the data immediately.
  final stagingDir = Directory(
    '${Directory.systemTemp.path}${Platform.pathSeparator}ivra_exports',
  );
  if (!stagingDir.existsSync()) {
    stagingDir.createSync(recursive: true);
  }
  final stagedFile = File(
    '${stagingDir.path}${Platform.pathSeparator}$safeName',
  );
  await stagedFile.writeAsBytes(bytes, flush: true);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(stagedFile.path, mimeType: mimeType, name: safeName)],
      subject: safeName,
    ),
  );

  return ExportFileResult(
    fileName: safeName,
    path: null,
    message: '$safeName ready to share',
  );
}
