import 'dart:math';
import 'dart:ui' show Locale;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/models.dart';
import '../l10n/app_localizations.dart';

class QrCodeLabelData {
  const QrCodeLabelData({
    required this.hotelName,
    required this.floor,
    required this.room,
    this.productName,
    this.productSku,
    required this.url,
  });

  final String hotelName;
  final String floor;
  final String room;
  final String? productName;
  final String? productSku;
  final String url;
}

class QrCodePdfService {
  Future<_PdfFonts>? _pdfFonts;

  Future<_PdfFonts> _loadPdfFonts() {
    return _pdfFonts ??= _loadPdfFontsFromAssets();
  }

  Future<_PdfFonts> _loadPdfFontsFromAssets() async {
    final regular = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
    final bold = await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf');
    return _PdfFonts(
      regular: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    );
  }

  /// Generates a print-ready PDF containing the grid of QR code labels.
  /// Standard sheet is A4 with 12 labels (3 columns x 4 rows) per page.
  Future<Uint8List> generateQrPdf({
    required List<QrCodeLabelData> labels,
    required String languageCode,
  }) async {
    final fonts = await _loadPdfFonts();
    final pdf = pw.Document();

    final l10n = AppLocalizations(Locale(languageCode));
    final scanInstructions = l10n.t('qrLabelScanInstructions') ?? 'Scan with IVRA app to refill or replace';
    final floorLabel = l10n.t('qrFloorRoom') != null ? '' : 'Floor'; // helper if custom text needed
    final roomLabel = l10n.t('qrFloorRoom') != null ? '' : 'Room';

    // Chunk labels into pages (12 labels per page max)
    final chunkedLabels = <List<QrCodeLabelData>>[];
    for (var i = 0; i < labels.length; i += 12) {
      chunkedLabels.add(labels.sublist(i, min(i + 12, labels.length)));
    }

    final textDirection = languageCode == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    for (final pageLabels in chunkedLabels) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          textDirection: textDirection,
          theme: pw.ThemeData.withFont(
            base: fonts.regular,
            bold: fonts.bold,
          ),
          build: (context) {
            // Build a 3x4 grid for A4 paper
            final rows = <pw.Widget>[];
            for (var rowIdx = 0; rowIdx < 4; rowIdx++) {
              final rowCells = <pw.Widget>[];
              for (var colIdx = 0; colIdx < 3; colIdx++) {
                final labelIdx = rowIdx * 3 + colIdx;
                if (labelIdx < pageLabels.length) {
                  final label = pageLabels[labelIdx];
                  rowCells.add(
                    pw.Expanded(
                      child: pw.Container(
                        margin: const pw.EdgeInsets.all(6),
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey400,
                            width: 1,
                          ),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        height: 165,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            // Header
                            pw.Text(
                              label.hotelName,
                              maxLines: 1,
                              overflow: pw.TextOverflow.clip,
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.SizedBox(height: 2),
                            // Room/Floor details
                            pw.Text(
                              l10n.tParams('qrFloorRoom', {'floor': label.floor, 'room': label.room}) ??
                                  '$floorLabel ${label.floor} \u2022 $roomLabel ${label.room}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.SizedBox(height: 4),

                            // QR Code
                            pw.Center(
                              child: pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: label.url,
                                width: 64,
                                height: 64,
                              ),
                            ),
                            pw.SizedBox(height: 4),

                            // Product details (if present)
                            if (label.productName != null) ...[
                              pw.Text(
                                label.productName!,
                                maxLines: 1,
                                overflow: pw.TextOverflow.clip,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                              if (label.productSku != null)
                                pw.Text(
                                  label.productSku!,
                                  style: const pw.TextStyle(
                                    fontSize: 7,
                                    color: PdfColors.grey600,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                            ] else ...[
                              // Spacer for general room label
                              pw.Text(
                                'ROOM GATEWAY',
                                style: pw.TextStyle(
                                  fontSize: 7,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.teal700,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ],
                            pw.SizedBox(height: 2),

                            // Scanning instructions
                            pw.Text(
                              scanInstructions,
                              style: const pw.TextStyle(
                                fontSize: 5.5,
                                color: PdfColors.grey500,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  // Empty cell placeholder
                  rowCells.add(pw.Expanded(child: pw.SizedBox()));
                }
              }
              rows.add(
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: rowCells,
                ),
              );
            }

            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: rows,
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}

class _PdfFonts {
  const _PdfFonts({
    required this.regular,
    required this.bold,
  });

  final pw.Font regular;
  final pw.Font bold;
}

final qrCodePdfServiceProvider = Provider<QrCodePdfService>((ref) {
  return QrCodePdfService();
});
