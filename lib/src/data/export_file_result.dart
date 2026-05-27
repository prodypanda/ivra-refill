class ExportFileResult {
  const ExportFileResult({
    required this.fileName,
    required this.message,
    this.path,
  });

  final String fileName;
  final String message;
  final String? path;
}
