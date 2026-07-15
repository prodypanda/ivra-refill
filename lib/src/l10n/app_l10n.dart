import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_l10n_ar.dart';
import 'app_l10n_en.dart';
import 'app_l10n_fr.dart';
import 'app_l10n_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
    Locale('it')
  ];

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// No description provided for @confirmDeleteHotel.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the hotel \'{hotelName}\'? This action is permanent, cannot be undone, and will permanently remove all associated rooms, staff assignments, and records.'**
  String confirmDeleteHotel(String hotelName);

  /// No description provided for @confirmDeleteRoom.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete room \'{roomNumber}\'? This action is permanent, cannot be undone, and will permanently remove all associated products and history.'**
  String confirmDeleteRoom(String roomNumber);

  /// No description provided for @confirmDeleteFloor.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete floor \'{floorNumber}\' and all of its rooms? This action is permanent and cannot be undone.'**
  String confirmDeleteFloor(String floorNumber);

  /// No description provided for @confirmDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete team member \'{userName}\'? This action is permanent, cannot be undone, and they will immediately lose access to the application.'**
  String confirmDeleteUser(String userName);

  /// No description provided for @confirmDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete product \'{productName}\'? This action is permanent, cannot be undone, and will affect store stock tracking.'**
  String confirmDeleteProduct(String productName);

  /// No description provided for @confirmDeleteAlert.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this alert? This action is permanent and cannot be undone.'**
  String get confirmDeleteAlert;

  /// No description provided for @confirmDeleteAllAlerts.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all alerts? This action is permanent, cannot be undone, and will clear all current notifications.'**
  String get confirmDeleteAllAlerts;

  /// No description provided for @clearAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get clearAuditLogs;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Action'**
  String get confirmAction;

  /// No description provided for @confirmClearLogs.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all audit logs? This action is permanent and cannot be undone.'**
  String get confirmClearLogs;

  /// No description provided for @btnConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get btnConfirm;

  /// No description provided for @composeMessage.
  ///
  /// In en, this message translates to:
  /// **'Compose Message'**
  String get composeMessage;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Title'**
  String get notificationTitle;

  /// No description provided for @notificationDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'New Notification'**
  String get notificationDefaultTitle;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'High Importance Notifications'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'This channel is used for important notifications.'**
  String get notificationChannelDescription;

  /// No description provided for @notificationTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. New Feature Alert!'**
  String get notificationTitleHint;

  /// No description provided for @notificationBody.
  ///
  /// In en, this message translates to:
  /// **'Notification Body'**
  String get notificationBody;

  /// No description provided for @notificationBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the message here...'**
  String get notificationBodyHint;

  /// No description provided for @actionButtons.
  ///
  /// In en, this message translates to:
  /// **'Action Buttons'**
  String get actionButtons;

  /// No description provided for @actionButtonsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Dismiss, Open App'**
  String get actionButtonsHint;

  /// No description provided for @pageToOpen.
  ///
  /// In en, this message translates to:
  /// **'Page to open'**
  String get pageToOpen;

  /// No description provided for @menuSendPush.
  ///
  /// In en, this message translates to:
  /// **'Send Push'**
  String get menuSendPush;

  /// No description provided for @actionAndRouting.
  ///
  /// In en, this message translates to:
  /// **'Action & Routing'**
  String get actionAndRouting;

  /// No description provided for @openSpecificPage.
  ///
  /// In en, this message translates to:
  /// **'Open Specific Page (Optional)'**
  String get openSpecificPage;

  /// No description provided for @defaultNoPage.
  ///
  /// In en, this message translates to:
  /// **'Default (No specific page)'**
  String get defaultNoPage;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @dashboardOpsAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Operations analytics'**
  String get dashboardOpsAnalytics;

  /// No description provided for @dashboardExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get dashboardExport;

  /// No description provided for @dashboardDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dashboardDaily;

  /// No description provided for @dashboardWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get dashboardWeekly;

  /// No description provided for @dashboardMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get dashboardMonthly;

  /// No description provided for @dashboardRoomsAttention.
  ///
  /// In en, this message translates to:
  /// **'Rooms needing attention'**
  String get dashboardRoomsAttention;

  /// No description provided for @dashboardProductUsage.
  ///
  /// In en, this message translates to:
  /// **'Product usage'**
  String get dashboardProductUsage;

  /// No description provided for @dashboardUsageByFloor.
  ///
  /// In en, this message translates to:
  /// **'Usage by floor'**
  String get dashboardUsageByFloor;

  /// No description provided for @dashboardStockForecast.
  ///
  /// In en, this message translates to:
  /// **'Stock depletion forecast'**
  String get dashboardStockForecast;

  /// No description provided for @dashboardUnusualPatterns.
  ///
  /// In en, this message translates to:
  /// **'Unusual patterns'**
  String get dashboardUnusualPatterns;

  /// No description provided for @dashboardNoStockData.
  ///
  /// In en, this message translates to:
  /// **'No stock data'**
  String get dashboardNoStockData;

  /// No description provided for @dashboardRoomsRequireReview.
  ///
  /// In en, this message translates to:
  /// **'{count} rooms require review'**
  String dashboardRoomsRequireReview(String count);

  /// No description provided for @dashboardNoUnusualPatterns.
  ///
  /// In en, this message translates to:
  /// **'No unusual patterns detected'**
  String get dashboardNoUnusualPatterns;

  /// No description provided for @dashboardHighPriority.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get dashboardHighPriority;

  /// No description provided for @dashboardStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get dashboardStable;

  /// No description provided for @errorLoadingHotels.
  ///
  /// In en, this message translates to:
  /// **'Error loading hotels'**
  String get errorLoadingHotels;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @roomsEditRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Update room {roomNumber}'**
  String roomsEditRoomTitle(String roomNumber);

  /// No description provided for @roomsEditProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Update {productName} bottle in room {roomNumber}'**
  String roomsEditProductTitle(String productName, String roomNumber);

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Store Stock'**
  String get inventory;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @approvals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvals;

  /// No description provided for @actionButtonsAndroid.
  ///
  /// In en, this message translates to:
  /// **'Action Buttons (Android Only)'**
  String get actionButtonsAndroid;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @acknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get acknowledge;

  /// No description provided for @openApp.
  ///
  /// In en, this message translates to:
  /// **'Open App'**
  String get openApp;

  /// No description provided for @sendNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get sendNotification;

  /// No description provided for @targetAudience.
  ///
  /// In en, this message translates to:
  /// **'Target Audience'**
  String get targetAudience;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @byRole.
  ///
  /// In en, this message translates to:
  /// **'By Role'**
  String get byRole;

  /// No description provided for @byHotel.
  ///
  /// In en, this message translates to:
  /// **'By Hotel'**
  String get byHotel;

  /// No description provided for @byUserEmail.
  ///
  /// In en, this message translates to:
  /// **'By User Email'**
  String get byUserEmail;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get selectRole;

  /// No description provided for @selectHotel.
  ///
  /// In en, this message translates to:
  /// **'Select Hotel'**
  String get selectHotel;

  /// No description provided for @userEmail.
  ///
  /// In en, this message translates to:
  /// **'User Email'**
  String get userEmail;

  /// No description provided for @menuAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get menuAuditLogs;

  /// No description provided for @auditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get auditLogs;

  /// No description provided for @auditAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get auditAction;

  /// No description provided for @auditDevice.
  ///
  /// In en, this message translates to:
  /// **'Device / OS'**
  String get auditDevice;

  /// No description provided for @auditIpAddress.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get auditIpAddress;

  /// No description provided for @auditTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get auditTimestamp;

  /// No description provided for @auditUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get auditUser;

  /// No description provided for @enterSpecificUserEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter specific user email'**
  String get enterSpecificUserEmail;

  /// No description provided for @dispatchNotification.
  ///
  /// In en, this message translates to:
  /// **'Dispatch Notification'**
  String get dispatchNotification;

  /// No description provided for @pleaseEnterTitleBody.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title and body'**
  String get pleaseEnterTitleBody;

  /// No description provided for @pleaseSelectTarget.
  ///
  /// In en, this message translates to:
  /// **'Please select a target value'**
  String get pleaseSelectTarget;

  /// No description provided for @notificationSent.
  ///
  /// In en, this message translates to:
  /// **'Sent: {successCount} success, {failureCount} failed'**
  String notificationSent(String successCount, String failureCount);

  /// No description provided for @dashboardShort.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardShort;

  /// No description provided for @dashboardHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Today at Ivra'**
  String get dashboardHeroTitle;

  /// No description provided for @dashboardRefillActivity.
  ///
  /// In en, this message translates to:
  /// **'Refill Activity (Last 7 Days)'**
  String get dashboardRefillActivity;

  /// No description provided for @refillActivity.
  ///
  /// In en, this message translates to:
  /// **'Refill Activity'**
  String get refillActivity;

  /// No description provided for @myCompletedTasksThisWeek.
  ///
  /// In en, this message translates to:
  /// **'My Completed Refills This Week'**
  String get myCompletedTasksThisWeek;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @lastYear.
  ///
  /// In en, this message translates to:
  /// **'Last year'**
  String get lastYear;

  /// No description provided for @allHotels.
  ///
  /// In en, this message translates to:
  /// **'All Hotels'**
  String get allHotels;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @chartRefills.
  ///
  /// In en, this message translates to:
  /// **'refills'**
  String get chartRefills;

  /// No description provided for @teamEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get teamEditProfile;

  /// No description provided for @teamEditProfileSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get teamEditProfileSuccess;

  /// No description provided for @hotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get hotels;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @refill.
  ///
  /// In en, this message translates to:
  /// **'Refill'**
  String get refill;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @correction.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get correction;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @suggestedOrders.
  ///
  /// In en, this message translates to:
  /// **'Suggested orders'**
  String get suggestedOrders;

  /// No description provided for @bottles.
  ///
  /// In en, this message translates to:
  /// **'Bottles'**
  String get bottles;

  /// No description provided for @bidons.
  ///
  /// In en, this message translates to:
  /// **'Refill bottles'**
  String get bidons;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode'**
  String get demoMode;

  /// No description provided for @downloadCsv.
  ///
  /// In en, this message translates to:
  /// **'Download CSV'**
  String get downloadCsv;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @reportRefillHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Refill history'**
  String get reportRefillHistoryTitle;

  /// No description provided for @reportRefillHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'Export recent refill activity by hotel, room, product, user, and time.'**
  String get reportRefillHistoryBody;

  /// No description provided for @reportSuggestedOrdersBody.
  ///
  /// In en, this message translates to:
  /// **'Export bottles, refill bottles, and recycling recommendations.'**
  String get reportSuggestedOrdersBody;

  /// No description provided for @reportInventorySnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Store Stock snapshot'**
  String get reportInventorySnapshotTitle;

  /// No description provided for @reportInventorySnapshotBody.
  ///
  /// In en, this message translates to:
  /// **'Export current bottle and refill bottle stock by hotel and product.'**
  String get reportInventorySnapshotBody;

  /// No description provided for @reportOpenAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Open alerts'**
  String get reportOpenAlertsTitle;

  /// No description provided for @reportOpenAlertsBody.
  ///
  /// In en, this message translates to:
  /// **'Export low stock, replacement, inactivity, and suspicious activity alerts.'**
  String get reportOpenAlertsBody;

  /// No description provided for @scheduleReportEmail.
  ///
  /// In en, this message translates to:
  /// **'Schedule report email'**
  String get scheduleReportEmail;

  /// No description provided for @scheduleReportEmailHint.
  ///
  /// In en, this message translates to:
  /// **'We will send a summary of this report to this address every Monday.'**
  String get scheduleReportEmailHint;

  /// No description provided for @scheduledReportEmailDrafted.
  ///
  /// In en, this message translates to:
  /// **'Email report scheduled successfully'**
  String get scheduledReportEmailDrafted;

  /// No description provided for @reportFilterDateRange.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date Range'**
  String get reportFilterDateRange;

  /// No description provided for @reportAllProducts.
  ///
  /// In en, this message translates to:
  /// **'All products'**
  String get reportAllProducts;

  /// No description provided for @reportAllRooms.
  ///
  /// In en, this message translates to:
  /// **'All rooms'**
  String get reportAllRooms;

  /// No description provided for @reportClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get reportClearFilters;

  /// No description provided for @reportFiltersApplyExports.
  ///
  /// In en, this message translates to:
  /// **'Note: Filters apply to both screen metrics and downloaded exports.'**
  String get reportFiltersApplyExports;

  /// No description provided for @reportAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics Overview'**
  String get reportAnalyticsTitle;

  /// No description provided for @reportKpiRefills.
  ///
  /// In en, this message translates to:
  /// **'Total Refills'**
  String get reportKpiRefills;

  /// No description provided for @reportKpiCorrections.
  ///
  /// In en, this message translates to:
  /// **'Stock Corrections'**
  String get reportKpiCorrections;

  /// No description provided for @reportKpiReplacements.
  ///
  /// In en, this message translates to:
  /// **'Replacements'**
  String get reportKpiReplacements;

  /// No description provided for @reportKpiActiveRooms.
  ///
  /// In en, this message translates to:
  /// **'Active Rooms'**
  String get reportKpiActiveRooms;

  /// No description provided for @reportTrendChart.
  ///
  /// In en, this message translates to:
  /// **'Refill Activity Trend (Last 14 Days)'**
  String get reportTrendChart;

  /// No description provided for @reportUsageByProduct.
  ///
  /// In en, this message translates to:
  /// **'Refills by Product'**
  String get reportUsageByProduct;

  /// No description provided for @reportUsageByRoom.
  ///
  /// In en, this message translates to:
  /// **'Refills by Room'**
  String get reportUsageByRoom;

  /// No description provided for @reportNoAnalyticsData.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded for this period.'**
  String get reportNoAnalyticsData;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @metricHotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get metricHotels;

  /// No description provided for @metricRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get metricRooms;

  /// No description provided for @metricPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Pending approvals'**
  String get metricPendingApprovals;

  /// No description provided for @metricOpenAlerts.
  ///
  /// In en, this message translates to:
  /// **'Open alerts'**
  String get metricOpenAlerts;

  /// No description provided for @metricBottlesToReplace.
  ///
  /// In en, this message translates to:
  /// **'Bottles to replace'**
  String get metricBottlesToReplace;

  /// No description provided for @metricLowStockProducts.
  ///
  /// In en, this message translates to:
  /// **'Low stock products'**
  String get metricLowStockProducts;

  /// No description provided for @inventoryTableProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get inventoryTableProduct;

  /// No description provided for @inventoryTableFullBottles.
  ///
  /// In en, this message translates to:
  /// **'Full bottles'**
  String get inventoryTableFullBottles;

  /// No description provided for @inventoryTableFullBottlesWithPump.
  ///
  /// In en, this message translates to:
  /// **'Full {size} bottles with pump'**
  String inventoryTableFullBottlesWithPump(String size);

  /// No description provided for @inventoryTableFullBottlesWithoutPump.
  ///
  /// In en, this message translates to:
  /// **'Full {size} bottles without pump'**
  String inventoryTableFullBottlesWithoutPump(String size);

  /// No description provided for @inventoryTableFullBottlesWithPumpGeneric.
  ///
  /// In en, this message translates to:
  /// **'Full bottles with pump'**
  String get inventoryTableFullBottlesWithPumpGeneric;

  /// No description provided for @inventoryTableFullBottlesWithoutPumpGeneric.
  ///
  /// In en, this message translates to:
  /// **'Full bottles without pump'**
  String get inventoryTableFullBottlesWithoutPumpGeneric;

  /// No description provided for @inventoryCollapseHeader.
  ///
  /// In en, this message translates to:
  /// **'Empty & Open Bottles'**
  String get inventoryCollapseHeader;

  /// No description provided for @inventoryTableEmptyBottles.
  ///
  /// In en, this message translates to:
  /// **'Replaced bottles after {months} months (Used)'**
  String inventoryTableEmptyBottles(String months);

  /// No description provided for @inventoryTableEmptyBottlesGeneric.
  ///
  /// In en, this message translates to:
  /// **'Replaced bottles (Used)'**
  String get inventoryTableEmptyBottlesGeneric;

  /// No description provided for @inventoryTableEmptyBidons.
  ///
  /// In en, this message translates to:
  /// **'Empty refill bottles'**
  String get inventoryTableEmptyBidons;

  /// No description provided for @inventoryTableFullBidons.
  ///
  /// In en, this message translates to:
  /// **'Full {size} refill bottles'**
  String inventoryTableFullBidons(String size);

  /// No description provided for @inventoryTableFullBidonsGeneric.
  ///
  /// In en, this message translates to:
  /// **'Full refill bottles'**
  String get inventoryTableFullBidonsGeneric;

  /// No description provided for @inventoryTableOpenBidons.
  ///
  /// In en, this message translates to:
  /// **'Used refill bottles'**
  String get inventoryTableOpenBidons;

  /// No description provided for @inventoryTableStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get inventoryTableStatus;

  /// No description provided for @errorUniqueViolation.
  ///
  /// In en, this message translates to:
  /// **'This record already exists.'**
  String get errorUniqueViolation;

  /// No description provided for @errorForeignKeyViolation.
  ///
  /// In en, this message translates to:
  /// **'Related record not found.'**
  String get errorForeignKeyViolation;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action.'**
  String get errorPermissionDenied;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errorGeneric;

  /// No description provided for @inventoryStatusHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get inventoryStatusHealthy;

  /// No description provided for @inventoryStatusLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get inventoryStatusLowStock;

  /// No description provided for @auditFilterAllActions.
  ///
  /// In en, this message translates to:
  /// **'All Actions'**
  String get auditFilterAllActions;

  /// No description provided for @sortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get sortNameAsc;

  /// No description provided for @sortNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get sortNameDesc;

  /// No description provided for @sortMostFullBottles.
  ///
  /// In en, this message translates to:
  /// **'Most Full Bottles'**
  String get sortMostFullBottles;

  /// No description provided for @sortMostEmptyBottles.
  ///
  /// In en, this message translates to:
  /// **'Most Empty Bottles'**
  String get sortMostEmptyBottles;

  /// No description provided for @bulkAdjustSelectProducts.
  ///
  /// In en, this message translates to:
  /// **'Select products'**
  String get bulkAdjustSelectProducts;

  /// No description provided for @bulkAdjustSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get bulkAdjustSelectAll;

  /// No description provided for @bulkAdjustDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get bulkAdjustDeselectAll;

  /// No description provided for @bulkAdjustNoProductsSelected.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one product.'**
  String get bulkAdjustNoProductsSelected;

  /// No description provided for @orderNewBottlesText.
  ///
  /// In en, this message translates to:
  /// **'Order {count} new 1L bottles'**
  String orderNewBottlesText(String count);

  /// No description provided for @orderNewBidonsText.
  ///
  /// In en, this message translates to:
  /// **'Order {count} new 5L refill bottles'**
  String orderNewBidonsText(String count);

  /// No description provided for @recycleBottlesText.
  ///
  /// In en, this message translates to:
  /// **'Recycle {count} bottles'**
  String recycleBottlesText(String count);

  /// No description provided for @bottleCannotRefillRecycled.
  ///
  /// In en, this message translates to:
  /// **'This bottle has been recycled and cannot be refilled. Please replace it.'**
  String get bottleCannotRefillRecycled;

  /// No description provided for @adjustStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get adjustStockTitle;

  /// No description provided for @hotelRoomsTracked.
  ///
  /// In en, this message translates to:
  /// **'rooms tracked'**
  String get hotelRoomsTracked;

  /// No description provided for @hotelPendingChip.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get hotelPendingChip;

  /// No description provided for @hotelLabelName.
  ///
  /// In en, this message translates to:
  /// **'Hotel name'**
  String get hotelLabelName;

  /// No description provided for @hotelLabelLegalName.
  ///
  /// In en, this message translates to:
  /// **'Legal name'**
  String get hotelLabelLegalName;

  /// No description provided for @hotelLabelState.
  ///
  /// In en, this message translates to:
  /// **'State (Governorate)'**
  String get hotelLabelState;

  /// No description provided for @hotelLabelCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get hotelLabelCountry;

  /// No description provided for @hotelLabelContactName.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get hotelLabelContactName;

  /// No description provided for @hotelLabelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get hotelLabelEmail;

  /// No description provided for @hotelLabelPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get hotelLabelPhone;

  /// No description provided for @hotelLabelAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get hotelLabelAddress;

  /// No description provided for @hotelLabelNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get hotelLabelNotes;

  /// No description provided for @btnCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get btnCreate;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btnSave;

  /// No description provided for @btnSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get btnSubmitRequest;

  /// No description provided for @demoModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Local simulations using offline database templates.'**
  String get demoModeDescription;

  /// No description provided for @offlineModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Queues actions when disconnected and syncs later.'**
  String get offlineModeDescription;

  /// No description provided for @syncQueueHeader.
  ///
  /// In en, this message translates to:
  /// **'Sync Queue'**
  String get syncQueueHeader;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @itemsToSync.
  ///
  /// In en, this message translates to:
  /// **'actions pending sync'**
  String get itemsToSync;

  /// No description provided for @editRequestQueued.
  ///
  /// In en, this message translates to:
  /// **'Hotel edit request queued'**
  String get editRequestQueued;

  /// No description provided for @editRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Hotel edit request submitted'**
  String get editRequestSubmitted;

  /// No description provided for @hotelUpdated.
  ///
  /// In en, this message translates to:
  /// **'Hotel information updated'**
  String get hotelUpdated;

  /// No description provided for @hotelCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Hotel created successfully'**
  String get hotelCreatedSuccessfully;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @enterNumberError.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get enterNumberError;

  /// No description provided for @createHotel.
  ///
  /// In en, this message translates to:
  /// **'Create hotel'**
  String get createHotel;

  /// No description provided for @requestHotelEdit.
  ///
  /// In en, this message translates to:
  /// **'Request hotel edit'**
  String get requestHotelEdit;

  /// No description provided for @authTitleCannotAccess.
  ///
  /// In en, this message translates to:
  /// **'You need an invitation to access Ivra.'**
  String get authTitleCannotAccess;

  /// No description provided for @authBtnGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get authBtnGoogleSignIn;

  /// No description provided for @authBtnSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authBtnSignOut;

  /// No description provided for @authLabelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authLabelEmail;

  /// No description provided for @authLabelPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authLabelPassword;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authBtnSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authBtnSignIn;

  /// No description provided for @authBtnForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authBtnForgotPassword;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPasswordTitle;

  /// No description provided for @setPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your password'**
  String get setPasswordTitle;

  /// No description provided for @setPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Please set a secure password for your account to complete your registration.'**
  String get setPasswordBody;

  /// No description provided for @setPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get setPasswordButton;

  /// No description provided for @authBtnSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authBtnSendResetLink;

  /// No description provided for @authResetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to'**
  String get authResetLinkSent;

  /// No description provided for @authValidationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authValidationEmailRequired;

  /// No description provided for @authValidationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authValidationEmailInvalid;

  /// No description provided for @authValidationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authValidationPasswordRequired;

  /// No description provided for @authValidationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get authValidationPasswordTooShort;

  /// No description provided for @authValidationPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authValidationPasswordsDoNotMatch;

  /// No description provided for @authResetNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new password'**
  String get authResetNewPasswordTitle;

  /// No description provided for @authLabelNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authLabelNewPassword;

  /// No description provided for @authLabelConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authLabelConfirmPassword;

  /// No description provided for @authBtnUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get authBtnUpdatePassword;

  /// No description provided for @authBtnReturnToApp.
  ///
  /// In en, this message translates to:
  /// **'Return to app'**
  String get authBtnReturnToApp;

  /// No description provided for @authPasswordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully.'**
  String get authPasswordUpdatedSuccess;

  /// No description provided for @authUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again, or contact support if the problem persists.'**
  String get authUnexpectedError;

  /// No description provided for @asyncErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load this section'**
  String get asyncErrorTitle;

  /// No description provided for @btnRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get btnRetry;

  /// No description provided for @authProfileLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your profile.'**
  String get authProfileLoadErrorTitle;

  /// No description provided for @authProfileLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'This is usually a temporary connection issue. Please retry.'**
  String get authProfileLoadErrorBody;

  /// No description provided for @authAccountDeactivated.
  ///
  /// In en, this message translates to:
  /// **'This account has been deactivated. Contact your administrator for access.'**
  String get authAccountDeactivated;

  /// No description provided for @settingsPayloadInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'Payload must be a JSON object.'**
  String get settingsPayloadInvalidJson;

  /// No description provided for @exportDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'{fileName} download started'**
  String exportDownloadStarted(String fileName);

  /// No description provided for @exportSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {fileName} to {path}'**
  String exportSaved(String fileName, String path);

  /// No description provided for @settingsPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync ({count})'**
  String settingsPendingSync(String count);

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Sustainable Hospitality Solutions'**
  String get splashTagline;

  /// No description provided for @accountSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile. Please try again.'**
  String get accountSaveFailed;

  /// No description provided for @accountPasswordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change your password. Please try again.'**
  String get accountPasswordChangeFailed;

  /// No description provided for @accountSignOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out. Check your connection and try again.'**
  String get accountSignOutFailed;

  /// No description provided for @hotelCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the hotel. Please try again.'**
  String get hotelCreateFailed;

  /// No description provided for @hotelUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the hotel. Please try again.'**
  String get hotelUpdateFailed;

  /// No description provided for @teamInviteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the invitation. Please try again.'**
  String get teamInviteFailed;

  /// No description provided for @teamHotelsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update hotel assignments. Please try again.'**
  String get teamHotelsUpdateFailed;

  /// No description provided for @roomsTooltipCreateTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create room template'**
  String get roomsTooltipCreateTemplate;

  /// No description provided for @roomsNoRoomsFound.
  ///
  /// In en, this message translates to:
  /// **'No rooms or products found.'**
  String get roomsNoRoomsFound;

  /// No description provided for @roomsScanConfirmFromCart.
  ///
  /// In en, this message translates to:
  /// **'Product \"{product}\" is not currently assigned to this room, but you have {count} in your cart. Would you like to take 1 from your cart and assign it to this room?'**
  String roomsScanConfirmFromCart(String product, String count);

  /// No description provided for @roomsScanConfirmFromHotel.
  ///
  /// In en, this message translates to:
  /// **'Product \"{product}\" is not in this room. There are {count} bottles in the hotel inventory. Would you like to get 1 and assign it to this room?'**
  String roomsScanConfirmFromHotel(String product, String count);

  /// No description provided for @roomsNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products assigned to this room.'**
  String get roomsNoProducts;

  /// No description provided for @roomsStatusNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products'**
  String get roomsStatusNoProducts;

  /// No description provided for @roomsSearchEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search query or filters.'**
  String get roomsSearchEmptyHint;

  /// No description provided for @roomsEmptyHotelWithTemplate.
  ///
  /// In en, this message translates to:
  /// **'Add your first room using the template button above.'**
  String get roomsEmptyHotelWithTemplate;

  /// No description provided for @roomsEmptyHotelNoTemplate.
  ///
  /// In en, this message translates to:
  /// **'No rooms have been assigned to this hotel yet.'**
  String get roomsEmptyHotelNoTemplate;

  /// No description provided for @roomsLabelRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get roomsLabelRoom;

  /// No description provided for @bottleStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get bottleStatusActive;

  /// No description provided for @bottleStatusNeedsRefill.
  ///
  /// In en, this message translates to:
  /// **'Needs refill'**
  String get bottleStatusNeedsRefill;

  /// No description provided for @bottleStatusRefilled.
  ///
  /// In en, this message translates to:
  /// **'Refilled'**
  String get bottleStatusRefilled;

  /// No description provided for @bottleStatusRefillLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Refill limit reached'**
  String get bottleStatusRefillLimitReached;

  /// No description provided for @bottleStatusTooOld.
  ///
  /// In en, this message translates to:
  /// **'Too old'**
  String get bottleStatusTooOld;

  /// No description provided for @bottleStatusNeedsReplacement.
  ///
  /// In en, this message translates to:
  /// **'Needs replacement'**
  String get bottleStatusNeedsReplacement;

  /// No description provided for @bottleStatusRecycled.
  ///
  /// In en, this message translates to:
  /// **'Recycled'**
  String get bottleStatusRecycled;

  /// No description provided for @bottleStatusDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get bottleStatusDamaged;

  /// No description provided for @bottleStatusLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get bottleStatusLost;

  /// No description provided for @roomsLabelFloor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get roomsLabelFloor;

  /// No description provided for @roomsLabelRefills.
  ///
  /// In en, this message translates to:
  /// **'Refills'**
  String get roomsLabelRefills;

  /// No description provided for @roomsLabelAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get roomsLabelAge;

  /// No description provided for @roomsLabelDaysUnit.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get roomsLabelDaysUnit;

  /// No description provided for @roomsRefillQueued.
  ///
  /// In en, this message translates to:
  /// **'Refill queued for room'**
  String get roomsRefillQueued;

  /// No description provided for @roomsRefillRecorded.
  ///
  /// In en, this message translates to:
  /// **'Refill recorded for room'**
  String get roomsRefillRecorded;

  /// No description provided for @roomsBtnBottleEdit.
  ///
  /// In en, this message translates to:
  /// **'Bottle edit'**
  String get roomsBtnBottleEdit;

  /// No description provided for @roomsBtnReplaceBottle.
  ///
  /// In en, this message translates to:
  /// **'Replace bottle'**
  String get roomsBtnReplaceBottle;

  /// No description provided for @roomsBtnRefillBottle.
  ///
  /// In en, this message translates to:
  /// **'Refill bottle'**
  String get roomsBtnRefillBottle;

  /// No description provided for @roomsBtnRoomEdit.
  ///
  /// In en, this message translates to:
  /// **'Room edit'**
  String get roomsBtnRoomEdit;

  /// No description provided for @roomsBtnHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get roomsBtnHistory;

  /// No description provided for @roomsBtnMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get roomsBtnMoreActions;

  /// No description provided for @roomsBtnMarkDamaged.
  ///
  /// In en, this message translates to:
  /// **'Mark as Damaged'**
  String get roomsBtnMarkDamaged;

  /// No description provided for @roomsBtnMarkLost.
  ///
  /// In en, this message translates to:
  /// **'Mark as Lost'**
  String get roomsBtnMarkLost;

  /// No description provided for @roomsLabelProofPhoto.
  ///
  /// In en, this message translates to:
  /// **'Proof Photo'**
  String get roomsLabelProofPhoto;

  /// No description provided for @roomsNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get roomsNotesOptional;

  /// No description provided for @roomsLabelUploadedProof.
  ///
  /// In en, this message translates to:
  /// **'Uploaded Proof'**
  String get roomsLabelUploadedProof;

  /// No description provided for @roomsUploadProofAction.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get roomsUploadProofAction;

  /// No description provided for @roomsReplacementQueued.
  ///
  /// In en, this message translates to:
  /// **'Bottle replacement queued for room'**
  String get roomsReplacementQueued;

  /// No description provided for @roomsReplacementRecorded.
  ///
  /// In en, this message translates to:
  /// **'Bottle replaced for room'**
  String get roomsReplacementRecorded;

  /// No description provided for @roomsReplacementNotes.
  ///
  /// In en, this message translates to:
  /// **'Bottle replaced from room workflow'**
  String get roomsReplacementNotes;

  /// No description provided for @roomsStatusAllOk.
  ///
  /// In en, this message translates to:
  /// **'All OK'**
  String get roomsStatusAllOk;

  /// No description provided for @roomsStatusAttentionRequired.
  ///
  /// In en, this message translates to:
  /// **'Attention Required'**
  String get roomsStatusAttentionRequired;

  /// No description provided for @roomsStatusRefillNeeded.
  ///
  /// In en, this message translates to:
  /// **'Refill Needed'**
  String get roomsStatusRefillNeeded;

  /// No description provided for @roomsSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search room...'**
  String get roomsSearchPlaceholder;

  /// No description provided for @roomsRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent rooms'**
  String get roomsRecentTitle;

  /// No description provided for @roomsRecentClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get roomsRecentClear;

  /// No description provided for @roomsGestionExpressQr.
  ///
  /// In en, this message translates to:
  /// **'Express QR Management'**
  String get roomsGestionExpressQr;

  /// No description provided for @roomsGestionQr.
  ///
  /// In en, this message translates to:
  /// **'QR Code Management'**
  String get roomsGestionQr;

  /// No description provided for @expressQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Express QR Management'**
  String get expressQrTitle;

  /// No description provided for @expressQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow direct scanning of dispenser-level QR codes'**
  String get expressQrSubtitle;

  /// No description provided for @roomsSelectHotelFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a hotel...'**
  String get roomsSelectHotelFirst;

  /// No description provided for @roomsViewDetailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed View'**
  String get roomsViewDetailed;

  /// No description provided for @roomsViewCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact View'**
  String get roomsViewCompact;

  /// No description provided for @roomsCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get roomsCollapseAll;

  /// No description provided for @roomsExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get roomsExpandAll;

  /// No description provided for @roomsBtnAddRoom.
  ///
  /// In en, this message translates to:
  /// **'Add room'**
  String get roomsBtnAddRoom;

  /// No description provided for @roomsDialogAddRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Add room to floor'**
  String get roomsDialogAddRoomTitle;

  /// No description provided for @roomsMsgRoomAdded.
  ///
  /// In en, this message translates to:
  /// **'Room added'**
  String get roomsMsgRoomAdded;

  /// No description provided for @roomsMsgRoomAddQueued.
  ///
  /// In en, this message translates to:
  /// **'Room creation queued'**
  String get roomsMsgRoomAddQueued;

  /// No description provided for @roomsHistoryRefill.
  ///
  /// In en, this message translates to:
  /// **'Refill'**
  String get roomsHistoryRefill;

  /// No description provided for @roomsHistoryNewBottle.
  ///
  /// In en, this message translates to:
  /// **'New bottle placed'**
  String get roomsHistoryNewBottle;

  /// No description provided for @roomsHistoryStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed from {oldValue} to {newValue}'**
  String roomsHistoryStatusChanged(String oldValue, String newValue);

  /// No description provided for @roomsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get roomsFilterAll;

  /// No description provided for @roomsDialogBottleEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Request bottle edit for room'**
  String get roomsDialogBottleEditTitle;

  /// No description provided for @roomsLabelBottleStatus.
  ///
  /// In en, this message translates to:
  /// **'Bottle status'**
  String get roomsLabelBottleStatus;

  /// No description provided for @roomsLabelBottleStartDate.
  ///
  /// In en, this message translates to:
  /// **'Bottle start date'**
  String get roomsLabelBottleStartDate;

  /// No description provided for @roomsValidationEnterValidDate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid date'**
  String get roomsValidationEnterValidDate;

  /// No description provided for @roomsMsgEditRequestQueued.
  ///
  /// In en, this message translates to:
  /// **'Bottle edit request queued'**
  String get roomsMsgEditRequestQueued;

  /// No description provided for @roomsMsgDetailsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Bottle details updated'**
  String get roomsMsgDetailsUpdated;

  /// No description provided for @roomsMsgEditRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Bottle edit request submitted'**
  String get roomsMsgEditRequestSubmitted;

  /// No description provided for @roomsDialogRoomEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Request room edit for'**
  String get roomsDialogRoomEditTitle;

  /// No description provided for @roomsLabelRoomNumber.
  ///
  /// In en, this message translates to:
  /// **'Room number'**
  String get roomsLabelRoomNumber;

  /// No description provided for @roomsLabelFloorNumber.
  ///
  /// In en, this message translates to:
  /// **'Floor number'**
  String get roomsLabelFloorNumber;

  /// No description provided for @roomsMsgRoomEditQueued.
  ///
  /// In en, this message translates to:
  /// **'Room edit request queued'**
  String get roomsMsgRoomEditQueued;

  /// No description provided for @roomsMsgRoomDetailsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Room details updated'**
  String get roomsMsgRoomDetailsUpdated;

  /// No description provided for @roomsMsgRoomEditSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Room edit request submitted'**
  String get roomsMsgRoomEditSubmitted;

  /// No description provided for @roomsMsgRequestRoomEdit.
  ///
  /// In en, this message translates to:
  /// **'Update room'**
  String get roomsMsgRequestRoomEdit;

  /// No description provided for @roomsDialogHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'history'**
  String get roomsDialogHistoryTitle;

  /// No description provided for @roomsNoHistoryRecorded.
  ///
  /// In en, this message translates to:
  /// **'No refill history has been recorded yet.'**
  String get roomsNoHistoryRecorded;

  /// No description provided for @roomsMsgUndoQueued.
  ///
  /// In en, this message translates to:
  /// **'Undo queued'**
  String get roomsMsgUndoQueued;

  /// No description provided for @roomsMsgRefillUndone.
  ///
  /// In en, this message translates to:
  /// **'Refill undone'**
  String get roomsMsgRefillUndone;

  /// No description provided for @roomsBtnClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get roomsBtnClose;

  /// No description provided for @qrScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get qrScanTitle;

  /// No description provided for @qrScanPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter QR code manually...'**
  String get qrScanPlaceholder;

  /// No description provided for @qrDemoCodes.
  ///
  /// In en, this message translates to:
  /// **'Demo QR Codes'**
  String get qrDemoCodes;

  /// No description provided for @qrActionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select Action'**
  String get qrActionPrompt;

  /// No description provided for @qrActionMessage.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do for {product}?'**
  String qrActionMessage(String product);

  /// No description provided for @qrActionRefill.
  ///
  /// In en, this message translates to:
  /// **'Refill Bottle'**
  String get qrActionRefill;

  /// No description provided for @qrActionReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace Bottle'**
  String get qrActionReplace;

  /// No description provided for @hotelNotFound.
  ///
  /// In en, this message translates to:
  /// **'Hotel Not Found'**
  String get hotelNotFound;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product Not Found'**
  String get productNotFound;

  /// No description provided for @qrAccessDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to perform actions at this hotel.'**
  String get qrAccessDeniedMessage;

  /// No description provided for @roomsFillCount.
  ///
  /// In en, this message translates to:
  /// **'Refill Count'**
  String get roomsFillCount;

  /// No description provided for @roomsBottleStatus.
  ///
  /// In en, this message translates to:
  /// **'Dispenser Status'**
  String get roomsBottleStatus;

  /// No description provided for @btnBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get btnBack;

  /// No description provided for @qrActionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Action Successful'**
  String get qrActionSuccess;

  /// No description provided for @qrActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action Failed'**
  String get qrActionFailed;

  /// No description provided for @qrUpdatedStatus.
  ///
  /// In en, this message translates to:
  /// **'Updated Dispenser Status:'**
  String get qrUpdatedStatus;

  /// No description provided for @qrScanAnother.
  ///
  /// In en, this message translates to:
  /// **'Scan another QR code'**
  String get qrScanAnother;

  /// No description provided for @qrReturnRooms.
  ///
  /// In en, this message translates to:
  /// **'Return to rooms'**
  String get qrReturnRooms;

  /// No description provided for @qrTryScanAgain.
  ///
  /// In en, this message translates to:
  /// **'Try scanning again'**
  String get qrTryScanAgain;

  /// No description provided for @qrFloorRoom.
  ///
  /// In en, this message translates to:
  /// **'Floor {floor} • Room {room}'**
  String qrFloorRoom(String floor, String room);

  /// No description provided for @qrRoomFloor.
  ///
  /// In en, this message translates to:
  /// **'Room {room} • Floor {floor}'**
  String qrRoomFloor(String room, String floor);

  /// No description provided for @qrCameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get qrCameraPermission;

  /// No description provided for @qrCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get qrCameraUnavailable;

  /// No description provided for @qrHotelNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not match hotel: \"{hotel}\"'**
  String qrHotelNotFoundMessage(String hotel);

  /// No description provided for @qrProductNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Room {room} (Floor {floor}) does not contain product SKU: \"{sku}\"'**
  String qrProductNotFoundMessage(String room, String floor, String sku);

  /// No description provided for @qrGenerateTabScan.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get qrGenerateTabScan;

  /// No description provided for @qrGenerateTabGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate QR Codes'**
  String get qrGenerateTabGenerate;

  /// No description provided for @qrGenerateHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get qrGenerateHotel;

  /// No description provided for @qrGenerateScope.
  ///
  /// In en, this message translates to:
  /// **'QR Label Type'**
  String get qrGenerateScope;

  /// No description provided for @qrGenerateScopeRoom.
  ///
  /// In en, this message translates to:
  /// **'Room Door (No SKU)'**
  String get qrGenerateScopeRoom;

  /// No description provided for @qrGenerateScopeDispenser.
  ///
  /// In en, this message translates to:
  /// **'Dispenser (With SKU)'**
  String get qrGenerateScopeDispenser;

  /// No description provided for @qrGenerateRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get qrGenerateRoom;

  /// No description provided for @qrGenerateProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get qrGenerateProduct;

  /// No description provided for @qrGenerateAllRooms.
  ///
  /// In en, this message translates to:
  /// **'All Rooms'**
  String get qrGenerateAllRooms;

  /// No description provided for @qrGenerateAllProducts.
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get qrGenerateAllProducts;

  /// No description provided for @qrGenerateBtnDownload.
  ///
  /// In en, this message translates to:
  /// **'Generate & Download PDF'**
  String get qrGenerateBtnDownload;

  /// No description provided for @qrGenerateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF...'**
  String get qrGenerateDownloading;

  /// No description provided for @qrGenerateSuccess.
  ///
  /// In en, this message translates to:
  /// **'PDF generated and downloaded successfully'**
  String get qrGenerateSuccess;

  /// No description provided for @settingsScannerHeader.
  ///
  /// In en, this message translates to:
  /// **'Scanner Settings'**
  String get settingsScannerHeader;

  /// No description provided for @settingsPrecisionScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Precision Scan Window'**
  String get settingsPrecisionScanTitle;

  /// No description provided for @settingsPrecisionScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only scan codes aligned in the viewfinder center'**
  String get settingsPrecisionScanSubtitle;

  /// No description provided for @settingsTapToScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to Scan'**
  String get settingsTapToScanTitle;

  /// No description provided for @settingsTapToScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap on a detected QR code box to scan it'**
  String get settingsTapToScanSubtitle;

  /// No description provided for @qrConfirmAssignTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Not Placed'**
  String get qrConfirmAssignTitle;

  /// No description provided for @qrConfirmAssignMessage.
  ///
  /// In en, this message translates to:
  /// **'Product {product} is not assigned to Room {room}. Add 1 piece to inventory and assign it to the room?'**
  String qrConfirmAssignMessage(String product, String room);

  /// No description provided for @qrAssignSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product assigned and refilled successfully'**
  String get qrAssignSuccess;

  /// No description provided for @qrActionCanceled.
  ///
  /// In en, this message translates to:
  /// **'Operation Canceled'**
  String get qrActionCanceled;

  /// No description provided for @qrActionCanceledMessage.
  ///
  /// In en, this message translates to:
  /// **'You chose not to assign the product. You can scan another code or return to rooms.'**
  String get qrActionCanceledMessage;

  /// No description provided for @scanAssignTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Product to Room'**
  String get scanAssignTitle;

  /// No description provided for @scanAssignSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product Assigned Successfully'**
  String get scanAssignSuccess;

  /// No description provided for @scanAssignFailed.
  ///
  /// In en, this message translates to:
  /// **'Assignment Failed'**
  String get scanAssignFailed;

  /// No description provided for @scanAssignInStock.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock — will deduct 1 and assign to room'**
  String scanAssignInStock(String count);

  /// No description provided for @scanAssignOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock — 1 unit will be auto-added to inventory then assigned'**
  String get scanAssignOutOfStock;

  /// No description provided for @scanAssignDescription.
  ///
  /// In en, this message translates to:
  /// **'This product is not yet assigned to this room. Tap below to assign it.'**
  String get scanAssignDescription;

  /// No description provided for @scanAssignButton.
  ///
  /// In en, this message translates to:
  /// **'Assign to Room'**
  String get scanAssignButton;

  /// No description provided for @scanAssignAutoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to Inventory & Assign'**
  String get scanAssignAutoAdd;

  /// No description provided for @scanAssignAutoAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to Inventory?'**
  String get scanAssignAutoAddTitle;

  /// No description provided for @scanAssignAutoAddMessage.
  ///
  /// In en, this message translates to:
  /// **'Product \"{product}\" is out of stock. Would you like to automatically add 1 unit to inventory and assign it to this room?'**
  String scanAssignAutoAddMessage(String product);

  /// No description provided for @scanAssignConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, add & assign'**
  String get scanAssignConfirm;

  /// No description provided for @scanAssignSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Product {product} has been assigned to Room {room} (Floor {floor}).'**
  String scanAssignSuccessMessage(String product, String room, String floor);

  /// No description provided for @qrMultipleDetected.
  ///
  /// In en, this message translates to:
  /// **'Multiple QR codes detected. Tap to select:'**
  String get qrMultipleDetected;

  /// No description provided for @qrUnknownSku.
  ///
  /// In en, this message translates to:
  /// **'SKU \"{sku}\" does not match any known product.'**
  String qrUnknownSku(String sku);

  /// No description provided for @goToRoom.
  ///
  /// In en, this message translates to:
  /// **'Go to Room'**
  String get goToRoom;

  /// No description provided for @errorLoadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Error loading products'**
  String get errorLoadingProducts;

  /// No description provided for @errorLoadingInventory.
  ///
  /// In en, this message translates to:
  /// **'Error loading inventory'**
  String get errorLoadingInventory;

  /// No description provided for @qrGenAllRoomProducts.
  ///
  /// In en, this message translates to:
  /// **'All products in the selected room'**
  String get qrGenAllRoomProducts;

  /// No description provided for @qrGenAllInventoryProducts.
  ///
  /// In en, this message translates to:
  /// **'All products in the inventory'**
  String get qrGenAllInventoryProducts;

  /// No description provided for @qrLabelScanInstructions.
  ///
  /// In en, this message translates to:
  /// **'Scan with IVRA app to refill or replace'**
  String get qrLabelScanInstructions;

  /// No description provided for @roomsSearchProductPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search product by name or SKU...'**
  String get roomsSearchProductPlaceholder;

  /// No description provided for @adjustStockForProduct.
  ///
  /// In en, this message translates to:
  /// **'Adjust Stock for {product}'**
  String adjustStockForProduct(String product);

  /// No description provided for @roomsBtnRequestCorrection.
  ///
  /// In en, this message translates to:
  /// **'Request correction'**
  String get roomsBtnRequestCorrection;

  /// No description provided for @roomsLabelReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get roomsLabelReason;

  /// No description provided for @roomsMsgCorrectionQueued.
  ///
  /// In en, this message translates to:
  /// **'Correction request queued'**
  String get roomsMsgCorrectionQueued;

  /// No description provided for @roomsMsgCorrectionSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Correction request submitted'**
  String get roomsMsgCorrectionSubmitted;

  /// No description provided for @roomsBtnCreateRooms.
  ///
  /// In en, this message translates to:
  /// **'Create rooms'**
  String get roomsBtnCreateRooms;

  /// No description provided for @roomsLabelProductsInRoom.
  ///
  /// In en, this message translates to:
  /// **'Products in each room'**
  String get roomsLabelProductsInRoom;

  /// No description provided for @roomsMsgSelectOneProduct.
  ///
  /// In en, this message translates to:
  /// **'Select at least one product'**
  String get roomsMsgSelectOneProduct;

  /// No description provided for @roomsMsgDuplicateRoomNumbers.
  ///
  /// In en, this message translates to:
  /// **'These room numbers already exist in this hotel: {numbers}. Choose a different starting number or count.'**
  String roomsMsgDuplicateRoomNumbers(String numbers);

  /// No description provided for @productsCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Catalog'**
  String get productsCatalogTitle;

  /// No description provided for @productsBtnCreate.
  ///
  /// In en, this message translates to:
  /// **'Create product'**
  String get productsBtnCreate;

  /// No description provided for @productsNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products in the catalog yet.'**
  String get productsNoProducts;

  /// No description provided for @productsLabelBottleVolume.
  ///
  /// In en, this message translates to:
  /// **'Bottle volume'**
  String get productsLabelBottleVolume;

  /// No description provided for @productsLabelBidonVolume.
  ///
  /// In en, this message translates to:
  /// **'Refill bottle volume'**
  String get productsLabelBidonVolume;

  /// No description provided for @productsLabelMaxRefill.
  ///
  /// In en, this message translates to:
  /// **'Max refill limit'**
  String get productsLabelMaxRefill;

  /// No description provided for @productsLabelMaxAge.
  ///
  /// In en, this message translates to:
  /// **'Max bottle age'**
  String get productsLabelMaxAge;

  /// No description provided for @productsLabelLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock alert'**
  String get productsLabelLowStock;

  /// No description provided for @productsBtnEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get productsBtnEdit;

  /// No description provided for @productsLabelSku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get productsLabelSku;

  /// No description provided for @productsLabelNameEn.
  ///
  /// In en, this message translates to:
  /// **'Name English'**
  String get productsLabelNameEn;

  /// No description provided for @productsLabelNameFr.
  ///
  /// In en, this message translates to:
  /// **'Name French'**
  String get productsLabelNameFr;

  /// No description provided for @productsLabelNameAr.
  ///
  /// In en, this message translates to:
  /// **'Name Arabic'**
  String get productsLabelNameAr;

  /// No description provided for @productsLabelNameIt.
  ///
  /// In en, this message translates to:
  /// **'Name Italian'**
  String get productsLabelNameIt;

  /// No description provided for @productsLabelImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Picture'**
  String get productsLabelImage;

  /// No description provided for @productsLabelImageHint.
  ///
  /// In en, this message translates to:
  /// **'Select an image from your device'**
  String get productsLabelImageHint;

  /// No description provided for @productsImageSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {name}'**
  String productsImageSelected(String name);

  /// No description provided for @productsImageSet.
  ///
  /// In en, this message translates to:
  /// **'Image is set (tap to change)'**
  String get productsImageSet;

  /// No description provided for @productsImageNone.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get productsImageNone;

  /// No description provided for @productsImageRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get productsImageRemove;

  /// No description provided for @productsImageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed. Please try again.'**
  String get productsImageUploadFailed;

  /// No description provided for @productsImageInvalidType.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid image file.'**
  String get productsImageInvalidType;

  /// No description provided for @productsImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is too large (max {max} MB).'**
  String productsImageTooLarge(String max);

  /// No description provided for @productsAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully'**
  String get productsAddedSuccess;

  /// No description provided for @productsUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully'**
  String get productsUpdatedSuccess;

  /// No description provided for @productsLabelBottleMl.
  ///
  /// In en, this message translates to:
  /// **'Bottle ml'**
  String get productsLabelBottleMl;

  /// No description provided for @productsLabelBidonMl.
  ///
  /// In en, this message translates to:
  /// **'Refill bottle ml'**
  String get productsLabelBidonMl;

  /// No description provided for @productsLabelMaxRefills.
  ///
  /// In en, this message translates to:
  /// **'Max refills'**
  String get productsLabelMaxRefills;

  /// No description provided for @productsLabelMaxAgeDays.
  ///
  /// In en, this message translates to:
  /// **'Max age days'**
  String get productsLabelMaxAgeDays;

  /// No description provided for @productsLabelLowBottles.
  ///
  /// In en, this message translates to:
  /// **'Low bottles'**
  String get productsLabelLowBottles;

  /// No description provided for @productsLabelLowBidons.
  ///
  /// In en, this message translates to:
  /// **'Low refill bottles'**
  String get productsLabelLowBidons;

  /// No description provided for @productsLabelBottleType.
  ///
  /// In en, this message translates to:
  /// **'Bottle Type'**
  String get productsLabelBottleType;

  /// No description provided for @productsLabelBottleWithPump.
  ///
  /// In en, this message translates to:
  /// **'Bottle with pump'**
  String get productsLabelBottleWithPump;

  /// No description provided for @productsLabelBottleWithoutPump.
  ///
  /// In en, this message translates to:
  /// **'Bottle without pump'**
  String get productsLabelBottleWithoutPump;

  /// No description provided for @productsLabelRefillType.
  ///
  /// In en, this message translates to:
  /// **'Refill Type'**
  String get productsLabelRefillType;

  /// No description provided for @productsLabelRefillable.
  ///
  /// In en, this message translates to:
  /// **'Refillable'**
  String get productsLabelRefillable;

  /// No description provided for @productsLabelDirectReplacement.
  ///
  /// In en, this message translates to:
  /// **'Direct replacement'**
  String get productsLabelDirectReplacement;

  /// No description provided for @productsDialogCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create product'**
  String get productsDialogCreateTitle;

  /// No description provided for @productsDialogEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get productsDialogEditTitle;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @refills.
  ///
  /// In en, this message translates to:
  /// **'refills'**
  String get refills;

  /// No description provided for @inventoryNoHotels.
  ///
  /// In en, this message translates to:
  /// **'No Hotels Found'**
  String get inventoryNoHotels;

  /// No description provided for @inventoryAddHotelHint.
  ///
  /// In en, this message translates to:
  /// **'Add a hotel to get started.'**
  String get inventoryAddHotelHint;

  /// No description provided for @inventoryNoItemsToAdjust.
  ///
  /// In en, this message translates to:
  /// **'No store stock items available to adjust.'**
  String get inventoryNoItemsToAdjust;

  /// No description provided for @inventoryNoInventoryYet.
  ///
  /// In en, this message translates to:
  /// **'No store stock yet'**
  String get inventoryNoInventoryYet;

  /// No description provided for @inventoryNoProductsInInventory.
  ///
  /// In en, this message translates to:
  /// **'There are no products in the store stock.'**
  String get inventoryNoProductsInInventory;

  /// No description provided for @inventoryNoSuggestedOrders.
  ///
  /// In en, this message translates to:
  /// **'No suggested orders'**
  String get inventoryNoSuggestedOrders;

  /// No description provided for @inventoryLevelsSufficient.
  ///
  /// In en, this message translates to:
  /// **'Your store stock levels are currently sufficient.'**
  String get inventoryLevelsSufficient;

  /// No description provided for @teamAccounts.
  ///
  /// In en, this message translates to:
  /// **'Team accounts'**
  String get teamAccounts;

  /// No description provided for @teamNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No team members found.'**
  String get teamNoMembers;

  /// No description provided for @teamTableColumnName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get teamTableColumnName;

  /// No description provided for @teamTableColumnEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get teamTableColumnEmail;

  /// No description provided for @teamTableColumnRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get teamTableColumnRole;

  /// No description provided for @teamTableColumnHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get teamTableColumnHotel;

  /// No description provided for @teamTableColumnStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get teamTableColumnStatus;

  /// No description provided for @teamTableColumnActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get teamTableColumnActions;

  /// No description provided for @teamPendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'Pending invitations'**
  String get teamPendingInvitations;

  /// No description provided for @teamNoPendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'No pending invitations.'**
  String get teamNoPendingInvitations;

  /// No description provided for @teamInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite team member'**
  String get teamInviteTitle;

  /// No description provided for @teamLabelFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get teamLabelFullName;

  /// No description provided for @settingsOfflineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get settingsOfflineMode;

  /// No description provided for @settingsOfflineQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue actions'**
  String get settingsOfflineQueue;

  /// No description provided for @settingsOfflineSend.
  ///
  /// In en, this message translates to:
  /// **'Send actions'**
  String get settingsOfflineSend;

  /// No description provided for @settingsBiometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get settingsBiometricTitle;

  /// No description provided for @settingsBiometricHint.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint or face to sign in.'**
  String get settingsBiometricHint;

  /// No description provided for @settingsBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock is not available on this device.'**
  String get settingsBiometricUnavailable;

  /// No description provided for @authBtnBiometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric login'**
  String get authBtnBiometricLogin;

  /// No description provided for @authBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to access Ivra'**
  String get authBiometricReason;

  /// No description provided for @authBiometricNeedsLogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign in once to enable biometric login.'**
  String get authBiometricNeedsLogin;

  /// No description provided for @authBiometricOfflineNoSession.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Connect to the internet to sign in.'**
  String get authBiometricOfflineNoSession;

  /// No description provided for @authBiometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed.'**
  String get authBiometricFailed;

  /// No description provided for @settingsBtnClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsBtnClear;

  /// No description provided for @settingsBtnSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get settingsBtnSyncNow;

  /// No description provided for @settingsNoPendingActions.
  ///
  /// In en, this message translates to:
  /// **'No pending actions.'**
  String get settingsNoPendingActions;

  /// No description provided for @teamManageHotels.
  ///
  /// In en, this message translates to:
  /// **'Manage hotels'**
  String get teamManageHotels;

  /// No description provided for @teamAssignHotelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign hotels'**
  String get teamAssignHotelsTitle;

  /// No description provided for @teamNoHotelsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No hotels assigned'**
  String get teamNoHotelsAssigned;

  /// No description provided for @teamHotelsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Hotel assignments updated'**
  String get teamHotelsUpdated;

  /// No description provided for @teamSelectHotels.
  ///
  /// In en, this message translates to:
  /// **'Select hotels'**
  String get teamSelectHotels;

  /// No description provided for @teamHotelsAssigned.
  ///
  /// In en, this message translates to:
  /// **'hotels assigned'**
  String get teamHotelsAssigned;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get accountProfile;

  /// No description provided for @accountProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get accountProfileUpdated;

  /// No description provided for @accountPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountPassword;

  /// No description provided for @accountPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get accountPasswordUpdated;

  /// No description provided for @accountFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get accountFullName;

  /// No description provided for @accountFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get accountFullNameRequired;

  /// No description provided for @accountNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get accountNewPassword;

  /// No description provided for @accountConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get accountConfirmPassword;

  /// No description provided for @accountPasswordHintSupabase.
  ///
  /// In en, this message translates to:
  /// **'Updates your account login password.'**
  String get accountPasswordHintSupabase;

  /// No description provided for @accountPasswordHintDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo mode accepts the change locally.'**
  String get accountPasswordHintDemo;

  /// No description provided for @accountSignOutHint.
  ///
  /// In en, this message translates to:
  /// **'End the current session on this device.'**
  String get accountSignOutHint;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmail;

  /// No description provided for @accountRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get accountRole;

  /// No description provided for @accountScope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get accountScope;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get accountStatus;

  /// No description provided for @accountActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accountActive;

  /// No description provided for @accountInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get accountInactive;

  /// No description provided for @accountIvraGlobal.
  ///
  /// In en, this message translates to:
  /// **'Ivra global'**
  String get accountIvraGlobal;

  /// No description provided for @accountTeamAccounts.
  ///
  /// In en, this message translates to:
  /// **'Team accounts'**
  String get accountTeamAccounts;

  /// No description provided for @accountNoOtherAccounts.
  ///
  /// In en, this message translates to:
  /// **'No other accounts found.'**
  String get accountNoOtherAccounts;

  /// No description provided for @accountYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get accountYou;

  /// No description provided for @alertsRefreshSmart.
  ///
  /// In en, this message translates to:
  /// **'Refresh smart alerts'**
  String get alertsRefreshSmart;

  /// No description provided for @alertsResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get alertsResolve;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @approvalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending approvals'**
  String get approvalsEmpty;

  /// No description provided for @approvalsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'All approval requests have been processed.'**
  String get approvalsEmptySubtitle;

  /// No description provided for @approvalsApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approvalsApprove;

  /// No description provided for @approvalsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get approvalsReject;

  /// No description provided for @approvalsActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed. Please try again.'**
  String get approvalsActionFailed;

  /// No description provided for @approvalsApproved.
  ///
  /// In en, this message translates to:
  /// **'Request approved.'**
  String get approvalsApproved;

  /// No description provided for @approvalsRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected.'**
  String get approvalsRejected;

  /// No description provided for @approvalsApproveQueued.
  ///
  /// In en, this message translates to:
  /// **'Approval queued for sync.'**
  String get approvalsApproveQueued;

  /// No description provided for @approvalsRejectQueued.
  ///
  /// In en, this message translates to:
  /// **'Rejection queued for sync.'**
  String get approvalsRejectQueued;

  /// No description provided for @approvalsAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied. Only admins can review approvals.'**
  String get approvalsAccessDenied;

  /// No description provided for @approvalsRequestNotFound.
  ///
  /// In en, this message translates to:
  /// **'Approval request not found or already processed.'**
  String get approvalsRequestNotFound;

  /// No description provided for @inviteAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept invitation'**
  String get inviteAcceptTitle;

  /// No description provided for @inviteAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get inviteAlreadyHaveAccount;

  /// No description provided for @inviteBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get inviteBackToSignIn;

  /// No description provided for @inviteEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get inviteEmail;

  /// No description provided for @invitePassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get invitePassword;

  /// No description provided for @inviteConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get inviteConfirmPassword;

  /// No description provided for @settingsRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry action'**
  String get settingsRetryAction;

  /// No description provided for @settingsRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove action'**
  String get settingsRemoveAction;

  /// No description provided for @settingsActionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Queued action updated'**
  String get settingsActionUpdated;

  /// No description provided for @settingsActionRemoved.
  ///
  /// In en, this message translates to:
  /// **'Offline action removed'**
  String get settingsActionRemoved;

  /// No description provided for @settingsQueueCleared.
  ///
  /// In en, this message translates to:
  /// **'Offline queue cleared'**
  String get settingsQueueCleared;

  /// No description provided for @settingsTestAccessAs.
  ///
  /// In en, this message translates to:
  /// **'Test access as'**
  String get settingsTestAccessAs;

  /// No description provided for @settingsDemoUserChanged.
  ///
  /// In en, this message translates to:
  /// **'Demo user changed'**
  String get settingsDemoUserChanged;

  /// No description provided for @settingsPayloadJson.
  ///
  /// In en, this message translates to:
  /// **'Queued payload JSON'**
  String get settingsPayloadJson;

  /// No description provided for @settingsSaveAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Save and retry'**
  String get settingsSaveAndRetry;

  /// No description provided for @settingsDemoUser.
  ///
  /// In en, this message translates to:
  /// **'Demo user'**
  String get settingsDemoUser;

  /// No description provided for @settingsSupabaseConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get settingsSupabaseConnected;

  /// No description provided for @settingsSupabaseHint.
  ///
  /// In en, this message translates to:
  /// **'The app is using live data.'**
  String get settingsSupabaseHint;

  /// No description provided for @settingsNoSupabaseHint.
  ///
  /// In en, this message translates to:
  /// **'Server connection is not configured.'**
  String get settingsNoSupabaseHint;

  /// No description provided for @settingsEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit queued action'**
  String get settingsEditAction;

  /// No description provided for @settingsResolveConflict.
  ///
  /// In en, this message translates to:
  /// **'Resolve sync conflict'**
  String get settingsResolveConflict;

  /// No description provided for @settingsActionSynced.
  ///
  /// In en, this message translates to:
  /// **'Action synced'**
  String get settingsActionSynced;

  /// No description provided for @offlineBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get offlineBannerTitle;

  /// No description provided for @offlineBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Data may not be up to date'**
  String get offlineBannerSubtitle;

  /// No description provided for @offlineBannerPending.
  ///
  /// In en, this message translates to:
  /// **'pending actions'**
  String get offlineBannerPending;

  /// No description provided for @offlineBannerSyncBtn.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get offlineBannerSyncBtn;

  /// No description provided for @offlineBannerAutoSynced.
  ///
  /// In en, this message translates to:
  /// **'Back online! Synced {count} actions'**
  String offlineBannerAutoSynced(String count);

  /// No description provided for @offlineBannerSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed for some actions'**
  String get offlineBannerSyncFailed;

  /// No description provided for @teamInvitationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Invitation cancelled for {email}'**
  String teamInvitationCancelled(String email);

  /// No description provided for @teamInvitationResent.
  ///
  /// In en, this message translates to:
  /// **'Invitation resent to {email}'**
  String teamInvitationResent(String email);

  /// No description provided for @teamInvitationCopied.
  ///
  /// In en, this message translates to:
  /// **'Invitation link copied for {email}'**
  String teamInvitationCopied(String email);

  /// No description provided for @approvalsRequestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested by {name}'**
  String approvalsRequestedBy(String name);

  /// No description provided for @approvalsOldValue.
  ///
  /// In en, this message translates to:
  /// **'Old: {value}'**
  String approvalsOldValue(String value);

  /// No description provided for @approvalsNewValue.
  ///
  /// In en, this message translates to:
  /// **'New: {value}'**
  String approvalsNewValue(String value);

  /// No description provided for @alertsSeverityLabel.
  ///
  /// In en, this message translates to:
  /// **'Severity {severity}'**
  String alertsSeverityLabel(String severity);

  /// No description provided for @alertsStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get alertsStatusResolved;

  /// No description provided for @alertsStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get alertsStatusOpen;

  /// No description provided for @alertsMetricCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get alertsMetricCritical;

  /// No description provided for @alertsFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get alertsFilterTitle;

  /// No description provided for @alertsFilterSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get alertsFilterSeverity;

  /// No description provided for @alertsFilterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get alertsFilterType;

  /// No description provided for @alertsFilterHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get alertsFilterHotel;

  /// No description provided for @alertsFilterProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get alertsFilterProduct;

  /// No description provided for @alertsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get alertsFilterAll;

  /// No description provided for @alertsFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get alertsFilterClear;

  /// No description provided for @alertsFilterNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No alerts match the current filters.'**
  String get alertsFilterNoMatch;

  /// No description provided for @alertsFilterShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing {count} of {total}'**
  String alertsFilterShowing(String count, String total);

  /// No description provided for @settingsActionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit queued action'**
  String get settingsActionEditTitle;

  /// No description provided for @settingsActionConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolve sync conflict'**
  String get settingsActionConflictTitle;

  /// No description provided for @settingsActionAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts {count}'**
  String settingsActionAttempts(String count);

  /// No description provided for @settingsActionListAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts: {count}'**
  String settingsActionListAttempts(String count);

  /// No description provided for @settingsActionListError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String settingsActionListError(String message);

  /// No description provided for @syncActionRefill.
  ///
  /// In en, this message translates to:
  /// **'Refill'**
  String get syncActionRefill;

  /// No description provided for @syncActionUndoRefill.
  ///
  /// In en, this message translates to:
  /// **'Undo refill'**
  String get syncActionUndoRefill;

  /// No description provided for @syncActionCorrectionRequest.
  ///
  /// In en, this message translates to:
  /// **'Correction request'**
  String get syncActionCorrectionRequest;

  /// No description provided for @syncActionBottleReplacement.
  ///
  /// In en, this message translates to:
  /// **'Bottle replacement'**
  String get syncActionBottleReplacement;

  /// No description provided for @syncActionStockAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Stock adjustment'**
  String get syncActionStockAdjustment;

  /// No description provided for @syncActionPendingEdit.
  ///
  /// In en, this message translates to:
  /// **'Pending edit'**
  String get syncActionPendingEdit;

  /// No description provided for @userRoleAppAdmin.
  ///
  /// In en, this message translates to:
  /// **'App admin'**
  String get userRoleAppAdmin;

  /// No description provided for @userRoleAppManager.
  ///
  /// In en, this message translates to:
  /// **'App manager'**
  String get userRoleAppManager;

  /// No description provided for @userRoleHotelManager.
  ///
  /// In en, this message translates to:
  /// **'Hotel manager'**
  String get userRoleHotelManager;

  /// No description provided for @userRoleHotelStaff.
  ///
  /// In en, this message translates to:
  /// **'Hotel staff'**
  String get userRoleHotelStaff;

  /// No description provided for @teamStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get teamStatusActive;

  /// No description provided for @teamStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get teamStatusInactive;

  /// No description provided for @teamHotelAll.
  ///
  /// In en, this message translates to:
  /// **'All hotels'**
  String get teamHotelAll;

  /// No description provided for @teamHotelNone.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get teamHotelNone;

  /// No description provided for @invitationStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get invitationStatusPending;

  /// No description provided for @invitationStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get invitationStatusAccepted;

  /// No description provided for @invitationStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get invitationStatusCancelled;

  /// No description provided for @invitationStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get invitationStatusExpired;

  /// No description provided for @alertResolvedToast.
  ///
  /// In en, this message translates to:
  /// **'Alert resolved'**
  String get alertResolvedToast;

  /// No description provided for @alertDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Alert deleted'**
  String get alertDeletedToast;

  /// No description provided for @alertResolveFailedToast.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve the alert. Please try again.'**
  String get alertResolveFailedToast;

  /// No description provided for @alertDeleteFailedToast.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the alert. Please try again.'**
  String get alertDeleteFailedToast;

  /// No description provided for @notificationAcknowledgedToast.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get notificationAcknowledgedToast;

  /// No description provided for @notificationMoreInfo.
  ///
  /// In en, this message translates to:
  /// **'More info'**
  String get notificationMoreInfo;

  /// No description provided for @bulkAdjustStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk stock adjustment'**
  String get bulkAdjustStockTitle;

  /// No description provided for @bulkAdjustStockHint.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity adjustments that will apply to ALL products.'**
  String get bulkAdjustStockHint;

  /// No description provided for @bulkAdjustStockSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bulk stock adjustment successfully applied'**
  String get bulkAdjustStockSuccess;

  /// No description provided for @bulkAdjustStockOfflineQueued.
  ///
  /// In en, this message translates to:
  /// **'Bulk adjustments queued for offline sync'**
  String get bulkAdjustStockOfflineQueued;

  /// No description provided for @resolveAll.
  ///
  /// In en, this message translates to:
  /// **'Resolve all'**
  String get resolveAll;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @alertsRefreshedToast.
  ///
  /// In en, this message translates to:
  /// **'{count} smart alerts created'**
  String alertsRefreshedToast(String count);

  /// No description provided for @alertsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet'**
  String get alertsEmptyTitle;

  /// No description provided for @alertsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Refresh smart alerts to scan stock, refill limits, bottle age, and pending approvals.'**
  String get alertsEmptyMessage;

  /// No description provided for @alertsEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh alerts'**
  String get alertsEmptyAction;

  /// No description provided for @alertTypeLowBidonStock.
  ///
  /// In en, this message translates to:
  /// **'Low refill bottle stock'**
  String get alertTypeLowBidonStock;

  /// No description provided for @alertLowBottleTitle.
  ///
  /// In en, this message translates to:
  /// **'Low {product} bottle stock'**
  String alertLowBottleTitle(String product);

  /// No description provided for @alertLowBidonTitle.
  ///
  /// In en, this message translates to:
  /// **'Low {product} refill bottle stock'**
  String alertLowBidonTitle(String product);

  /// No description provided for @alertLowBottleBody.
  ///
  /// In en, this message translates to:
  /// **'{hotel}: {remain} full bottles remain. Threshold is {threshold}.'**
  String alertLowBottleBody(String hotel, String remain, String threshold);

  /// No description provided for @alertLowBidonBody.
  ///
  /// In en, this message translates to:
  /// **'{hotel}: {remain} full refill bottles remain. Threshold is {threshold}.'**
  String alertLowBidonBody(String hotel, String remain, String threshold);

  /// No description provided for @alertTypeLowBottleStock.
  ///
  /// In en, this message translates to:
  /// **'Low bottles'**
  String get alertTypeLowBottleStock;

  /// No description provided for @alertTypeBottleAgeLimit.
  ///
  /// In en, this message translates to:
  /// **'Bottle age'**
  String get alertTypeBottleAgeLimit;

  /// No description provided for @alertBottleAgeLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Room {room} {product} bottle is too old'**
  String alertBottleAgeLimitTitle(String room, String product);

  /// No description provided for @alertBottleAgeLimitBody.
  ///
  /// In en, this message translates to:
  /// **'Bottle age is {age} days. Limit is {limit} days.'**
  String alertBottleAgeLimitBody(String age, String limit);

  /// No description provided for @alertTypeRefillLimit.
  ///
  /// In en, this message translates to:
  /// **'Refill limit'**
  String get alertTypeRefillLimit;

  /// No description provided for @alertRefillLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Room {room} {product} reached refill limit'**
  String alertRefillLimitTitle(String room, String product);

  /// No description provided for @alertRefillLimitBody.
  ///
  /// In en, this message translates to:
  /// **'{used}/{max} refills used. Replace and recycle the bottle.'**
  String alertRefillLimitBody(String used, String max);

  /// No description provided for @alertTypePendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get alertTypePendingApproval;

  /// No description provided for @alertPendingApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending approval: {request}'**
  String alertPendingApprovalTitle(String request);

  /// No description provided for @alertPendingApprovalBody.
  ///
  /// In en, this message translates to:
  /// **'Requested by {name}.'**
  String alertPendingApprovalBody(String name);

  /// No description provided for @alertTypeSuspiciousActivity.
  ///
  /// In en, this message translates to:
  /// **'Suspicious activity'**
  String get alertTypeSuspiciousActivity;

  /// No description provided for @alertTypeInactiveHotel.
  ///
  /// In en, this message translates to:
  /// **'Inactive hotel'**
  String get alertTypeInactiveHotel;

  /// No description provided for @refillEventApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get refillEventApproved;

  /// No description provided for @refillEventRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get refillEventRejected;

  /// No description provided for @teamDeactivateAccountTooltip.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account'**
  String get teamDeactivateAccountTooltip;

  /// No description provided for @teamReactivateAccountTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reactivate account'**
  String get teamReactivateAccountTooltip;

  /// No description provided for @settingsSyncedSummary.
  ///
  /// In en, this message translates to:
  /// **'Synced {synced} actions'**
  String settingsSyncedSummary(String synced);

  /// No description provided for @settingsSyncedSummarySingular.
  ///
  /// In en, this message translates to:
  /// **'Synced {synced} action'**
  String settingsSyncedSummarySingular(String synced);

  /// No description provided for @settingsSyncedWithFailures.
  ///
  /// In en, this message translates to:
  /// **'Synced {synced}, {failed} failed'**
  String settingsSyncedWithFailures(String synced, String failed);

  /// No description provided for @inviteAcceptHeading.
  ///
  /// In en, this message translates to:
  /// **'Accept Ivra invitation'**
  String get inviteAcceptHeading;

  /// No description provided for @inviteSubtitleWithHotel.
  ///
  /// In en, this message translates to:
  /// **'{name} was invited as {role} for {hotel}.'**
  String inviteSubtitleWithHotel(String name, String role, String hotel);

  /// No description provided for @inviteSubtitleNoHotel.
  ///
  /// In en, this message translates to:
  /// **'{name} was invited as {role}.'**
  String inviteSubtitleNoHotel(String name, String role);

  /// No description provided for @inviteEmailMismatch.
  ///
  /// In en, this message translates to:
  /// **'Use the email address this invitation was sent to.'**
  String get inviteEmailMismatch;

  /// No description provided for @inviteAccountCreatedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Account created. Confirm your email, then return to this invitation link and enter the same password to finish joining.'**
  String get inviteAccountCreatedConfirm;

  /// No description provided for @inviteInvalidHeading.
  ///
  /// In en, this message translates to:
  /// **'Invitation unavailable'**
  String get inviteInvalidHeading;

  /// No description provided for @inviteInvalidBody.
  ///
  /// In en, this message translates to:
  /// **'This invitation may have expired, been cancelled, or already been accepted.'**
  String get inviteInvalidBody;

  /// No description provided for @teamMemberReactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} reactivated'**
  String teamMemberReactivated(String name);

  /// No description provided for @teamMemberDeactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} deactivated'**
  String teamMemberDeactivated(String name);

  /// No description provided for @settingsActionLastTried.
  ///
  /// In en, this message translates to:
  /// **'Last tried {datetime}'**
  String settingsActionLastTried(String datetime);

  /// No description provided for @settingsActionNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Action still needs review'**
  String get settingsActionNeedsReview;

  /// No description provided for @teamInviteLinkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Invitation link is unavailable'**
  String get teamInviteLinkUnavailable;

  /// No description provided for @teamCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy invitation link'**
  String get teamCopyLink;

  /// No description provided for @teamResendInvitation.
  ///
  /// In en, this message translates to:
  /// **'Resend invitation'**
  String get teamResendInvitation;

  /// No description provided for @teamCancelInvitation.
  ///
  /// In en, this message translates to:
  /// **'Cancel invitation'**
  String get teamCancelInvitation;

  /// No description provided for @teamCannotInviteSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot invite yourself'**
  String get teamCannotInviteSelf;

  /// No description provided for @btnUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get btnUpdate;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In en, this message translates to:
  /// **'The page you are looking for does not exist or has been moved.'**
  String get notFoundBody;

  /// No description provided for @notFoundButton.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get notFoundButton;

  /// No description provided for @downloadAppBannerText.
  ///
  /// In en, this message translates to:
  /// **'For the best experience, download our Android App.'**
  String get downloadAppBannerText;

  /// No description provided for @downloadAppBannerButton.
  ///
  /// In en, this message translates to:
  /// **'Download App'**
  String get downloadAppBannerButton;

  /// No description provided for @sendPushTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get sendPushTitle;

  /// No description provided for @teamViewAs.
  ///
  /// In en, this message translates to:
  /// **'View as'**
  String get teamViewAs;

  /// No description provided for @impersonationBanner.
  ///
  /// In en, this message translates to:
  /// **'Viewing as {name}'**
  String impersonationBanner(String name);

  /// No description provided for @impersonationExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get impersonationExit;

  /// No description provided for @pdfHeaderType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get pdfHeaderType;

  /// No description provided for @pdfHeaderPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get pdfHeaderPrevious;

  /// No description provided for @pdfHeaderNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get pdfHeaderNew;

  /// No description provided for @pdfHeaderOccurredAt.
  ///
  /// In en, this message translates to:
  /// **'Occurred at'**
  String get pdfHeaderOccurredAt;

  /// No description provided for @pdfHeaderNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get pdfHeaderNotes;

  /// No description provided for @pdfHeaderProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get pdfHeaderProduct;

  /// No description provided for @pdfHeader1LBottles.
  ///
  /// In en, this message translates to:
  /// **'1L bottles'**
  String get pdfHeader1LBottles;

  /// No description provided for @pdfHeader5LBidons.
  ///
  /// In en, this message translates to:
  /// **'5L refill bottles'**
  String get pdfHeader5LBidons;

  /// No description provided for @pdfHeaderRecycle.
  ///
  /// In en, this message translates to:
  /// **'Recycle'**
  String get pdfHeaderRecycle;

  /// No description provided for @pdfHeaderFullBottles.
  ///
  /// In en, this message translates to:
  /// **'Full bottles'**
  String get pdfHeaderFullBottles;

  /// No description provided for @pdfHeaderEmptyBottles.
  ///
  /// In en, this message translates to:
  /// **'Empty bottles'**
  String get pdfHeaderEmptyBottles;

  /// No description provided for @pdfHeaderFullBidons.
  ///
  /// In en, this message translates to:
  /// **'Full refill bottles'**
  String get pdfHeaderFullBidons;

  /// No description provided for @pdfHeaderOpenBidons.
  ///
  /// In en, this message translates to:
  /// **'Opened refill bottles'**
  String get pdfHeaderOpenBidons;

  /// No description provided for @pdfHeaderEmptyBidons.
  ///
  /// In en, this message translates to:
  /// **'Empty refill bottles'**
  String get pdfHeaderEmptyBidons;

  /// No description provided for @pdfHeaderSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get pdfHeaderSeverity;

  /// No description provided for @pdfHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get pdfHeaderTitle;

  /// No description provided for @pdfHeaderCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get pdfHeaderCreatedAt;

  /// No description provided for @approvalStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvalStatusApproved;

  /// No description provided for @approvalStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get approvalStatusRejected;

  /// No description provided for @approvalStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get approvalStatusCancelled;

  /// No description provided for @approvalStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get approvalStatusPending;

  /// No description provided for @pdfTitleSuggestedOrders.
  ///
  /// In en, this message translates to:
  /// **'Ivra Suggested Orders'**
  String get pdfTitleSuggestedOrders;

  /// No description provided for @pdfTitleInventorySnapshot.
  ///
  /// In en, this message translates to:
  /// **'Ivra Store Stock Snapshot'**
  String get pdfTitleInventorySnapshot;

  /// No description provided for @pdfTitleRefillHistory.
  ///
  /// In en, this message translates to:
  /// **'Ivra Refill History'**
  String get pdfTitleRefillHistory;

  /// No description provided for @pdfTitleOpenAlerts.
  ///
  /// In en, this message translates to:
  /// **'Ivra Open Alerts'**
  String get pdfTitleOpenAlerts;

  /// No description provided for @productHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Product History'**
  String get productHistoryTitle;

  /// No description provided for @productHistoryNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No history recorded for this product.'**
  String get productHistoryNoHistory;

  /// No description provided for @productHistoryRefill.
  ///
  /// In en, this message translates to:
  /// **'Refilled in Room {roomNumber}'**
  String productHistoryRefill(String roomNumber);

  /// No description provided for @productHistoryReplacement.
  ///
  /// In en, this message translates to:
  /// **'Replaced bottle in Room {roomNumber}'**
  String productHistoryReplacement(String roomNumber);

  /// No description provided for @productHistoryAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Manual Stock Adjustment'**
  String get productHistoryAdjustment;

  /// No description provided for @productHistoryActionBy.
  ///
  /// In en, this message translates to:
  /// **'By {user}'**
  String productHistoryActionBy(String user);

  /// No description provided for @productHistoryReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String productHistoryReason(String reason);

  /// No description provided for @productHistoryDeltaFullBottles.
  ///
  /// In en, this message translates to:
  /// **'Full bottles'**
  String get productHistoryDeltaFullBottles;

  /// No description provided for @productHistoryDeltaUsedBottles.
  ///
  /// In en, this message translates to:
  /// **'Used bottles'**
  String get productHistoryDeltaUsedBottles;

  /// No description provided for @productHistoryDeltaFullBidons.
  ///
  /// In en, this message translates to:
  /// **'Full refill bottles'**
  String get productHistoryDeltaFullBidons;

  /// No description provided for @productHistoryDeltaOpenBidons.
  ///
  /// In en, this message translates to:
  /// **'Opened refill bottles'**
  String get productHistoryDeltaOpenBidons;

  /// No description provided for @productHistoryDeltaEmptyBidons.
  ///
  /// In en, this message translates to:
  /// **'Empty refill bottles'**
  String get productHistoryDeltaEmptyBidons;

  /// No description provided for @productHistoryNewBottle.
  ///
  /// In en, this message translates to:
  /// **'New bottle placed in Room {roomNumber}'**
  String productHistoryNewBottle(String roomNumber);

  /// No description provided for @productHistoryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get productHistoryFilterAll;

  /// No description provided for @productHistoryFilterRoom.
  ///
  /// In en, this message translates to:
  /// **'Room Events'**
  String get productHistoryFilterRoom;

  /// No description provided for @productHistoryFilterManual.
  ///
  /// In en, this message translates to:
  /// **'Adjustments'**
  String get productHistoryFilterManual;

  /// No description provided for @productHistoryStatRefills.
  ///
  /// In en, this message translates to:
  /// **'Refills'**
  String get productHistoryStatRefills;

  /// No description provided for @productHistoryStatReplacements.
  ///
  /// In en, this message translates to:
  /// **'Replacements'**
  String get productHistoryStatReplacements;

  /// No description provided for @productHistoryStatAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Adjustments'**
  String get productHistoryStatAdjustments;

  /// No description provided for @inventoryEnforceTitle.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Stock'**
  String get inventoryEnforceTitle;

  /// No description provided for @inventoryEnforceTemplateContent.
  ///
  /// In en, this message translates to:
  /// **'Placing {total} bottle(s) of {product} requires stock. Store Stock only has {current}. Would you like to automatically add {needed} bottle(s) to the store stock and proceed?'**
  String inventoryEnforceTemplateContent(
      String total, String product, String current, String needed);

  /// No description provided for @inventoryEnforceReplaceContent.
  ///
  /// In en, this message translates to:
  /// **'Replacing the bottle of {product} in Room {room} requires 1 full bottle. Store Stock has 0. Would you like to automatically add 1 bottle to the store stock and proceed?'**
  String inventoryEnforceReplaceContent(String product, String room);

  /// No description provided for @housekeeperReplaceGetFromHotel.
  ///
  /// In en, this message translates to:
  /// **'Replacing {product} in Room {room} requires 1 full bottle, but you do not have it in your inventory. However, {count} bottles are available in the hotel inventory. Would you like to take 1 bottle from the hotel inventory and proceed?'**
  String housekeeperReplaceGetFromHotel(
      String product, String room, String count);

  /// No description provided for @housekeeperReplaceNotifyManager.
  ///
  /// In en, this message translates to:
  /// **'Replacing {product} in Room {room} requires 1 full bottle, but you do not have it in your inventory, and it is not available in the hotel inventory either. Please inform the hotel manager.'**
  String housekeeperReplaceNotifyManager(String product, String room);

  /// No description provided for @housekeeperAddGetFromHotel.
  ///
  /// In en, this message translates to:
  /// **'Adding {product} to Room {room} requires 1 full bottle, but you do not have it in your inventory. However, {count} bottles are available in the hotel inventory. Would you like to take 1 bottle from the hotel inventory and proceed?'**
  String housekeeperAddGetFromHotel(String product, String room, String count);

  /// No description provided for @housekeeperAddNotifyManager.
  ///
  /// In en, this message translates to:
  /// **'Adding {product} to Room {room} requires 1 full bottle, but you do not have it in your inventory, and it is not available in the hotel inventory either. Please inform the hotel manager.'**
  String housekeeperAddNotifyManager(String product, String room);

  /// No description provided for @housekeeperRefillGetFromHotel.
  ///
  /// In en, this message translates to:
  /// **'Refilling {product} in Room {room} requires 1 full bidon, but you do not have any open or full bidon in your inventory. However, {count} bidons are available in the hotel inventory. Would you like to take 1 bidon from the hotel inventory and proceed?'**
  String housekeeperRefillGetFromHotel(
      String product, String room, String count);

  /// No description provided for @housekeeperRefillNotifyManager.
  ///
  /// In en, this message translates to:
  /// **'Refilling {product} in Room {room} requires 1 full bidon, but you do not have any open or full bidon in your inventory, and it is not available in the hotel inventory either. Please inform the hotel manager.'**
  String housekeeperRefillNotifyManager(String product, String room);

  /// No description provided for @btnOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get btnOk;

  /// No description provided for @inventoryEnforceBtnProceed.
  ///
  /// In en, this message translates to:
  /// **'Auto-Adjust & Proceed'**
  String get inventoryEnforceBtnProceed;

  /// No description provided for @inventoryEnforceReasonTemplate.
  ///
  /// In en, this message translates to:
  /// **'Auto-adjusted for room creation template'**
  String get inventoryEnforceReasonTemplate;

  /// No description provided for @inventoryEnforceReasonReplace.
  ///
  /// In en, this message translates to:
  /// **'Auto-adjusted for replacement'**
  String get inventoryEnforceReasonReplace;

  /// No description provided for @inventoryEnforceOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Initialize Store Stock'**
  String get inventoryEnforceOnboardingTitle;

  /// No description provided for @inventoryEnforceOnboardingContent.
  ///
  /// In en, this message translates to:
  /// **'Since this is a new hotel, there are no products in the store stock. Would you like to automatically initialize the store stock with {total} bottles to place in the rooms?'**
  String inventoryEnforceOnboardingContent(String total);

  /// No description provided for @authBtnCreateRole.
  ///
  /// In en, this message translates to:
  /// **'Create Role'**
  String get authBtnCreateRole;

  /// No description provided for @authCreateRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Role'**
  String get authCreateRoleTitle;

  /// No description provided for @authRoleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Role Name (lowercase snake_case)'**
  String get authRoleNameLabel;

  /// No description provided for @authRoleNameError.
  ///
  /// In en, this message translates to:
  /// **'Role name must be lowercase snake_case (e.g., night_auditor)'**
  String get authRoleNameError;

  /// No description provided for @authRoleDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Friendly Display Name (e.g., Night Auditor)'**
  String get authRoleDisplayNameLabel;

  /// No description provided for @authRoleDisplayNameError.
  ///
  /// In en, this message translates to:
  /// **'Display name cannot be empty'**
  String get authRoleDisplayNameError;

  /// No description provided for @authRoleDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get authRoleDescLabel;

  /// No description provided for @authCategoryCore.
  ///
  /// In en, this message translates to:
  /// **'Core Operations'**
  String get authCategoryCore;

  /// No description provided for @authCategoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get authCategoryManagement;

  /// No description provided for @authCategoryControl.
  ///
  /// In en, this message translates to:
  /// **'Control & Approvals'**
  String get authCategoryControl;

  /// No description provided for @authCategoryAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Broadcasts'**
  String get authCategoryAnalytics;

  /// No description provided for @authCategorySecurity.
  ///
  /// In en, this message translates to:
  /// **'Security & Administration'**
  String get authCategorySecurity;

  /// No description provided for @authBulkGrantAll.
  ///
  /// In en, this message translates to:
  /// **'Grant All'**
  String get authBulkGrantAll;

  /// No description provided for @authBulkRevokeAll.
  ///
  /// In en, this message translates to:
  /// **'Revoke All'**
  String get authBulkRevokeAll;

  /// No description provided for @authRoleCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Role created successfully.'**
  String get authRoleCreatedSuccess;

  /// No description provided for @authSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search permissions...'**
  String get authSearchHint;

  /// No description provided for @authorizationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Authorizations Matrix'**
  String get authorizationsTitle;

  /// No description provided for @authorizationsHeader.
  ///
  /// In en, this message translates to:
  /// **'Authorizations Matrix'**
  String get authorizationsHeader;

  /// No description provided for @authorizationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage application features and action permissions by user role.'**
  String get authorizationsSubtitle;

  /// No description provided for @authorizationsPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get authorizationsPermission;

  /// No description provided for @authorizationsUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Authorizations updated successfully.'**
  String get authorizationsUpdatedSuccessfully;

  /// No description provided for @roleAppAdmin.
  ///
  /// In en, this message translates to:
  /// **'App Admin'**
  String get roleAppAdmin;

  /// No description provided for @roleAppManager.
  ///
  /// In en, this message translates to:
  /// **'App Manager'**
  String get roleAppManager;

  /// No description provided for @roleHotelManager.
  ///
  /// In en, this message translates to:
  /// **'Hotel Manager'**
  String get roleHotelManager;

  /// No description provided for @roleHotelStaff.
  ///
  /// In en, this message translates to:
  /// **'Hotel Staff'**
  String get roleHotelStaff;

  /// No description provided for @permManageHotels.
  ///
  /// In en, this message translates to:
  /// **'Manage Hotels'**
  String get permManageHotels;

  /// No description provided for @permManageHotelsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create, edit, and delete hotel properties'**
  String get permManageHotelsDesc;

  /// No description provided for @permManageRooms.
  ///
  /// In en, this message translates to:
  /// **'Manage Rooms'**
  String get permManageRooms;

  /// No description provided for @permManageRoomsDesc.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, and remove rooms and floors'**
  String get permManageRoomsDesc;

  /// No description provided for @permManageProducts.
  ///
  /// In en, this message translates to:
  /// **'Manage Products'**
  String get permManageProducts;

  /// No description provided for @permManageProductsDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure global product types and catalogs'**
  String get permManageProductsDesc;

  /// No description provided for @permManageTeam.
  ///
  /// In en, this message translates to:
  /// **'Manage Team'**
  String get permManageTeam;

  /// No description provided for @permManageTeamDesc.
  ///
  /// In en, this message translates to:
  /// **'Invite and manage team members and roles'**
  String get permManageTeamDesc;

  /// No description provided for @permSubmitEditRequests.
  ///
  /// In en, this message translates to:
  /// **'Submit Edit Requests'**
  String get permSubmitEditRequests;

  /// No description provided for @permSubmitEditRequestsDesc.
  ///
  /// In en, this message translates to:
  /// **'Submit room, bottle, and stock modification requests'**
  String get permSubmitEditRequestsDesc;

  /// No description provided for @permApproveCorrections.
  ///
  /// In en, this message translates to:
  /// **'Approve Corrections'**
  String get permApproveCorrections;

  /// No description provided for @permApproveCorrectionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Approve or reject pending change and correction requests'**
  String get permApproveCorrectionsDesc;

  /// No description provided for @permViewApprovals.
  ///
  /// In en, this message translates to:
  /// **'View Approvals'**
  String get permViewApprovals;

  /// No description provided for @permViewApprovalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Access the approvals dashboard screen'**
  String get permViewApprovalsDesc;

  /// No description provided for @permViewAlerts.
  ///
  /// In en, this message translates to:
  /// **'View Alerts'**
  String get permViewAlerts;

  /// No description provided for @permViewAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'View and monitor operation alerts'**
  String get permViewAlertsDesc;

  /// No description provided for @permViewReports.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get permViewReports;

  /// No description provided for @permViewReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Access analytics reports and performance charts'**
  String get permViewReportsDesc;

  /// No description provided for @permSendNotifications.
  ///
  /// In en, this message translates to:
  /// **'Send Push Notifications'**
  String get permSendNotifications;

  /// No description provided for @permSendNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Compose and broadcast app push notifications'**
  String get permSendNotificationsDesc;

  /// No description provided for @permViewAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'View Security Audit Logs'**
  String get permViewAuditLogs;

  /// No description provided for @permViewAuditLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'Inspect detailed operation and login history logs'**
  String get permViewAuditLogsDesc;

  /// No description provided for @permViewRooms.
  ///
  /// In en, this message translates to:
  /// **'View Rooms'**
  String get permViewRooms;

  /// No description provided for @permViewRoomsDesc.
  ///
  /// In en, this message translates to:
  /// **'View room refill status list and details'**
  String get permViewRoomsDesc;

  /// No description provided for @permViewInventory.
  ///
  /// In en, this message translates to:
  /// **'View Inventory'**
  String get permViewInventory;

  /// No description provided for @permViewInventoryDesc.
  ///
  /// In en, this message translates to:
  /// **'View hotel inventory stock status and suggest orders'**
  String get permViewInventoryDesc;

  /// No description provided for @permViewAuthorizations.
  ///
  /// In en, this message translates to:
  /// **'View Authorizations'**
  String get permViewAuthorizations;

  /// No description provided for @permViewAuthorizationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Access and manage role-based permission settings screen'**
  String get permViewAuthorizationsDesc;

  /// No description provided for @dialogRefillTitle.
  ///
  /// In en, this message translates to:
  /// **'Refill Dispenser'**
  String get dialogRefillTitle;

  /// No description provided for @dialogRefillSliderLabel.
  ///
  /// In en, this message translates to:
  /// **'Refill percentage (added volume):'**
  String get dialogRefillSliderLabel;

  /// No description provided for @dialogRefillPreExisting.
  ///
  /// In en, this message translates to:
  /// **'Already Full:'**
  String get dialogRefillPreExisting;

  /// No description provided for @dialogRefillAdded.
  ///
  /// In en, this message translates to:
  /// **'To Add:'**
  String get dialogRefillAdded;

  /// No description provided for @dialogRefillNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get dialogRefillNotes;

  /// No description provided for @dialogRefillConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Refill'**
  String get dialogRefillConfirm;

  /// No description provided for @femmeDeChambre.
  ///
  /// In en, this message translates to:
  /// **'Housekeeper'**
  String get femmeDeChambre;

  /// No description provided for @checkoutStock.
  ///
  /// In en, this message translates to:
  /// **'Checkout Stock'**
  String get checkoutStock;

  /// No description provided for @returnStock.
  ///
  /// In en, this message translates to:
  /// **'Return Stock'**
  String get returnStock;

  /// No description provided for @housekeeperCart.
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get housekeeperCart;

  /// No description provided for @noAllocations.
  ///
  /// In en, this message translates to:
  /// **'No active allocations. Check out stock to start.'**
  String get noAllocations;

  /// No description provided for @fullBottles.
  ///
  /// In en, this message translates to:
  /// **'Full Bottles'**
  String get fullBottles;

  /// No description provided for @openBidonVolumeLeft.
  ///
  /// In en, this message translates to:
  /// **'Remaining Volume'**
  String get openBidonVolumeLeft;

  /// No description provided for @housekeeperStockCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Stock checked out successfully!'**
  String get housekeeperStockCheckedOut;

  /// No description provided for @housekeeperStockReturned.
  ///
  /// In en, this message translates to:
  /// **'Stock returned successfully!'**
  String get housekeeperStockReturned;

  /// No description provided for @housekeeperStockHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get housekeeperStockHistory;

  /// No description provided for @housekeeperStockHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No movements recorded yet for this product.'**
  String get housekeeperStockHistoryEmpty;

  /// No description provided for @stockEventCheckout.
  ///
  /// In en, this message translates to:
  /// **'Taken from hotel inventory'**
  String get stockEventCheckout;

  /// No description provided for @stockEventReturn.
  ///
  /// In en, this message translates to:
  /// **'Returned to hotel inventory'**
  String get stockEventReturn;

  /// No description provided for @stockEventRoomPlacement.
  ///
  /// In en, this message translates to:
  /// **'Placed in room'**
  String get stockEventRoomPlacement;

  /// No description provided for @stockEventRefillUse.
  ///
  /// In en, this message translates to:
  /// **'Used for refill'**
  String get stockEventRefillUse;

  /// No description provided for @stockEventReplaceUse.
  ///
  /// In en, this message translates to:
  /// **'Used for bottle replacement'**
  String get stockEventReplaceUse;

  /// No description provided for @housekeeperHotelStockAvailable.
  ///
  /// In en, this message translates to:
  /// **'Hotel inventory: {bottles} full bottles, {bidons} full bidons available'**
  String housekeeperHotelStockAvailable(String bottles, String bidons);

  /// No description provided for @sourceHousekeeperCart.
  ///
  /// In en, this message translates to:
  /// **'From housekeeper cart'**
  String get sourceHousekeeperCart;

  /// No description provided for @sourceHotelInventory.
  ///
  /// In en, this message translates to:
  /// **'From hotel inventory'**
  String get sourceHotelInventory;

  /// No description provided for @userRoleHousekeeper.
  ///
  /// In en, this message translates to:
  /// **'Housekeeper'**
  String get userRoleHousekeeper;

  /// No description provided for @roomsBtnAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get roomsBtnAddProduct;

  /// No description provided for @roomsConfirmRemoveProduct.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the product \'{productName}\' from room \'{roomNumber}\'?'**
  String roomsConfirmRemoveProduct(String productName, String roomNumber);

  /// No description provided for @roomsProductRemoved.
  ///
  /// In en, this message translates to:
  /// **'Product removed'**
  String get roomsProductRemoved;

  /// No description provided for @roomsProductAdded.
  ///
  /// In en, this message translates to:
  /// **'Product added'**
  String get roomsProductAdded;

  /// No description provided for @roomsAddProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Add product to room'**
  String get roomsAddProductTitle;

  /// No description provided for @roomsSelectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get roomsSelectProduct;

  /// No description provided for @myBasket.
  ///
  /// In en, this message translates to:
  /// **'My Basket'**
  String get myBasket;

  /// No description provided for @housekeepersTitle.
  ///
  /// In en, this message translates to:
  /// **'Housekeepers'**
  String get housekeepersTitle;

  /// No description provided for @allHistory.
  ///
  /// In en, this message translates to:
  /// **'All history'**
  String get allHistory;

  /// No description provided for @changePicture.
  ///
  /// In en, this message translates to:
  /// **'Change picture'**
  String get changePicture;

  /// No description provided for @inviteHousekeeper.
  ///
  /// In en, this message translates to:
  /// **'Invite housekeeper'**
  String get inviteHousekeeper;

  /// No description provided for @removeHousekeeper.
  ///
  /// In en, this message translates to:
  /// **'Remove housekeeper'**
  String get removeHousekeeper;

  /// No description provided for @basketContent.
  ///
  /// In en, this message translates to:
  /// **'Basket content'**
  String get basketContent;

  /// No description provided for @noHousekeepers.
  ///
  /// In en, this message translates to:
  /// **'No housekeepers found'**
  String get noHousekeepers;

  /// No description provided for @btnClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get btnClose;

  /// No description provided for @deleteGeneric.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteGeneric;

  /// No description provided for @teamDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get teamDeactivate;

  /// No description provided for @teamReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get teamReactivate;

  /// No description provided for @event_checkout.
  ///
  /// In en, this message translates to:
  /// **'Stock Checked Out'**
  String get event_checkout;

  /// No description provided for @event_returned.
  ///
  /// In en, this message translates to:
  /// **'Stock Returned'**
  String get event_returned;

  /// No description provided for @event_roomPlacement.
  ///
  /// In en, this message translates to:
  /// **'Placed in Room'**
  String get event_roomPlacement;

  /// No description provided for @event_refillUse.
  ///
  /// In en, this message translates to:
  /// **'Refill Used'**
  String get event_refillUse;

  /// No description provided for @event_replaceUse.
  ///
  /// In en, this message translates to:
  /// **'Bottle Replaced'**
  String get event_replaceUse;

  /// No description provided for @dialogRefillNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. standard refill...'**
  String get dialogRefillNotesHint;

  /// No description provided for @dateFormatHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get dateFormatHint;

  /// No description provided for @errorWithArgs.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithArgs(String error);

  /// No description provided for @teamHotelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{city}, {country}'**
  String teamHotelSubtitle(String city, String country);

  /// No description provided for @productEventTitle.
  ///
  /// In en, this message translates to:
  /// **'{productName} - {eventLabel}'**
  String productEventTitle(String productName, String eventLabel);

  /// No description provided for @chipLabelValue.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String chipLabelValue(String label, String value);

  /// No description provided for @productSkuLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} ({sku})'**
  String productSkuLabel(String label, String sku);

  /// No description provided for @productSkuLabelReverse.
  ///
  /// In en, this message translates to:
  /// **'{sku} - {label}'**
  String productSkuLabelReverse(String label, String sku);

  /// No description provided for @roomNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Room {number}'**
  String roomNumberLabel(String number);

  /// No description provided for @onboardingStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR Code'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code on a bottle or room to start.'**
  String get onboardingStep1Desc;

  /// No description provided for @onboardingStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Refill a Bottle'**
  String get onboardingStep2Title;

  /// No description provided for @onboardingStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Easily track product refills and keep inventory up to date.'**
  String get onboardingStep2Desc;

  /// No description provided for @onboardingStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Pending Actions'**
  String get onboardingStep3Title;

  /// No description provided for @onboardingStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Check your dashboard for any pending alerts or tasks.'**
  String get onboardingStep3Desc;

  /// No description provided for @onboardingStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Switch Language'**
  String get onboardingStep4Title;

  /// No description provided for @onboardingStep4Desc.
  ///
  /// In en, this message translates to:
  /// **'Change your preferred language in the Settings menu at any time.'**
  String get onboardingStep4Desc;

  /// No description provided for @onboardingStep5Title.
  ///
  /// In en, this message translates to:
  /// **'View Inventory'**
  String get onboardingStep5Title;

  /// No description provided for @onboardingStep5Desc.
  ///
  /// In en, this message translates to:
  /// **'Keep track of your hotel\'s stock levels and incoming orders.'**
  String get onboardingStep5Desc;

  /// No description provided for @onboardingStep6Title.
  ///
  /// In en, this message translates to:
  /// **'Approve Requests'**
  String get onboardingStep6Title;

  /// No description provided for @onboardingStep6Desc.
  ///
  /// In en, this message translates to:
  /// **'Review and approve pending stock requests from your staff.'**
  String get onboardingStep6Desc;

  /// No description provided for @onboardingStep7Title.
  ///
  /// In en, this message translates to:
  /// **'Check Alerts'**
  String get onboardingStep7Title;

  /// No description provided for @onboardingStep7Desc.
  ///
  /// In en, this message translates to:
  /// **'Stay informed about low inventory or operational alerts.'**
  String get onboardingStep7Desc;

  /// No description provided for @onboardingStep8Title.
  ///
  /// In en, this message translates to:
  /// **'Manage Hotels'**
  String get onboardingStep8Title;

  /// No description provided for @onboardingStep8Desc.
  ///
  /// In en, this message translates to:
  /// **'Add and configure multiple hotels under your management.'**
  String get onboardingStep8Desc;

  /// No description provided for @onboardingStep9Title.
  ///
  /// In en, this message translates to:
  /// **'Invite Team'**
  String get onboardingStep9Title;

  /// No description provided for @onboardingStep9Desc.
  ///
  /// In en, this message translates to:
  /// **'Invite managers and staff members to join your workspace.'**
  String get onboardingStep9Desc;

  /// No description provided for @onboardingStep10Title.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get onboardingStep10Title;

  /// No description provided for @onboardingStep10Desc.
  ///
  /// In en, this message translates to:
  /// **'Generate detailed reports and export data across all hotels.'**
  String get onboardingStep10Desc;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get onboardingDone;

  /// No description provided for @onboardingResetMessage.
  ///
  /// In en, this message translates to:
  /// **'Onboarding tour reset. It will be shown on the dashboard.'**
  String get onboardingResetMessage;

  /// No description provided for @replayOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Replay onboarding tour'**
  String get replayOnboarding;

  /// No description provided for @rolePermissionsGuide.
  ///
  /// In en, this message translates to:
  /// **'Role & Permissions Guide'**
  String get rolePermissionsGuide;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpContextDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Overview'**
  String get helpContextDashboardTitle;

  /// No description provided for @helpContextDashboardDesc.
  ///
  /// In en, this message translates to:
  /// **'This screen shows a summary of your hotel\'s refill operations for today. You can quickly see recent activities, pending approvals, and low stock alerts.'**
  String get helpContextDashboardDesc;

  /// No description provided for @helpContextInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory Management'**
  String get helpContextInventoryTitle;

  /// No description provided for @helpContextInventoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your product stock levels. Tap a product card to see details or adjust quantities for your current hotel.'**
  String get helpContextInventoryDesc;

  /// No description provided for @helpContextRoomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rooms Status'**
  String get helpContextRoomsTitle;

  /// No description provided for @helpContextRoomsDesc.
  ///
  /// In en, this message translates to:
  /// **'View all rooms and their product status. Tap a room to refill or replace bottles directly, or scan a QR code to jump straight to the correct room.'**
  String get helpContextRoomsDesc;

  /// No description provided for @helpContextReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports & Exports'**
  String get helpContextReportsTitle;

  /// No description provided for @helpContextReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate and export refill history, inventory snapshots, and alert summaries. Use the download buttons to save this data as CSV files.'**
  String get helpContextReportsDesc;

  /// Empty state message when no products are found
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @markDamagedTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark damaged - {product} in Room {room}'**
  String markDamagedTitle(String product, String room);

  /// No description provided for @markLostTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark lost - {product} in Room {room}'**
  String markLostTitle(String product, String room);

  /// No description provided for @hkDeactivateWithStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Housekeeper Cart Inventory'**
  String get hkDeactivateWithStockTitle;

  /// No description provided for @hkDeactivateWithStockMessage.
  ///
  /// In en, this message translates to:
  /// **'This housekeeper has active inventory in their cart. Would you like to return this inventory to the hotel\'s central inventory before deactivating their account?'**
  String get hkDeactivateWithStockMessage;

  /// No description provided for @btnReturnAndDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Return & Deactivate'**
  String get btnReturnAndDeactivate;

  /// No description provided for @btnJustDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Just Deactivate'**
  String get btnJustDeactivate;

  /// No description provided for @hkDeleteWithStockMessage.
  ///
  /// In en, this message translates to:
  /// **'This housekeeper has active inventory in their cart. Deleting this housekeeper will automatically return all of their inventory to the hotel\'s central inventory.\n\nAre you sure you want to delete team member \'{userName}\'? This action is permanent, cannot be undone, and they will immediately lose access to the application.'**
  String hkDeleteWithStockMessage(String userName);

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get whatsNew;

  /// No description provided for @feature.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get feature;

  /// No description provided for @noPermissionsFound.
  ///
  /// In en, this message translates to:
  /// **'No permissions found.'**
  String get noPermissionsFound;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppL10nAr();
    case 'en':
      return AppL10nEn();
    case 'fr':
      return AppL10nFr();
    case 'it':
      return AppL10nIt();
  }

  throw FlutterError(
      'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
