import 'app_enums.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.isActive = true,
    this.hotelId,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final bool isActive;
  final String? hotelId;

  bool get isIvraUser =>
      role == UserRole.appAdmin || role == UserRole.appManager;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: (map['full_name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      role: UserRole.fromValue((map['role'] ?? 'hotel_staff') as String),
      isActive: (map['is_active'] ?? true) as bool,
      hotelId: map['hotel_id'] as String?,
    );
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    UserRole? role,
    bool? isActive,
    String? hotelId,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      hotelId: hotelId ?? this.hotelId,
    );
  }
}

class TeamInvitation {
  const TeamInvitation({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    required this.createdAt,
    this.inviteToken,
    this.hotelId,
    this.hotelName,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String status;
  final DateTime createdAt;
  final String? inviteToken;
  final String? hotelId;
  final String? hotelName;

  factory TeamInvitation.fromMap(Map<String, dynamic> map) {
    return TeamInvitation(
      id: map['id'] as String,
      email: (map['email'] ?? '') as String,
      fullName: (map['full_name'] ?? '') as String,
      role: UserRole.fromValue((map['role'] ?? 'hotel_staff') as String),
      status: (map['status'] ?? 'pending') as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      inviteToken: map['invite_token'] as String?,
      hotelId: map['hotel_id'] as String?,
      hotelName: map['hotel_name'] as String?,
    );
  }

  TeamInvitation copyWith({
    String? status,
    DateTime? createdAt,
  }) {
    return TeamInvitation(
      id: id,
      email: email,
      fullName: fullName,
      role: role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      inviteToken: inviteToken,
      hotelId: hotelId,
      hotelName: hotelName,
    );
  }
}

class Hotel {
  const Hotel({
    required this.id,
    required this.name,
    this.legalName = '',
    required this.city,
    required this.country,
    required this.contactName,
    required this.email,
    required this.phone,
    this.address = '',
    this.notes = '',
    required this.roomCount,
    required this.pendingEdits,
  });

  final String id;
  final String name;
  final String legalName;
  final String city;
  final String country;
  final String contactName;
  final String email;
  final String phone;
  final String address;
  final String notes;
  final int roomCount;
  final int pendingEdits;

  Hotel copyWith({
    String? name,
    String? legalName,
    String? city,
    String? country,
    String? contactName,
    String? email,
    String? phone,
    String? address,
    String? notes,
    int? roomCount,
    int? pendingEdits,
  }) {
    return Hotel(
      id: id,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      city: city ?? this.city,
      country: country ?? this.country,
      contactName: contactName ?? this.contactName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      roomCount: roomCount ?? this.roomCount,
      pendingEdits: pendingEdits ?? this.pendingEdits,
    );
  }

  factory Hotel.fromMap(Map<String, dynamic> map) {
    return Hotel(
      id: map['id'] as String,
      name: (map['name'] ?? '') as String,
      legalName: (map['legal_name'] ?? '') as String,
      city: (map['city'] ?? '') as String,
      country: (map['country'] ?? '') as String,
      contactName: (map['contact_name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      notes: (map['notes'] ?? '') as String,
      roomCount: (map['room_count'] ?? 0) as int,
      pendingEdits: (map['pending_edits'] ?? 0) as int,
    );
  }
}

class FloorInfo {
  const FloorInfo({
    required this.id,
    required this.hotelId,
    required this.floorNumber,
    required this.name,
  });

  final String id;
  final String hotelId;
  final int floorNumber;
  final String name;
}

class RoomInfo {
  const RoomInfo({
    required this.id,
    required this.hotelId,
    required this.floorId,
    required this.roomNumber,
    required this.floorNumber,
    required this.productCount,
  });

  final String id;
  final String hotelId;
  final String floorId;
  final String roomNumber;
  final int floorNumber;
  final int productCount;

  factory RoomInfo.fromMap(Map<String, dynamic> map) {
    return RoomInfo(
      id: map['id'] as String,
      hotelId: map['hotel_id'] as String,
      floorId: map['floor_id'] as String,
      roomNumber: (map['room_number'] ?? '') as String,
      floorNumber: (map['floor_number'] ?? 0) as int,
      productCount: (map['product_count'] ?? 0) as int,
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.nameEn,
    required this.nameFr,
    required this.nameAr,
    required this.nameIt,
    this.bottleVolumeMl = 1000,
    this.bidonVolumeMl = 5000,
    required this.maxRefillCount,
    required this.maxBottleAgeDays,
    required this.lowBottleThreshold,
    required this.lowBidonThreshold,
    this.imageUrl,
  });

  final String id;
  final String sku;
  final String nameEn;
  final String nameFr;
  final String nameAr;
  final String nameIt;
  final int bottleVolumeMl;
  final int bidonVolumeMl;
  final int maxRefillCount;
  final int maxBottleAgeDays;
  final int lowBottleThreshold;
  final int lowBidonThreshold;
  final String? imageUrl;

  String label(String languageCode) {
    return switch (languageCode) {
      'fr' => nameFr,
      'ar' => nameAr,
      'it' => nameIt,
      _ => nameEn,
    };
  }

  String get imagePath {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return imageUrl!;
    }
    final cleanSku = sku.toLowerCase().replaceAll('-', '_');
    return 'assets/images/$cleanSku.png';
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      sku: (map['sku'] ?? '') as String,
      nameEn: (map['name_en'] ?? '') as String,
      nameFr: (map['name_fr'] ?? '') as String,
      nameAr: (map['name_ar'] ?? '') as String,
      nameIt: (map['name_it'] ?? map['name_en'] ?? '') as String,
      bottleVolumeMl: (map['bottle_volume_ml'] ?? 1000) as int,
      bidonVolumeMl: (map['bidon_volume_ml'] ?? 5000) as int,
      maxRefillCount: (map['max_refill_count'] ?? 0) as int,
      maxBottleAgeDays: (map['max_bottle_age_days'] ?? 0) as int,
      lowBottleThreshold: (map['low_bottle_threshold'] ?? 0) as int,
      lowBidonThreshold: (map['low_bidon_threshold'] ?? 0) as int,
      imageUrl: map['image_url'] as String?,
    );
  }

  Product copyWith({
    String? sku,
    String? nameEn,
    String? nameFr,
    String? nameAr,
    String? nameIt,
    int? bottleVolumeMl,
    int? bidonVolumeMl,
    int? maxRefillCount,
    int? maxBottleAgeDays,
    int? lowBottleThreshold,
    int? lowBidonThreshold,
    String? imageUrl,
  }) {
    return Product(
      id: id,
      sku: sku ?? this.sku,
      nameEn: nameEn ?? this.nameEn,
      nameFr: nameFr ?? this.nameFr,
      nameAr: nameAr ?? this.nameAr,
      nameIt: nameIt ?? this.nameIt,
      bottleVolumeMl: bottleVolumeMl ?? this.bottleVolumeMl,
      bidonVolumeMl: bidonVolumeMl ?? this.bidonVolumeMl,
      maxRefillCount: maxRefillCount ?? this.maxRefillCount,
      maxBottleAgeDays: maxBottleAgeDays ?? this.maxBottleAgeDays,
      lowBottleThreshold: lowBottleThreshold ?? this.lowBottleThreshold,
      lowBidonThreshold: lowBidonThreshold ?? this.lowBidonThreshold,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class RoomProduct {
  const RoomProduct({
    required this.id,
    required this.hotelId,
    required this.roomId,
    required this.roomNumber,
    required this.floorNumber,
    required this.product,
    required this.refillCount,
    required this.lastRefillAt,
    required this.bottleStartedAt,
    required this.status,
  });

  final String id;
  final String hotelId;
  final String roomId;
  final String roomNumber;
  final int floorNumber;
  final Product product;
  final int refillCount;
  final DateTime? lastRefillAt;
  final DateTime bottleStartedAt;
  final BottleStatus status;

  int bottleAgeDays(DateTime now) => now.difference(bottleStartedAt).inDays;

  bool get canRefill => status != BottleStatus.recycled;

  RoomProduct copyWith({
    String? roomNumber,
    int? floorNumber,
    int? refillCount,
    DateTime? lastRefillAt,
    DateTime? bottleStartedAt,
    BottleStatus? status,
  }) {
    return RoomProduct(
      id: id,
      hotelId: hotelId,
      roomId: roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      floorNumber: floorNumber ?? this.floorNumber,
      product: product,
      refillCount: refillCount ?? this.refillCount,
      lastRefillAt: lastRefillAt ?? this.lastRefillAt,
      bottleStartedAt: bottleStartedAt ?? this.bottleStartedAt,
      status: status ?? this.status,
    );
  }
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.hotelId,
    required this.product,
    required this.fullBottles,
    required this.emptyBottles,
    required this.fullBidons,
    required this.openBidons,
    required this.emptyBidons,
  });

  final String id;
  final String hotelId;
  final Product product;
  final int fullBottles;
  final int emptyBottles;
  final int fullBidons;
  final int openBidons;
  final int emptyBidons;

  bool get lowBottles => fullBottles <= product.lowBottleThreshold;
  bool get lowBidons => fullBidons <= product.lowBidonThreshold;

  InventoryItem copyWith({
    int? fullBottles,
    int? emptyBottles,
    int? fullBidons,
    int? openBidons,
    int? emptyBidons,
  }) {
    return InventoryItem(
      id: id,
      hotelId: hotelId,
      product: product,
      fullBottles: fullBottles ?? this.fullBottles,
      emptyBottles: emptyBottles ?? this.emptyBottles,
      fullBidons: fullBidons ?? this.fullBidons,
      openBidons: openBidons ?? this.openBidons,
      emptyBidons: emptyBidons ?? this.emptyBidons,
    );
  }
}

class RefillEvent {
  const RefillEvent({
    required this.id,
    required this.roomProductId,
    required this.type,
    required this.previousRefillCount,
    required this.newRefillCount,
    required this.occurredAt,
    required this.performedBy,
    this.notes,
  });

  final String id;
  final String roomProductId;
  final RefillEventType type;
  final int previousRefillCount;
  final int newRefillCount;
  final DateTime occurredAt;
  final String performedBy;
  final String? notes;

  bool canUndo(DateTime now, String currentUserId) {
    return type == RefillEventType.refill &&
        performedBy == currentUserId &&
        now.difference(occurredAt).inMinutes < 30;
  }
}

class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.hotelId,
    required this.title,
    required this.targetTable,
    required this.status,
    required this.requestedByName,
    required this.requestedAt,
    required this.oldValue,
    required this.newValue,
    this.targetId,
    this.oldData = const {},
    this.newData = const {},
  });

