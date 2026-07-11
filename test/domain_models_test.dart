import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/domain/models.dart';

void main() {
  group('Domain Models Tests', () {
    test('Hotel model correctly instantiates and provides defaults', () {
      final hotel = Hotel(
        id: 'h1',
        name: 'Grand Hotel',
        city: 'Paris',
        country: 'France',
        contactName: 'Jean Dupont',
        email: 'jean@grandhotel.fr',
        phone: '+33123456789',
        roomCount: 100,
        pendingEdits: 0,
      );

      expect(hotel.id, 'h1');
      expect(hotel.legalName, '');
      expect(hotel.address, '');
      expect(hotel.notes, '');
      expect(hotel.expressQrEnabled, false);

      final hotelMap = {'id': 'h1', 'name': 'Grand Hotel', 'city': 'Paris', 'country': 'France', 'contact_name': 'Jean', 'email': 'jean@grandhotel.fr', 'phone': '123', 'room_count': 100, 'pending_edits': 0};

      final hotelFromMap = Hotel.fromMap(hotelMap);
      expect(hotelFromMap.id, 'h1');
      expect(hotelFromMap.name, 'Grand Hotel');
    });

    test('Product model correctly instantiates and provides defaults', () {
      final product = Product(
        id: 'p1',
        sku: 'SKU-01',
        nameEn: 'Shampoo',
        nameFr: 'Shampooing',
        nameAr: 'شامبو',
        nameIt: 'Shampoo',
        maxRefillCount: 5,
        maxBottleAgeDays: 365,
        lowBottleThreshold: 20,
        lowBidonThreshold: 2,
      );

      expect(product.bottleVolumeMl, 1000);
      expect(product.bidonVolumeMl, 5000);
      expect(product.bottleType, BottleType.withPump);
      expect(product.refillType, RefillType.refillable);

      final map = {'id': 'p1', 'sku': 'SKU-01', 'name_en': 'Shampoo', 'name_fr': 'Shampooing', 'name_ar': 'شامبو', 'name_it': 'Shampoo', 'max_refill_count': 5, 'max_bottle_age_days': 365, 'low_bottle_threshold': 20, 'low_bidon_threshold': 2};

      final productFromMap = Product.fromMap(map);
      expect(productFromMap.id, 'p1');
      expect(productFromMap.nameEn, 'Shampoo');
    });

    test('RoomInfo model correctly instantiates and serializes', () {
      final roomInfo = RoomInfo(
        id: 'r1',
        hotelId: 'h1',
        floorId: 'f1',
        roomNumber: '101',
        floorNumber: 1,
        productCount: 3,
      );

      final map = {'id': 'r1', 'hotel_id': 'h1', 'floor_id': 'f1', 'room_number': '101', 'floor_number': 1, 'product_count': 3};

      final fromMap = RoomInfo.fromMap(map);
      expect(fromMap.id, 'r1');
      expect(fromMap.hotelId, 'h1');
    });

    test('RefillEvent model correctly instantiates and parses', () {
      final date = DateTime.now();
      final event = RefillEvent(
        id: 'e1',
        roomProductId: 'rp1',
        type: RefillEventType.refill,
        previousRefillCount: 0,
        newRefillCount: 1,
        occurredAt: date,
        performedBy: 'user1',
      );

      expect(event.id, 'e1');
      expect(event.type, RefillEventType.refill);
    });

    test('AlertItem model correctly instantiates and serializes', () {
      final date = DateTime.now();
      final alert = AlertItem(
        id: 'a1',
        hotelId: 'h1',
        type: AlertType.lowBidonStock,
        severity: 2,
        title: 'Low Stock',
        body: 'Shampoo running low',
        createdAt: date,
        isResolved: false,
      );

      expect(alert.id, 'a1');
      expect(alert.title, 'Low Stock');
    });

    test('Models copyWith functions properly', () {
      final hotel = Hotel(
        id: 'h1',
        name: 'Old Name',
        city: 'Paris',
        country: 'France',
        contactName: 'Old',
        email: 'old@h.fr',
        phone: '123',
        roomCount: 100,
        pendingEdits: 0,
      );
      final hCopy = hotel.copyWith(name: 'New Name');
      expect(hCopy.name, 'New Name');
      expect(hCopy.id, 'h1');

      final product = Product(
        id: 'p1',
        sku: 'SKU-01',
        nameEn: 'Old Product',
        nameFr: 'Ancien Produit',
        nameAr: 'Old Ar',
        nameIt: 'Old It',
        maxRefillCount: 5,
        maxBottleAgeDays: 365,
        lowBottleThreshold: 20,
        lowBidonThreshold: 2,
      );
      final pCopy = product.copyWith(nameEn: 'New Product');
      expect(pCopy.nameEn, 'New Product');
      expect(pCopy.id, 'p1');

      final alert = AlertItem(
        id: 'a1',
        hotelId: 'h1',
        type: AlertType.lowBidonStock,
        severity: 2,
        title: 'Low Stock',
        body: 'Running low',
        createdAt: DateTime.now(),
        isResolved: false,
      );
      final aCopy = alert.copyWith(isResolved: true);
      expect(aCopy.isResolved, true);
      expect(aCopy.id, 'a1');
    });
  });
}
