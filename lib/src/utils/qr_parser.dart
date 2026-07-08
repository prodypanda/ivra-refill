class QrParser {
  const QrParser._();

  /// Extracts a product SKU or room identifier from various QR code formats.
  ///
  /// Supports:
  /// - IVRA website URLs: https://ivra-cosmetics.com/QR/IVR-TNSHA-500 -> IVR-TNSHA-500
  /// - Product prefixes: product:IVR-TNSHA-500 -> IVR-TNSHA-500
  /// - Raw strings: IVR-TNSHA-500 -> IVR-TNSHA-500
  ///
  /// Does NOT modify `room:` prefixed codes so they can be handled separately.
  static String parsePayload(String rawCode) {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) return '';

    // If it's explicitly a room code, return as-is
    if (trimmed.startsWith('room:')) {
      return trimmed;
    }

    // Check for web URL format containing /QR/<sku>
    final urlMatch = RegExp(r'/QR/([^/?]+)', caseSensitive: false).firstMatch(trimmed);
    if (urlMatch != null) {
      return urlMatch.group(1)!;
    }

    // Check for product: prefix
    if (trimmed.startsWith('product:')) {
      return trimmed.split(':')[1];
    }

    return trimmed;
  }
}