  final String id;
  final String hotelId;
  final String title;
  final String targetTable;
  final ApprovalStatus status;
  final String requestedByName;
  final DateTime requestedAt;
  final String oldValue;
  final String newValue;
  final String? targetId;
  final Map<String, dynamic> oldData;
  final Map<String, dynamic> newData;
}

class AlertItem {
  const AlertItem({
    required this.id,
    required this.hotelId,
    this.roomProductId,
    this.productId,
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isResolved,
  });

  final String id;
  final String hotelId;
  final String? roomProductId;
  final String? productId;
  final AlertType type;
  final int severity;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isResolved;

  AlertItem copyWith({
    int? severity,
    String? title,
    String? body,
    bool? isResolved,
  }) {
    return AlertItem(
      id: id,
      hotelId: hotelId,
      roomProductId: roomProductId,
      productId: productId,
      type: type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      isResolved: isResolved ?? this.isResolved,
    );
  }

  (String, String) localizedStrings(dynamic l10n, String lang, Product? product) {
    String translatedTitle = title;
    String translatedBody = body;

    if (product != null) {
      if (type == AlertType.lowBottleStock || type == AlertType.lowBidonStock) {
        final isBottle = type == AlertType.lowBottleStock;
        // SQL body format: "HotelName has N full bottles/bidons remaining. Threshold is N."
        final bodyRegex = RegExp(r'^(.+?)\s+has\s+(\d+).*?(\d+)\.$');
        final match = bodyRegex.firstMatch(body);
        if (match != null) {
          final hotelName = match.group(1) ?? '';
          final remain = match.group(2) ?? '';
          final threshold = match.group(3) ?? '';
          final productName = product.label(lang);

          translatedTitle = l10n.tParams(
            isBottle ? 'alertLowBottleTitle' : 'alertLowBidonTitle',
            {'product': productName},
          );
          translatedBody = l10n.tParams(
            isBottle ? 'alertLowBottleBody' : 'alertLowBidonBody',
            {'hotel': hotelName, 'remain': remain, 'threshold': threshold},
          );
        }
      } else if (type == AlertType.refillLimit) {
        final titleMatch = RegExp(r'Room (\S+)').firstMatch(title);
        final bodyMatch = RegExp(r'(\d+)/(\d+)').firstMatch(body);
        if (titleMatch != null && bodyMatch != null) {
          translatedTitle = l10n.tParams('alertRefillLimitTitle', {
            'room': titleMatch.group(1) ?? '',
            'product': product.label(lang),
          });
          translatedBody = l10n.tParams('alertRefillLimitBody', {
            'used': bodyMatch.group(1) ?? '',
            'max': bodyMatch.group(2) ?? '',
          });
        }
      } else if (type == AlertType.bottleAgeLimit) {
        final titleMatch = RegExp(r'Room (\S+)').firstMatch(title);
        final bodyMatch = RegExp(r'is (\d+) days.*?is (\d+) days').firstMatch(body);
        if (titleMatch != null && bodyMatch != null) {
          translatedTitle = l10n.tParams('alertBottleAgeLimitTitle', {
            'room': titleMatch.group(1) ?? '',
            'product': product.label(lang),
          });
          translatedBody = l10n.tParams('alertBottleAgeLimitBody', {
            'age': bodyMatch.group(1) ?? '',
            'limit': bodyMatch.group(2) ?? '',
          });
        }
      }
    }

    if (type == AlertType.pendingApproval) {
      final titleMatch = RegExp(r'Pending approval:\s+(.+)').firstMatch(title);
      final bodyMatch = RegExp(r'Requested by\s+(.+)\.').firstMatch(body);
      if (titleMatch != null && bodyMatch != null) {
        translatedTitle = l10n.tParams('alertPendingApprovalTitle', {
          'request': titleMatch.group(1) ?? '',
        });
        translatedBody = l10n.tParams('alertPendingApprovalBody', {
          'user': bodyMatch.group(1) ?? '',
        });
      }
    } else if (type == AlertType.suspiciousActivity) {
      final bodyMatch = RegExp(r'(.+) reported suspicious activity').firstMatch(body);
      if (bodyMatch != null) {
        translatedTitle = l10n.t('alertSuspiciousActivityTitle');
        translatedBody = l10n.tParams('alertSuspiciousActivityBody', {
          'user': bodyMatch.group(1) ?? '',
        });
      }
    } else if (type == AlertType.inactiveHotel) {
      translatedTitle = l10n.t('alertInactiveHotelTitle');
      translatedBody = l10n.t('alertInactiveHotelBody');
    }

    return (translatedTitle, translatedBody);
  }
}

