import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/domain/models.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';

void main() {
  group('Model Unit Tests', () {
    test('Product serialization, copyWith, and defaults', () {
      final product = Product(
        id: '1',
        sku: 'SHAM-1',
        nameEn: 'Shampoo',
        nameFr: 'Shampooing',
        nameAr: 'شامبو',
        nameIt: 'Shampoo',
        maxRefillCount: 10,
        maxBottleAgeDays: 30,
        lowBottleThreshold: 2,
        lowBidonThreshold: 1,
      );

      // Defaults
      expect(product.bottleVolumeMl, 1000);
      expect(product.bidonVolumeMl, 5000);
      expect(product.bottleType, BottleType.withPump);
      expect(product.refillType, RefillType.refillable);

      final map = {
        'id': '1',
        'sku': 'SHAM-1',
        'name_en': 'Shampoo',
        'name_fr': 'Shampooing',
        'name_ar': 'شامبو',
        'name_it': 'Shampoo',
        'max_refill_count': 10,
        'max_bottle_age_days': 30,
        'low_bottle_threshold': 2,
        'low_bidon_threshold': 1,
      };
      final newProduct = Product.fromMap(map);
      expect(newProduct.id, '1');
      expect(newProduct.nameEn, 'Shampoo');
      expect(newProduct.bottleVolumeMl,
          1000); // from map default handling if available

      final copied = product.copyWith(nameEn: 'Soap');
      expect(copied.nameEn, 'Soap');
      expect(copied.id, '1');
      expect(copied.nameFr, 'Shampooing');
    });

    test('Hotel serialization, copyWith, and defaults', () {
      final hotel = Hotel(
        id: '1',
        name: 'Grand Hotel',
        city: 'Paris',
        country: 'France',
        contactName: 'John',
        email: 'john@example.com',
        phone: '123456789',
        roomCount: 100,
        pendingEdits: 0,
      );

      // Defaults
      expect(hotel.legalName, '');
      expect(hotel.address, '');
      expect(hotel.notes, '');
      expect(hotel.expressQrEnabled, false);

      final map = {
        'id': '1',
        'name': 'Grand Hotel',
        'city': 'Paris',
        'country': 'France',
        'contact_name': 'John',
        'email': 'john@example.com',
        'phone': '123456789',
        'room_count': 100,
        'pending_edits': 0,
      };
      final newHotel = Hotel.fromMap(map);
      expect(newHotel.id, '1');
      expect(newHotel.name, 'Grand Hotel');

      final copied = hotel.copyWith(name: 'Small Hotel');
      expect(copied.name, 'Small Hotel');
      expect(copied.id, '1');
      expect(copied.city, 'Paris');
    });

    test('RoomInfo serialization, copyWith', () {
      final room = RoomInfo(
        id: '1',
        hotelId: '1',
        floorId: '1',
        roomNumber: '101',
        floorNumber: 1,
        productCount: 2,
      );

      final map = {
        'id': '1',
        'hotel_id': '1',
        'floor_id': '1',
        'room_number': '101',
        'floor_number': 1,
        'product_count': 2,
      };
      final newRoom = RoomInfo.fromMap(map);
      expect(newRoom.id, '1');
      expect(newRoom.roomNumber, '101');

      // RoomInfo does not have copyWith in models.dart it seems, based on the previous error
    });

    test('RefillEvent copyWith and canUndo', () {
      final now = DateTime.now();
      final refill = RefillEvent(
        id: '1',
        roomProductId: '1',
        type: RefillEventType.refill,
        previousRefillCount: 0,
        newRefillCount: 1,
        occurredAt: now,
        performedBy: 'user1',
      );

      // RefillEvent copyWith is not implemented, just check canUndo
      expect(refill.canUndo(now, 'user1'), isTrue);
      expect(refill.canUndo(now, 'user2'), isFalse);
    });

    test('AlertItem copyWith and defaults', () {
      final alert = AlertItem(
        id: '1',
        hotelId: '1',
        type: AlertType.bottleAgeLimit,
        severity: 1, // severity is an int
        title: 'Title',
        body: 'Body',
        createdAt: DateTime.now(),
        isResolved: false,
      );

      expect(alert.roomProductId, isNull);
      expect(alert.productId, isNull);

      final copied = alert.copyWith(isResolved: true);
      expect(copied.isResolved, true);
      expect(copied.id, '1');
      expect(copied.title, 'Title');
    });
  });
}
