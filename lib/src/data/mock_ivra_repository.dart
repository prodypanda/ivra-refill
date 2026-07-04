import 'dart:math';

import 'dart:io' show Platform;
import 'package:uuid/uuid.dart';


import '../domain/app_enums.dart';
import '../domain/models.dart';
import 'ivra_repository.dart';

class MockIvraRepository implements IvraRepository {
  MockIvraRepository() {
    _mockRolePermissions = {
      'app_admin': {
        'manage_hotels',
        'manage_rooms',
        'manage_products',
        'manage_team',
        'view_approvals',
        'approve_corrections',
        'view_reports',
        'send_notifications',
        'view_audit_logs',
        'view_alerts',
        'view_rooms',
        'view_inventory',
        'submit_edit_requests',
        'view_authorizations',
      },
      'app_manager': {
        'manage_hotels',
        'manage_rooms',
        'manage_products',
        'manage_team',
        'view_approvals',
        'approve_corrections',
        'view_reports',
        'send_notifications',
        'view_alerts',
        'view_rooms',
        'view_inventory',
        'submit_edit_requests',
      },
      'hotel_manager': {
        'manage_hotels',
        'manage_rooms',
        'manage_team',
        'view_approvals',
        'view_reports',
        'view_alerts',
        'view_rooms',
        'view_inventory',
        'submit_edit_requests',
      },
      'hotel_staff': {
        'view_alerts',
        'view_rooms',
        'view_inventory',
      },
      'housekeeper': {
        'view_alerts',
        'view_rooms',
        'view_inventory',
      },
    };
    _hotels = [
      const Hotel(
        id: 'hotel-seaside',
        name: 'Seaside Hotel',
        legalName: 'Seaside Hotel Limited',
        city: 'Sousse',
        country: 'Tunisia',
        contactName: 'Amina Bello',
        email: 'ops@seaside.example',
        phone: '+234 800 000 0000',
        address: '12 Ocean Drive, Victoria Island',
        notes: 'Pilot hotel for refill lifecycle operations.',
        roomCount: 84,
        pendingEdits: 2,
      ),
      const Hotel(
        id: 'hotel-palms',
        name: 'Palms Residence',
        legalName: 'Palms Residence Ltd',
        city: 'Tunis',
        country: 'Tunisia',
        contactName: 'Daniel Okeke',
        email: 'manager@palms.example',
        phone: '+234 811 000 0000',
        address: '8 Palm Avenue, Maitama',
        roomCount: 46,
        pendingEdits: 0,
      ),
    ];

    _rooms = [
      const RoomInfo(
        id: 'room-101',
        hotelId: 'hotel-seaside',
        floorId: 'floor-1',
        roomNumber: '101',
        floorNumber: 1,
        productCount: 4,
      ),
      const RoomInfo(
        id: 'room-205',
        hotelId: 'hotel-seaside',
        floorId: 'floor-2',
        roomNumber: '205',
        floorNumber: 2,
        productCount: 5,
      ),
    ];

    _roomProducts = [
      RoomProduct(
        id: 'rp-101-shampoo',
        hotelId: _hotels.first.id,
        roomId: 'room-101',
        roomNumber: '101',
        floorNumber: 1,
        product: _products[0],
        refillCount: 7,
        lastRefillAt: DateTime.now().subtract(const Duration(days: 3)),
        bottleStartedAt: DateTime.now().subtract(const Duration(days: 145)),
        status: BottleStatus.refilled,
      ),
      RoomProduct(
        id: 'rp-101-wash',
        hotelId: _hotels.first.id,
        roomId: 'room-101',
        roomNumber: '101',
        floorNumber: 1,
        product: _products[3],
        refillCount: 11,
        lastRefillAt: DateTime.now().subtract(const Duration(hours: 4)),
        bottleStartedAt: DateTime.now().subtract(const Duration(days: 260)),
        status: BottleStatus.refillLimitReached,
      ),
      RoomProduct(
        id: 'rp-205-gel',
        hotelId: _hotels.first.id,
        roomId: 'room-205',
        roomNumber: '205',
        floorNumber: 2,
        product: _products[2],
        refillCount: 2,
        lastRefillAt: DateTime.now().subtract(const Duration(days: 10)),
        bottleStartedAt: DateTime.now().subtract(const Duration(days: 60)),
        status: BottleStatus.needsRefill,
      ),
    ];

    _inventory = [
      InventoryItem(
        id: 'inv-shampoo',
        hotelId: 'hotel-seaside',
        product: _products[0],
        fullBottles: 9,
        emptyBottles: 17,
        fullBidons: 3,
        openBidons: 1,
        emptyBidons: 5,
        openBidonVolumeLeftMl: 2500.0,
      ),
      InventoryItem(
        id: 'inv-gel',
        hotelId: 'hotel-seaside',
        product: _products[2],
        fullBottles: 22,
        emptyBottles: 6,
        fullBidons: 7,
        openBidons: 1,
        emptyBidons: 2,
        openBidonVolumeLeftMl: 4000.0,
      ),
    ];

    _openBidonVolumeLeft['prod-shampoo'] = 2500.0;
    _openBidonVolumeLeft['prod-shower-gel'] = 4000.0;

    _approvalRequests = [
      ApprovalRequest(
        id: 'apr-room-205',
        hotelId: 'hotel-seaside',
        title: 'Move room 205 to floor 3',
        targetTable: 'rooms',
        status: ApprovalStatus.pending,
        requestedByName: 'Amina Bello',
        requestedAt: DateTime.now().subtract(const Duration(hours: 7)),
        oldValue: 'Floor 2',
        newValue: 'Floor 3',
      ),
      ApprovalRequest(
        id: 'apr-contact',
        hotelId: 'hotel-seaside',
        title: 'Update hotel phone number',
        targetTable: 'hotels',
        status: ApprovalStatus.pending,
        requestedByName: 'Amina Bello',
        requestedAt: DateTime.now().subtract(const Duration(days: 1)),
        oldValue: '+234 800 000 0000',
        newValue: '+234 800 111 2222',
      ),
    ];

    _alerts = [
      AlertItem(
        id: 'alert-stock',
        hotelId: 'hotel-seaside',
        productId: 'prod-shampoo',
        type: AlertType.lowBidonStock,
        severity: 2,
        title: 'Low shampoo bidon stock',
        body: 'Seaside Hotel has 3 full shampoo bidons remaining.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isResolved: false,
      ),
      AlertItem(
        id: 'alert-limit',
        hotelId: 'hotel-seaside',
        roomProductId: 'rp-101-wash',
        productId: 'prod-hand-wash',
        type: AlertType.refillLimit,
        severity: 3,
        title: 'Hand wash bottle reached refill limit',
        body: 'Room 101 hand wash bottle must be replaced.',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        isResolved: false,
      ),
    ];

    _teamMembers = [
      _currentUser,
      const UserProfile(
        id: 'demo-manager',
        fullName: 'Ivra Manager',
        email: 'manager@ivra.example',
        role: UserRole.appManager,
        roleString: 'app_manager',
      ),
      const UserProfile(
        id: 'hotel-manager-seaside',
        fullName: 'Amina Bello',
        email: 'amina@seaside.example',
        role: UserRole.hotelManager,
        roleString: 'hotel_manager',
        hotelId: 'hotel-seaside',
      ),
      const UserProfile(
        id: 'hotel-staff-seaside',
        fullName: 'Housekeeping Lead',
        email: 'housekeeping@seaside.example',
        role: UserRole.hotelStaff,
        roleString: 'hotel_staff',
        hotelId: 'hotel-seaside',
      ),
    ];

    _teamInvitations = [
      TeamInvitation(
        id: 'invite-palms-manager',
        email: 'opslead@palms.example',
        fullName: 'Palms Ops Lead',
        role: UserRole.hotelManager,
        status: 'pending',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        inviteToken: 'demo-palms-invite',
        hotelId: 'hotel-palms',
        hotelName: 'Palms Residence',
      ),
    ];

    bool isTest = false;
    try {
      isTest = Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {}

    if (!isTest) {
      _events.addAll([
        RefillEvent(
          id: 'refill-evt-1',
          roomProductId: 'rp-101-shampoo',
          type: RefillEventType.refill,
          previousRefillCount: 6,
          newRefillCount: 7,
          occurredAt: DateTime.now().subtract(const Duration(days: 3)),
          performedBy: 'hotel-staff-seaside',
          performedByName: 'Sarah Staff',
          notes: 'Refilled to max',
        ),
        RefillEvent(
          id: 'refill-evt-2',
          roomProductId: 'rp-101-wash',
          type: RefillEventType.bottleReplaced,
          previousRefillCount: 10,
          newRefillCount: 0,
          occurredAt: DateTime.now().subtract(const Duration(hours: 4)),
          performedBy: 'hotel-staff-seaside',
          performedByName: 'Sarah Staff',
          notes: 'Replaced old bottle',
        ),
      ]);

      _inventoryEvents.addAll([
        InventoryEvent(
          id: 'inv-evt-1',
          hotelId: 'hotel-seaside',
          productId: 'prod-shampoo',
          fullBottlesDelta: 5,
          emptyBottlesDelta: -5,
          fullBidonsDelta: 0,
          openBidonsDelta: 0,
          emptyBidonsDelta: 0,
          reason: 'Monthly delivery received',
          performedBy: 'hotel-manager-seaside',
          occurredAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        InventoryEvent(
          id: 'inv-evt-2',
          hotelId: 'hotel-seaside',
          productId: 'prod-shampoo',
          fullBottlesDelta: 0,
          emptyBottlesDelta: 0,
          fullBidonsDelta: 2,
          openBidonsDelta: 0,
          emptyBidonsDelta: -2,
          reason: 'Stock correction',
          performedBy: 'demo-admin',
          occurredAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);
    }
  }



  final _uuid = const Uuid();

  final List<String> _mockRoles = [
    'app_admin',
    'app_manager',
    'hotel_manager',
    'hotel_staff',
  ];
  late final Map<String, Set<String>> _mockRolePermissions;

  var _currentUser = const UserProfile(
    id: 'demo-admin',
    fullName: 'Ivra Admin',
    email: 'admin@ivra.example',
    role: UserRole.appAdmin,
    roleString: 'app_admin',
  );

  final _products = [
    Product(
      id: 'prod-shampoo',
      sku: 'IVR-SHA-1L',
      nameEn: 'Shampoo',
      nameFr: 'Shampooing',
      nameAr: 'شامبو',
      nameIt: 'Shampoo',
      maxRefillCount: 10,
      maxBottleAgeDays: 240,
      lowBottleThreshold: 12,
      lowBidonThreshold: 4,
    ),
    Product(
      id: 'prod-conditioner',
      sku: 'IVR-CON-1L',
      nameEn: 'Conditioner',
      nameFr: 'Après-shampooing',
      nameAr: 'بلسم',
      nameIt: 'Balsamo',
      maxRefillCount: 10,
      maxBottleAgeDays: 240,
      lowBottleThreshold: 12,
      lowBidonThreshold: 4,
    ),
    Product(
      id: 'prod-shower-gel',
      sku: 'IVR-GEL-1L',
      nameEn: 'Shower Gel',
      nameFr: 'Gel douche',
      nameAr: 'جل الاستحمام',
      nameIt: 'Bagnoschiuma',
      maxRefillCount: 10,
      maxBottleAgeDays: 240,
      lowBottleThreshold: 12,
      lowBidonThreshold: 4,
    ),
    Product(
      id: 'prod-hand-wash',
      sku: 'IVR-HWA-1L',
      nameEn: 'Hand Wash',
      nameFr: 'Savon mains',
      nameAr: 'غسول اليدين',
      nameIt: 'Sapone Mani',
      maxRefillCount: 10,
      maxBottleAgeDays: 240,
      lowBottleThreshold: 12,
      lowBidonThreshold: 4,
    ),
    Product(
      id: 'prod-lotion',
      sku: 'IVR-LOT-1L',
      nameEn: 'Hand and Body Lotion',
      nameFr: 'Lait mains et corps',
      nameAr: 'لوشن اليد والجسم',
      nameIt: 'Crema Mani e Corpo',
      maxRefillCount: 10,
      maxBottleAgeDays: 240,
      lowBottleThreshold: 12,
      lowBidonThreshold: 4,
    ),
  ];

  late final List<Hotel> _hotels;
  late final List<RoomInfo> _rooms;
  late final List<RoomProduct> _roomProducts;
  late final List<InventoryItem> _inventory;
  late final List<ApprovalRequest> _approvalRequests;
  late final List<AlertItem> _alerts;
  late final List<UserProfile> _teamMembers;
  late final List<TeamInvitation> _teamInvitations;
  final List<RefillEvent> _events = [];
  final List<InventoryEvent> _inventoryEvents = [];
  final Set<String> _processedClientRequestIds = {};
  final List<AuditLog> _mockAuditLogs = [];
  final Map<String, double> _openBidonVolumeLeft = {};
  final List<HousekeeperAllocation> _housekeeperAllocations = [];


  @override
  Future<void> clearCachedData() async {}

  @override
  Future<UserProfile> currentUser() async => _currentUser;

  @override
  Future<void> updateCurrentUserProfile({required String fullName}) async {
    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Full name is required.');
    }

    _currentUser = _currentUser.copyWith(fullName: trimmedName);
    final index = _teamMembers.indexWhere(
      (member) => member.id == _currentUser.id,
    );
    if (index != -1) {
      _teamMembers[index] = _teamMembers[index].copyWith(
        fullName: trimmedName,
      );
    }
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
  }) async {
    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Full name is required.');
    }

    final index = _teamMembers.indexWhere(
      (member) => member.id == userId,
    );
    if (index != -1) {
      _teamMembers[index] = _teamMembers[index].copyWith(
        fullName: trimmedName,
      );
    }
    
    if (_currentUser.id == userId) {
      _currentUser = _currentUser.copyWith(fullName: trimmedName);
    }
  }

  @override
  Future<void> changeCurrentUserPassword({required String password}) async {
    if (password.length < 8) {
      throw ArgumentError('Password must be at least 8 characters.');
    }
  }

  /// Demo-only: switch the active demo user. This is intentionally NOT part of
  /// the [IvraRepository] interface — it only exists on the in-memory mock used
  /// in demo mode and tests. Production code must narrow to [MockIvraRepository]
  /// before calling it.
  Future<void> switchDemoUser({required String userId}) async {
    final member = _teamMembers.firstWhere((item) => item.id == userId);
    _currentUser = member;
  }

  @override
  Future<DashboardMetrics> dashboardMetrics({String? hotelId}) async {
    final lowStock = (await inventory(hotelId: hotelId)).where(
      (item) => item.lowBidons || item.lowBottles,
    );
    final roomsList = _rooms.where((room) => hotelId == null || room.hotelId == hotelId).toList();

    return DashboardMetrics(
      hotelCount: hotelId == null ? _hotels.length : 1,
      roomCount: roomsList.length,
      pendingApprovals: _approvalRequests
          .where((item) =>
              item.status == ApprovalStatus.pending &&
              (hotelId == null || item.hotelId == hotelId))
          .length,
      openAlerts: _alerts
          .where((alert) =>
              !alert.isResolved &&
              (hotelId == null || alert.hotelId == hotelId))
          .length,
      bottlesToReplace: _roomProducts
          .where((item) =>
              (hotelId == null || item.hotelId == hotelId) &&
              (item.status == BottleStatus.refillLimitReached ||
                  item.status == BottleStatus.tooOld))
          .length,
      lowStockProducts: lowStock.length,
    );
  }

  @override
  Future<List<Hotel>> hotels() async => List.unmodifiable(_hotels);

  @override
  Future<List<UserProfile>> teamMembers({String? hotelId}) async {
    return _teamMembers
        .where((member) =>
            hotelId == null ||
            member.hotelId == hotelId ||
            member.hotelId == null)
        .toList();
  }

  @override
  Future<List<TeamInvitation>> teamInvitations({String? hotelId}) async {
    return _teamInvitations
        .where((invite) =>
            invite.status == 'pending' &&
            (hotelId == null || invite.hotelId == hotelId))
        .toList();
  }

  @override
  Future<List<Product>> products() async => List.unmodifiable(_products);

  @override
  Future<List<RoomInfo>> rooms({String? hotelId}) async {
    return _rooms
        .where((room) => hotelId == null || room.hotelId == hotelId)
        .toList();
  }

  @override
  Future<List<RoomProduct>> roomProducts({
    String? hotelId,
    String? roomId,
  }) async {
    return _roomProducts.where((item) {
      return (hotelId == null || item.hotelId == hotelId) &&
          (roomId == null || item.roomId == roomId);
    }).toList();
  }

  @override
  Future<List<InventoryItem>> inventory({String? hotelId}) async {
    return _inventory
        .where((item) => hotelId == null || item.hotelId == hotelId)
        .toList();
  }

  @override
  Future<List<HousekeeperAllocation>> fetchHousekeeperAllocations({String? housekeeperId, String? hotelId}) async {
    return _housekeeperAllocations.where((alloc) {
      final matchHousekeeper = housekeeperId == null || alloc.housekeeperId == housekeeperId;
      final matchHotel = hotelId == null || alloc.hotelId == hotelId;
      return matchHousekeeper && matchHotel;
    }).toList();
  }

  @override
  Future<void> checkoutHousekeeperStock({
    required String housekeeperId,
    required String productId,
    required int fullBottles,
    required int fullBidons,
  }) async {
    if (fullBottles < 0 || fullBidons < 0) {
      throw ArgumentError('Invalid quantities');
    }

    final profiles = _teamMembers.where((u) => u.id == housekeeperId).toList();
    if (profiles.isEmpty) {
      throw Exception('Housekeeper profile not found');
    }
    final hotelId = profiles.first.hotelId;
    if (hotelId == null) {
      throw Exception('Housekeeper is not assigned to a hotel');
    }

    final invIndex = _inventory.indexWhere((item) => item.hotelId == hotelId && item.product.id == productId);
    if (invIndex == -1) {
      throw Exception('Product inventory not found');
    }
    final centralInv = _inventory[invIndex];
    if (centralInv.fullBottles < fullBottles || centralInv.fullBidons < fullBidons) {
      throw Exception('Insufficient central stock');
    }

    _inventory[invIndex] = centralInv.copyWith(
      fullBottles: centralInv.fullBottles - fullBottles,
      fullBidons: centralInv.fullBidons - fullBidons,
    );

    _mockAuditLogs.insert(0, AuditLog(
      id: DateTime.now().toIso8601String(),
      createdAt: DateTime.now(),
      action: 'Checked out housekeeper stock',
      userId: housekeeperId,
      details: {
        'housekeeper_id': housekeeperId,
        'product_id': productId,
        'full_bottles': fullBottles,
        'full_bidons': fullBidons,
      },
    ));

    final product = centralInv.product;
    final allocIndex = _housekeeperAllocations.indexWhere((alloc) => alloc.housekeeperId == housekeeperId && alloc.product.id == productId);
    if (allocIndex == -1) {
      _housekeeperAllocations.add(HousekeeperAllocation(
        id: DateTime.now().toIso8601String(),
        housekeeperId: housekeeperId,
        hotelId: hotelId,
        product: product,
        fullBottles: fullBottles,
        emptyBottles: 0,
        fullBidons: fullBidons,
        openBidons: 0,
        emptyBidons: 0,
        openBidonVolumeLeftMl: 0.0,
      ));
    } else {
      final existing = _housekeeperAllocations[allocIndex];
      _housekeeperAllocations[allocIndex] = existing.copyWith(
        fullBottles: existing.fullBottles + fullBottles,
        fullBidons: existing.fullBidons + fullBidons,
      );
    }
  }

  @override
  Future<void> returnHousekeeperStock({
    required String housekeeperId,
    required String productId,
    required int fullBottles,
    required int emptyBottles,
    required int fullBidons,
    required int openBidons,
    required int emptyBidons,
    required double openBidonVolumeLeftMl,
  }) async {
    final profiles = _teamMembers.where((u) => u.id == housekeeperId).toList();
    if (profiles.isEmpty) {
      throw Exception('Housekeeper profile not found');
    }
    final hotelId = profiles.first.hotelId;
    if (hotelId == null) {
      throw Exception('Housekeeper is not assigned to a hotel');
    }

    final allocIndex = _housekeeperAllocations.indexWhere((alloc) => alloc.housekeeperId == housekeeperId && alloc.product.id == productId);
    if (allocIndex == -1) {
      throw Exception('Allocation not found');
    }
    final alloc = _housekeeperAllocations[allocIndex];

    if (alloc.fullBottles < fullBottles ||
        alloc.emptyBottles < emptyBottles ||
        alloc.fullBidons < fullBidons ||
        alloc.openBidons < openBidons ||
        alloc.emptyBidons < emptyBidons ||
        alloc.openBidonVolumeLeftMl < openBidonVolumeLeftMl) {
      throw Exception('Insufficient housekeeper allocation to return');
    }

    _housekeeperAllocations[allocIndex] = alloc.copyWith(
      fullBottles: alloc.fullBottles - fullBottles,
      emptyBottles: alloc.emptyBottles - emptyBottles,
      fullBidons: alloc.fullBidons - fullBidons,
      openBidons: alloc.openBidons - openBidons,
      emptyBidons: alloc.emptyBidons - emptyBidons,
      openBidonVolumeLeftMl: alloc.openBidonVolumeLeftMl - openBidonVolumeLeftMl,
    );

    final invIndex = _inventory.indexWhere((item) => item.hotelId == hotelId && item.product.id == productId);
    if (invIndex == -1) {
      throw Exception('Central inventory item not found');
    }
    final centralInv = _inventory[invIndex];

    double newCentralOpenVolume = centralInv.openBidonVolumeLeftMl + openBidonVolumeLeftMl;
    int additionalFullBidons = 0;
    final int capacity = centralInv.product.bidonVolumeMl;

    if (newCentralOpenVolume >= capacity) {
      int extraFull = (newCentralOpenVolume / capacity).floor();
      additionalFullBidons += extraFull;
      newCentralOpenVolume = newCentralOpenVolume - (extraFull * capacity);
    }

    _inventory[invIndex] = centralInv.copyWith(
      fullBottles: centralInv.fullBottles + fullBottles,
      emptyBottles: centralInv.emptyBottles + emptyBottles,
      fullBidons: centralInv.fullBidons + fullBidons + additionalFullBidons,
      openBidons: newCentralOpenVolume > 0 ? 1 : 0,
      emptyBidons: centralInv.emptyBidons + emptyBidons,
      openBidonVolumeLeftMl: newCentralOpenVolume,
    );

    _mockAuditLogs.insert(0, AuditLog(
      id: DateTime.now().toIso8601String(),
      createdAt: DateTime.now(),
      action: 'Returned housekeeper stock',
      userId: housekeeperId,
      details: {
        'housekeeper_id': housekeeperId,
        'product_id': productId,
        'full_bottles': fullBottles,
        'empty_bottles': emptyBottles,
        'full_bidons': fullBidons,
        'open_bidons': openBidons,
        'empty_bidons': emptyBidons,
        'open_bidon_volume_left_ml': openBidonVolumeLeftMl,
      },
    ));
  }

  @override
  Future<List<SuggestedOrder>> suggestedOrders({String? hotelId}) async {
    final scopedInventory = await inventory(hotelId: hotelId);
    return scopedInventory
        .map((item) {
          final recycleCount = _roomProducts
              .where((roomProduct) =>
                  roomProduct.hotelId == item.hotelId &&
                  roomProduct.product.id == item.product.id &&
                  (roomProduct.status == BottleStatus.refillLimitReached ||
                      roomProduct.status == BottleStatus.tooOld ||
                      roomProduct.status == BottleStatus.needsReplacement))
              .length;
          return SuggestedOrder(
            hotelId: item.hotelId,
            product: item.product,
            bottlesToOrder:
                max(item.product.lowBottleThreshold * 2 - item.fullBottles, 0),
            bidonsToOrder: item.product.isRefillable
                ? max(item.product.lowBidonThreshold * 2 - item.fullBidons, 0)
                : 0,
            bottlesToRecycle: recycleCount,
          );
        })
        .where((order) =>
            order.bottlesToOrder > 0 ||
            order.bidonsToOrder > 0 ||
            order.bottlesToRecycle > 0)
        .toList();
  }

  @override
  Future<List<ApprovalRequest>> approvalRequests({String? hotelId}) async {
    return _approvalRequests
        .where((item) =>
            item.status == ApprovalStatus.pending &&
            (hotelId == null || item.hotelId == hotelId))
        .toList();
  }

  @override
  Future<List<AlertItem>> alerts({String? hotelId}) async {
    return _alerts
        .where((item) => hotelId == null || item.hotelId == hotelId)
        .toList();
  }

  @override
  Future<int> refreshSmartAlerts({String? hotelId}) async {
    var created = 0;
    final now = DateTime.now();

    for (final item in await inventory(hotelId: hotelId)) {
      if (item.lowBottles) {
        created += _insertAlertIfMissing(
          AlertItem(
            id: _uuid.v4(),
            hotelId: item.hotelId,
            productId: item.product.id,
            type: AlertType.lowBottleStock,
            severity: 2,
            title: 'Low ${item.product.nameEn.toLowerCase()} bottle stock',
            body:
                '${item.fullBottles} full bottles remain. Threshold is ${item.product.lowBottleThreshold}.',
            createdAt: now,
            isResolved: false,
          ),
        );
      }

      if (item.lowBidons) {
        created += _insertAlertIfMissing(
          AlertItem(
            id: _uuid.v4(),
            hotelId: item.hotelId,
            productId: item.product.id,
            type: AlertType.lowBidonStock,
            severity: 2,
            title: 'Low ${item.product.nameEn.toLowerCase()} bidon stock',
            body:
                '${item.fullBidons} full bidons remain. Threshold is ${item.product.lowBidonThreshold}.',
            createdAt: now,
            isResolved: false,
          ),
        );
      }
    }

    for (final roomProduct in await roomProducts(hotelId: hotelId)) {
      if (roomProduct.product.isRefillable &&
          (roomProduct.refillCount >= roomProduct.product.maxRefillCount ||
           roomProduct.status == BottleStatus.refillLimitReached ||
           roomProduct.status == BottleStatus.needsReplacement)) {
        created += _insertAlertIfMissing(
          AlertItem(
            id: _uuid.v4(),
            hotelId: roomProduct.hotelId,
            roomProductId: roomProduct.id,
            productId: roomProduct.product.id,
            type: AlertType.refillLimit,
            severity: 3,
            title:
                'Room ${roomProduct.roomNumber} ${roomProduct.product.nameEn} reached refill limit',
            body:
                '${roomProduct.refillCount}/${roomProduct.product.maxRefillCount} refills used. Replace and recycle the bottle.',
            createdAt: now,
            isResolved: false,
          ),
        );
      }

      final ageDays = roomProduct.bottleAgeDays(now);
      if (ageDays >= roomProduct.product.maxBottleAgeDays) {
        created += _insertAlertIfMissing(
          AlertItem(
            id: _uuid.v4(),
            hotelId: roomProduct.hotelId,
            roomProductId: roomProduct.id,
            productId: roomProduct.product.id,
            type: AlertType.bottleAgeLimit,
            severity: 3,
            title:
                'Room ${roomProduct.roomNumber} ${roomProduct.product.nameEn} bottle is too old',
            body:
                'Bottle age is $ageDays days. Limit is ${roomProduct.product.maxBottleAgeDays} days.',
            createdAt: now,
            isResolved: false,
          ),
        );
      }
    }

    for (final request in await approvalRequests(hotelId: hotelId)) {
      if (request.status == ApprovalStatus.pending) {
        created += _insertAlertIfMissing(
          AlertItem(
            id: _uuid.v4(),
            hotelId: request.hotelId,
            type: AlertType.pendingApproval,
            severity: 1,
            title: 'Pending approval: ${request.title}',
            body: 'Requested by ${request.requestedByName}.',
            createdAt: now,
            isResolved: false,
          ),
        );
      }
    }

    return created;
  }

  @override
  Future<void> resolveAlert({required String alertId}) async {
    final index = _alerts.indexWhere((alert) => alert.id == alertId);
    if (index == -1) return;
    _alerts[index] = _alerts[index].copyWith(isResolved: true);
  }

  // In-memory user→hotel assignments for multi-hotel support
  final Map<String, Set<String>> _userHotelAssignments = {
    'user-admin': {'hotel-seaside', 'hotel-palms'},
    'user-manager': {'hotel-seaside'},
    'user-staff': {'hotel-seaside'},
  };

  @override
  Future<List<Hotel>> userHotels({required String userId}) async {
    final hotelIds = _userHotelAssignments[userId] ?? {};
    return _hotels.where((h) => hotelIds.contains(h.id)).toList();
  }

  @override
  Future<void> assignUserHotel({
    required String userId,
    required String hotelId,
  }) async {
    _userHotelAssignments.putIfAbsent(userId, () => {}).add(hotelId);
  }

  @override
  Future<void> unassignUserHotel({
    required String userId,
    required String hotelId,
  }) async {
    _userHotelAssignments[userId]?.remove(hotelId);
  }

  @override
  Future<List<AuditLog>> fetchAuditLogs() async {
    return List.from(_mockAuditLogs);
  }

  @override
  Future<void> clearAuditLogs() async {
    _mockAuditLogs.clear();
  }

  @override
  Future<List<RefillEvent>> recentRefillEvents({String? hotelId}) async {
    if (hotelId == null) return _events;
    final roomProductIds = _roomProducts
        .where((item) => item.hotelId == hotelId)
        .map((item) => item.id)
        .toSet();
    return _events
        .where((event) => roomProductIds.contains(event.roomProductId))
        .toList();
  }

  @override
  Future<List<InventoryEvent>> recentInventoryEvents({String? hotelId}) async {
    if (hotelId == null) return _inventoryEvents;
    return _inventoryEvents.where((event) => event.hotelId == hotelId).toList();
  }


  @override
  Future<Set<String>> appliedClientRequestIds({String? hotelId}) async {
    // The demo repository records every processed idempotency key, mirroring
    // the server-side `client_request_id` columns on refill/inventory events.
    return Set<String>.from(_processedClientRequestIds);
  }

  @override
  Future<void> createHotel({
    required String name,
    String legalName = '',
    required String city,
    required String country,
    required String contactName,
    required String email,
    required String phone,
    String address = '',
    String notes = '',
  }) async {
    _hotels.add(
      Hotel(
        id: _uuid.v4(),
        name: name,
        legalName: legalName,
        city: city,
        country: country,
        contactName: contactName,
        email: email,
        phone: phone,
        address: address,
        notes: notes,
        roomCount: 0,
        pendingEdits: 0,
      ),
    );
  }

  @override
  Future<void> deleteHotel(String hotelId) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final i = _hotels.indexWhere((h) => h.id == hotelId);
    if (i >= 0) {
      _hotels.removeAt(i);
    }
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _roomProducts.removeWhere((rp) => rp.roomId == roomId);
  }

