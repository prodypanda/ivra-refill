// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get markAsRead => 'Mark as Read';

  @override
  String confirmDeleteHotel(String hotelName) {
    return 'Are you sure you want to delete the hotel \'$hotelName\'? This action is permanent, cannot be undone, and will permanently remove all associated rooms, staff assignments, and records.';
  }

  @override
  String confirmDeleteRoom(String roomNumber) {
    return 'Are you sure you want to delete room \'$roomNumber\'? This action is permanent, cannot be undone, and will permanently remove all associated products and history.';
  }

  @override
  String confirmDeleteFloor(String floorNumber) {
    return 'Are you sure you want to delete floor \'$floorNumber\' and all of its rooms? This action is permanent and cannot be undone.';
  }

  @override
  String confirmDeleteUser(String userName) {
    return 'Are you sure you want to delete team member \'$userName\'? This action is permanent, cannot be undone, and they will immediately lose access to the application.';
  }

  @override
  String confirmDeleteProduct(String productName) {
    return 'Are you sure you want to delete product \'$productName\'? This action is permanent, cannot be undone, and will affect store stock tracking.';
  }

  @override
  String get confirmDeleteAlert =>
      'Are you sure you want to delete this alert? This action is permanent and cannot be undone.';

  @override
  String get confirmDeleteAllAlerts =>
      'Are you sure you want to delete all alerts? This action is permanent, cannot be undone, and will clear all current notifications.';

  @override
  String get clearAuditLogs => 'Clear Logs';

  @override
  String get confirmAction => 'Confirm Action';

  @override
  String get confirmClearLogs =>
      'Are you sure you want to clear all audit logs? This action is permanent and cannot be undone.';

  @override
  String get btnConfirm => 'Confirm';

  @override
  String get composeMessage => 'Compose Message';

  @override
  String get notificationTitle => 'Notification Title';

  @override
  String get notificationDefaultTitle => 'New Notification';

  @override
  String get notificationChannelName => 'High Importance Notifications';

  @override
  String get notificationChannelDescription =>
      'This channel is used for important notifications.';

  @override
  String get notificationTitleHint => 'e.g. New Feature Alert!';

  @override
  String get notificationBody => 'Notification Body';

  @override
  String get notificationBodyHint => 'Enter the message here...';

  @override
  String get actionButtons => 'Action Buttons';

  @override
  String get actionButtonsHint => 'e.g. Dismiss, Open App';

  @override
  String get pageToOpen => 'Page to open';

  @override
  String get menuSendPush => 'Send Push';

  @override
  String get actionAndRouting => 'Action & Routing';

  @override
  String get openSpecificPage => 'Open Specific Page (Optional)';

  @override
  String get defaultNoPage => 'Default (No specific page)';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get dashboardOpsAnalytics => 'Operations analytics';

  @override
  String get dashboardExport => 'Export';

  @override
  String get dashboardDaily => 'Daily';

  @override
  String get dashboardWeekly => 'Weekly';

  @override
  String get dashboardMonthly => 'Monthly';

  @override
  String get dashboardRoomsAttention => 'Rooms needing attention';

  @override
  String get dashboardProductUsage => 'Product usage';

  @override
  String get dashboardUsageByFloor => 'Usage by floor';

  @override
  String get dashboardStockForecast => 'Stock depletion forecast';

  @override
  String get dashboardUnusualPatterns => 'Unusual patterns';

  @override
  String get dashboardNoStockData => 'No stock data';

  @override
  String dashboardRoomsRequireReview(String count) {
    return '$count rooms require review';
  }

  @override
  String get dashboardNoUnusualPatterns => 'No unusual patterns detected';

  @override
  String get dashboardHighPriority => 'High';

  @override
  String get dashboardStable => 'Stable';

  @override
  String get errorLoadingHotels => 'Error loading hotels';

  @override
  String get sending => 'Sending...';

  @override
  String roomsEditRoomTitle(String roomNumber) {
    return 'Update room $roomNumber';
  }

  @override
  String roomsEditProductTitle(String productName, String roomNumber) {
    return 'Update $productName bottle in room $roomNumber';
  }

  @override
  String get inventory => 'Store Stock';

  @override
  String get alerts => 'Alerts';

  @override
  String get approvals => 'Approvals';

  @override
  String get actionButtonsAndroid => 'Action Buttons (Android Only)';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get acknowledge => 'Acknowledge';

  @override
  String get openApp => 'Open App';

  @override
  String get sendNotification => 'Send Notification';

  @override
  String get targetAudience => 'Target Audience';

  @override
  String get allUsers => 'All Users';

  @override
  String get byRole => 'By Role';

  @override
  String get byHotel => 'By Hotel';

  @override
  String get byUserEmail => 'By User Email';

  @override
  String get selectRole => 'Select Role';

  @override
  String get selectHotel => 'Select Hotel';

  @override
  String get userEmail => 'User Email';

  @override
  String get menuAuditLogs => 'Audit Logs';

  @override
  String get auditLogs => 'Audit Logs';

  @override
  String get auditAction => 'Action';

  @override
  String get auditDevice => 'Device / OS';

  @override
  String get auditIpAddress => 'IP Address';

  @override
  String get auditTimestamp => 'Time';

  @override
  String get auditUser => 'User';

  @override
  String get enterSpecificUserEmail => 'Enter specific user email';

  @override
  String get dispatchNotification => 'Dispatch Notification';

  @override
  String get pleaseEnterTitleBody => 'Please enter a title and body';

  @override
  String get pleaseSelectTarget => 'Please select a target value';

  @override
  String notificationSent(String successCount, String failureCount) {
    return 'Sent: $successCount success, $failureCount failed';
  }

  @override
  String get dashboardShort => 'Dashboard';

  @override
  String get dashboardHeroTitle => 'Today at Ivra';

  @override
  String get dashboardRefillActivity => 'Refill Activity (Last 7 Days)';

  @override
  String get refillActivity => 'Refill Activity';

  @override
  String get myCompletedTasksThisWeek => 'My Completed Refills This Week';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get lastMonth => 'Last month';

  @override
  String get lastYear => 'Last year';

  @override
  String get allHotels => 'All Hotels';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get chartRefills => 'refills';

  @override
  String get teamEditProfile => 'Edit Profile';

  @override
  String get teamEditProfileSuccess => 'Profile updated successfully';

  @override
  String get hotels => 'Hotels';

  @override
  String get rooms => 'Rooms';

  @override
  String get products => 'Products';

  @override
  String get team => 'Team';

  @override
  String get account => 'Account';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get more => 'More';

  @override
  String get refill => 'Refill';

  @override
  String get undo => 'Undo';

  @override
  String get correction => 'Correction';

  @override
  String get pending => 'Pending';

  @override
  String get suggestedOrders => 'Suggested orders';

  @override
  String get bottles => 'Bottles';

  @override
  String get bidons => 'Refill bottles';

  @override
  String get language => 'Language';

  @override
  String get demoMode => 'Demo mode';

  @override
  String get downloadCsv => 'Download CSV';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get reportRefillHistoryTitle => 'Refill history';

  @override
  String get reportRefillHistoryBody =>
      'Export recent refill activity by hotel, room, product, user, and time.';

  @override
  String get reportSuggestedOrdersBody =>
      'Export bottles, refill bottles, and recycling recommendations.';

  @override
  String get reportInventorySnapshotTitle => 'Store Stock snapshot';

  @override
  String get reportInventorySnapshotBody =>
      'Export current bottle and refill bottle stock by hotel and product.';

  @override
  String get reportOpenAlertsTitle => 'Open alerts';

  @override
  String get reportOpenAlertsBody =>
      'Export low stock, replacement, inactivity, and suspicious activity alerts.';

  @override
  String get scheduleReportEmail => 'Schedule report email';

  @override
  String get scheduleReportEmailHint =>
      'We will send a summary of this report to this address every Monday.';

  @override
  String get scheduledReportEmailDrafted =>
      'Email report scheduled successfully';

  @override
  String get reportFilterDateRange => 'Filter by Date Range';

  @override
  String get reportAllProducts => 'All products';

  @override
  String get reportAllRooms => 'All rooms';

  @override
  String get reportClearFilters => 'Clear Filters';

  @override
  String get reportFiltersApplyExports =>
      'Note: Filters apply to both screen metrics and downloaded exports.';

  @override
  String get reportAnalyticsTitle => 'Analytics Overview';

  @override
  String get reportKpiRefills => 'Total Refills';

  @override
  String get reportKpiCorrections => 'Stock Corrections';

  @override
  String get reportKpiReplacements => 'Replacements';

  @override
  String get reportKpiActiveRooms => 'Active Rooms';

  @override
  String get reportTrendChart => 'Refill Activity Trend (Last 14 Days)';

  @override
  String get reportUsageByProduct => 'Refills by Product';

  @override
  String get reportUsageByRoom => 'Refills by Room';

  @override
  String get reportNoAnalyticsData => 'No activity recorded for this period.';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get metricHotels => 'Hotels';

  @override
  String get metricRooms => 'Rooms';

  @override
  String get metricPendingApprovals => 'Pending approvals';

  @override
  String get metricOpenAlerts => 'Open alerts';

  @override
  String get metricBottlesToReplace => 'Bottles to replace';

  @override
  String get metricLowStockProducts => 'Low stock products';

  @override
  String get inventoryTableProduct => 'Product';

  @override
  String get inventoryTableFullBottles => 'Full bottles';

  @override
  String inventoryTableFullBottlesWithPump(String size) {
    return 'Full $size bottles with pump';
  }

  @override
  String inventoryTableFullBottlesWithoutPump(String size) {
    return 'Full $size bottles without pump';
  }

  @override
  String get inventoryTableFullBottlesWithPumpGeneric =>
      'Full bottles with pump';

  @override
  String get inventoryTableFullBottlesWithoutPumpGeneric =>
      'Full bottles without pump';

  @override
  String get inventoryCollapseHeader => 'Empty & Open Bottles';

  @override
  String inventoryTableEmptyBottles(String months) {
    return 'Replaced bottles after $months months (Used)';
  }

  @override
  String get inventoryTableEmptyBottlesGeneric => 'Replaced bottles (Used)';

  @override
  String get inventoryTableEmptyBidons => 'Empty refill bottles';

  @override
  String inventoryTableFullBidons(String size) {
    return 'Full $size refill bottles';
  }

  @override
  String get inventoryTableFullBidonsGeneric => 'Full refill bottles';

  @override
  String get inventoryTableOpenBidons => 'Used refill bottles';

  @override
  String get inventoryTableStatus => 'Status';

  @override
  String get errorUniqueViolation => 'This record already exists.';

  @override
  String get errorForeignKeyViolation => 'Related record not found.';

  @override
  String get errorPermissionDenied =>
      'You do not have permission to perform this action.';

  @override
  String get errorGeneric => 'An unexpected error occurred. Please try again.';

  @override
  String get inventoryStatusHealthy => 'Healthy';

  @override
  String get inventoryStatusLowStock => 'Low stock';

  @override
  String get auditFilterAllActions => 'All Actions';

  @override
  String get sortNameAsc => 'Name (A-Z)';

  @override
  String get sortNameDesc => 'Name (Z-A)';

  @override
  String get sortMostFullBottles => 'Most Full Bottles';

  @override
  String get sortMostEmptyBottles => 'Most Empty Bottles';

  @override
  String get bulkAdjustSelectProducts => 'Select products';

  @override
  String get bulkAdjustSelectAll => 'Select all';

  @override
  String get bulkAdjustDeselectAll => 'Deselect all';

  @override
  String get bulkAdjustNoProductsSelected =>
      'Please select at least one product.';

  @override
  String orderNewBottlesText(String count) {
    return 'Order $count new 1L bottles';
  }

  @override
  String orderNewBidonsText(String count) {
    return 'Order $count new 5L refill bottles';
  }

  @override
  String recycleBottlesText(String count) {
    return 'Recycle $count bottles';
  }

  @override
  String get bottleCannotRefillRecycled =>
      'This bottle has been recycled and cannot be refilled. Please replace it.';

  @override
  String get adjustStockTitle => 'Adjust stock';

  @override
  String get hotelRoomsTracked => 'rooms tracked';

  @override
  String get hotelPendingChip => 'pending';

  @override
  String get hotelLabelName => 'Hotel name';

  @override
  String get hotelLabelLegalName => 'Legal name';

  @override
  String get hotelLabelState => 'State (Governorate)';

  @override
  String get hotelLabelCountry => 'Country';

  @override
  String get hotelLabelContactName => 'Contact name';

  @override
  String get hotelLabelEmail => 'Email';

  @override
  String get hotelLabelPhone => 'Phone';

  @override
  String get hotelLabelAddress => 'Address';

  @override
  String get hotelLabelNotes => 'Notes';

  @override
  String get btnCreate => 'Create';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnSave => 'Save';

  @override
  String get btnSubmitRequest => 'Submit request';

  @override
  String get demoModeDescription =>
      'Local simulations using offline database templates.';

  @override
  String get offlineModeDescription =>
      'Queues actions when disconnected and syncs later.';

  @override
  String get syncQueueHeader => 'Sync Queue';

  @override
  String get syncNow => 'Sync now';

  @override
  String get itemsToSync => 'actions pending sync';

  @override
  String get editRequestQueued => 'Hotel edit request queued';

  @override
  String get editRequestSubmitted => 'Hotel edit request submitted';

  @override
  String get hotelUpdated => 'Hotel information updated';

  @override
  String get hotelCreatedSuccessfully => 'Hotel created successfully';

  @override
  String get requiredField => 'Required';

  @override
  String get enterNumberError => 'Enter a number';

  @override
  String get createHotel => 'Create hotel';

  @override
  String get requestHotelEdit => 'Request hotel edit';

  @override
  String get authTitleCannotAccess => 'You need an invitation to access Ivra.';

  @override
  String get authBtnGoogleSignIn => 'Sign in with Google';

  @override
  String get authBtnSignOut => 'Sign out';

  @override
  String get authLabelEmail => 'Email';

  @override
  String get authLabelPassword => 'Password';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authBtnSignIn => 'Sign in';

  @override
  String get authBtnForgotPassword => 'Forgot password?';

  @override
  String get authResetPasswordTitle => 'Reset password';

  @override
  String get setPasswordTitle => 'Set your password';

  @override
  String get setPasswordBody =>
      'Please set a secure password for your account to complete your registration.';

  @override
  String get setPasswordButton => 'Set Password';

  @override
  String get authBtnSendResetLink => 'Send reset link';

  @override
  String get authResetLinkSent => 'Password reset link sent to';

  @override
  String get authValidationEmailRequired => 'Email is required';

  @override
  String get authValidationEmailInvalid => 'Enter a valid email address';

  @override
  String get authValidationPasswordRequired => 'Password is required';

  @override
  String get authValidationPasswordTooShort =>
      'Password must be at least 8 characters';

  @override
  String get authValidationPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get authResetNewPasswordTitle => 'Create new password';

  @override
  String get authLabelNewPassword => 'New password';

  @override
  String get authLabelConfirmPassword => 'Confirm password';

  @override
  String get authBtnUpdatePassword => 'Update password';

  @override
  String get authBtnReturnToApp => 'Return to app';

  @override
  String get authPasswordUpdatedSuccess => 'Password updated successfully.';

  @override
  String get authUnexpectedError =>
      'Something went wrong. Please try again, or contact support if the problem persists.';

  @override
  String get asyncErrorTitle => 'Could not load this section';

  @override
  String get btnRetry => 'Retry';

  @override
  String get authProfileLoadErrorTitle => 'We couldn\'t load your profile.';

  @override
  String get authProfileLoadErrorBody =>
      'This is usually a temporary connection issue. Please retry.';

  @override
  String get authAccountDeactivated =>
      'This account has been deactivated. Contact your administrator for access.';

  @override
  String get settingsPayloadInvalidJson => 'Payload must be a JSON object.';

  @override
  String exportDownloadStarted(String fileName) {
    return '$fileName download started';
  }

  @override
  String exportSaved(String fileName, String path) {
    return 'Saved $fileName to $path';
  }

  @override
  String settingsPendingSync(String count) {
    return 'Pending sync ($count)';
  }

  @override
  String get splashTagline => 'Sustainable Hospitality Solutions';

  @override
  String get accountSaveFailed =>
      'Could not save your profile. Please try again.';

  @override
  String get accountPasswordChangeFailed =>
      'Could not change your password. Please try again.';

  @override
  String get accountSignOutFailed =>
      'Could not sign out. Check your connection and try again.';

  @override
  String get hotelCreateFailed =>
      'Could not create the hotel. Please try again.';

  @override
  String get hotelUpdateFailed =>
      'Could not update the hotel. Please try again.';

  @override
  String get teamInviteFailed =>
      'Could not send the invitation. Please try again.';

  @override
  String get teamHotelsUpdateFailed =>
      'Could not update hotel assignments. Please try again.';

  @override
  String get roomsTooltipCreateTemplate => 'Create room template';

  @override
  String get roomsNoRoomsFound => 'No rooms or products found.';

  @override
  String get roomsNoProducts => 'No products assigned to this room.';

  @override
  String get roomsStatusNoProducts => 'No products';

  @override
  String get roomsSearchEmptyHint =>
      'Try adjusting your search query or filters.';

  @override
  String get roomsEmptyHotelWithTemplate =>
      'Add your first room using the template button above.';

  @override
  String get roomsEmptyHotelNoTemplate =>
      'No rooms have been assigned to this hotel yet.';

  @override
  String get roomsLabelRoom => 'Room';

  @override
  String get bottleStatusActive => 'Active';

  @override
  String get bottleStatusNeedsRefill => 'Needs refill';

  @override
  String get bottleStatusRefilled => 'Refilled';

  @override
  String get bottleStatusRefillLimitReached => 'Refill limit reached';

  @override
  String get bottleStatusTooOld => 'Too old';

  @override
  String get bottleStatusNeedsReplacement => 'Needs replacement';

  @override
  String get bottleStatusRecycled => 'Recycled';

  @override
  String get bottleStatusDamaged => 'Damaged';

  @override
  String get bottleStatusLost => 'Lost';

  @override
  String get roomsLabelFloor => 'Floor';

  @override
  String get roomsLabelRefills => 'Refills';

  @override
  String get roomsLabelAge => 'Age';

  @override
  String get roomsLabelDaysUnit => 'd';

  @override
  String get roomsRefillQueued => 'Refill queued for room';

  @override
  String get roomsRefillRecorded => 'Refill recorded for room';

  @override
  String get roomsBtnBottleEdit => 'Bottle edit';

  @override
  String get roomsBtnReplaceBottle => 'Replace bottle';

  @override
  String get roomsBtnRefillBottle => 'Refill bottle';

  @override
  String get roomsBtnRoomEdit => 'Room edit';

  @override
  String get roomsBtnHistory => 'History';

  @override
  String get roomsBtnMoreActions => 'More actions';

  @override
  String get roomsBtnMarkDamaged => 'Mark as Damaged';

  @override
  String get roomsBtnMarkLost => 'Mark as Lost';

  @override
  String get roomsLabelProofPhoto => 'Proof Photo';

  @override
  String get roomsNotesOptional => 'Notes (Optional)';

  @override
  String get roomsLabelUploadedProof => 'Uploaded Proof';

  @override
  String get roomsUploadProofAction => 'Upload Photo';

  @override
  String get roomsReplacementQueued => 'Bottle replacement queued for room';

  @override
  String get roomsReplacementRecorded => 'Bottle replaced for room';

  @override
  String get roomsReplacementNotes => 'Bottle replaced from room workflow';

  @override
  String get roomsStatusAllOk => 'All OK';

  @override
  String get roomsStatusAttentionRequired => 'Attention Required';

  @override
  String get roomsStatusRefillNeeded => 'Refill Needed';

  @override
  String get roomsSearchPlaceholder => 'Search room...';

  @override
  String get roomsRecentTitle => 'Recent rooms';

  @override
  String get roomsRecentClear => 'Clear';

  @override
  String get roomsGestionExpressQr => 'Express QR Management';

  @override
  String get roomsSelectHotelFirst => 'Select a hotel...';

  @override
  String get roomsViewDetailed => 'Detailed View';

  @override
  String get roomsViewCompact => 'Compact View';

  @override
  String get roomsCollapseAll => 'Collapse all';

  @override
  String get roomsExpandAll => 'Expand all';

  @override
  String get roomsBtnAddRoom => 'Add room';

  @override
  String get roomsDialogAddRoomTitle => 'Add room to floor';

  @override
  String get roomsMsgRoomAdded => 'Room added';

  @override
  String get roomsMsgRoomAddQueued => 'Room creation queued';

  @override
  String get roomsHistoryRefill => 'Refill';

  @override
  String get roomsHistoryNewBottle => 'New bottle placed';

  @override
  String roomsHistoryStatusChanged(String oldValue, String newValue) {
    return 'Status changed from $oldValue to $newValue';
  }

  @override
  String get roomsFilterAll => 'All';

  @override
  String get roomsDialogBottleEditTitle => 'Request bottle edit for room';

  @override
  String get roomsLabelBottleStatus => 'Bottle status';

  @override
  String get roomsLabelBottleStartDate => 'Bottle start date';

  @override
  String get roomsValidationEnterValidDate => 'Enter a valid date';

  @override
  String get roomsMsgEditRequestQueued => 'Bottle edit request queued';

  @override
  String get roomsMsgDetailsUpdated => 'Bottle details updated';

  @override
  String get roomsMsgEditRequestSubmitted => 'Bottle edit request submitted';

  @override
  String get roomsDialogRoomEditTitle => 'Request room edit for';

  @override
  String get roomsLabelRoomNumber => 'Room number';

  @override
  String get roomsLabelFloorNumber => 'Floor number';

  @override
  String get roomsMsgRoomEditQueued => 'Room edit request queued';

  @override
  String get roomsMsgRoomDetailsUpdated => 'Room details updated';

  @override
  String get roomsMsgRoomEditSubmitted => 'Room edit request submitted';

  @override
  String get roomsMsgRequestRoomEdit => 'Update room';

  @override
  String get roomsDialogHistoryTitle => 'history';

  @override
  String get roomsNoHistoryRecorded =>
      'No refill history has been recorded yet.';

  @override
  String get roomsMsgUndoQueued => 'Undo queued';

  @override
  String get roomsMsgRefillUndone => 'Refill undone';

  @override
  String get roomsBtnClose => 'Close';

  @override
  String get qrScanTitle => 'Scan QR Code';

  @override
  String get qrScanPlaceholder => 'Enter QR code manually...';

  @override
  String get qrDemoCodes => 'Demo QR Codes';

  @override
  String get qrActionPrompt => 'Select Action';

  @override
  String qrActionMessage(String product) {
    return 'What would you like to do for $product?';
  }

  @override
  String get qrActionRefill => 'Refill Bottle';

  @override
  String get qrActionReplace => 'Replace Bottle';

  @override
  String get hotelNotFound => 'Hotel Not Found';

  @override
  String get productNotFound => 'Product Not Found';

  @override
  String get qrAccessDeniedMessage =>
      'You are not authorized to perform actions at this hotel.';

  @override
  String get roomsFillCount => 'Refill Count';

  @override
  String get roomsBottleStatus => 'Dispenser Status';

  @override
  String get btnBack => 'Back';

  @override
  String get qrActionSuccess => 'Action Successful';

  @override
  String get qrActionFailed => 'Action Failed';

  @override
  String get qrUpdatedStatus => 'Updated Dispenser Status:';

  @override
  String get qrScanAnother => 'Scan another QR code';

  @override
  String get qrReturnRooms => 'Return to rooms';

  @override
  String get qrTryScanAgain => 'Try scanning again';

  @override
  String qrFloorRoom(String floor, String room) {
    return 'Floor $floor • Room $room';
  }

  @override
  String qrRoomFloor(String room, String floor) {
    return 'Room $room • Floor $floor';
  }

  @override
  String get qrCameraPermission => 'Camera permission denied';

  @override
  String get qrCameraUnavailable => 'Camera unavailable';

  @override
  String qrHotelNotFoundMessage(String hotel) {
    return 'Could not match hotel: \"$hotel\"';
  }

  @override
  String qrProductNotFoundMessage(String room, String floor, String sku) {
    return 'Room $room (Floor $floor) does not contain product SKU: \"$sku\"';
  }

  @override
  String get qrGenerateTabScan => 'Scan QR Code';

  @override
  String get qrGenerateTabGenerate => 'Generate QR Codes';

  @override
  String get qrGenerateHotel => 'Hotel';

  @override
  String get qrGenerateScope => 'QR Label Type';

  @override
  String get qrGenerateScopeRoom => 'Room Door (No SKU)';

  @override
  String get qrGenerateScopeDispenser => 'Dispenser (With SKU)';

  @override
  String get qrGenerateRoom => 'Room';

  @override
  String get qrGenerateProduct => 'Product';

  @override
  String get qrGenerateAllRooms => 'All Rooms';

  @override
  String get qrGenerateAllProducts => 'All Products';

  @override
  String get qrGenerateBtnDownload => 'Generate & Download PDF';

  @override
  String get qrGenerateDownloading => 'Generating PDF...';

  @override
  String get qrGenerateSuccess => 'PDF generated and downloaded successfully';

  @override
  String get settingsScannerHeader => 'Scanner Settings';

  @override
  String get settingsPrecisionScanTitle => 'Precision Scan Window';

  @override
  String get settingsPrecisionScanSubtitle =>
      'Only scan codes aligned in the viewfinder center';

  @override
  String get settingsTapToScanTitle => 'Tap to Scan';

  @override
  String get settingsTapToScanSubtitle =>
      'Tap on a detected QR code box to scan it';

  @override
  String get qrConfirmAssignTitle => 'Product Not Placed';

  @override
  String qrConfirmAssignMessage(String product, String room) {
    return 'Product $product is not assigned to Room $room. Add 1 piece to inventory and assign it to the room?';
  }

  @override
  String get qrAssignSuccess => 'Product assigned and refilled successfully';

  @override
  String get qrActionCanceled => 'Operation Canceled';

  @override
  String get qrActionCanceledMessage =>
      'You chose not to assign the product. You can scan another code or return to rooms.';

  @override
  String get scanAssignTitle => 'Assign Product to Room';

  @override
  String get scanAssignSuccess => 'Product Assigned Successfully';

  @override
  String get scanAssignFailed => 'Assignment Failed';

  @override
  String scanAssignInStock(String count) {
    return '$count in stock — will deduct 1 and assign to room';
  }

  @override
  String get scanAssignOutOfStock =>
      'Out of stock — 1 unit will be auto-added to inventory then assigned';

  @override
  String get scanAssignDescription =>
      'This product is not yet assigned to this room. Tap below to assign it.';

  @override
  String get scanAssignButton => 'Assign to Room';

  @override
  String get scanAssignAutoAdd => 'Add to Inventory & Assign';

  @override
  String get scanAssignAutoAddTitle => 'Add to Inventory?';

  @override
  String scanAssignAutoAddMessage(String product) {
    return 'Product \"$product\" is out of stock. Would you like to automatically add 1 unit to inventory and assign it to this room?';
  }

  @override
  String get scanAssignConfirm => 'Yes, add & assign';

  @override
  String scanAssignSuccessMessage(String product, String room, String floor) {
    return 'Product $product has been assigned to Room $room (Floor $floor).';
  }

  @override
  String get qrMultipleDetected => 'Multiple QR codes detected. Tap to select:';

  @override
  String qrUnknownSku(String sku) {
    return 'SKU \"$sku\" does not match any known product.';
  }

  @override
  String get goToRoom => 'Go to Room';

  @override
  String get errorLoadingProducts => 'Error loading products';

  @override
  String get errorLoadingInventory => 'Error loading inventory';

  @override
  String get qrGenAllRoomProducts => 'All products in the selected room';

  @override
  String get qrGenAllInventoryProducts => 'All products in the inventory';

  @override
  String get qrLabelScanInstructions =>
      'Scan with IVRA app to refill or replace';

  @override
  String get roomsSearchProductPlaceholder =>
      'Search product by name or SKU...';

  @override
  String adjustStockForProduct(String product) {
    return 'Adjust Stock for $product';
  }

  @override
  String get roomsBtnRequestCorrection => 'Request correction';

  @override
  String get roomsLabelReason => 'Reason';

  @override
  String get roomsMsgCorrectionQueued => 'Correction request queued';

  @override
  String get roomsMsgCorrectionSubmitted => 'Correction request submitted';

  @override
  String get roomsBtnCreateRooms => 'Create rooms';

  @override
  String get roomsLabelProductsInRoom => 'Products in each room';

  @override
  String get roomsMsgSelectOneProduct => 'Select at least one product';

  @override
  String roomsMsgDuplicateRoomNumbers(String numbers) {
    return 'These room numbers already exist in this hotel: $numbers. Choose a different starting number or count.';
  }

  @override
  String get productsCatalogTitle => 'Product Catalog';

  @override
  String get productsBtnCreate => 'Create product';

  @override
  String get productsNoProducts => 'No products in the catalog yet.';

  @override
  String get productsLabelBottleVolume => 'Bottle volume';

  @override
  String get productsLabelBidonVolume => 'Refill bottle volume';

  @override
  String get productsLabelMaxRefill => 'Max refill limit';

  @override
  String get productsLabelMaxAge => 'Max bottle age';

  @override
  String get productsLabelLowStock => 'Low stock alert';

  @override
  String get productsBtnEdit => 'Edit product';

  @override
  String get productsLabelSku => 'SKU';

  @override
  String get productsLabelNameEn => 'Name English';

  @override
  String get productsLabelNameFr => 'Name French';

  @override
  String get productsLabelNameAr => 'Name Arabic';

  @override
  String get productsLabelNameIt => 'Name Italian';

  @override
  String get productsLabelImage => 'Upload Picture';

  @override
  String get productsLabelImageHint => 'Select an image from your device';

  @override
  String productsImageSelected(String name) {
    return 'Selected: $name';
  }

  @override
  String get productsImageSet => 'Image is set (tap to change)';

  @override
  String get productsImageNone => 'No image selected';

  @override
  String get productsImageRemove => 'Remove image';

  @override
  String get productsImageUploadFailed =>
      'Image upload failed. Please try again.';

  @override
  String get productsImageInvalidType => 'Please select a valid image file.';

  @override
  String productsImageTooLarge(String max) {
    return 'Image is too large (max $max MB).';
  }

  @override
  String get productsAddedSuccess => 'Product added successfully';

  @override
  String get productsUpdatedSuccess => 'Product updated successfully';

  @override
  String get productsLabelBottleMl => 'Bottle ml';

  @override
  String get productsLabelBidonMl => 'Refill bottle ml';

  @override
  String get productsLabelMaxRefills => 'Max refills';

  @override
  String get productsLabelMaxAgeDays => 'Max age days';

  @override
  String get productsLabelLowBottles => 'Low bottles';

  @override
  String get productsLabelLowBidons => 'Low refill bottles';

  @override
  String get productsLabelBottleType => 'Bottle Type';

  @override
  String get productsLabelBottleWithPump => 'Bottle with pump';

  @override
  String get productsLabelBottleWithoutPump => 'Bottle without pump';

  @override
  String get productsLabelRefillType => 'Refill Type';

  @override
  String get productsLabelRefillable => 'Refillable';

  @override
  String get productsLabelDirectReplacement => 'Direct replacement';

  @override
  String get productsDialogCreateTitle => 'Create product';

  @override
  String get productsDialogEditTitle => 'Edit product';

  @override
  String get days => 'days';

  @override
  String get refills => 'refills';

  @override
  String get inventoryNoHotels => 'No Hotels Found';

  @override
  String get inventoryAddHotelHint => 'Add a hotel to get started.';

  @override
  String get inventoryNoItemsToAdjust =>
      'No store stock items available to adjust.';

  @override
  String get inventoryNoInventoryYet => 'No store stock yet';

  @override
  String get inventoryNoProductsInInventory =>
      'There are no products in the store stock.';

  @override
  String get inventoryNoSuggestedOrders => 'No suggested orders';

  @override
  String get inventoryLevelsSufficient =>
      'Your store stock levels are currently sufficient.';

  @override
  String get teamAccounts => 'Team accounts';

  @override
  String get teamNoMembers => 'No team members found.';

  @override
  String get teamTableColumnName => 'Name';

  @override
  String get teamTableColumnEmail => 'Email';

  @override
  String get teamTableColumnRole => 'Role';

  @override
  String get teamTableColumnHotel => 'Hotel';

  @override
  String get teamTableColumnStatus => 'Status';

  @override
  String get teamTableColumnActions => 'Actions';

  @override
  String get teamPendingInvitations => 'Pending invitations';

  @override
  String get teamNoPendingInvitations => 'No pending invitations.';

  @override
  String get teamInviteTitle => 'Invite team member';

  @override
  String get teamLabelFullName => 'Full name';

  @override
  String get settingsOfflineMode => 'Offline mode';

  @override
  String get settingsOfflineQueue => 'Queue actions';

  @override
  String get settingsOfflineSend => 'Send actions';

  @override
  String get settingsBiometricTitle => 'Biometric unlock';

  @override
  String get settingsBiometricHint =>
      'Use your fingerprint or face to sign in.';

  @override
  String get settingsBiometricUnavailable =>
      'Biometric unlock is not available on this device.';

  @override
  String get authBtnBiometricLogin => 'Biometric login';

  @override
  String get authBiometricReason => 'Authenticate to access Ivra';

  @override
  String get authBiometricNeedsLogin =>
      'Please sign in once to enable biometric login.';

  @override
  String get authBiometricOfflineNoSession =>
      'You are offline. Connect to the internet to sign in.';

  @override
  String get authBiometricFailed => 'Biometric authentication failed.';

  @override
  String get settingsBtnClear => 'Clear';

  @override
  String get settingsBtnSyncNow => 'Sync now';

  @override
  String get settingsNoPendingActions => 'No pending actions.';

  @override
  String get teamManageHotels => 'Manage hotels';

  @override
  String get teamAssignHotelsTitle => 'Assign hotels';

  @override
  String get teamNoHotelsAssigned => 'No hotels assigned';

  @override
  String get teamHotelsUpdated => 'Hotel assignments updated';

  @override
  String get teamSelectHotels => 'Select hotels';

  @override
  String get teamHotelsAssigned => 'hotels assigned';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountProfile => 'Profile';

  @override
  String get accountProfileUpdated => 'Profile updated';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountPasswordUpdated => 'Password updated';

  @override
  String get accountFullName => 'Full name';

  @override
  String get accountFullNameRequired => 'Full name is required';

  @override
  String get accountNewPassword => 'New password';

  @override
  String get accountConfirmPassword => 'Confirm new password';

  @override
  String get accountPasswordHintSupabase =>
      'Updates your account login password.';

  @override
  String get accountPasswordHintDemo => 'Demo mode accepts the change locally.';

  @override
  String get accountSignOutHint => 'End the current session on this device.';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountRole => 'Role';

  @override
  String get accountScope => 'Scope';

  @override
  String get accountStatus => 'Status';

  @override
  String get accountActive => 'Active';

  @override
  String get accountInactive => 'Inactive';

  @override
  String get accountIvraGlobal => 'Ivra global';

  @override
  String get accountTeamAccounts => 'Team accounts';

  @override
  String get accountNoOtherAccounts => 'No other accounts found.';

  @override
  String get accountYou => 'You';

  @override
  String get alertsRefreshSmart => 'Refresh smart alerts';

  @override
  String get alertsResolve => 'Resolve';

  @override
  String get delete => 'Delete';

  @override
  String get approvalsEmpty => 'No pending approvals';

  @override
  String get approvalsEmptySubtitle =>
      'All approval requests have been processed.';

  @override
  String get approvalsApprove => 'Approve';

  @override
  String get approvalsReject => 'Reject';

  @override
  String get approvalsActionFailed => 'The action failed. Please try again.';

  @override
  String get approvalsApproved => 'Request approved.';

  @override
  String get approvalsRejected => 'Request rejected.';

  @override
  String get approvalsApproveQueued => 'Approval queued for sync.';

  @override
  String get approvalsRejectQueued => 'Rejection queued for sync.';

  @override
  String get approvalsAccessDenied =>
      'Access denied. Only admins can review approvals.';

  @override
  String get approvalsRequestNotFound =>
      'Approval request not found or already processed.';

  @override
  String get inviteAcceptTitle => 'Accept invitation';

  @override
  String get inviteAlreadyHaveAccount => 'I already have an account';

  @override
  String get inviteBackToSignIn => 'Back to sign in';

  @override
  String get inviteEmail => 'Email';

  @override
  String get invitePassword => 'Password';

  @override
  String get inviteConfirmPassword => 'Confirm password';

  @override
  String get settingsRetryAction => 'Retry action';

  @override
  String get settingsRemoveAction => 'Remove action';

  @override
  String get settingsActionUpdated => 'Queued action updated';

  @override
  String get settingsActionRemoved => 'Offline action removed';

  @override
  String get settingsQueueCleared => 'Offline queue cleared';

  @override
  String get settingsTestAccessAs => 'Test access as';

  @override
  String get settingsDemoUserChanged => 'Demo user changed';

  @override
  String get settingsPayloadJson => 'Queued payload JSON';

  @override
  String get settingsSaveAndRetry => 'Save and retry';

  @override
  String get settingsDemoUser => 'Demo user';

  @override
  String get settingsSupabaseConnected => 'Connected';

  @override
  String get settingsSupabaseHint => 'The app is using live data.';

  @override
  String get settingsNoSupabaseHint => 'Server connection is not configured.';

  @override
  String get settingsEditAction => 'Edit queued action';

  @override
  String get settingsResolveConflict => 'Resolve sync conflict';

  @override
  String get settingsActionSynced => 'Action synced';

  @override
  String get offlineBannerTitle => 'You are offline';

  @override
  String get offlineBannerSubtitle => 'Data may not be up to date';

  @override
  String get offlineBannerPending => 'pending actions';

  @override
  String get offlineBannerSyncBtn => 'Sync now';

  @override
  String offlineBannerAutoSynced(String count) {
    return 'Back online! Synced $count actions';
  }

  @override
  String get offlineBannerSyncFailed => 'Sync failed for some actions';

  @override
  String teamInvitationCancelled(String email) {
    return 'Invitation cancelled for $email';
  }

  @override
  String teamInvitationResent(String email) {
    return 'Invitation resent to $email';
  }

  @override
  String teamInvitationCopied(String email) {
    return 'Invitation link copied for $email';
  }

  @override
  String approvalsRequestedBy(String name) {
    return 'Requested by $name';
  }

  @override
  String approvalsOldValue(String value) {
    return 'Old: $value';
  }

  @override
  String approvalsNewValue(String value) {
    return 'New: $value';
  }

  @override
  String alertsSeverityLabel(String severity) {
    return 'Severity $severity';
  }

  @override
  String get alertsStatusResolved => 'Resolved';

  @override
  String get alertsStatusOpen => 'Open';

  @override
  String get alertsMetricCritical => 'Critical';

  @override
  String get alertsFilterTitle => 'Filters';

  @override
  String get alertsFilterSeverity => 'Severity';

  @override
  String get alertsFilterType => 'Type';

  @override
  String get alertsFilterHotel => 'Hotel';

  @override
  String get alertsFilterProduct => 'Product';

  @override
  String get alertsFilterAll => 'All';

  @override
  String get alertsFilterClear => 'Clear filters';

  @override
  String get alertsFilterNoMatch => 'No alerts match the current filters.';

  @override
  String alertsFilterShowing(String count, String total) {
    return 'Showing $count of $total';
  }

  @override
  String get settingsActionEditTitle => 'Edit queued action';

  @override
  String get settingsActionConflictTitle => 'Resolve sync conflict';

  @override
  String settingsActionAttempts(String count) {
    return 'Attempts $count';
  }

  @override
  String settingsActionListAttempts(String count) {
    return 'Attempts: $count';
  }

  @override
  String settingsActionListError(String message) {
    return 'Error: $message';
  }

  @override
  String get syncActionRefill => 'Refill';

  @override
  String get syncActionUndoRefill => 'Undo refill';

  @override
  String get syncActionCorrectionRequest => 'Correction request';

  @override
  String get syncActionBottleReplacement => 'Bottle replacement';

  @override
  String get syncActionStockAdjustment => 'Stock adjustment';

  @override
  String get syncActionPendingEdit => 'Pending edit';

  @override
  String get userRoleAppAdmin => 'App admin';

  @override
  String get userRoleAppManager => 'App manager';

  @override
  String get userRoleHotelManager => 'Hotel manager';

  @override
  String get userRoleHotelStaff => 'Hotel staff';

  @override
  String get teamStatusActive => 'Active';

  @override
  String get teamStatusInactive => 'Inactive';

  @override
  String get teamHotelAll => 'All hotels';

  @override
  String get teamHotelNone => '—';

  @override
  String get invitationStatusPending => 'Pending';

  @override
  String get invitationStatusAccepted => 'Accepted';

  @override
  String get invitationStatusCancelled => 'Cancelled';

  @override
  String get invitationStatusExpired => 'Expired';

  @override
  String get alertResolvedToast => 'Alert resolved';

  @override
  String get alertDeletedToast => 'Alert deleted';

  @override
  String get alertResolveFailedToast =>
      'Could not resolve the alert. Please try again.';

  @override
  String get alertDeleteFailedToast =>
      'Could not delete the alert. Please try again.';

  @override
  String get notificationAcknowledgedToast => 'Acknowledged';

  @override
  String get notificationMoreInfo => 'More info';

  @override
  String get bulkAdjustStockTitle => 'Bulk stock adjustment';

  @override
  String get bulkAdjustStockHint =>
      'Enter quantity adjustments that will apply to ALL products.';

  @override
  String get bulkAdjustStockSuccess =>
      'Bulk stock adjustment successfully applied';

  @override
  String get bulkAdjustStockOfflineQueued =>
      'Bulk adjustments queued for offline sync';

  @override
  String get resolveAll => 'Resolve all';

  @override
  String get deleteAll => 'Delete all';

  @override
  String alertsRefreshedToast(String count) {
    return '$count smart alerts created';
  }

  @override
  String get alertsEmptyTitle => 'No alerts yet';

  @override
  String get alertsEmptyMessage =>
      'Refresh smart alerts to scan stock, refill limits, bottle age, and pending approvals.';

  @override
  String get alertsEmptyAction => 'Refresh alerts';

  @override
  String get alertTypeLowBidonStock => 'Low refill bottle stock';

  @override
  String alertLowBottleTitle(String product) {
    return 'Low $product bottle stock';
  }

  @override
  String alertLowBidonTitle(String product) {
    return 'Low $product refill bottle stock';
  }

  @override
  String alertLowBottleBody(String hotel, String remain, String threshold) {
    return '$hotel: $remain full bottles remain. Threshold is $threshold.';
  }

  @override
  String alertLowBidonBody(String hotel, String remain, String threshold) {
    return '$hotel: $remain full refill bottles remain. Threshold is $threshold.';
  }

  @override
  String get alertTypeLowBottleStock => 'Low bottles';

  @override
  String get alertTypeBottleAgeLimit => 'Bottle age';

  @override
  String alertBottleAgeLimitTitle(String room, String product) {
    return 'Room $room $product bottle is too old';
  }

  @override
  String alertBottleAgeLimitBody(String age, String limit) {
    return 'Bottle age is $age days. Limit is $limit days.';
  }

  @override
  String get alertTypeRefillLimit => 'Refill limit';

  @override
  String alertRefillLimitTitle(String room, String product) {
    return 'Room $room $product reached refill limit';
  }

  @override
  String alertRefillLimitBody(String used, String max) {
    return '$used/$max refills used. Replace and recycle the bottle.';
  }

  @override
  String get alertTypePendingApproval => 'Approval';

  @override
  String alertPendingApprovalTitle(String request) {
    return 'Pending approval: $request';
  }

  @override
  String alertPendingApprovalBody(String name) {
    return 'Requested by $name.';
  }

  @override
  String get alertTypeSuspiciousActivity => 'Suspicious activity';

  @override
  String get alertTypeInactiveHotel => 'Inactive hotel';

  @override
  String get refillEventApproved => 'Approved';

  @override
  String get refillEventRejected => 'Rejected';

  @override
  String get teamDeactivateAccountTooltip => 'Deactivate account';

  @override
  String get teamReactivateAccountTooltip => 'Reactivate account';

  @override
  String settingsSyncedSummary(String synced) {
    return 'Synced $synced actions';
  }

  @override
  String settingsSyncedSummarySingular(String synced) {
    return 'Synced $synced action';
  }

  @override
  String settingsSyncedWithFailures(String synced, String failed) {
    return 'Synced $synced, $failed failed';
  }

  @override
  String get inviteAcceptHeading => 'Accept Ivra invitation';

  @override
  String inviteSubtitleWithHotel(String name, String role, String hotel) {
    return '$name was invited as $role for $hotel.';
  }

  @override
  String inviteSubtitleNoHotel(String name, String role) {
    return '$name was invited as $role.';
  }

  @override
  String get inviteEmailMismatch =>
      'Use the email address this invitation was sent to.';

  @override
  String get inviteAccountCreatedConfirm =>
      'Account created. Confirm your email, then return to this invitation link and enter the same password to finish joining.';

  @override
  String get inviteInvalidHeading => 'Invitation unavailable';

  @override
  String get inviteInvalidBody =>
      'This invitation may have expired, been cancelled, or already been accepted.';

  @override
  String teamMemberReactivated(String name) {
    return '$name reactivated';
  }

  @override
  String teamMemberDeactivated(String name) {
    return '$name deactivated';
  }

  @override
  String settingsActionLastTried(String datetime) {
    return 'Last tried $datetime';
  }

  @override
  String get settingsActionNeedsReview => 'Action still needs review';

  @override
  String get teamInviteLinkUnavailable => 'Invitation link is unavailable';

  @override
  String get teamCopyLink => 'Copy invitation link';

  @override
  String get teamResendInvitation => 'Resend invitation';

  @override
  String get teamCancelInvitation => 'Cancel invitation';

  @override
  String get teamCannotInviteSelf => 'You cannot invite yourself';

  @override
  String get btnUpdate => 'Update';

  @override
  String get notFoundTitle => 'Page Not Found';

  @override
  String get notFoundBody =>
      'The page you are looking for does not exist or has been moved.';

  @override
  String get notFoundButton => 'Back to Dashboard';

  @override
  String get downloadAppBannerText =>
      'For the best experience, download our Android App.';

  @override
  String get downloadAppBannerButton => 'Download App';

  @override
  String get sendPushTitle => 'Send Notification';

  @override
  String get teamViewAs => 'View as';

  @override
  String impersonationBanner(String name) {
    return 'Viewing as $name';
  }

  @override
  String get impersonationExit => 'Exit';

  @override
  String get pdfHeaderType => 'Type';

  @override
  String get pdfHeaderPrevious => 'Previous';

  @override
  String get pdfHeaderNew => 'New';

  @override
  String get pdfHeaderOccurredAt => 'Occurred at';

  @override
  String get pdfHeaderNotes => 'Notes';

  @override
  String get pdfHeaderProduct => 'Product';

  @override
  String get pdfHeader1LBottles => '1L bottles';

  @override
  String get pdfHeader5LBidons => '5L refill bottles';

  @override
  String get pdfHeaderRecycle => 'Recycle';

  @override
  String get pdfHeaderFullBottles => 'Full bottles';

  @override
  String get pdfHeaderEmptyBottles => 'Empty bottles';

  @override
  String get pdfHeaderFullBidons => 'Full refill bottles';

  @override
  String get pdfHeaderOpenBidons => 'Opened refill bottles';

  @override
  String get pdfHeaderEmptyBidons => 'Empty refill bottles';

  @override
  String get pdfHeaderSeverity => 'Severity';

  @override
  String get pdfHeaderTitle => 'Title';

  @override
  String get pdfHeaderCreatedAt => 'Created at';

  @override
  String get approvalStatusApproved => 'Approved';

  @override
  String get approvalStatusRejected => 'Rejected';

  @override
  String get approvalStatusCancelled => 'Cancelled';

  @override
  String get approvalStatusPending => 'Pending';

  @override
  String get pdfTitleSuggestedOrders => 'Ivra Suggested Orders';

  @override
  String get pdfTitleInventorySnapshot => 'Ivra Store Stock Snapshot';

  @override
  String get pdfTitleRefillHistory => 'Ivra Refill History';

  @override
  String get pdfTitleOpenAlerts => 'Ivra Open Alerts';

  @override
  String get productHistoryTitle => 'Product History';

  @override
  String get productHistoryNoHistory => 'No history recorded for this product.';

  @override
  String productHistoryRefill(String roomNumber) {
    return 'Refilled in Room $roomNumber';
  }

  @override
  String productHistoryReplacement(String roomNumber) {
    return 'Replaced bottle in Room $roomNumber';
  }

  @override
  String get productHistoryAdjustment => 'Manual Stock Adjustment';

  @override
  String productHistoryActionBy(String user) {
    return 'By $user';
  }

  @override
  String productHistoryReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get productHistoryDeltaFullBottles => 'Full bottles';

  @override
  String get productHistoryDeltaUsedBottles => 'Used bottles';

  @override
  String get productHistoryDeltaFullBidons => 'Full refill bottles';

  @override
  String get productHistoryDeltaOpenBidons => 'Opened refill bottles';

  @override
  String get productHistoryDeltaEmptyBidons => 'Empty refill bottles';

  @override
  String productHistoryNewBottle(String roomNumber) {
    return 'New bottle placed in Room $roomNumber';
  }

  @override
  String get productHistoryFilterAll => 'All';

  @override
  String get productHistoryFilterRoom => 'Room Events';

  @override
  String get productHistoryFilterManual => 'Adjustments';

  @override
  String get productHistoryStatRefills => 'Refills';

  @override
  String get productHistoryStatReplacements => 'Replacements';

  @override
  String get productHistoryStatAdjustments => 'Adjustments';

  @override
  String get inventoryEnforceTitle => 'Insufficient Stock';

  @override
  String inventoryEnforceTemplateContent(
      String total, String product, String current, String needed) {
    return 'Placing $total bottle(s) of $product requires stock. Store Stock only has $current. Would you like to automatically add $needed bottle(s) to the store stock and proceed?';
  }

  @override
  String inventoryEnforceReplaceContent(String product, String room) {
    return 'Replacing the bottle of $product in Room $room requires 1 full bottle. Store Stock has 0. Would you like to automatically add 1 bottle to the store stock and proceed?';
  }

  @override
  String housekeeperReplaceGetFromHotel(
      String product, String room, String count) {
    return 'Replacing $product in Room $room requires 1 full bottle, but you do not have it in your inventory. However, $count bottles are available in the hotel inventory. Would you like to take 1 bottle from the hotel inventory and proceed?';
  }

  @override
  String housekeeperReplaceNotifyManager(String product, String room) {
    return 'Replacing $product in Room $room requires 1 full bottle, but you do not have it in your inventory, and it is not available in the hotel inventory either. Please inform the hotel manager.';
  }

  @override
  String housekeeperAddGetFromHotel(String product, String room, String count) {
    return 'Adding $product to Room $room requires 1 full bottle, but you do not have it in your inventory. However, $count bottles are available in the hotel inventory. Would you like to take 1 bottle from the hotel inventory and proceed?';
  }

  @override
  String housekeeperAddNotifyManager(String product, String room) {
    return 'Adding $product to Room $room requires 1 full bottle, but you do not have it in your inventory, and it is not available in the hotel inventory either. Please inform the hotel manager.';
  }

  @override
  String housekeeperRefillGetFromHotel(
      String product, String room, String count) {
    return 'Refilling $product in Room $room requires 1 full bidon, but you do not have any open or full bidon in your inventory. However, $count bidons are available in the hotel inventory. Would you like to take 1 bidon from the hotel inventory and proceed?';
  }

  @override
  String housekeeperRefillNotifyManager(String product, String room) {
    return 'Refilling $product in Room $room requires 1 full bidon, but you do not have any open or full bidon in your inventory, and it is not available in the hotel inventory either. Please inform the hotel manager.';
  }

  @override
  String get btnOk => 'OK';

  @override
  String get inventoryEnforceBtnProceed => 'Auto-Adjust & Proceed';

  @override
  String get inventoryEnforceReasonTemplate =>
      'Auto-adjusted for room creation template';

  @override
  String get inventoryEnforceReasonReplace => 'Auto-adjusted for replacement';

  @override
  String get inventoryEnforceOnboardingTitle => 'Initialize Store Stock';

  @override
  String inventoryEnforceOnboardingContent(String total) {
    return 'Since this is a new hotel, there are no products in the store stock. Would you like to automatically initialize the store stock with $total bottles to place in the rooms?';
  }

  @override
  String get authBtnCreateRole => 'Create Role';

  @override
  String get authCreateRoleTitle => 'Create Custom Role';

  @override
  String get authRoleNameLabel => 'Role Name (lowercase snake_case)';

  @override
  String get authRoleNameError =>
      'Role name must be lowercase snake_case (e.g., night_auditor)';

  @override
  String get authRoleDisplayNameLabel =>
      'Friendly Display Name (e.g., Night Auditor)';

  @override
  String get authRoleDisplayNameError => 'Display name cannot be empty';

  @override
  String get authRoleDescLabel => 'Description';

  @override
  String get authCategoryCore => 'Core Operations';

  @override
  String get authCategoryManagement => 'Management';

  @override
  String get authCategoryControl => 'Control & Approvals';

  @override
  String get authCategoryAnalytics => 'Analytics & Broadcasts';

  @override
  String get authCategorySecurity => 'Security & Administration';

  @override
  String get authBulkGrantAll => 'Grant All';

  @override
  String get authBulkRevokeAll => 'Revoke All';

  @override
  String get authRoleCreatedSuccess => 'Role created successfully.';

  @override
  String get authSearchHint => 'Search permissions...';

  @override
  String get authorizationsTitle => 'Authorizations Matrix';

  @override
  String get authorizationsHeader => 'Authorizations Matrix';

  @override
  String get authorizationsSubtitle =>
      'Manage application features and action permissions by user role.';

  @override
  String get authorizationsPermission => 'Permission';

  @override
  String get authorizationsUpdatedSuccessfully =>
      'Authorizations updated successfully.';

  @override
  String get roleAppAdmin => 'App Admin';

  @override
  String get roleAppManager => 'App Manager';

  @override
  String get roleHotelManager => 'Hotel Manager';

  @override
  String get roleHotelStaff => 'Hotel Staff';

  @override
  String get permManageHotels => 'Manage Hotels';

  @override
  String get permManageHotelsDesc =>
      'Create, edit, and delete hotel properties';

  @override
  String get permManageRooms => 'Manage Rooms';

  @override
  String get permManageRoomsDesc => 'Add, edit, and remove rooms and floors';

  @override
  String get permManageProducts => 'Manage Products';

  @override
  String get permManageProductsDesc =>
      'Configure global product types and catalogs';

  @override
  String get permManageTeam => 'Manage Team';

  @override
  String get permManageTeamDesc => 'Invite and manage team members and roles';

  @override
  String get permSubmitEditRequests => 'Submit Edit Requests';

  @override
  String get permSubmitEditRequestsDesc =>
      'Submit room, bottle, and stock modification requests';

  @override
  String get permApproveCorrections => 'Approve Corrections';

  @override
  String get permApproveCorrectionsDesc =>
      'Approve or reject pending change and correction requests';

  @override
  String get permViewApprovals => 'View Approvals';

  @override
  String get permViewApprovalsDesc => 'Access the approvals dashboard screen';

  @override
  String get permViewAlerts => 'View Alerts';

  @override
  String get permViewAlertsDesc => 'View and monitor operation alerts';

  @override
  String get permViewReports => 'View Reports';

  @override
  String get permViewReportsDesc =>
      'Access analytics reports and performance charts';

  @override
  String get permSendNotifications => 'Send Push Notifications';

  @override
  String get permSendNotificationsDesc =>
      'Compose and broadcast app push notifications';

  @override
  String get permViewAuditLogs => 'View Security Audit Logs';

  @override
  String get permViewAuditLogsDesc =>
      'Inspect detailed operation and login history logs';

  @override
  String get permViewRooms => 'View Rooms';

  @override
  String get permViewRoomsDesc => 'View room refill status list and details';

  @override
  String get permViewInventory => 'View Inventory';

  @override
  String get permViewInventoryDesc =>
      'View hotel inventory stock status and suggest orders';

  @override
  String get permViewAuthorizations => 'View Authorizations';

  @override
  String get permViewAuthorizationsDesc =>
      'Access and manage role-based permission settings screen';

  @override
  String get dialogRefillTitle => 'Refill Dispenser';

  @override
  String get dialogRefillSliderLabel => 'Refill percentage (added volume):';

  @override
  String get dialogRefillPreExisting => 'Already Full:';

  @override
  String get dialogRefillAdded => 'To Add:';

  @override
  String get dialogRefillNotes => 'Notes (optional)';

  @override
  String get dialogRefillConfirm => 'Confirm Refill';

  @override
  String get femmeDeChambre => 'Housekeeper';

  @override
  String get checkoutStock => 'Checkout Stock';

  @override
  String get returnStock => 'Return Stock';

  @override
  String get housekeeperCart => 'My Cart';

  @override
  String get noAllocations =>
      'No active allocations. Check out stock to start.';

  @override
  String get fullBottles => 'Full Bottles';

  @override
  String get openBidonVolumeLeft => 'Remaining Volume';

  @override
  String get housekeeperStockCheckedOut => 'Stock checked out successfully!';

  @override
  String get housekeeperStockReturned => 'Stock returned successfully!';

  @override
  String get housekeeperStockHistory => 'History';

  @override
  String get housekeeperStockHistoryEmpty =>
      'No movements recorded yet for this product.';

  @override
  String get stockEventCheckout => 'Taken from hotel inventory';

  @override
  String get stockEventReturn => 'Returned to hotel inventory';

  @override
  String get stockEventRoomPlacement => 'Placed in room';

  @override
  String get stockEventRefillUse => 'Used for refill';

  @override
  String get stockEventReplaceUse => 'Used for bottle replacement';

  @override
  String housekeeperHotelStockAvailable(String bottles, String bidons) {
    return 'Hotel inventory: $bottles full bottles, $bidons full bidons available';
  }

  @override
  String get sourceHousekeeperCart => 'From housekeeper cart';

  @override
  String get sourceHotelInventory => 'From hotel inventory';

  @override
  String get userRoleHousekeeper => 'Housekeeper';

  @override
  String get roomsBtnAddProduct => 'Add product';

  @override
  String roomsConfirmRemoveProduct(String productName, String roomNumber) {
    return 'Are you sure you want to remove the product \'$productName\' from room \'$roomNumber\'?';
  }

  @override
  String get roomsProductRemoved => 'Product removed';

  @override
  String get roomsProductAdded => 'Product added';

  @override
  String get roomsAddProductTitle => 'Add product to room';

  @override
  String get roomsSelectProduct => 'Select Product';

  @override
  String get myBasket => 'My Basket';

  @override
  String get housekeepersTitle => 'Housekeepers';

  @override
  String get allHistory => 'All history';

  @override
  String get changePicture => 'Change picture';

  @override
  String get inviteHousekeeper => 'Invite housekeeper';

  @override
  String get removeHousekeeper => 'Remove housekeeper';

  @override
  String get basketContent => 'Basket content';

  @override
  String get noHousekeepers => 'No housekeepers found';

  @override
  String get btnClose => 'Close';

  @override
  String get deleteGeneric => 'Delete';

  @override
  String get teamDeactivate => 'Deactivate';

  @override
  String get teamReactivate => 'Reactivate';

  @override
  String get event_checkout => 'Stock Checked Out';

  @override
  String get event_returned => 'Stock Returned';

  @override
  String get event_roomPlacement => 'Placed in Room';

  @override
  String get event_refillUse => 'Refill Used';

  @override
  String get event_replaceUse => 'Bottle Replaced';

  @override
  String get dialogRefillNotesHint => 'e.g. standard refill...';

  @override
  String get dateFormatHint => 'YYYY-MM-DD';

  @override
  String errorWithArgs(String error) {
    return 'Error: $error';
  }

  @override
  String teamHotelSubtitle(String city, String country) {
    return '$city, $country';
  }

  @override
  String productEventTitle(String productName, String eventLabel) {
    return '$productName - $eventLabel';
  }

  @override
  String chipLabelValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String productSkuLabel(String label, String sku) {
    return '$label ($sku)';
  }

  @override
  String productSkuLabelReverse(String label, String sku) {
    return '$sku - $label';
  }

  @override
  String roomNumberLabel(String number) {
    return 'Room $number';
  }
}