class SuggestedOrder {
  const SuggestedOrder({
    required this.hotelId,
    required this.product,
    required this.bottlesToOrder,
    required this.bidonsToOrder,
    required this.bottlesToRecycle,
  });

  final String hotelId;
  final Product product;
  final int bottlesToOrder;
  final int bidonsToOrder;
  final int bottlesToRecycle;
}

class DashboardMetrics {
  const DashboardMetrics({
    required this.hotelCount,
    required this.roomCount,
    required this.pendingApprovals,
    required this.openAlerts,
    required this.bottlesToReplace,
    required this.lowStockProducts,
  });

  final int hotelCount;
  final int roomCount;
  final int pendingApprovals;
  final int openAlerts;
  final int bottlesToReplace;
  final int lowStockProducts;
}

class AuditLog {
  const AuditLog({
    required this.id,
    required this.createdAt,
    this.userId,
    required this.action,
    this.details,
    this.ipAddress,
    this.deviceInfo,
  });

  final String id;
  final DateTime createdAt;
  final String? userId;
  final String action;
  final Map<String, dynamic>? details;
  final String? ipAddress;
  final String? deviceInfo;

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      userId: map['user_id'] as String?,
      action: map['action'] as String,
      details: map['details'] as Map<String, dynamic>?,
      ipAddress: map['ip_address'] as String?,
      deviceInfo: map['device_info'] as String?,
    );
  }
}

class DailyRefillProgress {
  const DailyRefillProgress({
    required this.refilledRoomsCount,
    required this.totalRoomsCount,
    required this.nextPriorityRoom,
  });

  final int refilledRoomsCount;
  final int totalRoomsCount;
  final String nextPriorityRoom;
}