  @override
  Future<void> deleteFloor(String floorId) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<void> deleteUser(String userId) async {
    _teamMembers.removeWhere((u) => u.id == userId);
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    _alerts.removeWhere((a) => a.id == alertId);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    _products.removeWhere((p) => p.id == productId);
  }

  @override
  Future<void> createRoomsFromTemplate({
    required String hotelId,
    required int floorNumber,
    required int firstRoomNumber,
    required int roomCount,
    required List<String> productIds,
    bool autoAdjustInventory = false,
  }) async {
    final floorId = 'floor-$hotelId-$floorNumber';
    final products = _products
        .where((product) => productIds.contains(product.id))
        .toList(growable: false);

    // Enforce inventory check first
    for (final product in products) {
      final inventoryIndex = _inventory.indexWhere(
        (stock) => stock.hotelId == hotelId && stock.product.id == product.id,
      );
      final currentStock = inventoryIndex != -1 ? _inventory[inventoryIndex].fullBottles : 0;
      if (currentStock < roomCount) {
        if (!autoAdjustInventory) {
          throw StateError('Insufficient inventory for product ${product.nameEn}. Needed: $roomCount, Available: $currentStock');
        } else {
          final needed = roomCount - currentStock;
          if (inventoryIndex != -1) {
            final stock = _inventory[inventoryIndex];
            _inventory[inventoryIndex] = stock.copyWith(
              fullBottles: stock.fullBottles + needed,
            );
          } else {
            _inventory.add(InventoryItem(
              id: _uuid.v4(),
              hotelId: hotelId,
              product: product,
              fullBottles: needed,
              emptyBottles: 0,
              fullBidons: 0,
              openBidons: 0,
              emptyBidons: 0,
            ));
          }
          // Log adjustment
          _inventoryEvents.insert(
            0,
            InventoryEvent(
              id: _uuid.v4(),
              hotelId: hotelId,
              productId: product.id,
              fullBottlesDelta: needed,
              emptyBottlesDelta: 0,
              fullBidonsDelta: 0,
              openBidonsDelta: 0,
              emptyBidonsDelta: 0,
              reason: 'Auto-adjusted for room creation template',
              performedBy: _currentUser.id,
              occurredAt: DateTime.now(),
            ),
          );
        }
      }
    }

    for (var index = 0; index < roomCount; index += 1) {
      final roomNumber = '${firstRoomNumber + index}';
      final roomId = _uuid.v4();
      _rooms.add(
        RoomInfo(
          id: roomId,
          hotelId: hotelId,
          floorId: floorId,
          roomNumber: roomNumber,
          floorNumber: floorNumber,
          productCount: products.length,
        ),
      );

      for (final product in products) {
        final roomProductId = _uuid.v4();
        _roomProducts.add(
          RoomProduct(
            id: roomProductId,
            hotelId: hotelId,
            roomId: roomId,
            roomNumber: roomNumber,
            floorNumber: floorNumber,
            product: product,
            refillCount: 0,
            lastRefillAt: null,
            bottleStartedAt: DateTime.now(),
            status: BottleStatus.active,
          ),
        );

        // Decrement stock
        final inventoryIndex = _inventory.indexWhere(
          (stock) => stock.hotelId == hotelId && stock.product.id == product.id,
        );
        if (inventoryIndex != -1) {
          final stock = _inventory[inventoryIndex];
          _inventory[inventoryIndex] = stock.copyWith(
            fullBottles: max(stock.fullBottles - 1, 0),
          );
        }

        // Log the initial bottle placement so a freshly created room shows a
        // "New bottle placed" entry in its history (the UI treats a
        // bottleReplaced event with previousRefillCount == 0 as the initial
        // placement).
        _events.insert(
          0,
          RefillEvent(
            id: _uuid.v4(),
            roomProductId: roomProductId,
            type: RefillEventType.bottleReplaced,
            previousRefillCount: 0,
            newRefillCount: 0,
            occurredAt: DateTime.now(),
            performedBy: _currentUser.id,
            notes: 'Initial bottle placement',
          ),
        );
      }
    }

    final hotelIndex = _hotels.indexWhere((hotel) => hotel.id == hotelId);
    if (hotelIndex != -1) {
      _hotels[hotelIndex] = _hotels[hotelIndex].copyWith(
        roomCount: _rooms.where((room) => room.hotelId == hotelId).length,
      );
    }
  }

