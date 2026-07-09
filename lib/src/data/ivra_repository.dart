import '../domain/models.dart';
import '../domain/app_enums.dart';


abstract class IvraRepository {
  Future<UserProfile> currentUser();

  Future<void> updateCurrentUserProfile({
    required String fullName,
  });

  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
    UserRole? role,
  });

  Future<void> changeCurrentUserPassword({
    required String password,
  });

  Future<DashboardMetrics> dashboardMetrics({String? hotelId});
  Future<List<Hotel>> hotels();
  Future<List<UserProfile>> teamMembers({String? hotelId});
  Future<List<TeamInvitation>> teamInvitations({String? hotelId});
  Future<List<Product>> products();
  Future<List<RoomInfo>> rooms({String? hotelId});
  Future<List<RoomProduct>> roomProducts({String? hotelId, String? roomId});
  Future<List<InventoryItem>> inventory({String? hotelId});
  Future<List<HousekeeperAllocation>> fetchHousekeeperAllocations({String? housekeeperId, String? hotelId});

  /// Per-product movement history for a housekeeper's cart (checkouts,
  /// returns, room placements, refill/replace usages).
  Future<List<HousekeeperStockEvent>> fetchHousekeeperStockEvents({
    String? housekeeperId,
    String? productId,
    String? hotelId,
    int limit = 100,
  });
  Future<void> checkoutHousekeeperStock({required String housekeeperId, required String productId, required int fullBottles, required int fullBidons});
  Future<void> returnHousekeeperStock({
    required String housekeeperId,
    required String productId,
    required int fullBottles,
    required int emptyBottles,
    required int fullBidons,
    required int openBidons,
    required int emptyBidons,
    required double openBidonVolumeLeftMl,
  });
  Future<List<SuggestedOrder>> suggestedOrders({String? hotelId});
  Future<List<ApprovalRequest>> approvalRequests({String? hotelId});
  Future<List<AlertItem>> alerts({String? hotelId});
  Future<List<RefillEvent>> recentRefillEvents({String? hotelId});
  Future<List<InventoryEvent>> recentInventoryEvents({String? hotelId});


  /// Returns the set of `client_request_id`s the server has already applied for
  /// the given hotel (refill/replace events plus stock-adjustment events).
  ///
  /// The optimistic offline overlay uses this to reconcile its pending queue:
  /// an action whose id appears here has already landed on the server (and is
  /// reflected in freshly fetched rows), so it must NOT be overlaid again and
  /// can be pruned from the local queue.
  Future<Set<String>> appliedClientRequestIds({String? hotelId});

  Future<List<AuditLog>> fetchAuditLogs();
  Future<void> clearAuditLogs();

  Future<List<String>> fetchRoles();
  Future<Map<String, Set<String>>> fetchRolePermissions();
  Future<List<String>> fetchAllPermissions();
  Future<void> updateRolePermission({
    required String role,
    required String permission,
    required bool isEnabled,
  });
  Future<void> createRole({
    required String name,
    String? description,
  });

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
  });

  Future<void> deleteHotel(String hotelId);
  Future<void> deleteRoom(String roomId);
  Future<void> deleteFloor(String floorId);
  Future<void> deleteUser(String userId);
  Future<void> deleteAlert(String alertId);
  Future<void> deleteProduct(String productId);

  Future<void> createRoomsFromTemplate({
    required String hotelId,
    required int floorNumber,
    required int firstRoomNumber,
    required int roomCount,
    required List<String> productIds,
    bool autoAdjustInventory = false,
  });

  Future<void> inviteTeamMember({
    required String email,
    required String fullName,
    required String role,
    String? hotelId,
  });

  /// Uploads a new profile picture for [userId] and returns its public URL.
  /// Permission checks (self, hotel manager of same hotel, app admin/manager)
  /// are enforced server-side.
  Future<String> updateUserAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileExtension,
  });

  Future<TeamInvitation?> invitationByToken({required String token});

  Future<void> acceptTeamInvitation({required String token});

  Future<void> cancelTeamInvitation({required String invitationId});

  Future<void> resendTeamInvitation({required String invitationId});

  Future<void> setTeamMemberActive({
    required String userId,
    required bool isActive,
  });

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
  });

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
  });

  Future<void> recordRefill({
    required String roomProductId,
    String? notes,
    String? clientRequestId,
  });

  Future<void> undoRefill({
    required String refillEventId,
    String? clientRequestId,
  });

  Future<void> requestCorrection({
    required String refillEventId,
    required String reason,
    String? clientRequestId,
  });

  Future<void> replaceBottle({
    required String roomProductId,
    String? notes,
    String? clientRequestId,
    bool autoAdjustInventory = false,
  });

  Future<String?> submitChangeRequest({
    required String hotelId,
    required String title,
    required String targetTable,
    required String targetId,
    required Map<String, dynamic> oldData,
    required Map<String, dynamic> newData,
    String? clientRequestId,
  });

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
  });

  Future<void> approveRequest({
    required String approvalRequestId,
    String? notes,
  });

  Future<void> rejectRequest({
    required String approvalRequestId,
    String? notes,
  });

  Future<int> refreshSmartAlerts({String? hotelId});

  Future<void> resolveAlert({required String alertId});

  Future<List<Hotel>> userHotels({required String userId});

  Future<void> assignUserHotel({
    required String userId,
    required String hotelId,
  });

  Future<void> unassignUserHotel({
    required String userId,
    required String hotelId,
  });

  Future<void> addProductToRoom({
    required String hotelId,
    required String floor,
    required String roomNumber,
    required String productSku,
    bool autoAdjustInventory = false,
    String? deductFromHousekeeperId,
  });

  Future<void> updateHotelExpressQrEnabled({
    required String hotelId,
    required bool enabled,
  });

  Future<void> removeProductFromRoom({required String roomProductId});

  /// Clear any locally persisted offline read-cache. Called on sign-out so a
  /// different account signing in offline can't be served the previous user's
  /// cached data.
  Future<void> clearCachedData();
}
