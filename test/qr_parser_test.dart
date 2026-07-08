import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/utils/qr_parser.dart';

void main() {
  group('QrParser Tests', () {
    test('should extract SKU from full IVRA URL', () {
      const url = 'https://ivra-cosmetics.com/QR/IVR-TNSHA-500';
      expect(QrParser.parsePayload(url), 'IVR-TNSHA-500');
    });

    test('should extract SKU from lowercase url path', () {
      const url = 'https://ivra-cosmetics.com/qr/IVR-TNSHA-500?source=scanner';
      expect(QrParser.parsePayload(url), 'IVR-TNSHA-500');
    });

    test('should extract SKU from product prefix', () {
      const productCode = 'product:IVR-TNSHA-500';
      expect(QrParser.parsePayload(productCode), 'IVR-TNSHA-500');
    });

    test('should return raw code if no product prefix or matching url', () {
      const rawSku = 'IVR-TNSHA-500';
      expect(QrParser.parsePayload(rawSku), 'IVR-TNSHA-500');
    });

    test('should return room code as-is', () {
      const roomCode = 'room:hotel_123:room_456';
      expect(QrParser.parsePayload(roomCode), 'room:hotel_123:room_456');
    });

    test('should return empty string on empty input', () {
      expect(QrParser.parsePayload('   '), '');
    });
  });
}
