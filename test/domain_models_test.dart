import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/domain/models.dart';

void main() {
  group('Product model', () {
    final product = Product(
      id: 'prod-1',
      sku: 'SKU-01',
      nameEn: 'English Name',
      nameFr: 'French Name',
      nameAr: 'Arabic Name',
      nameIt: 'Italian Name',
      maxRefillCount: 10,
      maxBottleAgeDays: 30,
      lowBottleThreshold: 5,
      lowBidonThreshold: 2,
    );

    test('label method returns correct localized string', () {
      expect(product.label('en'), 'English Name');
      expect(product.label('fr'), 'French Name');
      expect(product.label('ar'), 'Arabic Name');
      expect(product.label('it'), 'Italian Name');
      expect(product.label('es'), 'English Name'); // default to English
    });

    test('getters return correct flags', () {
      expect(product.isRefillable, true);
      expect(product.isDirectReplacement, false);

      final replacementProduct = Product(
        id: 'prod-2',
        sku: 'SKU-02',
        nameEn: 'English Name 2',
        nameFr: 'French Name 2',
        nameAr: 'Arabic Name 2',
        nameIt: 'Italian Name 2',
        maxRefillCount: 10,
        maxBottleAgeDays: 30,
        lowBottleThreshold: 5,
        lowBidonThreshold: 2,
        refillType: RefillType.directReplacement,
      );

      expect(replacementProduct.isRefillable, false);
      expect(replacementProduct.isDirectReplacement, true);
    });
  });

  group('Hotel model', () {
    final hotel = Hotel(
      id: 'hotel-1',
      name: 'Test Hotel',
      city: 'Test City',
      country: 'Test Country',
      contactName: 'Test Contact',
      email: 'test@hotel.com',
      phone: '123456789',
      roomCount: 100,
      pendingEdits: 0,
    );

    test('copyWith updates fields correctly', () {
      final updatedHotel = hotel.copyWith(
        name: 'New Hotel Name',
        roomCount: 150,
      );

      expect(updatedHotel.id, 'hotel-1'); // Unchanged
      expect(updatedHotel.name, 'New Hotel Name'); // Changed
      expect(updatedHotel.roomCount, 150); // Changed
      expect(updatedHotel.city, 'Test City'); // Unchanged
    });
  });

  group('RoomInfo model', () {
    test('fromMap creates valid instance', () {
      final map = {
        'id': 'room-1',
        'hotel_id': 'hotel-1',
        'floor_id': 'floor-1',
        'room_number': '101',
        'floor_number': 1,
        'product_count': 3,
      };

      final roomInfo = RoomInfo.fromMap(map);

      expect(roomInfo.id, 'room-1');
      expect(roomInfo.hotelId, 'hotel-1');
      expect(roomInfo.floorId, 'floor-1');
      expect(roomInfo.roomNumber, '101');
      expect(roomInfo.floorNumber, 1);
      expect(roomInfo.productCount, 3);
    });
  });

  group('RefillEvent model', () {
    test('canUndo returns true within 30 minutes', () {
      final now = DateTime.now();
      final event = RefillEvent(
        id: 'event-1',
        roomProductId: 'rp-1',
        type: RefillEventType.refill,
        previousRefillCount: 0,
        newRefillCount: 1,
        occurredAt: now.subtract(const Duration(minutes: 15)),
        performedBy: 'user-1',
      );

      expect(event.canUndo(now, 'user-1'), isTrue);
    });

    test('canUndo returns false after 30 minutes', () {
      final now = DateTime.now();
      final event = RefillEvent(
        id: 'event-1',
        roomProductId: 'rp-1',
        type: RefillEventType.refill,
        previousRefillCount: 0,
        newRefillCount: 1,
        occurredAt: now.subtract(const Duration(minutes: 45)),
        performedBy: 'user-1',
      );

      expect(event.canUndo(now, 'user-1'), isFalse);
    });

    test('canUndo returns false for wrong user', () {
      final now = DateTime.now();
      final event = RefillEvent(
        id: 'event-1',
        roomProductId: 'rp-1',
        type: RefillEventType.refill,
        previousRefillCount: 0,
        newRefillCount: 1,
        occurredAt: now.subtract(const Duration(minutes: 15)),
        performedBy: 'user-1',
      );

      expect(event.canUndo(now, 'user-2'), isFalse);
    });
  });

  group('AlertItem model', () {
    test('copyWith updates fields correctly', () {
      final alert = AlertItem(
        id: 'alert-1',
        hotelId: 'hotel-1',
        type: AlertType.lowBottleStock,
        severity: 1,
        title: 'Original Title',
        body: 'Original Body',
        createdAt: DateTime.now(),
        isResolved: false,
      );

      final updatedAlert = alert.copyWith(
        title: 'New Title',
        isResolved: true,
      );

      expect(updatedAlert.id, 'alert-1'); // Unchanged
      expect(updatedAlert.title, 'New Title'); // Changed
      expect(updatedAlert.isResolved, true); // Changed
      expect(updatedAlert.type, AlertType.lowBottleStock); // Unchanged
    });
  });
}
