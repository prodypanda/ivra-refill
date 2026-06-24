import 'dart:typed_data';
import 'dart:ui' show Locale;

import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

import '../domain/app_enums.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';

class ReportExportService {
  Future<_PdfFonts>? _pdfFonts;

  String refillHistoryCsv(List<RefillEvent> events) {
    final rows = [
      [
        'event_id',
        'room_product_id',
        'type',
        'previous_refill_count',
        'new_refill_count',
        'occurred_at',
        'performed_by',
        'notes',
      ],
      for (final event in events)
        [
          event.id,
          event.roomProductId,
          event.type.value,
          event.previousRefillCount,
          event.newRefillCount,
          event.occurredAt.toIso8601String(),
          event.performedBy,
          event.notes ?? '',
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String suggestedOrdersCsv(List<SuggestedOrder> orders, {String languageCode = 'en'}) {
    final rows = [
      [
        'hotel_id',
        'product_sku',
        'product_name',
        'bottles_to_order',
        'bidons_to_order',
        'bottles_to_recycle',
      ],
      for (final order in orders)
        [
          order.hotelId,
          order.product.sku,
          order.product.label(languageCode),
          order.bottlesToOrder,
          order.bidonsToOrder,
          order.bottlesToRecycle,
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String inventoryCsv(List<InventoryItem> items, {String languageCode = 'en'}) {
    final rows = [
      [
        'hotel_id',
        'product_sku',
        'product_name',
        'full_bottles',
        'empty_bottles',
        'full_bidons',
        'open_bidons',
        'empty_bidons',
        'low_bottles',
        'low_bidons',
      ],
      for (final item in items)
        [
          item.hotelId,
          item.product.sku,
          item.product.label(languageCode),
          item.fullBottles,
          item.emptyBottles,
          item.fullBidons,
          item.openBidons,
          item.emptyBidons,
          item.lowBottles,
          item.lowBidons,
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String alertsCsv(List<AlertItem> alerts) {
    final rows = [
      [
        'alert_id',
        'hotel_id',
        'type',
        'severity',
        'title',
        'body',
        'created_at',
        'is_resolved',
      ],
      for (final alert in alerts)
        [
          alert.id,
          alert.hotelId,
          alert.type.value,
          alert.severity,
          alert.title,
          alert.body,
          alert.createdAt.toIso8601String(),
          alert.isResolved,
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  Future<Uint8List> refillHistoryPdf(
    List<RefillEvent> events, {
    String languageCode = 'en',
  }) {
    final l10n = AppLocalizations(Locale(languageCode));
    return _buildPdf(
      languageCode: languageCode,
      title: _refillHistoryTitle(languageCode),
      headers: [
        l10n.t('pdfHeaderType'),
        l10n.t('pdfHeaderPrevious'),
        l10n.t('pdfHeaderNew'),
        l10n.t('pdfHeaderOccurredAt'),
        l10n.t('pdfHeaderNotes'),
      ],
      data: [
        for (final event in events)
          [
            l10n.refillEventTypeLabel(event.type),
            '${event.previousRefillCount}',
            '${event.newRefillCount}',
            _formatDateTime(event.occurredAt),
            event.notes ?? '',
          ],
      ],
    );
  }

  Future<Uint8List> suggestedOrdersPdf(
    List<SuggestedOrder> orders, {
    String languageCode = 'en',
  }) {
    final l10n = AppLocalizations(Locale(languageCode));
    return _buildPdf(
      languageCode: languageCode,
      title: _suggestedOrdersTitle(languageCode),
      headers: [
        l10n.t('pdfHeaderProduct'),
        l10n.t('pdfHeader1LBottles'),
        l10n.t('pdfHeader5LBidons'),
        l10n.t('pdfHeaderRecycle'),
      ],
      data: [
        for (final order in orders)
          [
            order.product.label(languageCode),
            '${order.bottlesToOrder}',
            '${order.bidonsToOrder}',
            '${order.bottlesToRecycle}',
          ],
      ],
    );
  }

  Future<Uint8List> inventoryPdf(
    List<InventoryItem> items, {
    String languageCode = 'en',
  }) {
    final l10n = AppLocalizations(Locale(languageCode));
    return _buildPdf(
      languageCode: languageCode,
      title: _inventoryTitle(languageCode),
      headers: [
        l10n.t('pdfHeaderProduct'),
        l10n.t('pdfHeaderFullBottles'),
        l10n.t('pdfHeaderEmptyBottles'),
        l10n.t('pdfHeaderFullBidons'),
        l10n.t('pdfHeaderOpenBidons'),
        l10n.t('pdfHeaderEmptyBidons'),
      ],
      data: [
        for (final item in items)
          [
            item.product.label(languageCode),
            '${item.fullBottles}',
            '${item.emptyBottles}',
            '${item.fullBidons}',
            '${item.openBidons}',
            '${item.emptyBidons}',
          ],
      ],
    );
  }

  Future<Uint8List> alertsPdf(
    List<AlertItem> alerts, {
    String languageCode = 'en',
    List<Product> products = const [],
    List<RoomProduct> roomProducts = const [],
  }) {
    final l10n = AppLocalizations(Locale(languageCode));
    final productById = {for (final p in products) p.id: p};
    final roomProductById = {for (final rp in roomProducts) rp.id: rp};

    return _buildPdf(
      languageCode: languageCode,
      title: _openAlertsTitle(languageCode),
      headers: [
        l10n.t('pdfHeaderSeverity'),
        l10n.t('pdfHeaderType'),
        l10n.t('pdfHeaderTitle'),
        l10n.t('pdfHeaderCreatedAt'),
      ],
      data: [
        for (final alert in alerts)
          (() {
            Product? alertProduct;
            if (alert.productId != null) {
              alertProduct = productById[alert.productId];
            } else if (alert.roomProductId != null) {
              alertProduct = roomProductById[alert.roomProductId]?.product;
            }
            final (localizedTitle, _) = alert.localizedStrings(
              l10n,
              languageCode,
              alertProduct,
            );
            return [
              l10n.tParams('alertsSeverityLabel', {'severity': '${alert.severity}'}),
              l10n.alertTypeLabel(alert.type),
              localizedTitle,
              _formatDateTime(alert.createdAt),
            ];
          })(),
      ],
    );
  }

  Future<Uint8List> _buildPdf({
    required String languageCode,
    required String title,
    required List<String> headers,
    required List<List<String>> data,
  }) async {
    final fonts = await _loadPdfFonts();
    final textDirection =
        languageCode == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        textDirection: textDirection,
        theme: pw.ThemeData.withFont(
          base: fonts.regular,
          bold: fonts.bold,
        ),
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
          ),
        ],
      ),
    );
    return pdf.save();
  }

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

  String _suggestedOrdersTitle(String languageCode) {
    final l10n = AppLocalizations(Locale(languageCode));
    return l10n.t('pdfTitleSuggestedOrders');
  }

  String _inventoryTitle(String languageCode) {
    final l10n = AppLocalizations(Locale(languageCode));
    return l10n.t('pdfTitleInventorySnapshot');
  }

  String _refillHistoryTitle(String languageCode) {
    final l10n = AppLocalizations(Locale(languageCode));
    return l10n.t('pdfTitleRefillHistory');
  }

  String _openAlertsTitle(String languageCode) {
    final l10n = AppLocalizations(Locale(languageCode));
    return l10n.t('pdfTitleOpenAlerts');
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final date = [
      local.year.toString().padLeft(4, '0'),
      local.month.toString().padLeft(2, '0'),
      local.day.toString().padLeft(2, '0'),
    ].join('-');
    final time = [
      local.hour.toString().padLeft(2, '0'),
      local.minute.toString().padLeft(2, '0'),
    ].join(':');
    return '$date $time';
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
