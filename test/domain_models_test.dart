import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/domain/models.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';

void main() {
  group('Product model tests', () {
    test('serialization and deserialization', () {
      final product = Product(
        id: 'p1',
        sku: 'SHAMPOO-01',
        nameEn: 'Shampoo',
        nameFr: 'Shampooing',
        nameAr: 'شامبو',
        nameIt: 'Shampoo',
        bottleVolumeMl: 1000,
        bidonVolumeMl: 5000,
        maxRefillCount: 10,
        maxBottleAgeDays: 365,
        lowBottleThreshold: 5,
        lowBidonThreshold: 2,
        imageUrl: 'http://example.com/image.png',
        bottleType: BottleType.withPump,
        refillType: RefillType.refillable,
      );

      final map = {
        'id': 'p1',
        'sku': 'SHAMPOO-01',
        'name_en': 'Shampoo',
        'name_fr': 'Shampooing',
        'name_ar': 'شامبو',
        'name_it': 'Shampoo',
        'bottle_volume_ml': 1000,
        'bidon_volume_ml': 5000,
        'max_refill_count': 10,
        'max_bottle_age_days': 365,
        'low_bottle_threshold': 5,
        'low_bidon_threshold': 2,
        'image_url': 'http://example.com/image.png',
        'bottle_type': 'with_pump',
        'refill_type': 'refillable',
      };

      final fromMap = Product.fromMap(map);
      expect(fromMap.id, product.id);
      expect(fromMap.sku, product.sku);
      expect(fromMap.nameEn, product.nameEn);
      expect(fromMap.bottleVolumeMl, product.bottleVolumeMl);
      expect(fromMap.imageUrl, product.imageUrl);
      expect(fromMap.bottleType, product.bottleType);
      expect(fromMap.refillType, product.refillType);
    });

    test('copyWith constraints', () {
      final product = Product(
        id: 'p1',
        sku: 'SHAMPOO-01',
        nameEn: 'Shampoo',
        nameFr: 'Shampooing',
        nameAr: 'شامبو',
        nameIt: 'Shampoo',
        maxRefillCount: 10,
        maxBottleAgeDays: 365,
        lowBottleThreshold: 5,
        lowBidonThreshold: 2,
      );

      final copied = product.copyWith(
        nameEn: 'Conditioner',
        bottleVolumeMl: 250,
      );

      expect(copied.id, 'p1');
      expect(copied.nameEn, 'Conditioner');
      expect(copied.bottleVolumeMl, 250);
      expect(copied.sku, 'SHAMPOO-01');
    });

    test('default states', () {
      final product = Product(
        id: 'p2',
        sku: 'SOAP-01',
        nameEn: 'Soap',
        nameFr: 'Savon',
        nameAr: 'صابون',
        nameIt: 'Sapone',
        maxRefillCount: 10,
        maxBottleAgeDays: 365,
        lowBottleThreshold: 5,
        lowBidonThreshold: 2,
      );

      expect(product.bottleType, BottleType.withPump);
      expect(product.refillType, RefillType.refillable);
      expect(product.bottleVolumeMl, 1000);
      expect(product.bidonVolumeMl, 5000);
    });
  });

  group('Hotel model tests', () {
    test('serialization and deserialization', () {
      final hotel = Hotel(
        id: 'h1',
        name: 'Grand Hotel',
        legalName: 'Grand Hotel LLC',
        city: 'Tunis',
        country: 'Tunisia',
        contactName: 'Jane Doe',
        email: 'info@grandhotel.com',
        phone: '12345678',
        address: '123 Main St',
        notes: 'VIP',
        roomCount: 50,
        pendingEdits: 0,
        expressQrEnabled: true,
      );

      final map = {
        'id': 'h1',
        'name': 'Grand Hotel',
        'legal_name': 'Grand Hotel LLC',
        'city': 'Tunis',
        'country': 'Tunisia',
        'contact_name': 'Jane Doe',
        'email': 'info@grandhotel.com',
        'phone': '12345678',
        'address': '123 Main St',
        'notes': 'VIP',
        'room_count': 50,
        'pending_edits': 0,
        'express_qr_enabled': true,
      };

      final fromMap = Hotel.fromMap(map);
      expect(fromMap.id, hotel.id);
      expect(fromMap.name, hotel.name);
      expect(fromMap.legalName, hotel.legalName);
      expect(fromMap.city, hotel.city);
      expect(fromMap.country, hotel.country);
      expect(fromMap.contactName, hotel.contactName);
      expect(fromMap.email, hotel.email);
      expect(fromMap.phone, hotel.phone);
      expect(fromMap.address, hotel.address);
      expect(fromMap.notes, hotel.notes);
      expect(fromMap.roomCount, hotel.roomCount);
      expect(fromMap.pendingEdits, hotel.pendingEdits);
      expect(fromMap.expressQrEnabled, hotel.expressQrEnabled);
    });

    test('copyWith constraints', () {
      final hotel = Hotel(
        id: 'h1',
        name: 'Grand Hotel',
        city: 'Tunis',
        country: 'Tunisia',
        contactName: 'Jane Doe',
        email: 'info@grandhotel.com',
        phone: '12345678',
        roomCount: 50,
        pendingEdits: 0,
      );

      final copied = hotel.copyWith(
        name: 'Grand Hotel Updated',
        expressQrEnabled: true,
      );

      expect(copied.id, 'h1');
      expect(copied.name, 'Grand Hotel Updated');
      expect(copied.city, 'Tunis');
      expect(copied.expressQrEnabled, true);
    });

    test('default states', () {
      final hotel = Hotel(
        id: 'h2',
        name: 'Small Hotel',
        city: 'Sousse',
        country: 'Tunisia',
        contactName: 'John Doe',
        email: 'info@smallhotel.com',
        phone: '87654321',
        roomCount: 10,
        pendingEdits: 0,
      );

      expect(hotel.legalName, '');
      expect(hotel.address, '');
      expect(hotel.notes, '');
      expect(hotel.expressQrEnabled, false);
    });
  });

  group('RoomInfo model tests', () {
    test('serialization and deserialization', () {
      final room = RoomInfo(
        id: 'r1',
        hotelId: 'h1',
        floorId: 'f1',
        roomNumber: '101',
        floorNumber: 1,
        productCount: 3,
      );

      final map = {
        'id': 'r1',
        'hotel_id': 'h1',
        'floor_id': 'f1',
        'room_number': '101',
        'floor_number': 1,
        'product_count': 3,
      };

      final fromMap = RoomInfo.fromMap(map);
      expect(fromMap.id, room.id);
      expect(fromMap.hotelId, room.hotelId);
      expect(fromMap.floorId, room.floorId);
      expect(fromMap.roomNumber, room.roomNumber);
      expect(fromMap.floorNumber, room.floorNumber);
      expect(fromMap.productCount, room.productCount);
    });
  });

  group('RefillEvent model tests', () {
    test('default states', () {
      final now = DateTime.now();
      final refill = RefillEvent(
        id: 're1',
        roomProductId: 'rp1',
        type: RefillEventType.refill,
        previousRefillCount: 0,
        newRefillCount: 1,
        occurredAt: now,
        performedBy: 'u1',
      );

      expect(refill.id, 're1');
      expect(refill.roomProductId, 'rp1');
    });
  });

  group('AlertItem model tests', () {
    test('copyWith constraints', () {
      final now = DateTime.now();
      final alert = AlertItem(
        id: 'a1',
        hotelId: 'h1',
        type: AlertType.lowBidonStock,
        severity: 1,
        title: 'Low Stock',
        body: 'Running out of shampoo',
        createdAt: now,
        isResolved: false,
      );

      final copied = alert.copyWith(
        isResolved: true,
      );

      expect(copied.id, 'a1');
      expect(copied.isResolved, true);
    });
  });
}
