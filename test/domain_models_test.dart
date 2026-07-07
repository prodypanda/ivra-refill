import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/domain/models.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';

void main() {
  group('Product Model Tests', () {
    test('Product constructor works', () {
      final product = Product(
        id: '1',
        sku: 'TEST-SKU',
        nameEn: 'Test Product',
        nameFr: 'Test Product FR',
        nameAr: 'Test Product AR',
        nameIt: 'Test Product IT',
        bottleVolumeMl: 300,
        bidonVolumeMl: 5000,
        maxRefillCount: 5,
        maxBottleAgeDays: 30,
        lowBottleThreshold: 10,
        lowBidonThreshold: 5,
      );

      expect(product.id, '1');
      expect(product.nameEn, 'Test Product');
      expect(product.sku, 'TEST-SKU');
      expect(product.bottleVolumeMl, 300);
    });

    test('Product copyWith', () {
      final product = Product(
        id: '1',
        sku: 'SKU',
        nameEn: 'Test',
        nameFr: 'Test',
        nameAr: 'Test',
        nameIt: 'Test',
        maxRefillCount: 5,
        maxBottleAgeDays: 30,
        lowBottleThreshold: 10,
        lowBidonThreshold: 5,
      );
      final updated = product.copyWith(nameEn: 'Updated');

      expect(updated.id, '1');
      expect(updated.nameEn, 'Updated');
      expect(updated.sku, 'SKU');
    });
  });

  group('Hotel Model Tests', () {
    test('Hotel constructor works', () {
      final hotel = Hotel(
        id: '1',
        name: 'Grand Hotel',
        city: 'Paris',
        country: 'France',
        contactName: 'John Doe',
        email: 'contact@grandhotel.com',
        phone: '123456789',
        roomCount: 100,
        pendingEdits: 0,
      );

      expect(hotel.id, '1');
      expect(hotel.name, 'Grand Hotel');
      expect(hotel.city, 'Paris');
    });

    test('Hotel copyWith', () {
      final hotel = Hotel(
        id: '1',
        name: 'Hotel',
        city: 'City',
        country: 'Country',
        contactName: 'Name',
        email: 'email@test.com',
        phone: '123',
        roomCount: 10,
        pendingEdits: 0,
      );
      final updated = hotel.copyWith(name: 'New Hotel');

      expect(updated.id, '1');
      expect(updated.name, 'New Hotel');
    });
  });

  group('RoomInfo Model Tests', () {
    test('RoomInfo default state', () {
      final room = RoomInfo(
        id: '1',
        hotelId: 'h1',
        floorId: 'f1',
        roomNumber: '101',
        floorNumber: 1,
        productCount: 2,
      );

      expect(room.id, '1');
      expect(room.roomNumber, '101');
      expect(room.productCount, 2);
    });
  });

  group('RefillEvent Model Tests', () {
    test('RefillEvent constraints', () {
      final refill = RefillEvent(
        id: '1',
        roomProductId: 'rp1',
        type: RefillEventType.bottleReplaced,
        previousRefillCount: 0,
        newRefillCount: 1,
        occurredAt: DateTime(2023),
        performedBy: 'u1',
      );

      expect(refill.id, '1');
      expect(refill.type, RefillEventType.bottleReplaced);
    });
  });

  group('AlertItem Model Tests', () {
    test('AlertItem copyWith', () {
      final alert = AlertItem(
        id: '1',
        hotelId: 'h1',
        type: AlertType.lowBidonStock,
        severity: 1,
        title: 'Low Stock',
        body: 'Body text',
        createdAt: DateTime.now(),
        isResolved: false,
      );
      final updated = alert.copyWith(isResolved: true);

      expect(updated.isResolved, true);
    });
  });
}
