// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppL10nAr extends AppL10n {
  AppL10nAr([String locale = 'ar']) : super(locale);

  @override
  String get markAsRead => 'تحديد كمقروء';

  @override
  String confirmDeleteHotel(String hotelName) {
    return 'هل أنت متأكد من رغبتك في حذف الفندق \'$hotelName\'؟ لا يمكن التراجع عن هذا الإجراء وسيتم إزالة جميع الغرف المرتبطة، وتعيينات الموظفين، والسجلات بشكل نهائي.';
  }

  @override
  String confirmDeleteRoom(String roomNumber) {
    return 'هل أنت متأكد من رغبتك في حذف الغرفة \'$roomNumber\'؟ لا يمكن التراجع عن هذا الإجراء وسيتم إزالة جميع المنتجات والسجلات المرتبطة بشكل نهائي.';
  }

  @override
  String confirmDeleteFloor(String floorNumber) {
    return 'هل أنت متأكد من رغبتك في حذف الطابق \'$floorNumber\' وجميع غرفه؟ لا يمكن التراجع عن هذا الإجراء بشكل نهائي.';
  }

  @override
  String confirmDeleteUser(String userName) {
    return 'هل أنت متأكد من رغبتك في حذف عضو الفريق \'$userName\'؟ لا يمكن التراجع عن هذا الإجراء وسيفقد إمكانية الوصول إلى التطبيق على الفور.';
  }

  @override
  String confirmDeleteProduct(String productName) {
    return 'هل أنت متأكد من رغبتك في حذف المنتج \'$productName\'؟ لا يمكن التراجع عن هذا الإجراء وسيؤثر على تتبع مخزون المتجر.';
  }

  @override
  String get confirmDeleteAlert =>
      'هل أنت متأكد من رغبتك في حذف هذا التنبيه؟ لا يمكن التراجع عن هذا الإجراء بشكل نهائي.';

  @override
  String get confirmDeleteAllAlerts =>
      'هل أنت متأكد من رغبتك في حذف جميع التنبيهات؟ لا يمكن التراجع عن هذا الإجراء وسيؤدي إلى مسح جميع الإشعارات الحالية.';

  @override
  String get clearAuditLogs => 'مسح السجلات';

  @override
  String get confirmAction => 'تأكيد الإجراء';

  @override
  String get confirmClearLogs =>
      'هل أنت متأكد من رغبتك في مسح جميع سجلات التدقيق؟ لا يمكن التراجع عن هذا الإجراء بشكل نهائي.';

  @override
  String get btnConfirm => 'تأكيد';

  @override
  String get composeMessage => 'كتابة الرسالة';

  @override
  String get notificationTitle => 'عنوان الإشعار';

  @override
  String get notificationDefaultTitle => 'إشعار جديد';

  @override
  String get notificationChannelName => 'إشعارات عالية الأهمية';

  @override
  String get notificationChannelDescription =>
      'تُستخدم هذه القناة للإشعارات المهمة.';

  @override
  String get notificationTitleHint => 'مثل: ميزة جديدة!';

  @override
  String get notificationBody => 'نص الإشعار';

  @override
  String get notificationBodyHint => 'أدخل الرسالة هنا...';

  @override
  String get actionButtons => 'أزرار الإجراءات';

  @override
  String get actionButtonsHint => 'مثل: تجاهل، فتح التطبيق';

  @override
  String get pageToOpen => 'الصفحة المطلوب فتحها';

  @override
  String get menuSendPush => 'إرسال إشعار';

  @override
  String get actionAndRouting => 'الإجراءات والتوجيه';

  @override
  String get openSpecificPage => 'فتح صفحة محددة (اختياري)';

  @override
  String get defaultNoPage => 'الافتراضي (لا توجد صفحة)';

  @override
  String get dashboard => 'لوحة القيادة';

  @override
  String get dashboardOpsAnalytics => 'تحليلات العمليات';

  @override
  String get dashboardExport => 'تصدير';

  @override
  String get dashboardDaily => 'يومي';

  @override
  String get dashboardWeekly => 'أسبوعي';

  @override
  String get dashboardMonthly => 'شهري';

  @override
  String get dashboardRoomsAttention => 'الغرف التي تحتاج إلى اهتمام';

  @override
  String get dashboardProductUsage => 'استخدام المنتج';

  @override
  String get dashboardUsageByFloor => 'الاستخدام حسب الطابق';

  @override
  String get dashboardStockForecast => 'توقعات نفاد مخزون المتجر';

  @override
  String get dashboardUnusualPatterns => 'أنماط غير عادية';

  @override
  String get dashboardNoStockData => 'لا توجد بيانات مخزون المتجر';

  @override
  String dashboardRoomsRequireReview(String count) {
    return '$count غرف تحتاج إلى مراجعة';
  }

  @override
  String get dashboardNoUnusualPatterns => 'لم يتم اكتشاف أنماط غير عادية';

  @override
  String get dashboardHighPriority => 'عالي';

  @override
  String get dashboardStable => 'مستقر';

  @override
  String get errorLoadingHotels => 'خطأ في تحميل الفنادق';

  @override
  String get sending => 'جاري الإرسال...';

  @override
  String roomsEditRoomTitle(String roomNumber) {
    return 'تحديث الغرفة $roomNumber';
  }

  @override
  String roomsEditProductTitle(String productName, String roomNumber) {
    return 'تحديث زجاجة $productName في الغرفة $roomNumber';
  }

  @override
  String get inventory => 'مخزون المتجر';

  @override
  String get alerts => 'تنبيهات';

  @override
  String get approvals => 'الموافقات';

  @override
  String get actionButtonsAndroid => 'أزرار الإجراءات (أندرويد فقط)';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get acknowledge => 'تأكيد';

  @override
  String get openApp => 'فتح التطبيق';

  @override
  String get sendNotification => 'إرسال إشعار';

  @override
  String get targetAudience => 'الجمهور المستهدف';

  @override
  String get allUsers => 'جميع المستخدمين';

  @override
  String get byRole => 'حسب الدور';

  @override
  String get byHotel => 'حسب الفندق';

  @override
  String get byUserEmail => 'حسب البريد الإلكتروني';

  @override
  String get selectRole => 'حدد الدور';

  @override
  String get selectHotel => 'حدد الفندق';

  @override
  String get userEmail => 'البريد الإلكتروني للمستخدم';

  @override
  String get menuAuditLogs => 'سجلات التدقيق';

  @override
  String get auditLogs => 'سجلات التدقيق';

  @override
  String get auditAction => 'إجراء';

  @override
  String get auditDevice => 'الجهاز';

  @override
  String get auditIpAddress => 'عنوان IP';

  @override
  String get auditTimestamp => 'الوقت';

  @override
  String get auditUser => 'المستخدم';

  @override
  String get enterSpecificUserEmail => 'أدخل بريد إلكتروني محدد';

  @override
  String get dispatchNotification => 'إرسال الإشعار';

  @override
  String get pleaseEnterTitleBody => 'الرجاء إدخال عنوان ونص';

  @override
  String get pleaseSelectTarget => 'الرجاء تحديد القيمة المستهدفة';

  @override
  String notificationSent(String successCount, String failureCount) {
    return 'تم الإرسال: $successCount نجاح، $failureCount فشل';
  }

  @override
  String get dashboardShort => 'التحكم';

  @override
  String get dashboardHeroTitle => 'اليوم في Ivra';

  @override
  String get dashboardRefillActivity => 'نشاط التعبئة (آخر 7 أيام)';

  @override
  String get refillActivity => 'نشاط التعبئة';

  @override
  String get myCompletedTasksThisWeek =>
      'عمليات إعادة التعبئة المكتملة لي هذا الأسبوع';

  @override
  String get last7Days => 'آخر 7 أيام';

  @override
  String get lastMonth => 'الشهر الماضي';

  @override
  String get lastYear => 'العام الماضي';

  @override
  String get allHotels => 'جميع الفنادق';

  @override
  String get monthJan => 'جانفي';

  @override
  String get monthFeb => 'فيفري';

  @override
  String get monthMar => 'مارس';

  @override
  String get monthApr => 'أفريل';

  @override
  String get monthMay => 'ماي';

  @override
  String get monthJun => 'جوان';

  @override
  String get monthJul => 'جويلية';

  @override
  String get monthAug => 'أوت';

  @override
  String get monthSep => 'سبتمبر';

  @override
  String get monthOct => 'أكتوبر';

  @override
  String get monthNov => 'نوفمبر';

  @override
  String get monthDec => 'ديسمبر';

  @override
  String get dayMon => 'اثن';

  @override
  String get dayTue => 'ثلا';

  @override
  String get dayWed => 'أرب';

  @override
  String get dayThu => 'خمي';

  @override
  String get dayFri => 'جمع';

  @override
  String get daySat => 'سبت';

  @override
  String get daySun => 'أحد';

  @override
  String get chartRefills => 'تعبئة';

  @override
  String get teamEditProfile => 'تعديل الملف';

  @override
  String get teamEditProfileSuccess => 'تم تحديث الملف';

  @override
  String get hotels => 'الفنادق';

  @override
  String get rooms => 'الغرف';

  @override
  String get products => 'المنتجات';

  @override
  String get team => 'الفريق';

  @override
  String get account => 'الحساب';

  @override
  String get reports => 'التقارير';

  @override
  String get settings => 'الإعدادات';

  @override
  String get more => 'المزيد';

  @override
  String get refill => 'إعادة تعبئة';

  @override
  String get undo => 'تراجع';

  @override
  String get correction => 'تصحيح';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get suggestedOrders => 'الكميات المقترحة';

  @override
  String get bottles => 'العبوات';

  @override
  String get bidons => 'قوارير إعادة التعبئة';

  @override
  String get language => 'اللغة';

  @override
  String get demoMode => 'وضع العرض';

  @override
  String get downloadCsv => 'تحميل CSV';

  @override
  String get downloadPdf => 'تحميل PDF';

  @override
  String get reportRefillHistoryTitle => 'سجل التعبئة';

  @override
  String get reportRefillHistoryBody =>
      'تصدير عمليات التعبئة الحديثة حسب الفندق والغرفة والمنتج والمستخدم والوقت.';

  @override
  String get reportSuggestedOrdersBody =>
      'تصدير توصيات العبوات والجالونات وإعادة التدوير.';

  @override
  String get reportInventorySnapshotTitle => 'لقطة مخزون المتجر';

  @override
  String get reportInventorySnapshotBody =>
      'تصدير مخزون المتجر للعبوات والجالونات الحالي حسب الفندق والمنتج.';

  @override
  String get reportOpenAlertsTitle => 'التنبيهات المفتوحة';

  @override
  String get reportOpenAlertsBody =>
      'تصدير تنبيهات انخفاض مخزون المتجر والاستبدال والخمول والنشاط المشبوه.';

  @override
  String get scheduleReportEmail => 'جدولة تقرير البريد الإلكتروني';

  @override
  String get scheduleReportEmailHint =>
      'سنرسل ملخصًا لهذا التقرير إلى هذا العنوان كل يوم اثنين.';

  @override
  String get scheduledReportEmailDrafted =>
      'تم جدولة تقرير البريد الإلكتروني بنجاح';

  @override
  String get reportFilterDateRange => 'تصفية حسب النطاق الزمني';

  @override
  String get reportAllProducts => 'جميع المنتجات';

  @override
  String get reportAllRooms => 'جميع الغرف';

  @override
  String get reportClearFilters => 'مسح الفلاتر';

  @override
  String get reportFiltersApplyExports =>
      'ملاحظة: تنطبق الفلاتر على كل من مقاييس الشاشة والصادرات التي تم تنزيلها.';

  @override
  String get reportAnalyticsTitle => 'نظرة عامة على التحليلات';

  @override
  String get reportKpiRefills => 'إجمالي عمليات إعادة التعبئة';

  @override
  String get reportKpiCorrections => 'تصحيحات مخزون المتجر';

  @override
  String get reportKpiReplacements => 'الاستبدالات';

  @override
  String get reportKpiActiveRooms => 'الغرف النشطة';

  @override
  String get reportTrendChart => 'اتجاه نشاط إعادة التعبئة (آخر 14 يومًا)';

  @override
  String get reportUsageByProduct => 'إعادة التعبئة حسب المنتج';

  @override
  String get reportUsageByRoom => 'إعادة التعبئة حسب الغرفة';

  @override
  String get reportNoAnalyticsData => 'لم يتم تسجيل أي نشاط خلال هذه الفترة.';

  @override
  String get exportFailed => 'فشل التصدير';

  @override
  String get metricHotels => 'الفنادق';

  @override
  String get metricRooms => 'الغرف';

  @override
  String get metricPendingApprovals => 'الموافقات المعلقة';

  @override
  String get metricOpenAlerts => 'التنبيهات المفتوحة';

  @override
  String get metricBottlesToReplace => 'عبوات للاستبدال';

  @override
  String get metricLowStockProducts => 'منتجات منخفضة مخزون المتجر';

  @override
  String get inventoryTableProduct => 'المنتج';

  @override
  String get inventoryTableFullBottles => 'العبوات الممتلئة';

  @override
  String inventoryTableFullBottlesWithPump(String size) {
    return 'عبوات ممتلئة بمضخة سعة $size';
  }

  @override
  String inventoryTableFullBottlesWithoutPump(String size) {
    return 'عبوات ممتلئة بدون مضخة سعة $size';
  }

  @override
  String get inventoryTableFullBottlesWithPumpGeneric =>
      'العبوات الممتلئة بمضخة';

  @override
  String get inventoryTableFullBottlesWithoutPumpGeneric =>
      'العبوات الممتلئة بدون مضخة';

  @override
  String get inventoryCollapseHeader => 'العبوات الفارغة والمفتوحة';

  @override
  String inventoryTableEmptyBottles(String months) {
    return 'العبوات المستبدلة بعد $months أشهر (مستعملة)';
  }

  @override
  String get inventoryTableEmptyBottlesGeneric => 'العبوات المستبدلة (مستعملة)';

  @override
  String get inventoryTableEmptyBidons => 'قوارير إعادة التعبئة الفارغة';

  @override
  String inventoryTableFullBidons(String size) {
    return 'عبوات إعادة تعبئة ممتلئة سعة $size';
  }

  @override
  String get inventoryTableFullBidonsGeneric => 'عبوات إعادة تعبئة ممتلئة';

  @override
  String get inventoryTableOpenBidons => 'قوارير إعادة التعبئة المستعملة';

  @override
  String get inventoryTableStatus => 'الحالة';

  @override
  String get errorUniqueViolation => 'هذا السجل موجود بالفعل.';

  @override
  String get errorForeignKeyViolation => 'السجل المرتبط غير موجود.';

  @override
  String get errorPermissionDenied => 'ليس لديك إذن لأداء هذا الإجراء.';

  @override
  String get errorGeneric => 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';

  @override
  String get inventoryStatusHealthy => 'سليم';

  @override
  String get inventoryStatusLowStock => 'مخزون منخفض';

  @override
  String get auditFilterAllActions => 'جميع الإجراءات';

  @override
  String get sortNameAsc => 'الاسم (أ-ي)';

  @override
  String get sortNameDesc => 'الاسم (ي-أ)';

  @override
  String get sortMostFullBottles => 'أكثر الزجاجات الممتلئة';

  @override
  String get sortMostEmptyBottles => 'أكثر الزجاجات الفارغة';

  @override
  String get bulkAdjustSelectProducts => 'حدد المنتجات';

  @override
  String get bulkAdjustSelectAll => 'تحديد الكل';

  @override
  String get bulkAdjustDeselectAll => 'إلغاء تحديد الكل';

  @override
  String get bulkAdjustNoProductsSelected => 'يرجى تحديد منتج واحد على الأقل.';

  @override
  String orderNewBottlesText(String count) {
    return 'طلب $count عبوات جديدة 1 لتر';
  }

  @override
  String orderNewBidonsText(String count) {
    return 'طلب $count قوارير إعادة تعبئة جديدة 5 لتر';
  }

  @override
  String recycleBottlesText(String count) {
    return 'إعادة تدوير $count عبوات';
  }

  @override
  String get bottleCannotRefillRecycled =>
      'تم إعادة تدوير هذه العبوة ولا يمكن إعادة تعبئتها. يرجى استبدالها.';

  @override
  String get adjustStockTitle => 'تعديل مخزون المتجر';

  @override
  String get hotelRoomsTracked => 'غرف متبعة';

  @override
  String get hotelPendingChip => 'قيد الانتظار';

  @override
  String get hotelLabelName => 'اسم الفندق';

  @override
  String get hotelLabelLegalName => 'الاسم القانوني';

  @override
  String get hotelLabelState => 'الولاية';

  @override
  String get hotelLabelCountry => 'البلد';

  @override
  String get hotelLabelContactName => 'جهة الاتصال';

  @override
  String get hotelLabelEmail => 'البريد الإلكتروني';

  @override
  String get hotelLabelPhone => 'الهاتف';

  @override
  String get hotelLabelAddress => 'العنوان';

  @override
  String get hotelLabelNotes => 'ملاحظات';

  @override
  String get btnCreate => 'إنشاء';

  @override
  String get btnCancel => 'إلغاء';

  @override
  String get btnSave => 'حفظ';

  @override
  String get btnSubmitRequest => 'تقديم الطلب';

  @override
  String get demoModeDescription =>
      'محاكاة محلية باستخدام قواعد البيانات الافتراضية.';

  @override
  String get offlineModeDescription =>
      'جدولة العمليات عند انقطاع الاتصال ومزامنتها لاحقاً.';

  @override
  String get syncQueueHeader => 'قائمة الانتظار';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get itemsToSync => 'عمليات قيد المزامنة';

  @override
  String get editRequestQueued => 'تمت جدولة طلب التعديل';

  @override
  String get editRequestSubmitted => 'تم تقديم طلب التعديل';

  @override
  String get hotelUpdated => 'تم تحديث معلومات الفندق';

  @override
  String get hotelCreatedSuccessfully => 'تم إنشاء الفندق بنجاح';

  @override
  String get requiredField => 'مطلوب';

  @override
  String get enterNumberError => 'أدخل رقماً';

  @override
  String get createHotel => 'إنشاء فندق';

  @override
  String get requestHotelEdit => 'طلب تعديل الفندق';

  @override
  String get authTitleCannotAccess => 'هذا الحساب يتطلب دعوة للوصول إلى إيفرا.';

  @override
  String get authBtnGoogleSignIn => 'تسجيل الدخول بواسطة جوجل';

  @override
  String get authBtnSignOut => 'تسجيل الخروج';

  @override
  String get authLabelEmail => 'البريد الإلكتروني';

  @override
  String get authLabelPassword => 'كلمة المرور';

  @override
  String get authShowPassword => 'إظهار كلمة المرور';

  @override
  String get authHidePassword => 'إخفاء كلمة المرور';

  @override
  String get authBtnSignIn => 'تسجيل الدخول';

  @override
  String get authBtnForgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get authResetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get setPasswordTitle => 'تعيين كلمة المرور';

  @override
  String get setPasswordBody =>
      'يرجى تعيين كلمة مرور آمنة لحسابك لإكمال تسجيلك.';

  @override
  String get setPasswordButton => 'تعيين كلمة المرور';

  @override
  String get authBtnSendResetLink => 'إرسال رابط إعادة التعيين';

  @override
  String get authResetLinkSent => 'تم إرسال رابط إعادة تعيين كلمة المرور إلى';

  @override
  String get authValidationEmailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get authValidationEmailInvalid => 'أدخل بريداً إلكترونياً صالحاً';

  @override
  String get authValidationPasswordRequired => 'كلمة المرور مطلوبة';

  @override
  String get authValidationPasswordTooShort =>
      'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل';

  @override
  String get authValidationPasswordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get authResetNewPasswordTitle => 'إنشاء كلمة مرور جديدة';

  @override
  String get authLabelNewPassword => 'كلمة المرور الجديدة';

  @override
  String get authLabelConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get authBtnUpdatePassword => 'تحديث كلمة المرور';

  @override
  String get authBtnReturnToApp => 'العودة إلى التطبيق';

  @override
  String get authPasswordUpdatedSuccess => 'تم تحديث كلمة المرور بنجاح.';

  @override
  String get authUnexpectedError =>
      'حدث خطأ غير متوقّع. حاول مرّة أخرى أو تواصل مع الدّعم إذا استمرّت المشكلة.';

  @override
  String get asyncErrorTitle => 'تعذّر تحميل هذا القسم';

  @override
  String get btnRetry => 'إعادة المحاولة';

  @override
  String get authProfileLoadErrorTitle => 'تعذّر تحميل ملفّك الشخصي.';

  @override
  String get authProfileLoadErrorBody =>
      'عادةً ما تكون هذه مشكلة اتّصال مؤقّتة. يرجى إعادة المحاولة.';

  @override
  String get authAccountDeactivated =>
      'تمّ تعطيل هذا الحساب. تواصل مع المدير لاستعادة الوصول.';

  @override
  String get settingsPayloadInvalidJson => 'يجب أن تكون الحمولة كائن JSON.';

  @override
  String exportDownloadStarted(String fileName) {
    return 'بدأ تنزيل $fileName';
  }

  @override
  String exportSaved(String fileName, String path) {
    return 'تمّ حفظ $fileName في $path';
  }

  @override
  String settingsPendingSync(String count) {
    return 'في انتظار المزامنة ($count)';
  }

  @override
  String get splashTagline => 'حلول ضيافة مستدامة';

  @override
  String get accountSaveFailed => 'تعذّر حفظ ملفّك. حاول مرّة أخرى.';

  @override
  String get accountPasswordChangeFailed =>
      'تعذّر تغيير كلمة المرور. حاول مرّة أخرى.';

  @override
  String get accountSignOutFailed =>
      'تعذّر تسجيل الخروج. تحقّق من الاتّصال ثمّ أعد المحاولة.';

  @override
  String get hotelCreateFailed => 'تعذّر إنشاء الفندق. حاول مرّة أخرى.';

  @override
  String get hotelUpdateFailed => 'تعذّر تحديث بيانات الفندق. حاول مرّة أخرى.';

  @override
  String get teamInviteFailed => 'تعذّر إرسال الدّعوة. حاول مرّة أخرى.';

  @override
  String get teamHotelsUpdateFailed =>
      'تعذّر تحديث تعيينات الفنادق. حاول مرّة أخرى.';

  @override
  String get roomsTooltipCreateTemplate => 'إنشاء نموذج غرفة';

  @override
  String get roomsNoRoomsFound => 'لم يتم العثور على غرف أو منتجات.';

  @override
  String get roomsNoProducts => 'لا توجد منتجات مخصصة لهذه الغرفة.';

  @override
  String get roomsStatusNoProducts => 'لا توجد منتجات';

  @override
  String get roomsSearchEmptyHint =>
      'جرّب تعديل استفسار البحث أو العوامل التصفية.';

  @override
  String get roomsEmptyHotelWithTemplate =>
      'أضف غرفتك الأولى باستخدام زر القالب في الأعلى.';

  @override
  String get roomsEmptyHotelNoTemplate =>
      'لم يتمّ تعيين أي غرفة لهذا الفندق بعد.';

  @override
  String get roomsLabelRoom => 'غرفة';

  @override
  String get bottleStatusActive => 'نشطة';

  @override
  String get bottleStatusNeedsRefill => 'بحاجة لإعادة التعبئة';

  @override
  String get bottleStatusRefilled => 'تمت إعادة التعبئة';

  @override
  String get bottleStatusRefillLimitReached => 'تم الوصول لحد التعبئة';

  @override
  String get bottleStatusTooOld => 'قديمة جداً';

  @override
  String get bottleStatusNeedsReplacement => 'بحاجة للاستبدال';

  @override
  String get bottleStatusRecycled => 'معاد تدويرها';

  @override
  String get bottleStatusDamaged => 'تالفة';

  @override
  String get bottleStatusLost => 'مفقودة';

  @override
  String get roomsLabelFloor => 'الطابق';

  @override
  String get roomsLabelRefills => 'التعبئة';

  @override
  String get roomsLabelAge => 'العمر';

  @override
  String get roomsLabelDaysUnit => 'ي';

  @override
  String get roomsRefillQueued => 'تمت جدولة إعادة التعبئة للغرفة';

  @override
  String get roomsRefillRecorded => 'تم تسجيل إعادة التعبئة للغرفة';

  @override
  String get roomsBtnBottleEdit => 'تعديل العبوة';

  @override
  String get roomsBtnReplaceBottle => 'استبدال العبوة';

  @override
  String get roomsBtnRefillBottle => 'إعادة تعبئة العبوة';

  @override
  String get roomsBtnRoomEdit => 'تعديل الغرفة';

  @override
  String get roomsBtnHistory => 'السجل';

  @override
  String get roomsBtnMoreActions => 'مزيد من الإجراءات';

  @override
  String get roomsBtnMarkDamaged => 'تحديد كتالف';

  @override
  String get roomsBtnMarkLost => 'تحديد كمفقود';

  @override
  String get roomsLabelProofPhoto => 'صورة الإثبات';

  @override
  String get roomsNotesOptional => 'ملاحظات (اختياري)';

  @override
  String get roomsLabelUploadedProof => 'الإثبات المرفوع';

  @override
  String get roomsUploadProofAction => 'رفع صورة';

  @override
  String get roomsReplacementQueued => 'تمت جدولة استبدال العبوة للغرفة';

  @override
  String get roomsReplacementRecorded => 'تم استبدال العبوة للغرفة';

  @override
  String get roomsReplacementNotes => 'تم استبدال العبوة من سير العمل للغرفة';

  @override
  String get roomsStatusAllOk => 'كل شيء سليم';

  @override
  String get roomsStatusAttentionRequired => 'انتباه مطلوب';

  @override
  String get roomsStatusRefillNeeded => 'تعبئة مطلوبة';

  @override
  String get roomsSearchPlaceholder => 'البحث عن غرفة...';

  @override
  String get roomsRecentTitle => 'الغرف الأخيرة';

  @override
  String get roomsRecentClear => 'مسح';

  @override
  String get roomsGestionExpressQr => 'الإدارة السريعة (QR)';

  @override
  String get roomsSelectHotelFirst => 'اختر فندقاً...';

  @override
  String get roomsViewDetailed => 'عرض تفصيلي';

  @override
  String get roomsViewCompact => 'عرض مبسط';

  @override
  String get roomsCollapseAll => 'طوي الكل';

  @override
  String get roomsExpandAll => 'توسيع الكل';

  @override
  String get roomsBtnAddRoom => 'إضافة غرفة';

  @override
  String get roomsDialogAddRoomTitle => 'إضافة غرفة للطابق';

  @override
  String get roomsMsgRoomAdded => 'تمت إضافة الغرفة';

  @override
  String get roomsMsgRoomAddQueued => 'تم وضع إنشاء الغرفة في قائمة الانتظار';

  @override
  String get roomsHistoryRefill => 'إعادة تعبئة';

  @override
  String get roomsHistoryNewBottle => 'تم وضع زجاجة جديدة';

  @override
  String roomsHistoryStatusChanged(String oldValue, String newValue) {
    return 'تغيرت الحالة من $oldValue إلى $newValue';
  }

  @override
  String get roomsFilterAll => 'الكل';

  @override
  String get roomsDialogBottleEditTitle => 'طلب تعديل العبوة للغرفة';

  @override
  String get roomsLabelBottleStatus => 'حالة العبوة';

  @override
  String get roomsLabelBottleStartDate => 'تاريخ بدء العبوة';

  @override
  String get roomsValidationEnterValidDate => 'أدخل تاريخاً صالحاً';

  @override
  String get roomsMsgEditRequestQueued => 'تمت جدولة طلب تعديل العبوة';

  @override
  String get roomsMsgDetailsUpdated => 'تم تحديث تفاصيل العبوة';

  @override
  String get roomsMsgEditRequestSubmitted => 'تم تقديم طلب تعديل العبوة';

  @override
  String get roomsDialogRoomEditTitle => 'طلب تعديل الغرفة لـ';

  @override
  String get roomsLabelRoomNumber => 'رقم الغرفة';

  @override
  String get roomsLabelFloorNumber => 'رقم الطابق';

  @override
  String get roomsMsgRoomEditQueued => 'تمت جدولة طلب تعديل الغرفة';

  @override
  String get roomsMsgRoomDetailsUpdated => 'تم تحديث تفاصيل الغرفة';

  @override
  String get roomsMsgRoomEditSubmitted => 'تم تقديم طلب تعديل الغرفة';

  @override
  String get roomsMsgRequestRoomEdit => 'تحديث الغرفة';

  @override
  String get roomsDialogHistoryTitle => 'سجل';

  @override
  String get roomsNoHistoryRecorded => 'لم يتم تسجيل أي سجل تعبئة بعد.';

  @override
  String get roomsMsgUndoQueued => 'تمت جدولة التراجع';

  @override
  String get roomsMsgRefillUndone => 'تم التراجع عن التعبئة';

  @override
  String get roomsBtnClose => 'إغلاق';

  @override
  String get qrScanTitle => 'مسح رمز QR';

  @override
  String get qrScanPlaceholder => 'أدخل رمز QR يدويًا...';

  @override
  String get qrDemoCodes => 'رموز QR التجريبية';

  @override
  String get qrActionPrompt => 'حدد إجراءً';

  @override
  String qrActionMessage(String product) {
    return 'ماذا تريد أن تفعل لـ $product؟';
  }

  @override
  String get qrActionRefill => 'تعبئة العبوة';

  @override
  String get qrActionReplace => 'استبدال العبوة';

  @override
  String get hotelNotFound => 'الفندق غير موجود';

  @override
  String get productNotFound => 'المنتج غير موجود';

  @override
  String get qrAccessDeniedMessage =>
      'ليس لديك صلاحية لتنفيذ إجراءات في هذا الفندق.';

  @override
  String get roomsFillCount => 'عدد مرات التعبئة';

  @override
  String get roomsBottleStatus => 'حالة الموزع';

  @override
  String get btnBack => 'رجوع';

  @override
  String get qrActionSuccess => 'تمت العملية بنجاح';

  @override
  String get qrActionFailed => 'فشلت العملية';

  @override
  String get qrUpdatedStatus => 'حالة الموزع المحدّثة:';

  @override
  String get qrScanAnother => 'مسح رمز QR آخر';

  @override
  String get qrReturnRooms => 'العودة إلى الغرف';

  @override
  String get qrTryScanAgain => 'أعد المسح مرة أخرى';

  @override
  String qrFloorRoom(String floor, String room) {
    return 'الطابق $floor • الغرفة $room';
  }

  @override
  String qrRoomFloor(String room, String floor) {
    return 'الغرفة $room • الطابق $floor';
  }

  @override
  String get qrCameraPermission => 'تم رفض إذن الكاميرا';

  @override
  String get qrCameraUnavailable => 'الكاميرا غير متاحة';

  @override
  String qrHotelNotFoundMessage(String hotel) {
    return 'تعذر العثور على الفندق: «$hotel»';
  }

  @override
  String qrProductNotFoundMessage(String room, String floor, String sku) {
    return 'الغرفة $room (الطابق $floor) لا تحتوي على المنتج SKU: «$sku»';
  }

  @override
  String get qrGenerateTabScan => 'مسح رمز QR';

  @override
  String get qrGenerateTabGenerate => 'توليد رموز QR';

  @override
  String get qrGenerateHotel => 'الفندق';

  @override
  String get qrGenerateScope => 'نوع ملصق QR';

  @override
  String get qrGenerateScopeRoom => 'باب الغرفة (بدون SKU)';

  @override
  String get qrGenerateScopeDispenser => 'الموزع (مع SKU)';

  @override
  String get qrGenerateRoom => 'الغرفة';

  @override
  String get qrGenerateProduct => 'المنتج';

  @override
  String get qrGenerateAllRooms => 'جميع الغرف';

  @override
  String get qrGenerateAllProducts => 'جميع المنتجات';

  @override
  String get qrGenerateBtnDownload => 'توليد وتنزيل PDF';

  @override
  String get qrGenerateDownloading => 'جاري توليد PDF...';

  @override
  String get qrGenerateSuccess => 'تم توليد وتنزيل ملف PDF بنجاح';

  @override
  String get settingsScannerHeader => 'إعدادات الماسح الضوئي';

  @override
  String get settingsPrecisionScanTitle => 'نافذة المسح الدقيقة';

  @override
  String get settingsPrecisionScanSubtitle =>
      'مسح الرموز المحاذية لمركز محدد فقط';

  @override
  String get settingsTapToScanTitle => 'النقر للمسح';

  @override
  String get settingsTapToScanSubtitle => 'انقر على مربع رمز QR المكتشف لمسحه';

  @override
  String get qrConfirmAssignTitle => 'المنتج غير موضوع';

  @override
  String qrConfirmAssignMessage(String product, String room) {
    return 'المنتج $product غير مخصص للغرفة $room. هل تريد إضافة قطعة واحدة إلى المخزون وتخصيصها للغرفة؟';
  }

  @override
  String get qrAssignSuccess => 'تم تخصيص المنتج وإعادة تعبئته بنجاح';

  @override
  String get qrActionCanceled => 'تم إلغاء العملية';

  @override
  String get qrActionCanceledMessage =>
      'اخترت عدم تخصيص المنتج. يمكنك مسح رمز آخر أو العودة إلى الغرف.';

  @override
  String get scanAssignTitle => 'تعيين المنتج للغرفة';

  @override
  String get scanAssignSuccess => 'تم تعيين المنتج بنجاح';

  @override
  String get scanAssignFailed => 'فشل التعيين';

  @override
  String scanAssignInStock(String count) {
    return '$count في المخزون — سيتم خصم 1 وتعيينه للغرفة';
  }

  @override
  String get scanAssignOutOfStock =>
      'نفد المخزون — ستتم إضافة وحدة واحدة تلقائياً ثم تعيينها';

  @override
  String get scanAssignDescription =>
      'هذا المنتج غير معيّن لهذه الغرفة بعد. انقر أدناه لتعيينه.';

  @override
  String get scanAssignButton => 'تعيين للغرفة';

  @override
  String get scanAssignAutoAdd => 'إضافة للمخزون وتعيين';

  @override
  String get scanAssignAutoAddTitle => 'إضافة للمخزون؟';

  @override
  String scanAssignAutoAddMessage(String product) {
    return 'المنتج \"$product\" نفد من المخزون. هل تريد إضافة وحدة واحدة تلقائياً وتعيينها لهذه الغرفة؟';
  }

  @override
  String get scanAssignConfirm => 'نعم، أضف وعيّن';

  @override
  String scanAssignSuccessMessage(String product, String room, String floor) {
    return 'تم تعيين المنتج $product للغرفة $room (الطابق $floor).';
  }

  @override
  String get qrMultipleDetected => 'تم اكتشاف عدة رموز QR. انقر للاختيار:';

  @override
  String qrUnknownSku(String sku) {
    return 'رمز SKU \"$sku\" لا يتطابق مع أي منتج معروف.';
  }

  @override
  String get goToRoom => 'الذهاب إلى الغرفة';

  @override
  String get errorLoadingProducts => 'خطأ في تحميل المنتجات';

  @override
  String get errorLoadingInventory => 'خطأ في تحميل المخزون';

  @override
  String get qrGenAllRoomProducts => 'جميع المنتجات في الغرفة المحددة';

  @override
  String get qrGenAllInventoryProducts => 'جميع المنتجات في المخزون';

  @override
  String get qrLabelScanInstructions =>
      'امسح بتطبيق IVRA لإعادة التعبئة أو الاستبدال';

  @override
  String get roomsSearchProductPlaceholder => 'البحث عن منتج بالاسم أو SKU...';

  @override
  String adjustStockForProduct(String product) {
    return 'تعديل مخزون المتجر لـ $product';
  }

  @override
  String get roomsBtnRequestCorrection => 'طلب تصحيح';

  @override
  String get roomsLabelReason => 'السبب';

  @override
  String get roomsMsgCorrectionQueued => 'تمت جدولة طلب التصحيح';

  @override
  String get roomsMsgCorrectionSubmitted => 'تم تقديم طلب التصحيح';

  @override
  String get roomsBtnCreateRooms => 'إنشاء الغرف';

  @override
  String get roomsLabelProductsInRoom => 'المنتجات في كل غرفة';

  @override
  String get roomsMsgSelectOneProduct => 'حدد منتجاً واحداً على الأقل';

  @override
  String roomsMsgDuplicateRoomNumbers(String numbers) {
    return 'أرقام الغرف هذه موجودة بالفعل في هذا الفندق: $numbers. اختر رقم بدء أو عدداً مختلفاً.';
  }

  @override
  String get productsCatalogTitle => 'كتالوج المنتجات';

  @override
  String get productsBtnCreate => 'إنشاء منتج';

  @override
  String get productsNoProducts => 'لا توجد منتجات في الكتالوج بعد.';

  @override
  String get productsLabelBottleVolume => 'حجم القارورة';

  @override
  String get productsLabelBidonVolume => 'حجم قارورة إعادة التعبئة';

  @override
  String get productsLabelMaxRefill => 'الحد الأقصى للتعبئة';

  @override
  String get productsLabelMaxAge => 'الحد الأقصى لعمر القارورة';

  @override
  String get productsLabelLowStock => 'تنبيه انخفاض مخزون المتجر';

  @override
  String get productsBtnEdit => 'تعديل المنتج';

  @override
  String get productsLabelSku => 'وحدة حفظ مخزون المتجر (SKU)';

  @override
  String get productsLabelNameEn => 'الاسم بالإنجليزية';

  @override
  String get productsLabelNameFr => 'الاسم بالفرنسية';

  @override
  String get productsLabelNameAr => 'الاسم بالعربية';

  @override
  String get productsLabelNameIt => 'الاسم بالإيطالية';

  @override
  String get productsLabelImage => 'تحميل صورة';

  @override
  String get productsLabelImageHint => 'اختر صورة من جهازك';

  @override
  String productsImageSelected(String name) {
    return 'المحدد: $name';
  }

  @override
  String get productsImageSet => 'تم تعيين الصورة (اضغط للتغيير)';

  @override
  String get productsImageNone => 'لم يتم اختيار صورة';

  @override
  String get productsImageRemove => 'إزالة الصورة';

  @override
  String get productsImageUploadFailed =>
      'فشل تحميل الصورة. يرجى المحاولة مرة أخرى.';

  @override
  String get productsImageInvalidType => 'يرجى اختيار ملف صورة صالح.';

  @override
  String productsImageTooLarge(String max) {
    return 'الصورة كبيرة جدًا (الحد الأقصى $max ميجابايت).';
  }

  @override
  String get productsAddedSuccess => 'تمت إضافة المنتج بنجاح';

  @override
  String get productsUpdatedSuccess => 'تم تحديث المنتج بنجاح';

  @override
  String get productsLabelBottleMl => 'القارورة مل';

  @override
  String get productsLabelBidonMl => 'مل قارورة إعادة التعبئة';

  @override
  String get productsLabelMaxRefills => 'الحد الأقصى للتعبئة';

  @override
  String get productsLabelMaxAgeDays => 'الحد الأقصى للعمر (أيام)';

  @override
  String get productsLabelLowBottles => 'حد انخفاض القوارير';

  @override
  String get productsLabelLowBidons => 'حد انخفاض قوارير إعادة التعبئة';

  @override
  String get productsLabelBottleType => 'نوع الزجاجة';

  @override
  String get productsLabelBottleWithPump => 'زجاجة بمضخة';

  @override
  String get productsLabelBottleWithoutPump => 'زجاجة بدون مضخة';

  @override
  String get productsLabelRefillType => 'نوع إعادة التعبئة';

  @override
  String get productsLabelRefillable => 'قابل لإعادة التعبئة';

  @override
  String get productsLabelDirectReplacement => 'استبدال مباشر';

  @override
  String get productsDialogCreateTitle => 'إنشاء منتج';

  @override
  String get productsDialogEditTitle => 'تعديل المنتج';

  @override
  String get days => 'أيام';

  @override
  String get refills => 'تعبئات';

  @override
  String get inventoryNoHotels => 'لم يتم العثور على فنادق';

  @override
  String get inventoryAddHotelHint => 'أضف فندقًا للبدء.';

  @override
  String get inventoryNoItemsToAdjust =>
      'لا توجد عناصر مخزون المتجر متاحة للتعديل.';

  @override
  String get inventoryNoInventoryYet => 'لا يوجد مخزون المتجر بعد';

  @override
  String get inventoryNoProductsInInventory =>
      'لا توجد منتجات في مخزون المتجر.';

  @override
  String get inventoryNoSuggestedOrders => 'لا توجد طلبات مقترحة';

  @override
  String get inventoryLevelsSufficient =>
      'مستويات مخزون المتجر لديك كافية حاليًا.';

  @override
  String get teamAccounts => 'حسابات الفريق';

  @override
  String get teamNoMembers => 'لم يتم العثور على أعضاء.';

  @override
  String get teamTableColumnName => 'الاسم';

  @override
  String get teamTableColumnEmail => 'البريد';

  @override
  String get teamTableColumnRole => 'الدور';

  @override
  String get teamTableColumnHotel => 'الفندق';

  @override
  String get teamTableColumnStatus => 'الحالة';

  @override
  String get teamTableColumnActions => 'الإجراءات';

  @override
  String get teamPendingInvitations => 'دعوات معلقة';

  @override
  String get teamNoPendingInvitations => 'لا توجد دعوات معلقة.';

  @override
  String get teamInviteTitle => 'دعوة عضو';

  @override
  String get teamLabelFullName => 'الاسم الكامل';

  @override
  String get settingsOfflineMode => 'وضع عدم الاتصال';

  @override
  String get settingsOfflineQueue => 'جدولة الإجراءات';

  @override
  String get settingsOfflineSend => 'إرسال الإجراءات';

  @override
  String get settingsBiometricTitle => 'الفتح بالبصمة';

  @override
  String get settingsBiometricHint => 'استخدم بصمتك أو وجهك لتسجيل الدخول.';

  @override
  String get settingsBiometricUnavailable =>
      'الفتح بالبصمة غير متاح على هذا الجهاز.';

  @override
  String get authBtnBiometricLogin => 'تسجيل الدخول بالبصمة';

  @override
  String get authBiometricReason => 'قم بالمصادقة للوصول إلى Ivra';

  @override
  String get authBiometricNeedsLogin =>
      'يرجى تسجيل الدخول مرة واحدة لتفعيل الدخول بالبصمة.';

  @override
  String get authBiometricOfflineNoSession =>
      'أنت غير متصل بالإنترنت. اتصل بالإنترنت لتسجيل الدخول.';

  @override
  String get authBiometricFailed => 'فشلت المصادقة بالبصمة.';

  @override
  String get settingsBtnClear => 'مسح';

  @override
  String get settingsBtnSyncNow => 'مزامنة';

  @override
  String get settingsNoPendingActions => 'لا توجد إجراءات معلقة.';

  @override
  String get teamManageHotels => 'إدارة الفنادق';

  @override
  String get teamAssignHotelsTitle => 'تعيين الفنادق';

  @override
  String get teamNoHotelsAssigned => 'لا توجد فنادق معينة';

  @override
  String get teamHotelsUpdated => 'تم تحديث التعيينات';

  @override
  String get teamSelectHotels => 'اختر الفنادق';

  @override
  String get teamHotelsAssigned => 'فنادق معينة';

  @override
  String get accountTitle => 'الحساب';

  @override
  String get accountProfile => 'الملف الشخصي';

  @override
  String get accountProfileUpdated => 'تم تحديث الملف الشخصي';

  @override
  String get accountPassword => 'كلمة المرور';

  @override
  String get accountPasswordUpdated => 'تم تحديث كلمة المرور';

  @override
  String get accountFullName => 'الاسم الكامل';

  @override
  String get accountFullNameRequired => 'الاسم الكامل مطلوب';

  @override
  String get accountNewPassword => 'كلمة مرور جديدة';

  @override
  String get accountConfirmPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get accountPasswordHintSupabase => 'يحدث كلمة مرور تسجيل الدخول.';

  @override
  String get accountPasswordHintDemo => 'وضع العرض يقبل التغيير محليًا.';

  @override
  String get accountSignOutHint => 'إنهاء الجلسة الحالية على هذا الجهاز.';

  @override
  String get accountSignOut => 'تسجيل الخروج';

  @override
  String get accountEmail => 'البريد الإلكتروني';

  @override
  String get accountRole => 'الدور';

  @override
  String get accountScope => 'النطاق';

  @override
  String get accountStatus => 'الحالة';

  @override
  String get accountActive => 'نشط';

  @override
  String get accountInactive => 'غير نشط';

  @override
  String get accountIvraGlobal => 'Ivra عالمي';

  @override
  String get accountTeamAccounts => 'حسابات الفريق';

  @override
  String get accountNoOtherAccounts => 'لم يتم العثور على حسابات أخرى.';

  @override
  String get accountYou => 'أنت';

  @override
  String get alertsRefreshSmart => 'تحديث التنبيهات الذكية';

  @override
  String get alertsResolve => 'حل';

  @override
  String get delete => 'حذف';

  @override
  String get approvalsEmpty => 'لا توجد موافقات معلقة';

  @override
  String get approvalsEmptySubtitle => 'تمت معالجة جميع طلبات الموافقة.';

  @override
  String get approvalsApprove => 'موافقة';

  @override
  String get approvalsReject => 'رفض';

  @override
  String get approvalsActionFailed => 'فشل الإجراء. حاول مرة أخرى.';

  @override
  String get approvalsApproved => 'تمت الموافقة على الطلب.';

  @override
  String get approvalsRejected => 'تم رفض الطلب.';

  @override
  String get approvalsApproveQueued => 'تمت إضافة الموافقة إلى قائمة المزامنة.';

  @override
  String get approvalsRejectQueued => 'تمت إضافة الرفض إلى قائمة المزامنة.';

  @override
  String get approvalsAccessDenied =>
      'الوصول مرفوض. المسؤولون فقط يمكنهم المراجعة.';

  @override
  String get approvalsRequestNotFound =>
      'طلب الموافقة غير موجود أو تمت معالجته.';

  @override
  String get inviteAcceptTitle => 'قبول الدعوة';

  @override
  String get inviteAlreadyHaveAccount => 'لدي حساب بالفعل';

  @override
  String get inviteBackToSignIn => 'العودة إلى تسجيل الدخول';

  @override
  String get inviteEmail => 'البريد الإلكتروني';

  @override
  String get invitePassword => 'كلمة المرور';

  @override
  String get inviteConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get settingsRetryAction => 'إعادة المحاولة';

  @override
  String get settingsRemoveAction => 'إزالة الإجراء';

  @override
  String get settingsActionUpdated => 'تم تحديث الإجراء المنتظر';

  @override
  String get settingsActionRemoved => 'تم إزالة الإجراء غير المتصل';

  @override
  String get settingsQueueCleared => 'تم مسح قائمة الانتظار';

  @override
  String get settingsTestAccessAs => 'اختبار الوصول كـ';

  @override
  String get settingsDemoUserChanged => 'تم تغيير المستخدم التجريبي';

  @override
  String get settingsPayloadJson => 'بيانات JSON المنتظرة';

  @override
  String get settingsSaveAndRetry => 'حفظ وإعادة المحاولة';

  @override
  String get settingsDemoUser => 'مستخدم تجريبي';

  @override
  String get settingsSupabaseConnected => 'متصل';

  @override
  String get settingsSupabaseHint => 'التطبيق يستخدم البيانات المباشرة.';

  @override
  String get settingsNoSupabaseHint => 'لم يتم تكوين الاتصال بالخادم.';

  @override
  String get settingsEditAction => 'تعديل الإجراء المنتظر';

  @override
  String get settingsResolveConflict => 'حل تعارض المزامنة';

  @override
  String get settingsActionSynced => 'تمت مزامنة الإجراء';

  @override
  String get offlineBannerTitle => 'أنت غير متصل';

  @override
  String get offlineBannerSubtitle => 'قد لا تكون البيانات محدثة';

  @override
  String get offlineBannerPending => 'إجراءات معلقة';

  @override
  String get offlineBannerSyncBtn => 'مزامنة';

  @override
  String offlineBannerAutoSynced(String count) {
    return 'عودة للاتصال! تمت مزامنة $count إجراءات';
  }

  @override
  String get offlineBannerSyncFailed => 'فشلت المزامنة لبعض الإجراءات';

  @override
  String teamInvitationCancelled(String email) {
    return 'تم إلغاء الدعوة لـ $email';
  }

  @override
  String teamInvitationResent(String email) {
    return 'تمت إعادة إرسال الدعوة إلى $email';
  }

  @override
  String teamInvitationCopied(String email) {
    return 'تمّ نسخ رابط الدعوة لـ $email';
  }

  @override
  String approvalsRequestedBy(String name) {
    return 'طلب من قبل $name';
  }

  @override
  String approvalsOldValue(String value) {
    return 'القديم: $value';
  }

  @override
  String approvalsNewValue(String value) {
    return 'الجديد: $value';
  }

  @override
  String alertsSeverityLabel(String severity) {
    return 'الخطورة $severity';
  }

  @override
  String get alertsStatusResolved => 'تمّ الحل';

  @override
  String get alertsStatusOpen => 'مفتوح';

  @override
  String get alertsMetricCritical => 'حرج';

  @override
  String get alertsFilterTitle => 'الفلاتر';

  @override
  String get alertsFilterSeverity => 'الخطورة';

  @override
  String get alertsFilterType => 'النوع';

  @override
  String get alertsFilterHotel => 'الفندق';

  @override
  String get alertsFilterProduct => 'المنتج';

  @override
  String get alertsFilterAll => 'الكل';

  @override
  String get alertsFilterClear => 'مسح الفلاتر';

  @override
  String get alertsFilterNoMatch => 'لا توجد تنبيهات تطابق الفلاتر الحالية.';

  @override
  String alertsFilterShowing(String count, String total) {
    return 'عرض $count من أصل $total';
  }

  @override
  String get settingsActionEditTitle => 'تعديل الإجراء المعلّق';

  @override
  String get settingsActionConflictTitle => 'حلّ تعارض المزامنة';

  @override
  String settingsActionAttempts(String count) {
    return 'المحاولات $count';
  }

  @override
  String settingsActionListAttempts(String count) {
    return 'المحاولات: $count';
  }

  @override
  String settingsActionListError(String message) {
    return 'خطأ: $message';
  }

  @override
  String get syncActionRefill => 'إعادة تعبئة';

  @override
  String get syncActionUndoRefill => 'تراجع عن إعادة التعبئة';

  @override
  String get syncActionCorrectionRequest => 'طلب تصحيح';

  @override
  String get syncActionBottleReplacement => 'استبدال العبوة';

  @override
  String get syncActionStockAdjustment => 'تعديل مخزون المتجر';

  @override
  String get syncActionPendingEdit => 'تعديل معلّق';

  @override
  String get userRoleAppAdmin => 'مسؤول التطبيق';

  @override
  String get userRoleAppManager => 'مدير التطبيق';

  @override
  String get userRoleHotelManager => 'مدير الفندق';

  @override
  String get userRoleHotelStaff => 'موظف الفندق';

  @override
  String get teamStatusActive => 'نشط';

  @override
  String get teamStatusInactive => 'غير نشط';

  @override
  String get teamHotelAll => 'جميع الفنادق';

  @override
  String get teamHotelNone => '—';

  @override
  String get invitationStatusPending => 'قيد الانتظار';

  @override
  String get invitationStatusAccepted => 'مقبولة';

  @override
  String get invitationStatusCancelled => 'ملغاة';

  @override
  String get invitationStatusExpired => 'منتهية';

  @override
  String get alertResolvedToast => 'تمّ حلّ التنبيه';

  @override
  String get alertDeletedToast => 'تم حذف التنبيه';

  @override
  String get alertResolveFailedToast =>
      'تعذّر حلّ التنبيه. يرجى المحاولة مرة أخرى.';

  @override
  String get alertDeleteFailedToast =>
      'تعذّر حذف التنبيه. يرجى المحاولة مرة أخرى.';

  @override
  String get notificationAcknowledgedToast => 'تم التأكيد';

  @override
  String get notificationMoreInfo => 'مزيد من المعلومات';

  @override
  String get bulkAdjustStockTitle => 'تعديل مخزون المتجر بالجملة';

  @override
  String get bulkAdjustStockHint =>
      'أدخل تعديلات الكمية التي ستنطبق على جميع المنتجات.';

  @override
  String get bulkAdjustStockSuccess =>
      'تم تطبيق تعديل مخزون المتجر بالجملة بنجاح';

  @override
  String get bulkAdjustStockOfflineQueued =>
      'تمت إضافة التعديلات بالجملة إلى قائمة المزامنة';

  @override
  String get resolveAll => 'حل الكل';

  @override
  String get deleteAll => 'حذف الكل';

  @override
  String alertsRefreshedToast(String count) {
    return 'تمّ إنشاء $count تنبيهات ذكيّة';
  }

  @override
  String get alertsEmptyTitle => 'لا توجد تنبيهات بعد';

  @override
  String get alertsEmptyMessage =>
      'حدّث التنبيهات الذكيّة لفحص مخزون المتجر وحدود إعادة التعبئة وعمر الزجاجات والموافقات المعلّقة.';

  @override
  String get alertsEmptyAction => 'تحديث التنبيهات';

  @override
  String get alertTypeLowBidonStock =>
      'مخزون المتجر من قوارير إعادة التعبئة منخفض';

  @override
  String alertLowBottleTitle(String product) {
    return 'انخفاض مخزون المتجر من زجاجات $product';
  }

  @override
  String alertLowBidonTitle(String product) {
    return 'انخفاض مخزون المتجر من قوارير إعادة التعبئة لـ $product';
  }

  @override
  String alertLowBottleBody(String hotel, String remain, String threshold) {
    return '$hotel: تبقى $remain زجاجات ممتلئة. الحد الأدنى هو $threshold.';
  }

  @override
  String alertLowBidonBody(String hotel, String remain, String threshold) {
    return '$hotel: تبقى $remain قوارير إعادة تعبئة ممتلئة. الحد الأدنى هو $threshold.';
  }

  @override
  String get alertTypeLowBottleStock => 'مخزون المتجر من زجاجات منخفض';

  @override
  String get alertTypeBottleAgeLimit => 'عمر الزجاجة';

  @override
  String alertBottleAgeLimitTitle(String room, String product) {
    return 'غرفة $room: زجاجة $product قديمة جدًا';
  }

  @override
  String alertBottleAgeLimitBody(String age, String limit) {
    return 'عمر الزجاجة $age يوم. الحد الأقصى هو $limit يوم.';
  }

  @override
  String get alertTypeRefillLimit => 'حد إعادة التعبئة';

  @override
  String alertRefillLimitTitle(String room, String product) {
    return 'غرفة $room: وصلت زجاجة $product إلى الحد الأقصى لإعادة التعبئة';
  }

  @override
  String alertRefillLimitBody(String used, String max) {
    return 'تم استخدام $used/$max من مرات إعادة التعبئة. استبدل الزجاجة وأعد تدويرها.';
  }

  @override
  String get alertTypePendingApproval => 'موافقة';

  @override
  String alertPendingApprovalTitle(String request) {
    return 'في انتظار الموافقة: $request';
  }

  @override
  String alertPendingApprovalBody(String name) {
    return 'مطلوب بواسطة $name.';
  }

  @override
  String get alertTypeSuspiciousActivity => 'نشاط مشبوه';

  @override
  String get alertTypeInactiveHotel => 'فندق غير نشط';

  @override
  String get refillEventApproved => 'تمّت الموافقة';

  @override
  String get refillEventRejected => 'تمّ الرفض';

  @override
  String get teamDeactivateAccountTooltip => 'تعطيل الحساب';

  @override
  String get teamReactivateAccountTooltip => 'إعادة تفعيل الحساب';

  @override
  String settingsSyncedSummary(String synced) {
    return 'تمّت مزامنة $synced إجراءات';
  }

  @override
  String settingsSyncedSummarySingular(String synced) {
    return 'تمّت مزامنة $synced إجراء';
  }

  @override
  String settingsSyncedWithFailures(String synced, String failed) {
    return 'تمّت مزامنة $synced، فشل $failed';
  }

  @override
  String get inviteAcceptHeading => 'قبول دعوة Ivra';

  @override
  String inviteSubtitleWithHotel(String name, String role, String hotel) {
    return 'تمّت دعوة $name بصفة $role في $hotel.';
  }

  @override
  String inviteSubtitleNoHotel(String name, String role) {
    return 'تمّت دعوة $name بصفة $role.';
  }

  @override
  String get inviteEmailMismatch =>
      'استخدم عنوان البريد الإلكتروني الذي أُرسلت إليه هذه الدعوة.';

  @override
  String get inviteAccountCreatedConfirm =>
      'تم إنشاء الحساب. أكّد بريدك الإلكتروني، ثم عُد إلى رابط الدعوة وأدخل نفس كلمة المرور لإكمال الانضمام.';

  @override
  String get inviteInvalidHeading => 'الدعوة غير متاحة';

  @override
  String get inviteInvalidBody =>
      'ربّما انتهت صلاحية هذه الدعوة، أو أُلغيت، أو تم قبولها مسبقًا.';

  @override
  String teamMemberReactivated(String name) {
    return 'تم إعادة تفعيل $name';
  }

  @override
  String teamMemberDeactivated(String name) {
    return 'تم تعطيل $name';
  }

  @override
  String settingsActionLastTried(String datetime) {
    return 'آخر محاولة $datetime';
  }

  @override
  String get settingsActionNeedsReview => 'الإجراء لا يزال بحاجة للمراجعة';

  @override
  String get teamInviteLinkUnavailable => 'رابط الدعوة غير متاح';

  @override
  String get teamCopyLink => 'نسخ رابط الدعوة';

  @override
  String get teamResendInvitation => 'إعادة إرسال الدعوة';

  @override
  String get teamCancelInvitation => 'إلغاء الدعوة';

  @override
  String get teamCannotInviteSelf => 'لا يمكنك دعوة نفسك';

  @override
  String get btnUpdate => 'تحديث';

  @override
  String get notFoundTitle => 'الصفحة غير موجودة';

  @override
  String get notFoundBody => 'الصفحة التي تبحث عنها غير موجودة أو تم نقلها.';

  @override
  String get notFoundButton => 'العودة إلى لوحة القيادة';

  @override
  String get downloadAppBannerText =>
      'للحصول على أفضل تجربة، قم بتنزيل تطبيق Android الخاص بنا.';

  @override
  String get downloadAppBannerButton => 'تنزيل التطبيق';

  @override
  String get sendPushTitle => 'إرسال إشعار';

  @override
  String get teamViewAs => 'العرض بصفة';

  @override
  String impersonationBanner(String name) {
    return 'العرض بصفة $name';
  }

  @override
  String get impersonationExit => 'خروج';

  @override
  String get pdfHeaderType => 'النوع';

  @override
  String get pdfHeaderPrevious => 'السابق';

  @override
  String get pdfHeaderNew => 'الجديد';

  @override
  String get pdfHeaderOccurredAt => 'تاريخ الحدوث';

  @override
  String get pdfHeaderNotes => 'ملاحظات';

  @override
  String get pdfHeaderProduct => 'المنتج';

  @override
  String get pdfHeader1LBottles => 'زجاجات 1 لتر';

  @override
  String get pdfHeader5LBidons => 'عبوات 5 لتر';

  @override
  String get pdfHeaderRecycle => 'إعادة تدوير';

  @override
  String get pdfHeaderFullBottles => 'زجاجات مملوءة';

  @override
  String get pdfHeaderEmptyBottles => 'زجاجات فارغة';

  @override
  String get pdfHeaderFullBidons => 'عبوات مملوءة';

  @override
  String get pdfHeaderOpenBidons => 'عبوات مفتوحة';

  @override
  String get pdfHeaderEmptyBidons => 'عبوات فارغة';

  @override
  String get pdfHeaderSeverity => 'الخطورة';

  @override
  String get pdfHeaderTitle => 'العنوان';

  @override
  String get pdfHeaderCreatedAt => 'تاريخ الإنشاء';

  @override
  String get approvalStatusApproved => 'تمت الموافقة';

  @override
  String get approvalStatusRejected => 'مرفوض';

  @override
  String get approvalStatusCancelled => 'ملغى';

  @override
  String get approvalStatusPending => 'قيد الانتظار';

  @override
  String get pdfTitleSuggestedOrders => 'طلبات Ivra المقترحة';

  @override
  String get pdfTitleInventorySnapshot => 'مخزون المتجر Ivra';

  @override
  String get pdfTitleRefillHistory => 'سجل تعبئة Ivra';

  @override
  String get pdfTitleOpenAlerts => 'تنبيهات Ivra المفتوحة';

  @override
  String get productHistoryTitle => 'سجل المنتج';

  @override
  String get productHistoryNoHistory => 'لا يوجد سجل مسجل لهذا المنتج.';

  @override
  String productHistoryRefill(String roomNumber) {
    return 'تمت إعادة التعبئة في الغرفة $roomNumber';
  }

  @override
  String productHistoryReplacement(String roomNumber) {
    return 'تم استبدال الزجاجة في الغرفة $roomNumber';
  }

  @override
  String get productHistoryAdjustment => 'تعديل مخزون المتجر يدويًا';

  @override
  String productHistoryActionBy(String user) {
    return 'بواسطة $user';
  }

  @override
  String productHistoryReason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get productHistoryDeltaFullBottles => 'زجاجات ممتلئة';

  @override
  String get productHistoryDeltaUsedBottles => 'زجاجات مستعملة';

  @override
  String get productHistoryDeltaFullBidons => 'زجاجات إعادة تعبئة ممتلئة';

  @override
  String get productHistoryDeltaOpenBidons => 'زجاجات إعادة تعبئة مفتوحة';

  @override
  String get productHistoryDeltaEmptyBidons => 'زجاجات إعادة تعبئة فارغة';

  @override
  String productHistoryNewBottle(String roomNumber) {
    return 'تم وضع زجاجة جديدة في الغرفة $roomNumber';
  }

  @override
  String get productHistoryFilterAll => 'الكل';

  @override
  String get productHistoryFilterRoom => 'عمليات الغرف';

  @override
  String get productHistoryFilterManual => 'التعديلات';

  @override
  String get productHistoryStatRefills => 'إعادات التعبئة';

  @override
  String get productHistoryStatReplacements => 'الاستبدالات';

  @override
  String get productHistoryStatAdjustments => 'التعديلات';

  @override
  String get inventoryEnforceTitle => 'مخزون المتجر غير كافٍ';

  @override
  String inventoryEnforceTemplateContent(
      String total, String product, String current, String needed) {
    return 'وضع $total زجاجة (زجاجات) من $product يتطلب مخزونًا للمتجر. يحتوي مخزون المتجر فقط على $current. هل ترغب في إضافة $needed زجاجة (زجاجات) تلقائيًا إلى مخزون المتجر والمتابعة؟';
  }

  @override
  String inventoryEnforceReplaceContent(String product, String room) {
    return 'استبدال زجاجة $product في الغرفة $room يتطلب زجاجة ممتلئة واحدة. مخزون المتجر يحتوي على 0. هل ترغب في إضافة زجاجة واحدة تلقائيًا إلى مخزون المتجر والمتابعة؟';
  }

  @override
  String housekeeperReplaceGetFromHotel(
      String product, String room, String count) {
    return 'استبدال $product في الغرفة $room يتطلب زجاجة ممتلئة واحدة، ولكنها ليست في مخزونك. ومع ذلك، تتوفر $count زجاجة في مخزون الفندق. هل ترغب في أخذ زجاجة واحدة من مخزون الفندق والمتابعة؟';
  }

  @override
  String housekeeperReplaceNotifyManager(String product, String room) {
    return 'استبدال $product في الغرفة $room يتطلب زجاجة ممتلئة واحدة، ولكنها ليست في مخزونك، وهي غير متوفرة في مخزون الفندق أيضًا. يرجى إبلاغ مدير الفندق.';
  }

  @override
  String housekeeperAddGetFromHotel(String product, String room, String count) {
    return 'إضافة $product في الغرفة $room يتطلب زجاجة ممتلئة واحدة، ولكنها ليست في مخزونك. ومع ذلك، تتوفر $count زجاجة في مخزون الفندق. هل ترغب في أخذ زجاجة واحدة من مخزون الفندق والمتابعة؟';
  }

  @override
  String housekeeperAddNotifyManager(String product, String room) {
    return 'إضافة $product في الغرفة $room يتطلب زجاجة ممتلئة واحدة، ولكنها ليست في مخزونك، وهي غير متوفرة في مخزون الفندق أيضًا. يرجى إبلاغ مدير الفندق.';
  }

  @override
  String housekeeperRefillGetFromHotel(
      String product, String room, String count) {
    return 'إعادة تعبئة $product في الغرفة $room يتطلب عبوة ممتلئة واحدة، ولكن ليس لديك أي عبوة مفتوحة أو ممتلئة في مخزونك. ومع ذلك، تتوفر $count عبوة في مخزون الفندق. هل ترغب في أخذ عبوة واحدة من مخزون الفندق والمتابعة؟';
  }

  @override
  String housekeeperRefillNotifyManager(String product, String room) {
    return 'إعادة تعبئة $product في الغرفة $room يتطلب عبوة ممتلئة واحدة، ولكن ليس لديك أي عبوة مفتوحة أو ممتلئة في مخزونك، وهي غير متوفرة في مخزون الفندق أيضًا. يرجى إبلاغ مدير الفندق.';
  }

  @override
  String get btnOk => 'موافق';

  @override
  String get inventoryEnforceBtnProceed => 'التعديل التلقائي والمتابعة';

  @override
  String get inventoryEnforceReasonTemplate =>
      'تعديل تلقائي لنموذج إنشاء الغرف';

  @override
  String get inventoryEnforceReasonReplace => 'تعديل تلقائي للاستبدال';

  @override
  String get inventoryEnforceOnboardingTitle => 'تهيئة مخزون المتجر';

  @override
  String inventoryEnforceOnboardingContent(String total) {
    return 'بما أن هذا فندق جديد، فلا توجد منتجات في مخزون المتجر. هل ترغب في تهيئة مخزون المتجر تلقائيًا بـ $total زجاجة لوضعها في الغرف؟';
  }

  @override
  String get authBtnCreateRole => 'إنشاء دور';

  @override
  String get authCreateRoleTitle => 'إنشاء دور مخصص';

  @override
  String get authRoleNameLabel => 'اسم الدور (أحرف صغيرة snake_case)';

  @override
  String get authRoleNameError =>
      'يجب أن يكون اسم الدور snake_case وبأحرف صغيرة (مثال: night_auditor)';

  @override
  String get authRoleDisplayNameLabel =>
      'اسم العرض المألوف (مثال: Night Auditor)';

  @override
  String get authRoleDisplayNameError => 'اسم العرض لا يمكن أن يكون فارغاً';

  @override
  String get authRoleDescLabel => 'الوصف';

  @override
  String get authCategoryCore => 'العمليات الأساسية';

  @override
  String get authCategoryManagement => 'الإدارة';

  @override
  String get authCategoryControl => 'الرقابة والموافقات';

  @override
  String get authCategoryAnalytics => 'التحليلات والبث';

  @override
  String get authCategorySecurity => 'الأمان والإدارة';

  @override
  String get authBulkGrantAll => 'منح الكل';

  @override
  String get authBulkRevokeAll => 'إلغاء الكل';

  @override
  String get authRoleCreatedSuccess => 'تم إنشاء الدور بنجاح.';

  @override
  String get authSearchHint => 'البحث في الصلاحيات...';

  @override
  String get authorizationsTitle => 'مصفوفة الصلاحيات';

  @override
  String get authorizationsHeader => 'مصفوفة الصلاحيات';

  @override
  String get authorizationsSubtitle =>
      'إدارة ميزات التطبيق وصلاحيات الإجراءات حسب دور المستخدم.';

  @override
  String get authorizationsPermission => 'الصلاحية';

  @override
  String get authorizationsUpdatedSuccessfully => 'تم تحديث الصلاحيات بنجاح.';

  @override
  String get roleAppAdmin => 'مدير التطبيق';

  @override
  String get roleAppManager => 'مشرف التطبيق';

  @override
  String get roleHotelManager => 'مدير الفندق';

  @override
  String get roleHotelStaff => 'موظف الفندق';

  @override
  String get permManageHotels => 'إدارة الفنادق';

  @override
  String get permManageHotelsDesc => 'إنشاء وتعديل وحذف الفنادق';

  @override
  String get permManageRooms => 'إدارة الغرف';

  @override
  String get permManageRoomsDesc => 'إضافة وتعديل وإزالة الغرف والطوابق';

  @override
  String get permManageProducts => 'إدارة المنتجات';

  @override
  String get permManageProductsDesc =>
      'تكوين أنواع المنتجات العالمية والكتالوجات';

  @override
  String get permManageTeam => 'إدارة الفريق';

  @override
  String get permManageTeamDesc => 'دعوة وإدارة أعضاء الفريق والأدوار';

  @override
  String get permSubmitEditRequests => 'تقديم طلبات التعديل';

  @override
  String get permSubmitEditRequestsDesc =>
      'تقديم طلبات تعديل الغرف والزجاجات والمخزون';

  @override
  String get permApproveCorrections => 'اعتماد التصحيحات';

  @override
  String get permApproveCorrectionsDesc =>
      'الموافقة على طلبات التغيير والتصحيح المعلقة أو رفضها';

  @override
  String get permViewApprovals => 'عرض الموافقات';

  @override
  String get permViewApprovalsDesc => 'الوصول إلى شاشة لوحة تحكم الموافقات';

  @override
  String get permViewAlerts => 'عرض التنبيهات';

  @override
  String get permViewAlertsDesc => 'عرض ومراقبة تنبيهات العمليات';

  @override
  String get permViewReports => 'عرض التقارير';

  @override
  String get permViewReportsDesc =>
      'الوصول إلى تقارير التحليلات ومخططات الأداء';

  @override
  String get permSendNotifications => 'إرسال إشعارات الهاتف';

  @override
  String get permSendNotificationsDesc => 'إنشاء وبث إشعارات الهاتف للتطبيق';

  @override
  String get permViewAuditLogs => 'عرض سجلات التدقيق الأمني';

  @override
  String get permViewAuditLogsDesc =>
      'فحص سجلات العمليات وتاريخ تسجيل الدخول المفصلة';

  @override
  String get permViewRooms => 'عرض الغرف';

  @override
  String get permViewRoomsDesc =>
      'عرض قائمة وحالات إعادة تعبئة الغرف وتفاصيلها';

  @override
  String get permViewInventory => 'عرض المخزون';

  @override
  String get permViewInventoryDesc => 'عرض حالة مخزون الفندق واقتراح الطلبات';

  @override
  String get permViewAuthorizations => 'عرض الصلاحيات';

  @override
  String get permViewAuthorizationsDesc =>
      'الوصول إلى شاشة إعدادات صلاحيات الأدوار وإدارتها';

  @override
  String get dialogRefillTitle => 'إعادة ملء الموزع';

  @override
  String get dialogRefillSliderLabel => 'نسبة إعادة التعبئة (الحجم المضاف):';

  @override
  String get dialogRefillPreExisting => 'السائل الموجود مسبقًا:';

  @override
  String get dialogRefillAdded => 'السائل المضاف حديثًا:';

  @override
  String get dialogRefillNotes => 'ملاحظات (اختياري)';

  @override
  String get dialogRefillConfirm => 'تأكيد إعادة التعبئة';

  @override
  String get femmeDeChambre => 'عاملة الغرف';

  @override
  String get checkoutStock => 'صرف مخزون';

  @override
  String get returnStock => 'إرجاع مخزون';

  @override
  String get housekeeperCart => 'عربتي';

  @override
  String get noAllocations => 'لا توجد حصص نشطة. قم بصرف مخزون للبدء.';

  @override
  String get fullBottles => 'زجاجات كاملة';

  @override
  String get openBidonVolumeLeft => 'الحجم المتبقي';

  @override
  String get housekeeperStockCheckedOut => 'تم صرف المخزون بنجاح!';

  @override
  String get housekeeperStockReturned => 'تم إرجاع المخزون بنجاح!';

  @override
  String get userRoleHousekeeper => 'عاملة الغرف';

  @override
  String get roomsBtnAddProduct => 'إضافة منتج';

  @override
  String roomsConfirmRemoveProduct(String productName, String roomNumber) {
    return 'هل أنت متأكد من رغبتك في إزالة المنتج \'$productName\' من الغرفة \'$roomNumber\'؟';
  }

  @override
  String get roomsProductRemoved => 'تمت إزالة المنتج';

  @override
  String get roomsProductAdded => 'تمت إضافة المنتج';

  @override
  String get roomsAddProductTitle => 'إضافة منتج إلى الغرفة';

  @override
  String get roomsSelectProduct => 'اختر المنتج';
}