  @override
  Future<void> inviteTeamMember({
    required String email,
    required String fullName,
    required String role,
    String? hotelId,
  }) async {
    Hotel? hotel;
    for (final item in _hotels) {
      if (item.id == hotelId) hotel = item;
    }
    _teamInvitations.insert(
      0,
      TeamInvitation(
        id: _uuid.v4(),
        email: email,
        fullName: fullName,
        role: UserRole.fromValue(role),
        status: 'pending',
        createdAt: DateTime.now(),
        inviteToken: _uuid.v4(),
        hotelId: hotelId,
        hotelName: hotel?.name,
      ),
    );
  }

  @override
  Future<TeamInvitation?> invitationByToken({required String token}) async {
    for (final invitation in _teamInvitations) {
      if (invitation.inviteToken == token && invitation.status == 'pending') {
        return invitation;
      }
    }
    return null;
  }

  @override
  Future<void> acceptTeamInvitation({required String token}) async {
    final index = _teamInvitations.indexWhere(
      (invite) => invite.inviteToken == token && invite.status == 'pending',
    );
    if (index == -1) {
      throw StateError('Pending invitation not found.');
    }

    final invitation = _teamInvitations[index];
    _teamInvitations[index] = invitation.copyWith(status: 'accepted');
    _teamMembers.add(
      UserProfile(
        id: _uuid.v4(),
        fullName: invitation.fullName,
        email: invitation.email,
        role: invitation.role,
        roleString: invitation.role.value,
        hotelId: invitation.hotelId,
      ),
    );
  }

