import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

import '../domain/models.dart';

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

  String suggestedOrdersCsv(List<SuggestedOrder> orders) {
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
          order.product.nameEn,
          order.bottlesToOrder,
          order.bidonsToOrder,
          order.bottlesToRecycle,
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String inventoryCsv(List<InventoryItem> items) {
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
          item.product.nameEn,
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
    return _buildPdf(
      languageCode: languageCode,
      title: _refillHistoryTitle(languageCode),
      headers: const [
        'Type',
        'Previous',
        'New',
        'Occurred at',
        'Notes',
      ],
      data: [
        for (final event in events)
          [
            event.type.value,
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
    return _buildPdf(
      languageCode: languageCode,
      title: _suggestedOrdersTitle(languageCode),
      headers: const [
        'Product',
        '1L bottles',
        '5L bidons',
        'Recycle',
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
    return _buildPdf(
      languageCode: languageCode,
      title: _inventoryTitle(languageCode),
      headers: const [
        'Product',
        'Full bottles',
        'Empty bottles',
        'Full bidons',
        'Open bidons',
        'Empty bidons',
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
  }) {
    return _buildPdf(
      languageCode: languageCode,
      title: _openAlertsTitle(languageCode),
      headers: const [
        'Severity',
        'Type',
        'Title',
        'Created at',
      ],
      data: [
        for (final alert in alerts)
          [
            '${alert.severity}',
            alert.type.value,
            alert.title,
            _formatDateTime(alert.createdAt),
          ],
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
    return switch (languageCode) {
      'fr' => 'Commandes suggerees Ivra',
      'ar' => 'طلبات Ivra المقترحة',
      _ => 'Ivra Suggested Orders',
    };
  }

  String _inventoryTitle(String languageCode) {
    return switch (languageCode) {
      'fr' => 'Inventaire Ivra',
      'ar' => 'مخزون Ivra',
      _ => 'Ivra Inventory Snapshot',
    };
  }

  String _refillHistoryTitle(String languageCode) {
    return switch (languageCode) {
      'fr' => 'Historique de recharge Ivra',
      'ar' => 'سجل تعبئة Ivra',
      _ => 'Ivra Refill History',
    };
  }

  String _openAlertsTitle(String languageCode) {
    return switch (languageCode) {
      'fr' => 'Alertes ouvertes Ivra',
      'ar' => 'تنبيهات Ivra المفتوحة',
      _ => 'Ivra Open Alerts',
    };
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
