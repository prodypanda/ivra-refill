import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/domain/models.dart';

void main() {
  group('Domain Models Tests', () {
    test('Product constructor and copyWith', () {
      final product = Product(
        id: 'p-1',
        sku: 'SKU123',
        nameEn: 'Shampoo',
        nameFr: 'Shampooing',
        nameAr: 'شامبو',
        nameIt: 'Shampoo',
        maxRefillCount: 5,
        maxBottleAgeDays: 30,
        lowBottleThreshold: 2,
        lowBidonThreshold: 1,
      );

      expect(product.id, 'p-1');
      expect(product.bottleVolumeMl, 1000); // default
      expect(product.bidonVolumeMl, 5000); // default
      expect(product.bottleType, BottleType.withPump); // default

      final copied = product.copyWith(bottleVolumeMl: 2000, maxRefillCount: 10);
      expect(copied.id, 'p-1');
      expect(copied.bottleVolumeMl, 2000);
      expect(copied.maxRefillCount, 10);
    });

    test('Hotel constructor and copyWith', () {
      final hotel = Hotel(
        id: 'h-1',
        name: 'Grand Hotel',
        city: 'Paris',
        country: 'France',
        contactName: 'Manager',
        email: 'mgr@example.com',
        phone: '12345',
        roomCount: 100,
        pendingEdits: 0,
      );

      expect(hotel.id, 'h-1');
      expect(hotel.legalName, ''); // default
      expect(hotel.expressQrEnabled, false); // default

      final copied = hotel.copyWith(expressQrEnabled: true, pendingEdits: 5);
      expect(copied.expressQrEnabled, true);
      expect(copied.pendingEdits, 5);
    });

    test('RoomInfo constructor', () {
      final roomInfo = RoomInfo(
        id: 'r-1',
        hotelId: 'h-1',
        floorId: 'f-1',
        roomNumber: '101',
        floorNumber: 1,
        productCount: 3,
      );

      expect(roomInfo.id, 'r-1');
      expect(roomInfo.roomNumber, '101');
      expect(roomInfo.productCount, 3);
    });

    test('RefillEvent constructor', () {
      final now = DateTime.now();
      final event = RefillEvent(
        id: 'e-1',
        roomProductId: 'rp-1',
        type: RefillEventType.refill,
        previousRefillCount: 0,
        newRefillCount: 1,
        occurredAt: now,
        performedBy: 'u-1',
      );

      expect(event.id, 'e-1');
      expect(event.type, RefillEventType.refill);
      expect(event.notes, null);
    });

    test('AlertItem constructor and copyWith', () {
      final now = DateTime.now();
      final alert = AlertItem(
        id: 'a-1',
        hotelId: 'h-1',
        type: AlertType.bottleAgeLimit,
        severity: 2,
        title: 'Alert',
        body: 'Body',
        createdAt: now,
        isResolved: false,
      );

      expect(alert.id, 'a-1');
      expect(alert.isResolved, false);

      final copied = alert.copyWith(isResolved: true, severity: 3);
      expect(copied.isResolved, true);
      expect(copied.severity, 3);
    });


    test('Product fromMap', () {
      final map = {
        'id': 'p-1',
        'sku': 'SKU123',
        'name_en': 'Shampoo',
        'name_fr': 'Shampooing',
        'name_ar': 'شامبو',
        'name_it': 'Shampoo',
        'max_refill_count': 5,
        'max_bottle_age_days': 30,
        'low_bottle_threshold': 2,
        'low_bidon_threshold': 1,
      };

      final deserialized = Product.fromMap(map);
      expect(deserialized.id, 'p-1');
      expect(deserialized.sku, 'SKU123');
      expect(deserialized.nameEn, 'Shampoo');
    });

    test('Hotel fromMap', () {
      final map = {
        'id': 'h-1',
        'name': 'Grand Hotel',
        'city': 'Paris',
        'country': 'France',
        'contact_name': 'Manager',
        'email': 'mgr@example.com',
        'phone': '12345',
        'room_count': 100,
        'pending_edits': 0,
      };

      final deserialized = Hotel.fromMap(map);
      expect(deserialized.id, 'h-1');
      expect(deserialized.name, 'Grand Hotel');
      expect(deserialized.city, 'Paris');
    });

    test('RoomInfo fromMap', () {
      final map = {
        'id': 'r-1',
        'hotel_id': 'h-1',
        'floor_id': 'f-1',
        'room_number': '101',
        'floor_number': 1,
        'product_count': 3,
      };

      final deserialized = RoomInfo.fromMap(map);
      expect(deserialized.id, 'r-1');
      expect(deserialized.roomNumber, '101');
      expect(deserialized.productCount, 3);
    });
  });
}
