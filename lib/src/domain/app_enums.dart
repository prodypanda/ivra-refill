enum UserRole {
  appAdmin('app_admin'),
  appManager('app_manager'),
  hotelManager('hotel_manager'),
  hotelStaff('hotel_staff');

  const UserRole(this.value);
  final String value;

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.hotelStaff,
    );
  }
}

enum ApprovalStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  cancelled('cancelled');

  const ApprovalStatus(this.value);
  final String value;
}

enum BottleStatus {
  active('active'),
  needsRefill('needs_refill'),
  refilled('refilled'),
  refillLimitReached('refill_limit_reached'),
  tooOld('too_old'),
  needsReplacement('needs_replacement'),
  recycled('recycled'),
  damaged('damaged'),
  lost('lost');

  const BottleStatus(this.value);
  final String value;

  static BottleStatus fromValue(String value) {
    return BottleStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BottleStatus.active,
    );
  }
}

enum RefillEventType {
  refill('refill'),
  undo('undo'),
  correctionRequested('correction_requested'),
  correctionApproved('correction_approved'),
  correctionRejected('correction_rejected'),
  bottleReplaced('bottle_replaced');

  const RefillEventType(this.value);
  final String value;
}

enum AlertType {
  lowBidonStock('low_bidon_stock'),
  lowBottleStock('low_bottle_stock'),
  bottleAgeLimit('bottle_age_limit'),
  refillLimit('refill_limit'),
  pendingApproval('pending_approval'),
  suspiciousActivity('suspicious_activity'),
  inactiveHotel('inactive_hotel');

  const AlertType(this.value);
  final String value;
}

enum SyncActionType {
  refill('refill'),
  undoRefill('undo_refill'),
  correctionRequest('correction_request'),
  bottleReplacement('bottle_replacement'),
  stockAdjustment('stock_adjustment'),
  pendingEdit('pending_edit');

  const SyncActionType(this.value);
  final String value;
}

enum TunisianState {
  tunis('Tunis'),
  ariana('Ariana'),
  benArous('Ben Arous'),
  manouba('Manouba'),
  nabeul('Nabeul'),
  zaghouan('Zaghouan'),
  bizerte('Bizerte'),
  beja('Béja'),
  jendouba('Jendouba'),
  kef('Kef'),
  siliana('Siliana'),
  sousse('Sousse'),
  monastir('Monastir'),
  mahdia('Mahdia'),
  sfax('Sfax'),
  kairouan('Kairouan'),
  kasserine('Kasserine'),
  sidiBouzid('Sidi Bouzid'),
  gabes('Gabès'),
  medenine('Médenine'),
  tataouine('Tataouine'),
  gafsa('Gafsa'),
  tozeur('Tozeur'),
  kebili('Kébili');

  const TunisianState(this.displayName);
  final String displayName;

  static TunisianState? fromString(String? value) {
    if (value == null) return null;
    return TunisianState.values.cast<TunisianState?>().firstWhere(
          (state) => state!.displayName == value || state.name == value,
          orElse: () => null,
        );
  }
}

enum BottleType {
  withPump('with_pump'),
  withoutPump('without_pump');

  const BottleType(this.value);
  final String value;

  static BottleType fromValue(String value) {
    return BottleType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => BottleType.withPump,
    );
  }
}

enum RefillType {
  refillable('refillable'),
  directReplacement('direct_replacement');

  const RefillType(this.value);
  final String value;

  static RefillType fromValue(String value) {
    return RefillType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RefillType.refillable,
    );
  }
}

