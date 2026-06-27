import 'app_enums.dart';
import '../utils/parse_utils.dart';

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
      id: asString(map['id']),
      fullName: asString(map['full_name']),
      email: asString(map['email']),
      role: UserRole.fromValue(asString(map['role'], fallback: 'hotel_staff')),
      isActive: asBool(map['is_active'], fallback: true),
      hotelId: asNullableString(map['hotel_id']),
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
      id: asString(map['id']),
      email: asString(map['email']),
      fullName: asString(map['full_name']),
      role: UserRole.fromValue(asString(map['role'], fallback: 'hotel_staff')),
      status: asString(map['status'], fallback: 'pending'),
      createdAt: asDateTime(map['created_at']),
      inviteToken: asNullableString(map['invite_token']),
      hotelId: asNullableString(map['hotel_id']),
      hotelName: asNullableString(map['hotel_name']),
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
      id: asString(map['id']),
      name: asString(map['name']),
      legalName: asString(map['legal_name']),
      city: asString(map['city']),
      country: asString(map['country']),
      contactName: asString(map['contact_name']),
      email: asString(map['email']),
      phone: asString(map['phone']),
      address: asString(map['address']),
      notes: asString(map['notes']),
      roomCount: asInt(map['room_count']),
      pendingEdits: asInt(map['pending_edits']),
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
      id: asString(map['id']),
      hotelId: asString(map['hotel_id']),
      floorId: asString(map['floor_id']),
      roomNumber: asString(map['room_number']),
      floorNumber: asInt(map['floor_number']),
      productCount: asInt(map['product_count']),
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
    this.bottleType = BottleType.withPump,
    this.refillType = RefillType.refillable,
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
  final BottleType bottleType;
  final RefillType refillType;

  bool get isRefillable => refillType == RefillType.refillable;
  bool get isDirectReplacement => refillType == RefillType.directReplacement;

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
      id: asString(map['id']),
      sku: asString(map['sku']),
      nameEn: asString(map['name_en']),
      nameFr: asString(map['name_fr']),
      nameAr: asString(map['name_ar']),
      nameIt: asString(map['name_it'], fallback: asString(map['name_en'])),
      bottleVolumeMl: asInt(map['bottle_volume_ml'], fallback: 1000),
      bidonVolumeMl: asInt(map['bidon_volume_ml'], fallback: 5000),
      maxRefillCount: asInt(map['max_refill_count']),
      maxBottleAgeDays: asInt(map['max_bottle_age_days']),
      lowBottleThreshold: asInt(map['low_bottle_threshold']),
      lowBidonThreshold: asInt(map['low_bidon_threshold']),
      imageUrl: asNullableString(map['image_url']),
      bottleType: BottleType.fromValue(asString(map['bottle_type'], fallback: 'with_pump')),
      refillType: RefillType.fromValue(asString(map['refill_type'], fallback: 'refillable')),
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
    BottleType? bottleType,
    RefillType? refillType,
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
      bottleType: bottleType ?? this.bottleType,
      refillType: refillType ?? this.refillType,
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
    required BottleStatus status,
  }) : _status = status;

  final String id;
  final String hotelId;
  final String roomId;
  final String roomNumber;
  final int floorNumber;
  final Product product;
  final int refillCount;
  final DateTime? lastRefillAt;
  final DateTime bottleStartedAt;
  final BottleStatus _status;

  BottleStatus get status {
    if (_status == BottleStatus.damaged ||
        _status == BottleStatus.lost ||
        _status == BottleStatus.recycled ||
        _status == BottleStatus.needsReplacement) {
      return _status;
    }
    // Check refill limit for refillable products
    if (product.isRefillable && refillCount >= product.maxRefillCount) {
      return BottleStatus.refillLimitReached;
    }
    // Check age limit
    final age = DateTime.now().difference(bottleStartedAt).inDays;
    if (age >= product.maxBottleAgeDays) {
      return BottleStatus.tooOld;
    }
    return _status;
  }

  int bottleAgeDays(DateTime now) => now.difference(bottleStartedAt).inDays;

  static const _nonRefillableStatuses = {
    BottleStatus.recycled,
    BottleStatus.damaged,
    BottleStatus.lost,
    BottleStatus.tooOld,
    BottleStatus.refillLimitReached,
    BottleStatus.needsReplacement,
  };

  bool get canRefill =>
      !_nonRefillableStatuses.contains(status) && product.isRefillable;

  RoomProduct copyWith({
    String? roomNumber,
    int? floorNumber,
    Product? product,
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
      product: product ?? this.product,
      refillCount: refillCount ?? this.refillCount,
      lastRefillAt: lastRefillAt ?? this.lastRefillAt,
      bottleStartedAt: bottleStartedAt ?? this.bottleStartedAt,
      status: status ?? this._status,
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
  bool get lowBidons => product.isRefillable && fullBidons <= product.lowBidonThreshold;

  InventoryItem copyWith({
    Product? product,
    int? fullBottles,
    int? emptyBottles,
    int? fullBidons,
    int? openBidons,
    int? emptyBidons,
  }) {
    return InventoryItem(
      id: id,
      hotelId: hotelId,
      product: product ?? this.product,
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
    this.performedByName,
    this.notes,
    this.clientRequestId,
    this.proofPhotoUrl,
  });

  final String id;
  final String roomProductId;
  final RefillEventType type;
  final int previousRefillCount;
  final int newRefillCount;
  final DateTime occurredAt;
  final String performedBy;
  final String? performedByName;
  final String? notes;
  final String? proofPhotoUrl;

  /// The idempotency key supplied by the client when the originating action was
  /// recorded (== [OfflineAction.id]). Lets the optimistic offline overlay tell
  /// whether a still-queued action has already been applied on the server, so
  /// it can avoid double-counting.
  final String? clientRequestId;

  bool canUndo(DateTime now, String currentUserId) {
    return type == RefillEventType.refill &&
        performedBy == currentUserId &&
        now.difference(occurredAt).inMinutes < 30;
  }
}

class InventoryEvent {
  const InventoryEvent({
    required this.id,
    required this.hotelId,
    required this.productId,
    required this.fullBottlesDelta,
    required this.emptyBottlesDelta,
    required this.fullBidonsDelta,
    required this.openBidonsDelta,
    required this.emptyBidonsDelta,
    required this.reason,
    required this.performedBy,
    required this.occurredAt,
    this.clientRequestId,
  });

  final String id;
  final String hotelId;
  final String productId;
  final int fullBottlesDelta;
  final int emptyBottlesDelta;
  final int fullBidonsDelta;
  final int openBidonsDelta;
  final int emptyBidonsDelta;
  final String reason;
  final String performedBy;
  final DateTime occurredAt;
  final String? clientRequestId;
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
      id: asString(map['id']),
      createdAt: asDateTime(map['created_at']),
      userId: asNullableString(map['user_id']),
      action: asString(map['action']),
      details: asNullableStringMap(map['details']),
      ipAddress: asNullableString(map['ip_address']),
      deviceInfo: asNullableString(map['device_info']),
    );
  }
}

class DailyRefillProgress {
  const DailyRefillProgress({
    required this.refilledRoomsCount,
    required this.totalRoomsCount,
    required this.status,
    this.nextPriorityRoomNumber,
  });

  final int refilledRoomsCount;
  final int totalRoomsCount;

  /// Language-neutral state of the summary. Presentation layers (Flutter UI
  /// and the native home widget) localize this for the active locale rather
  /// than the provider hard-coding English text.
  final DailyRefillStatus status;

  /// Raw room number to refill next (e.g. `201`), or null when there is no
  /// priority room (everything done, or no rooms). Never a pre-formatted,
  /// English "Room N" string.
  final String? nextPriorityRoomNumber;
}