  @override
  Future<void> cancelTeamInvitation({required String invitationId}) async {
    final index =
        _teamInvitations.indexWhere((invite) => invite.id == invitationId);
    if (index == -1) return;
    _teamInvitations[index] = _teamInvitations[index].copyWith(
      status: 'cancelled',
    );
  }

  @override
  Future<void> resendTeamInvitation({required String invitationId}) async {
    final index =
        _teamInvitations.indexWhere((invite) => invite.id == invitationId);
    if (index == -1) return;
    _teamInvitations[index] = _teamInvitations[index].copyWith(
      status: 'pending',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> setTeamMemberActive({
    required String userId,
    required bool isActive,
  }) async {
    final index = _teamMembers.indexWhere((member) => member.id == userId);
    if (index == -1 || userId == _currentUser.id) return;
    _teamMembers[index] = _teamMembers[index].copyWith(isActive: isActive);
  }

  @override
  Future<void> createProduct({
    required String sku,
    required String nameEn,
    required String nameFr,
    required String nameAr,
    String nameIt = '',
    required int bottleVolumeMl,
    required int bidonVolumeMl,
    required int maxRefillCount,
    required int maxBottleAgeDays,
    required int lowBottleThreshold,
    required int lowBidonThreshold,
    String? imageUrl,
    BottleType bottleType = BottleType.withPump,
    RefillType refillType = RefillType.refillable,
  }) async {
    _products.add(
      Product(
        id: _uuid.v4(),
        sku: sku,
        nameEn: nameEn,
        nameFr: nameFr,
        nameAr: nameAr,
        nameIt: nameIt.isEmpty ? nameEn : nameIt,
        bottleVolumeMl: bottleVolumeMl,
        bidonVolumeMl: bidonVolumeMl,
        maxRefillCount: maxRefillCount,
        maxBottleAgeDays: maxBottleAgeDays,
        lowBottleThreshold: lowBottleThreshold,
        lowBidonThreshold: lowBidonThreshold,
        imageUrl: imageUrl,
        bottleType: bottleType,
        refillType: refillType,
      ),
    );
  }

  @override
  Future<void> updateProduct({
    required String productId,
    required String sku,
    required String nameEn,
    required String nameFr,
    required String nameAr,
    String nameIt = '',
    required int bottleVolumeMl,
    required int bidonVolumeMl,
    required int maxRefillCount,
    required int maxBottleAgeDays,
    required int lowBottleThreshold,
    required int lowBidonThreshold,
    String? imageUrl,
    BottleType bottleType = BottleType.withPump,
    RefillType refillType = RefillType.refillable,
  }) async {
    final index = _products.indexWhere((product) => product.id == productId);
    if (index == -1) return;

    final updated = _products[index].copyWith(
      sku: sku,
      nameEn: nameEn,
      nameFr: nameFr,
      nameAr: nameAr,
      nameIt: nameIt.isEmpty ? nameEn : nameIt,
      bottleVolumeMl: bottleVolumeMl,
      bidonVolumeMl: bidonVolumeMl,
      maxRefillCount: maxRefillCount,
      maxBottleAgeDays: maxBottleAgeDays,
      lowBottleThreshold: lowBottleThreshold,
      lowBidonThreshold: lowBidonThreshold,
      imageUrl: imageUrl,
      bottleType: bottleType,
      refillType: refillType,
    );
    _products[index] = updated;

    // Update product inside _roomProducts
    for (int i = 0; i < _roomProducts.length; i++) {
      if (_roomProducts[i].product.id == productId) {
        _roomProducts[i] = _roomProducts[i].copyWith(product: updated);
      }
    }

    // Update product inside _inventory
    for (int i = 0; i < _inventory.length; i++) {
      if (_inventory[i].product.id == productId) {
        _inventory[i] = _inventory[i].copyWith(product: updated);
      }
    }
  }

  @override
  Future<void> recordRefill({
    required String roomProductId,
    String? notes,
    String? clientRequestId,
  }) async {
    if (_hasProcessedClientRequest(clientRequestId)) return;

    final index = _roomProducts.indexWhere((item) => item.id == roomProductId);
    if (index == -1) {
      throw StateError('Room product not found.');
    }

    final item = _roomProducts[index];
    final newCount = item.refillCount + 1;
    final status = newCount >= item.product.maxRefillCount
        ? BottleStatus.refillLimitReached
        : BottleStatus.refilled;
    final event = RefillEvent(
      id: _uuid.v4(),
      roomProductId: roomProductId,
      type: RefillEventType.refill,
      previousRefillCount: item.refillCount,
      newRefillCount: newCount,
      occurredAt: DateTime.now(),
      performedBy: _currentUser.id,
      performedByName: _currentUser.fullName,
      notes: notes,
      clientRequestId: clientRequestId,
    );

    _events.insert(0, event);
    _roomProducts[index] = item.copyWith(
      refillCount: newCount,
      lastRefillAt: event.occurredAt,
      status: status,
    );

    // Dynamic Inventory Refill Container (Bidon) Calculations
    if (item.product.refillType == RefillType.refillable) {
      int percentageVal = 100;
      if (notes != null) {
        final percentageMatch = RegExp(r'\[Refill:\s*(\d+)%\]').firstMatch(notes);
        if (percentageMatch != null) {
          percentageVal = int.parse(percentageMatch.group(1)!);
        }
      }

      final double bottleVol = item.product.bottleVolumeMl > 0 ? item.product.bottleVolumeMl.toDouble() : 1000.0;
      final double volumeAdded = (percentageVal / 100.0) * bottleVol;

      if (_currentUser.role == UserRole.housekeeper) {
        final allocIndex = _housekeeperAllocations.indexWhere(
          (alloc) => alloc.housekeeperId == _currentUser.id && alloc.product.id == item.product.id,
        );
        if (allocIndex != -1) {
          final alloc = _housekeeperAllocations[allocIndex];
          final double bidonVolume = alloc.product.bidonVolumeMl > 0 ? alloc.product.bidonVolumeMl.toDouble() : 5000.0;

          int fullBidons = alloc.fullBidons;
          int openBidons = alloc.openBidons;
          int emptyBidons = alloc.emptyBidons;

          double currentVolumeLeft = alloc.openBidonVolumeLeftMl;
          if (openBidons > 0 && currentVolumeLeft == 0.0) {
            currentVolumeLeft = bidonVolume;
          }

          currentVolumeLeft -= volumeAdded;

          while (currentVolumeLeft <= 0) {
            if (fullBidons > 0) {
              if (openBidons > 0) {
                emptyBidons++;
              }
              fullBidons--;
              openBidons = 1;
              currentVolumeLeft += bidonVolume;
            } else {
              if (openBidons > 0) {
                emptyBidons++;
              }
              currentVolumeLeft = 0.0;
              openBidons = 0;
              break; // Out of stock
            }
          }

          _housekeeperAllocations[allocIndex] = alloc.copyWith(
            fullBidons: fullBidons,
            openBidons: openBidons,
            emptyBidons: emptyBidons,
            openBidonVolumeLeftMl: currentVolumeLeft,
          );
        }
      } else {
        final invIndex = _inventory.indexWhere(
          (stock) => stock.hotelId == item.hotelId && stock.product.id == item.product.id,
        );
        if (invIndex != -1) {
          final invItem = _inventory[invIndex];
          final double bidonVolume = invItem.product.bidonVolumeMl > 0 ? invItem.product.bidonVolumeMl.toDouble() : 5000.0;

          int fullBidons = invItem.fullBidons;
          int openBidons = invItem.openBidons;
          int emptyBidons = invItem.emptyBidons;

          // Track remaining volume of currently open bidon
          double currentVolumeLeft = _openBidonVolumeLeft[invItem.product.id] ?? invItem.openBidonVolumeLeftMl;
          if (openBidons > 0 && currentVolumeLeft == 0.0) {
            currentVolumeLeft = bidonVolume;
          }

          currentVolumeLeft -= volumeAdded;

          while (currentVolumeLeft <= 0) {
            if (fullBidons > 0) {
              if (openBidons > 0) {
                emptyBidons++;
              }
              fullBidons--;
              openBidons = 1;
              currentVolumeLeft += bidonVolume;
            } else {
              if (openBidons > 0) {
                emptyBidons++;
              }
              currentVolumeLeft = 0.0;
              openBidons = 0;
              break; // Out of stock
            }
          }

          _openBidonVolumeLeft[invItem.product.id] = currentVolumeLeft;

          _inventory[invIndex] = invItem.copyWith(
            fullBidons: fullBidons,
            openBidons: openBidons,
            emptyBidons: emptyBidons,
            openBidonVolumeLeftMl: currentVolumeLeft,
          );
        }
      }
    }

    _markClientRequestProcessed(clientRequestId);
  }

  @override
  Future<void> undoRefill({
    required String refillEventId,
    String? clientRequestId,
  }) async {
    if (_hasProcessedClientRequest(clientRequestId)) return;

    final event = _events.firstWhere((item) => item.id == refillEventId);
    if (!event.canUndo(DateTime.now(), _currentUser.id)) {
      throw StateError('Undo is only available for 30 minutes.');
    }

    final index = _roomProducts.indexWhere(
      (item) => item.id == event.roomProductId,
    );
    if (index == -1) return;

    final item = _roomProducts[index];
    _events.insert(
      0,
      RefillEvent(
        id: _uuid.v4(),
        roomProductId: item.id,
        type: RefillEventType.undo,
        previousRefillCount: item.refillCount,
        newRefillCount: event.previousRefillCount,
        occurredAt: DateTime.now(),
        performedBy: _currentUser.id,
        performedByName: _currentUser.fullName,
      ),
    );
    _roomProducts[index] = item.copyWith(
      refillCount: event.previousRefillCount,
      status: BottleStatus.active,
    );

    // Restore volume/bidons symmetrically
    if (item.product.refillType == RefillType.refillable) {
      int percentageVal = 100;
      if (event.notes != null) {
        final percentageMatch = RegExp(r'\[Refill:\s*(\d+)%\]').firstMatch(event.notes!);
        if (percentageMatch != null) {
          percentageVal = int.parse(percentageMatch.group(1)!);
        }
      }

      final double bottleVol = item.product.bottleVolumeMl > 0 ? item.product.bottleVolumeMl.toDouble() : 1000.0;
      final double bidonVolume = item.product.bidonVolumeMl > 0 ? item.product.bidonVolumeMl.toDouble() : 5000.0;
      final double volumeToRestore = (percentageVal / 100.0) * bottleVol;

      if (_currentUser.role == UserRole.housekeeper) {
        final allocIndex = _housekeeperAllocations.indexWhere(
          (alloc) => alloc.housekeeperId == _currentUser.id && alloc.product.id == item.product.id,
        );
        if (allocIndex != -1) {
          final alloc = _housekeeperAllocations[allocIndex];
          int fullBidons = alloc.fullBidons;
          int openBidons = alloc.openBidons;
          int emptyBidons = alloc.emptyBidons;

          double currentVolumeLeft = alloc.openBidonVolumeLeftMl;

          if (openBidons == 0 && emptyBidons > 0) {
            openBidons = 1;
            emptyBidons--;
            currentVolumeLeft = 0.0;
          }

          currentVolumeLeft += volumeToRestore;

          while (currentVolumeLeft > bidonVolume && emptyBidons > 0) {
            emptyBidons--;
            fullBidons++;
            currentVolumeLeft -= bidonVolume;
          }

          if (currentVolumeLeft > bidonVolume) {
            currentVolumeLeft = bidonVolume;
          }

          _housekeeperAllocations[allocIndex] = alloc.copyWith(
            fullBidons: fullBidons,
            openBidons: openBidons,
            emptyBidons: emptyBidons,
            openBidonVolumeLeftMl: currentVolumeLeft,
          );
        }
      } else {
        final invIndex = _inventory.indexWhere(
          (stock) => stock.hotelId == item.hotelId && stock.product.id == item.product.id,
        );
        if (invIndex != -1) {
          final invItem = _inventory[invIndex];

          int fullBidons = invItem.fullBidons;
          int openBidons = invItem.openBidons;
          int emptyBidons = invItem.emptyBidons;

          double currentVolumeLeft = _openBidonVolumeLeft[invItem.product.id] ?? invItem.openBidonVolumeLeftMl;

          if (openBidons == 0 && emptyBidons > 0) {
            openBidons = 1;
            emptyBidons--;
            currentVolumeLeft = 0.0;
          }

          currentVolumeLeft += volumeToRestore;

          while (currentVolumeLeft > bidonVolume && emptyBidons > 0) {
            emptyBidons--;
            fullBidons++;
            currentVolumeLeft -= bidonVolume;
          }

          if (currentVolumeLeft > bidonVolume) {
            currentVolumeLeft = bidonVolume;
          }

          _openBidonVolumeLeft[invItem.product.id] = currentVolumeLeft;

          _inventory[invIndex] = invItem.copyWith(
            fullBidons: fullBidons,
            openBidons: openBidons,
            emptyBidons: emptyBidons,
            openBidonVolumeLeftMl: currentVolumeLeft,
          );
        }
      }
    }

    _markClientRequestProcessed(clientRequestId);
  }

  @override
  Future<void> requestCorrection({
    required String refillEventId,
    required String reason,
    String? clientRequestId,
  }) async {
    if (_hasProcessedClientRequest(clientRequestId)) return;

    final event = _events.firstWhere((item) => item.id == refillEventId);
    final roomProduct = _roomProducts.firstWhere(
      (item) => item.id == event.roomProductId,
    );
    _approvalRequests.insert(
      0,
      ApprovalRequest(
        id: _uuid.v4(),
        hotelId: roomProduct.hotelId,
        title: 'Correction request for room ${roomProduct.roomNumber}',
        targetTable: 'correction_requests',
        status: ApprovalStatus.pending,
        requestedByName: _currentUser.fullName,
        requestedAt: DateTime.now(),
        oldValue: 'Refill count ${event.newRefillCount}',
        newValue: reason,
      ),
    );
    _markClientRequestProcessed(clientRequestId);
  }

  @override
  Future<void> replaceBottle({
    required String roomProductId,
    String? notes,
    String? clientRequestId,
    bool autoAdjustInventory = false,
  }) async {
    if (_hasProcessedClientRequest(clientRequestId)) return;

    final index = _roomProducts.indexWhere((item) => item.id == roomProductId);
    if (index == -1) {
      throw StateError('Room product not found.');
    }

    final item = _roomProducts[index];

    if (_currentUser.role == UserRole.housekeeper) {
      final allocIndex = _housekeeperAllocations.indexWhere(
        (alloc) => alloc.housekeeperId == _currentUser.id && alloc.product.id == item.product.id,
      );
      int availableBottles = 0;
      if (allocIndex != -1) {
        availableBottles = _housekeeperAllocations[allocIndex].fullBottles;
      }

      if (availableBottles == 0) {
        if (!autoAdjustInventory) {
          throw StateError('Insufficient checked-out allocation for product ${item.product.nameEn}. Stock is 0.');
        } else {
          // Auto adjust
          if (allocIndex != -1) {
            final existing = _housekeeperAllocations[allocIndex];
            _housekeeperAllocations[allocIndex] = existing.copyWith(
              fullBottles: existing.fullBottles + 1,
            );
          } else {
            _housekeeperAllocations.add(HousekeeperAllocation(
              id: _uuid.v4(),
              housekeeperId: _currentUser.id,
              hotelId: item.hotelId,
              product: item.product,
              fullBottles: 1,
              emptyBottles: 0,
              fullBidons: 0,
              openBidons: 0,
              emptyBidons: 0,
              openBidonVolumeLeftMl: 0.0,
            ));
          }
        }
      }

      final now = DateTime.now();
      _events.insert(
        0,
        RefillEvent(
          id: _uuid.v4(),
          roomProductId: item.id,
          type: RefillEventType.bottleReplaced,
          previousRefillCount: item.refillCount,
          newRefillCount: 0,
          occurredAt: now,
          performedBy: _currentUser.id,
          performedByName: _currentUser.fullName,
          notes: notes,
          clientRequestId: clientRequestId,
        ),
      );
      _roomProducts[index] = RoomProduct(
        id: item.id,
        hotelId: item.hotelId,
        roomId: item.roomId,
        roomNumber: item.roomNumber,
        floorNumber: item.floorNumber,
        product: item.product,
        refillCount: 0,
        lastRefillAt: null,
        bottleStartedAt: now,
        status: BottleStatus.active,
      );

      final finalAllocIndex = _housekeeperAllocations.indexWhere(
        (alloc) => alloc.housekeeperId == _currentUser.id && alloc.product.id == item.product.id,
      );
      if (finalAllocIndex != -1) {
        final existing = _housekeeperAllocations[finalAllocIndex];
        _housekeeperAllocations[finalAllocIndex] = existing.copyWith(
          fullBottles: max(existing.fullBottles - 1, 0),
          emptyBottles: existing.emptyBottles + 1,
        );
      }

    } else {
      // Enforce inventory check first
      final inventoryIndex = _inventory.indexWhere(
        (stock) => stock.hotelId == item.hotelId && stock.product.id == item.product.id,
      );
      final currentStock = inventoryIndex != -1 ? _inventory[inventoryIndex].fullBottles : 0;
      if (currentStock == 0) {
        if (!autoAdjustInventory) {
          throw StateError('Insufficient inventory for replacement.');
        } else {
          // Auto adjust: add 1 full bottle
          if (inventoryIndex != -1) {
            final stock = _inventory[inventoryIndex];
            _inventory[inventoryIndex] = stock.copyWith(
              fullBottles: stock.fullBottles + 1,
            );
          } else {
            _inventory.add(InventoryItem(
              id: _uuid.v4(),
              hotelId: item.hotelId,
              product: item.product,
              fullBottles: 1,
              emptyBottles: 0,
              fullBidons: 0,
              openBidons: 0,
              emptyBidons: 0,
            ));
          }
          // Log event
          _inventoryEvents.insert(
            0,
            InventoryEvent(
              id: _uuid.v4(),
              hotelId: item.hotelId,
              productId: item.product.id,
              fullBottlesDelta: 1,
              emptyBottlesDelta: 0,
              fullBidonsDelta: 0,
              openBidonsDelta: 0,
              emptyBidonsDelta: 0,
              reason: 'Auto-adjusted for replacement',
              performedBy: _currentUser.id,
              occurredAt: DateTime.now(),
            ),
          );
        }
      }

      final now = DateTime.now();
      _events.insert(
        0,
        RefillEvent(
          id: _uuid.v4(),
          roomProductId: item.id,
          type: RefillEventType.bottleReplaced,
          previousRefillCount: item.refillCount,
          newRefillCount: 0,
          occurredAt: now,
          performedBy: _currentUser.id,
          performedByName: _currentUser.fullName,
          notes: notes,
          clientRequestId: clientRequestId,
        ),
      );
      _roomProducts[index] = RoomProduct(
        id: item.id,
        hotelId: item.hotelId,
        roomId: item.roomId,
        roomNumber: item.roomNumber,
        floorNumber: item.floorNumber,
        product: item.product,
        refillCount: 0,
        lastRefillAt: null,
        bottleStartedAt: now,
        status: BottleStatus.active,
      );

      // Re-fetch index in case it was added
      final finalInventoryIndex = _inventory.indexWhere(
        (stock) => stock.hotelId == item.hotelId && stock.product.id == item.product.id,
      );
      if (finalInventoryIndex != -1) {
        final stock = _inventory[finalInventoryIndex];
        _inventory[finalInventoryIndex] = stock.copyWith(
          fullBottles: max(stock.fullBottles - 1, 0),
          emptyBottles: stock.emptyBottles + 1,
        );
      }
    }

    _markClientRequestProcessed(clientRequestId);
  }

  @override
  Future<String?> submitChangeRequest({
    required String hotelId,
    required String title,
    required String targetTable,
    required String targetId,
    required Map<String, dynamic> oldData,
    required Map<String, dynamic> newData,
    String? clientRequestId,
  }) async {
    if (_hasProcessedClientRequest(clientRequestId)) {
      for (final request in _approvalRequests) {
        if (request.targetId == targetId) return request.id;
      }
      return null;
    }

    final requestId = _uuid.v4();
    _approvalRequests.insert(
      0,
      ApprovalRequest(
        id: requestId,
        hotelId: hotelId,
        title: title,
        targetTable: targetTable,
        targetId: targetId,
        status: ApprovalStatus.pending,
        requestedByName: _currentUser.fullName,
        requestedAt: DateTime.now(),
        oldValue: oldData.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(', '),
        newValue: newData.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(', '),
        oldData: Map<String, dynamic>.from(oldData),
        newData: Map<String, dynamic>.from(newData),
      ),
    );
    _insertAlertIfMissing(
      AlertItem(
        id: _uuid.v4(),
        hotelId: hotelId,
        type: AlertType.pendingApproval,
        severity: 1,
        title: 'Pending approval: $title',
        body: 'Requested by ${_currentUser.fullName}.',
        createdAt: DateTime.now(),
        isResolved: false,
      ),
    );

    final hotelIndex = _hotels.indexWhere((hotel) => hotel.id == hotelId);
    if (hotelIndex != -1) {
      _hotels[hotelIndex] = _hotels[hotelIndex].copyWith(
        pendingEdits: _hotels[hotelIndex].pendingEdits + 1,
      );
    }
    _markClientRequestProcessed(clientRequestId);
    return requestId;
  }

  @override
  Future<void> recordStockAdjustment({
    required String hotelId,
    required String productId,
    int fullBottlesDelta = 0,
    int emptyBottlesDelta = 0,
    int fullBidonsDelta = 0,
    int openBidonsDelta = 0,
    int emptyBidonsDelta = 0,
    String reason = '',
    String? clientRequestId,
  }) async {
    if (_hasProcessedClientRequest(clientRequestId)) return;

    final index = _inventory.indexWhere(
      (item) => item.hotelId == hotelId && item.product.id == productId,
    );
    if (index == -1) return;

    final item = _inventory[index];
    _inventory[index] = item.copyWith(
      fullBottles: max(item.fullBottles + fullBottlesDelta, 0),
      emptyBottles: max(item.emptyBottles + emptyBottlesDelta, 0),
      fullBidons: max(item.fullBidons + fullBidonsDelta, 0),
      openBidons: max(item.openBidons + openBidonsDelta, 0),
      emptyBidons: max(item.emptyBidons + emptyBidonsDelta, 0),
    );

    final event = InventoryEvent(
      id: 'inv-evt-${DateTime.now().microsecondsSinceEpoch}',
      hotelId: hotelId,
      productId: productId,
      fullBottlesDelta: fullBottlesDelta,
      emptyBottlesDelta: emptyBottlesDelta,
      fullBidonsDelta: fullBidonsDelta,
      openBidonsDelta: openBidonsDelta,
      emptyBidonsDelta: emptyBidonsDelta,
      reason: reason,
      performedBy: _currentUser.id,
      occurredAt: DateTime.now(),
      clientRequestId: clientRequestId,
    );
    _inventoryEvents.insert(0, event);

    _markClientRequestProcessed(clientRequestId);
  }


  bool _hasProcessedClientRequest(String? clientRequestId) {
    if (clientRequestId == null || clientRequestId.trim().isEmpty) {
      return false;
    }
    return _processedClientRequestIds.contains(clientRequestId);
  }

  void _markClientRequestProcessed(String? clientRequestId) {
    if (clientRequestId == null || clientRequestId.trim().isEmpty) {
      return;
    }
    _processedClientRequestIds.add(clientRequestId);
  }

  @override
  Future<void> approveRequest({
    required String approvalRequestId,
    String? notes,
  }) async {
    final request = _approvalRequests.firstWhere(
      (item) => item.id == approvalRequestId,
    );
    _applyApprovedChange(request);
    _resolveRelatedApprovalAlerts(approvalRequestId);
    _approvalRequests.removeWhere((item) => item.id == approvalRequestId);
  }

  @override
  Future<void> rejectRequest({
    required String approvalRequestId,
    String? notes,
  }) async {
    _resolveRelatedApprovalAlerts(approvalRequestId);
    _approvalRequests.removeWhere((item) => item.id == approvalRequestId);
  }

  int _insertAlertIfMissing(AlertItem alert) {
    final exists = _alerts.any((item) {
      return !item.isResolved &&
          item.hotelId == alert.hotelId &&
          item.roomProductId == alert.roomProductId &&
          item.productId == alert.productId &&
          item.type == alert.type &&
          item.title == alert.title;
    });
    if (exists) return 0;
    _alerts.insert(0, alert);
    return 1;
  }

  void _resolveRelatedApprovalAlerts(String approvalRequestId) {
    ApprovalRequest? request;
    for (final item in _approvalRequests) {
      if (item.id == approvalRequestId) request = item;
    }
    if (request == null) return;

    for (var index = 0; index < _alerts.length; index += 1) {
      final alert = _alerts[index];
      if (alert.hotelId == request.hotelId &&
          alert.type == AlertType.pendingApproval &&
          !alert.isResolved &&
          (alert.title == 'Pending approval: ${request.title}' ||
              alert.body == request.title)) {
        _alerts[index] = alert.copyWith(isResolved: true);
      }
    }
  }

  void _applyApprovedChange(ApprovalRequest request) {
    switch (request.targetTable) {
      case 'hotels':
        final index =
            _hotels.indexWhere((hotel) => hotel.id == request.targetId);
        if (index == -1) return;
        final hotel = _hotels[index];
        _hotels[index] = hotel.copyWith(
          name: request.newData['name'] as String?,
          legalName: request.newData['legal_name'] as String?,
          city: request.newData['city'] as String?,
          country: request.newData['country'] as String?,
          contactName: request.newData['contact_name'] as String?,
          email: request.newData['email'] as String?,
          phone: request.newData['phone'] as String?,
          address: request.newData['address'] as String?,
          notes: request.newData['notes'] as String?,
          pendingEdits: max(hotel.pendingEdits - 1, 0),
        );
        return;
      case 'rooms':
        final roomNumber = request.newData['room_number'] as String?;
        final floorNumber = request.newData['floor_number'] as int?;
        final roomIndex =
            _rooms.indexWhere((room) => room.id == request.targetId);
        if (roomIndex != -1) {
          final room = _rooms[roomIndex];
          _rooms[roomIndex] = RoomInfo(
            id: room.id,
            hotelId: room.hotelId,
            floorId: room.floorId,
            roomNumber: roomNumber ?? room.roomNumber,
            floorNumber: floorNumber ?? room.floorNumber,
            productCount: room.productCount,
          );
        }
        for (var index = 0; index < _roomProducts.length; index += 1) {
          final item = _roomProducts[index];
          if (item.roomId == request.targetId) {
            _roomProducts[index] = item.copyWith(
              roomNumber: roomNumber,
              floorNumber: floorNumber,
            );
          }
        }
        final productIds = request.newData['product_ids'] as List<dynamic>?;
        if (productIds != null) {
          final stringProductIds = productIds.cast<String>();
          // Remove products that are not in the new list
          _roomProducts.removeWhere((rp) =>
              rp.roomId == request.targetId! &&
              !stringProductIds.contains(rp.product.id));

          final autoAdjust = request.newData['auto_adjust_inventory'] == true;

          // Find products that need to be added
          for (final pid in stringProductIds) {
            final exists = _roomProducts.any((rp) =>
                rp.roomId == request.targetId! && rp.product.id == pid);
            if (!exists) {
              final productIndex = _products.indexWhere((p) => p.id == pid);
              if (productIndex != -1) {
                final product = _products[productIndex];

                // Check inventory
                final inventoryIndex = _inventory.indexWhere(
                  (stock) => stock.hotelId == request.hotelId && stock.product.id == pid,
                );
                final currentStock = inventoryIndex != -1 ? _inventory[inventoryIndex].fullBottles : 0;
                if (currentStock == 0) {
                  if (!autoAdjust) {
                    throw StateError('Insufficient inventory for product ${product.nameEn}. Stock is 0.');
                  } else {
                    // Auto-adjust: add 1 full bottle
                    if (inventoryIndex != -1) {
                      final stock = _inventory[inventoryIndex];
                      _inventory[inventoryIndex] = stock.copyWith(
                        fullBottles: stock.fullBottles + 1,
                      );
                    } else {
                      _inventory.add(InventoryItem(
                        id: _uuid.v4(),
                        hotelId: request.hotelId,
                        product: product,
                        fullBottles: 1,
                        emptyBottles: 0,
                        fullBidons: 0,
                        openBidons: 0,
                        emptyBidons: 0,
                      ));
                    }
                    // Log adjustment
                    _inventoryEvents.insert(
                      0,
                      InventoryEvent(
                        id: _uuid.v4(),
                        hotelId: request.hotelId,
                        productId: product.id,
                        fullBottlesDelta: 1,
                        emptyBottlesDelta: 0,
                        fullBidonsDelta: 0,
                        openBidonsDelta: 0,
                        emptyBidonsDelta: 0,
                        reason: 'Auto-adjusted for room product addition',
                        performedBy: _currentUser.id,
                        occurredAt: DateTime.now(),
                      ),
                    );
                  }
                }

                // Decrement inventory by 1
                final finalInventoryIndex = _inventory.indexWhere(
                  (stock) => stock.hotelId == request.hotelId && stock.product.id == pid,
                );
                if (finalInventoryIndex != -1) {
                  final stock = _inventory[finalInventoryIndex];
                  _inventory[finalInventoryIndex] = stock.copyWith(
                    fullBottles: max(stock.fullBottles - 1, 0),
                  );
                }

                final roomProductId = 'rp_${DateTime.now().millisecondsSinceEpoch}_$pid';
                _roomProducts.add(RoomProduct(
                  id: roomProductId,
                  hotelId: request.hotelId,
                  roomId: request.targetId!,
                  roomNumber: roomNumber ?? (roomIndex != -1 ? _rooms[roomIndex].roomNumber : ''),
                  floorNumber: floorNumber ?? (roomIndex != -1 ? _rooms[roomIndex].floorNumber : 0),
                  product: product,
                  refillCount: 0,
                  lastRefillAt: null,
                  bottleStartedAt: DateTime.now(),
                  status: BottleStatus.active,
                ));

                // Insert initial placement refill event
                _events.insert(
                  0,
                  RefillEvent(
                    id: _uuid.v4(),
                    roomProductId: roomProductId,
                    type: RefillEventType.bottleReplaced,
                    previousRefillCount: 0,
                    newRefillCount: 0,
                    occurredAt: DateTime.now(),
                    performedBy: _currentUser.id,
                    performedByName: _currentUser.fullName,
                    notes: 'Initial bottle placement',
                  ),
                );
              }
            }
          }
        }
        _decrementHotelPendingEdits(request.hotelId);
        return;
      case 'room_products':
        final index =
            _roomProducts.indexWhere((item) => item.id == request.targetId);
        if (index == -1) return;
        final item = _roomProducts[index];
        final statusValue = request.newData['status'] as String?;
        final startValue = request.newData['bottle_started_at'] as String?;
        final proofPhotoUrl = request.newData['proof_photo_url'] as String?;
        final oldStatus = item.status;
        final newStatus = statusValue == null ? oldStatus : BottleStatus.fromValue(statusValue);

        if (oldStatus != newStatus) {
          _events.insert(
            0,
            RefillEvent(
              id: _uuid.v4(),
              roomProductId: item.id,
              type: RefillEventType.bottleReplaced,
              previousRefillCount: item.refillCount,
              newRefillCount: item.refillCount,
              occurredAt: DateTime.now(),
              performedBy: _currentUser.id,
              performedByName: _currentUser.fullName,
              notes: 'Status changed from ${oldStatus.value} to ${newStatus.value}',
              proofPhotoUrl: proofPhotoUrl,
            ),
          );
        }

        _roomProducts[index] = item.copyWith(
          status: newStatus,
          bottleStartedAt:
              startValue == null ? null : DateTime.tryParse(startValue),
        );
        _decrementHotelPendingEdits(request.hotelId);
        return;
    }
  }

  void _decrementHotelPendingEdits(String hotelId) {
    final index = _hotels.indexWhere((hotel) => hotel.id == hotelId);
    if (index == -1) return;
    final hotel = _hotels[index];
    _hotels[index] = hotel.copyWith(
      pendingEdits: max(hotel.pendingEdits - 1, 0),
    );
  }

  @override
  Future<List<String>> fetchRoles() async {
    return _mockRoles;
  }

  @override
  Future<Map<String, Set<String>>> fetchRolePermissions() async {
    return Map.from(_mockRolePermissions);
  }

  @override
  Future<List<String>> fetchAllPermissions() async {
    final all = <String>{};
    for (final permSet in _mockRolePermissions.values) {
      all.addAll(permSet);
    }
    return all.toList()..sort();
  }

  @override
  Future<void> updateRolePermission({
    required String role,
    required String permission,
    required bool isEnabled,
  }) async {
    final permissions = _mockRolePermissions[role] ?? {};
    if (isEnabled) {
      permissions.add(permission);
    } else {
      permissions.remove(permission);
    }
    _mockRolePermissions[role] = permissions;

    _mockAuditLogs.insert(
      0,
      AuditLog(
        id: 'mock_audit_${DateTime.now().millisecondsSinceEpoch}_update_perm',
        userId: 'app_admin',
        action: 'Updated role permission',
        details: {
          'role': role,
          'permission': permission,
          'is_enabled': isEnabled,
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> createRole({
    required String name,
    String? description,
  }) async {
    if (!_mockRoles.contains(name)) {
      _mockRoles.add(name);
    }
    _mockRolePermissions[name] = {};

    _mockAuditLogs.insert(
      0,
      AuditLog(
        id: 'mock_audit_${DateTime.now().millisecondsSinceEpoch}_create_role',
        userId: 'app_admin',
        action: 'Created custom role',
        details: {
          'role': name,
          'description': description ?? '',
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> removeProductFromRoom({required String roomProductId}) async {
    final roomProductIndex = _roomProducts.indexWhere((rp) => rp.id == roomProductId);
    if (roomProductIndex == -1) {
      throw Exception('RoomProduct ID $roomProductId not found');
    }
    final roomProduct = _roomProducts[roomProductIndex];
    _roomProducts.removeAt(roomProductIndex);

    // Decrement productCount for the room
    final roomIndex = _rooms.indexWhere((r) => r.id == roomProduct.roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      _rooms[roomIndex] = RoomInfo(
        id: room.id,
        hotelId: room.hotelId,
        floorId: room.floorId,
        roomNumber: room.roomNumber,
        floorNumber: room.floorNumber,
        productCount: max(room.productCount - 1, 0),
      );
    }
  }

  @override
  Future<void> addProductToRoom({
    required String hotelId,
    required String floor,
    required String roomNumber,
    required String productSku,
    bool autoAdjustInventory = false,
  }) async {
    final product = _products.where((p) => p.sku.toLowerCase() == productSku.toLowerCase()).firstOrNull;
    if (product == null) {
      throw Exception('Product SKU $productSku not found');
    }

    final floorNum = int.tryParse(floor) ?? 0;
    // Find the room or create it if not exists
    var room = _rooms.where((r) => r.hotelId == hotelId && r.roomNumber == roomNumber && r.floorNumber == floorNum).firstOrNull;
    final roomId = room?.id ?? _uuid.v4();
    if (room == null) {
      room = RoomInfo(
        id: roomId,
        hotelId: hotelId,
        floorId: 'floor-$hotelId-$floorNum',
        roomNumber: roomNumber,
        floorNumber: floorNum,
        productCount: 1,
      );
      _rooms.add(room);
    } else {
      final roomIndex = _rooms.indexOf(room);
      _rooms[roomIndex] = RoomInfo(
        id: room.id,
        hotelId: room.hotelId,
        floorId: room.floorId,
        roomNumber: room.roomNumber,
        floorNumber: room.floorNumber,
        productCount: room.productCount + 1,
      );
    }

    // Check inventory
    final inventoryIndex = _inventory.indexWhere(
      (stock) => stock.hotelId == hotelId && stock.product.id == product.id,
    );
    final currentStock = inventoryIndex != -1 ? _inventory[inventoryIndex].fullBottles : 0;

    if (currentStock <= 0) {
      if (!autoAdjustInventory) {
        throw StateError('Product not in inventory');
      } else {
        // Automatically add 1 piece to the inventory first (by adding to stock)
        if (inventoryIndex != -1) {
          final stock = _inventory[inventoryIndex];
          _inventory[inventoryIndex] = stock.copyWith(
            fullBottles: stock.fullBottles + 1,
          );
        } else {
          _inventory.add(InventoryItem(
            id: _uuid.v4(),
            hotelId: hotelId,
            product: product,
            fullBottles: 1,
            emptyBottles: 0,
            fullBidons: 0,
            openBidons: 0,
            emptyBidons: 0,
          ));
        }

        // Log adjustment event (+1 bottle)
        _inventoryEvents.insert(
          0,
          InventoryEvent(
            id: _uuid.v4(),
            hotelId: hotelId,
            productId: product.id,
            fullBottlesDelta: 1,
            emptyBottlesDelta: 0,
            fullBidonsDelta: 0,
            openBidonsDelta: 0,
            emptyBidonsDelta: 0,
            reason: 'Auto-added to inventory for single room placement',
            performedBy: _currentUser.id,
            occurredAt: DateTime.now(),
          ),
        );
      }
    }

    // Now decrement the stock by 1
    final updatedInventoryIndex = _inventory.indexWhere(
      (stock) => stock.hotelId == hotelId && stock.product.id == product.id,
    );
    if (updatedInventoryIndex != -1) {
      final stock = _inventory[updatedInventoryIndex];
      _inventory[updatedInventoryIndex] = stock.copyWith(
        fullBottles: max(stock.fullBottles - 1, 0),
      );
    }

    // Insert into room products
    final roomProductId = _uuid.v4();
    _roomProducts.add(
      RoomProduct(
        id: roomProductId,
        hotelId: hotelId,
        roomId: roomId,
        roomNumber: roomNumber,
        floorNumber: floorNum,
        product: product,
        refillCount: 0,
        lastRefillAt: null,
        bottleStartedAt: DateTime.now(),
        status: BottleStatus.active,
      ),
    );

    // Add initial replacement event for history
    _events.insert(
      0,
      RefillEvent(
        id: _uuid.v4(),
        roomProductId: roomProductId,
        type: RefillEventType.bottleReplaced,
        previousRefillCount: 0,
        newRefillCount: 0,
        occurredAt: DateTime.now(),
        performedBy: _currentUser.id,
      ),
    );
  }
}
