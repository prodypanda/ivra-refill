// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppL10nFr extends AppL10n {
  AppL10nFr([String locale = 'fr']) : super(locale);

  @override
  String get markAsRead => 'Marquer comme lu';

  @override
  String confirmDeleteHotel(String hotelName) {
    return 'Voulez-vous vraiment supprimer l\'hôtel \'$hotelName\' ? Cette action est irréversible et supprimera définitivement toutes les chambres, affectations de personnel et enregistrements associés.';
  }

  @override
  String confirmDeleteRoom(String roomNumber) {
    return 'Voulez-vous vraiment supprimer la chambre \'$roomNumber\' ? Cette action est irréversible et supprimera définitivement tous les produits et l\'historique associés.';
  }

  @override
  String confirmDeleteFloor(String floorNumber) {
    return 'Voulez-vous vraiment supprimer l\'étage \'$floorNumber\' et toutes ses chambres ? Cette action est irréversible.';
  }

  @override
  String confirmDeleteUser(String userName) {
    return 'Voulez-vous vraiment supprimer le membre de l\'équipe \'$userName\' ? Cette action est irréversible et il perdra immédiatement l\'accès à l\'application.';
  }

  @override
  String confirmDeleteProduct(String productName) {
    return 'Voulez-vous vraiment supprimer le produit \'$productName\' ? Cette action est irréversible et affectera le suivi des stocks.';
  }

  @override
  String get confirmDeleteAlert =>
      'Voulez-vous vraiment supprimer cette alerte ? Cette action est irréversible.';

  @override
  String get confirmDeleteAllAlerts =>
      'Voulez-vous vraiment supprimer toutes les alertes ? Cette action est irréversible et effacera toutes les notifications actuelles.';

  @override
  String get clearAuditLogs => 'Effacer les journaux';

  @override
  String get confirmAction => 'Confirmer l\'action';

  @override
  String get confirmClearLogs =>
      'Voulez-vous vraiment effacer tous les journaux d\'audit ? Cette action est irréversible.';

  @override
  String get btnConfirm => 'Confirmer';

  @override
  String get composeMessage => 'Rédiger le message';

  @override
  String get notificationTitle => 'Titre de la notification';

  @override
  String get notificationDefaultTitle => 'Nouvelle notification';

  @override
  String get notificationChannelName => 'Notifications importantes';

  @override
  String get notificationChannelDescription =>
      'Ce canal est utilisé pour les notifications importantes.';

  @override
  String get notificationTitleHint => 'ex: Nouvelle fonctionnalité!';

  @override
  String get notificationBody => 'Corps de la notification';

  @override
  String get notificationBodyHint => 'Entrez le message ici...';

  @override
  String get actionButtons => 'Boutons d\'action';

  @override
  String get actionButtonsHint => 'ex: Ignorer, Ouvrir l\'application';

  @override
  String get pageToOpen => 'Page à ouvrir';

  @override
  String get menuSendPush => 'Envoyer Push';

  @override
  String get actionAndRouting => 'Action et Routage';

  @override
  String get openSpecificPage => 'Ouvrir une page spécifique (Optionnel)';

  @override
  String get defaultNoPage => 'Défaut (Aucune page spécifique)';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get dashboardOpsAnalytics => 'Analyses des opérations';

  @override
  String get dashboardExport => 'Exporter';

  @override
  String get dashboardDaily => 'Quotidien';

  @override
  String get dashboardWeekly => 'Hebdomadaire';

  @override
  String get dashboardMonthly => 'Mensuel';

  @override
  String get dashboardRoomsAttention => 'Chambres nécessitant de l\'attention';

  @override
  String get dashboardProductUsage => 'Utilisation du produit';

  @override
  String get dashboardUsageByFloor => 'Utilisation par étage';

  @override
  String get dashboardStockForecast => 'Prévision d\'épuisement des stocks';

  @override
  String get dashboardUnusualPatterns => 'Modèles inhabituels';

  @override
  String get dashboardNoStockData => 'Aucune donnée de stock';

  @override
  String dashboardRoomsRequireReview(String count) {
    return '$count chambres nécessitent une révision';
  }

  @override
  String get dashboardNoUnusualPatterns => 'Aucun modèle inhabituel détecté';

  @override
  String get dashboardHighPriority => 'Élevée';

  @override
  String get dashboardStable => 'Stable';

  @override
  String get errorLoadingHotels => 'Erreur lors du chargement des hôtels';

  @override
  String get sending => 'Envoi en cours...';

  @override
  String roomsEditRoomTitle(String roomNumber) {
    return 'Mettre à jour la chambre $roomNumber';
  }

  @override
  String roomsEditProductTitle(String productName, String roomNumber) {
    return 'Mettre à jour la bouteille de $productName dans la chambre $roomNumber';
  }

  @override
  String get inventory => 'Stock magasin';

  @override
  String get alerts => 'Alertes';

  @override
  String get approvals => 'Approbations';

  @override
  String get actionButtonsAndroid => 'Boutons d\'action (Android uniquement)';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get acknowledge => 'Confirmer';

  @override
  String get openApp => 'Ouvrir l\'application';

  @override
  String get sendNotification => 'Envoyer une notification';

  @override
  String get targetAudience => 'Public cible';

  @override
  String get allUsers => 'Tous les utilisateurs';

  @override
  String get byRole => 'Par Rôle';

  @override
  String get byHotel => 'Par Hôtel';

  @override
  String get byUserEmail => 'Par e-mail';

  @override
  String get selectRole => 'Sélectionner un rôle';

  @override
  String get selectHotel => 'Sélectionner un hôtel';

  @override
  String get userEmail => 'Email de l\'utilisateur';

  @override
  String get menuAuditLogs => 'Journaux d\'audit';

  @override
  String get auditLogs => 'Journaux d\'audit';

  @override
  String get auditAction => 'Action';

  @override
  String get auditDevice => 'Appareil / OS';

  @override
  String get auditIpAddress => 'Adresse IP';

  @override
  String get auditTimestamp => 'Heure';

  @override
  String get auditUser => 'Utilisateur';

  @override
  String get enterSpecificUserEmail => 'Entrez un e-mail spécifique';

  @override
  String get dispatchNotification => 'Diffuser la notification';

  @override
  String get pleaseEnterTitleBody => 'Veuillez entrer un titre et un corps';

  @override
  String get pleaseSelectTarget => 'Veuillez sélectionner une valeur cible';

  @override
  String notificationSent(String successCount, String failureCount) {
    return 'Envoyé : $successCount succès, $failureCount échecs';
  }

  @override
  String get dashboardShort => 'T. de bord';

  @override
  String get dashboardHeroTitle => 'Aujourd’hui chez Ivra';

  @override
  String get dashboardRefillActivity =>
      'Activité de recharge (7 derniers jours)';

  @override
  String get refillActivity => 'Activité de recharge';

  @override
  String get myCompletedTasksThisWeek =>
      'Mes recharges terminées cette semaine';

  @override
  String get last7Days => '7 derniers jours';

  @override
  String get lastMonth => 'Mois dernier';

  @override
  String get lastYear => 'L\'année dernière';

  @override
  String get allHotels => 'Tous les hôtels';

  @override
  String get monthJan => 'Janv.';

  @override
  String get monthFeb => 'Févr.';

  @override
  String get monthMar => 'Mars';

  @override
  String get monthApr => 'Avr.';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthJun => 'Juin';

  @override
  String get monthJul => 'Juil.';

  @override
  String get monthAug => 'Août';

  @override
  String get monthSep => 'Sept.';

  @override
  String get monthOct => 'Oct.';

  @override
  String get monthNov => 'Nov.';

  @override
  String get monthDec => 'Déc.';

  @override
  String get dayMon => 'Lun';

  @override
  String get dayTue => 'Mar';

  @override
  String get dayWed => 'Mer';

  @override
  String get dayThu => 'Jeu';

  @override
  String get dayFri => 'Ven';

  @override
  String get daySat => 'Sam';

  @override
  String get daySun => 'Dim';

  @override
  String get chartRefills => 'recharges';

  @override
  String get teamEditProfile => 'Modifier le profil';

  @override
  String get teamEditProfileSuccess => 'Profil mis à jour';

  @override
  String get hotels => 'Hôtels';

  @override
  String get rooms => 'Chambres';

  @override
  String get products => 'Produits';

  @override
  String get team => 'Equipe';

  @override
  String get account => 'Compte';

  @override
  String get reports => 'Rapports';

  @override
  String get settings => 'Paramètres';

  @override
  String get more => 'Plus';

  @override
  String get refill => 'Remplir';

  @override
  String get undo => 'Annuler';

  @override
  String get correction => 'Correction';

  @override
  String get pending => 'En attente';

  @override
  String get suggestedOrders => 'Commandes suggérées';

  @override
  String get bottles => 'Bouteilles';

  @override
  String get bidons => 'Bouteilles de recharge';

  @override
  String get language => 'Langue';

  @override
  String get demoMode => 'Mode démo';

  @override
  String get downloadCsv => 'Télécharger CSV';

  @override
  String get downloadPdf => 'Télécharger PDF';

  @override
  String get reportRefillHistoryTitle => 'Historique de recharge';

  @override
  String get reportRefillHistoryBody =>
      'Exporter les recharges récentes par hôtel, chambre, produit, utilisateur et heure.';

  @override
  String get reportSuggestedOrdersBody =>
      'Exporter les bouteilles, bouteilles de recharge et recommandations de recyclage.';

  @override
  String get reportInventorySnapshotTitle => 'Instantané du stock';

  @override
  String get reportInventorySnapshotBody =>
      'Exporter le stock actuel de bouteilles et bouteilles de recharge par hôtel et produit.';

  @override
  String get reportOpenAlertsTitle => 'Alertes ouvertes';

  @override
  String get reportOpenAlertsBody =>
      'Exporter les alertes de stock bas, remplacement, inactivité et activité suspecte.';

  @override
  String get scheduleReportEmail => 'Planifier le rapport par e-mail';

  @override
  String get scheduleReportEmailHint =>
      'Nous enverrons un résumé de ce rapport à cette adresse chaque lundi.';

  @override
  String get scheduledReportEmailDrafted =>
      'Rapport par e-mail planifié avec succès';

  @override
  String get reportFilterDateRange => 'Filtrer par plage de dates';

  @override
  String get reportAllProducts => 'Tous les produits';

  @override
  String get reportAllRooms => 'Toutes les chambres';

  @override
  String get reportClearFilters => 'Effacer les filtres';

  @override
  String get reportFiltersApplyExports =>
      'Remarque : Les filtres s\'appliquent à la fois aux indicateurs de l\'écran et aux exports téléchargés.';

  @override
  String get reportAnalyticsTitle => 'Aperçu analytique';

  @override
  String get reportKpiRefills => 'Recharges totales';

  @override
  String get reportKpiCorrections => 'Corrections de stock';

  @override
  String get reportKpiReplacements => 'Remplacements';

  @override
  String get reportKpiActiveRooms => 'Chambres actives';

  @override
  String get reportTrendChart =>
      'Tendance de l\'activité de recharge (14 derniers jours)';

  @override
  String get reportUsageByProduct => 'Recharges par produit';

  @override
  String get reportUsageByRoom => 'Recharges par chambre';

  @override
  String get reportNoAnalyticsData =>
      'Aucune activité enregistrée pour cette période.';

  @override
  String get exportFailed => 'Échec de l\'exportation';

  @override
  String get metricHotels => 'Hôtels';

  @override
  String get metricRooms => 'Chambres';

  @override
  String get metricPendingApprovals => 'Approbations en attente';

  @override
  String get metricOpenAlerts => 'Alertes ouvertes';

  @override
  String get metricBottlesToReplace => 'Bouteilles à remplacer';

  @override
  String get metricLowStockProducts => 'Produits en stock bas';

  @override
  String get inventoryTableProduct => 'Produit';

  @override
  String get inventoryTableFullBottles => 'Bouteilles pleines';

  @override
  String inventoryTableFullBottlesWithPump(String size) {
    return 'Bouteilles pleines de $size avec pompe';
  }

  @override
  String inventoryTableFullBottlesWithoutPump(String size) {
    return 'Bouteilles pleines de $size sans pompe';
  }

  @override
  String get inventoryTableFullBottlesWithPumpGeneric =>
      'Bouteilles pleines avec pompe';

  @override
  String get inventoryTableFullBottlesWithoutPumpGeneric =>
      'Bouteilles pleines sans pompe';

  @override
  String get inventoryCollapseHeader => 'Bouteilles vides & ouvertes';

  @override
  String inventoryTableEmptyBottles(String months) {
    return 'Bouteilles remplacées après $months mois (Utilisées)';
  }

  @override
  String get inventoryTableEmptyBottlesGeneric =>
      'Bouteilles remplacées (Utilisées)';

  @override
  String get inventoryTableEmptyBidons => 'Bouteilles de recharge vides';

  @override
  String inventoryTableFullBidons(String size) {
    return 'Bouteilles de recharge pleines de $size';
  }

  @override
  String get inventoryTableFullBidonsGeneric =>
      'Bouteilles de recharge pleines';

  @override
  String get inventoryTableOpenBidons => 'Bouteilles de recharge usagées';

  @override
  String get inventoryTableStatus => 'Statut';

  @override
  String get errorUniqueViolation => 'Cet enregistrement existe déjà.';

  @override
  String get errorForeignKeyViolation => 'Enregistrement associé introuvable.';

  @override
  String get errorPermissionDenied =>
      'Vous n\'avez pas la permission d\'effectuer cette action.';

  @override
  String get errorGeneric =>
      'Une erreur inattendue s\'est produite. Veuillez réessayer.';

  @override
  String get inventoryStatusHealthy => 'Sain';

  @override
  String get inventoryStatusLowStock => 'Stock bas';

  @override
  String get auditFilterAllActions => 'Toutes les actions';

  @override
  String get sortNameAsc => 'Nom (A-Z)';

  @override
  String get sortNameDesc => 'Nom (Z-A)';

  @override
  String get sortMostFullBottles => 'Plus de bouteilles pleines';

  @override
  String get sortMostEmptyBottles => 'Plus de bouteilles vides';

  @override
  String get bulkAdjustSelectProducts => 'Sélectionner les produits';

  @override
  String get bulkAdjustSelectAll => 'Tout sélectionner';

  @override
  String get bulkAdjustDeselectAll => 'Tout désélectionner';

  @override
  String get bulkAdjustNoProductsSelected =>
      'Veuillez sélectionner au moins un produit.';

  @override
  String orderNewBottlesText(String count) {
    return 'Commander $count nouvelles bouteilles 1L';
  }

  @override
  String orderNewBidonsText(String count) {
    return 'Commander $count nouvelles bouteilles de recharge 5L';
  }

  @override
  String recycleBottlesText(String count) {
    return 'Recycler $count bouteilles';
  }

  @override
  String get bottleCannotRefillRecycled =>
      'Cette bouteille a été recyclée et ne peut pas être rechargée. Veuillez la remplacer.';

  @override
  String get adjustStockTitle => 'Ajuster le stock';

  @override
  String get hotelRoomsTracked => 'chambres suivies';

  @override
  String get hotelPendingChip => 'en attente';

  @override
  String get hotelLabelName => 'Nom de l\'hôtel';

  @override
  String get hotelLabelLegalName => 'Nom légal';

  @override
  String get hotelLabelState => 'Gouvernorat';

  @override
  String get hotelLabelCountry => 'Pays';

  @override
  String get hotelLabelContactName => 'Nom du contact';

  @override
  String get hotelLabelEmail => 'E-mail';

  @override
  String get hotelLabelPhone => 'Téléphone';

  @override
  String get hotelLabelAddress => 'Adresse';

  @override
  String get hotelLabelNotes => 'Notes';

  @override
  String get btnCreate => 'Créer';

  @override
  String get btnCancel => 'Annuler';

  @override
  String get btnSave => 'Enregistrer';

  @override
  String get btnSubmitRequest => 'Soumettre la demande';

  @override
  String get demoModeDescription =>
      'Simulations locales utilisant des modèles de base de données.';

  @override
  String get offlineModeDescription =>
      'File d\'attente des actions hors ligne pour synchronisation ultérieure.';

  @override
  String get syncQueueHeader => 'File de synchronisation';

  @override
  String get syncNow => 'Synchroniser';

  @override
  String get itemsToSync => 'actions en attente';

  @override
  String get editRequestQueued => 'Demande de modification mise en attente';

  @override
  String get editRequestSubmitted => 'Demande de modification soumise';

  @override
  String get hotelUpdated => 'Informations de l\'hôtel mises à jour';

  @override
  String get hotelCreatedSuccessfully => 'Hôtel créé avec succès';

  @override
  String get requiredField => 'Requis';

  @override
  String get enterNumberError => 'Entrez un nombre';

  @override
  String get createHotel => 'Créer un hôtel';

  @override
  String get requestHotelEdit => 'Demander la modification';

  @override
  String get authTitleCannotAccess =>
      'Ce compte nécessite une invitation pour accéder à Ivra.';

  @override
  String get authBtnGoogleSignIn => 'Se connecter avec Google';

  @override
  String get authBtnSignOut => 'Se déconnecter';

  @override
  String get authLabelEmail => 'E-mail';

  @override
  String get authLabelPassword => 'Mot de passe';

  @override
  String get authShowPassword => 'Afficher le mot de passe';

  @override
  String get authHidePassword => 'Masquer le mot de passe';

  @override
  String get authBtnSignIn => 'Se connecter';

  @override
  String get authBtnForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authResetPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get setPasswordTitle => 'Définir votre mot de passe';

  @override
  String get setPasswordBody =>
      'Veuillez définir un mot de passe sécurisé pour votre compte afin de finaliser votre inscription.';

  @override
  String get setPasswordButton => 'Définir le mot de passe';

  @override
  String get authBtnSendResetLink => 'Envoyer le lien de réinitialisation';

  @override
  String get authResetLinkSent => 'Lien de réinitialisation envoyé à';

  @override
  String get authValidationEmailRequired => 'L\'e-mail est requis';

  @override
  String get authValidationEmailInvalid => 'Entrez une adresse e-mail valide';

  @override
  String get authValidationPasswordRequired => 'Le mot de passe est requis';

  @override
  String get authValidationPasswordTooShort =>
      'Le mot de passe doit comporter au moins 8 caractères';

  @override
  String get authValidationPasswordsDoNotMatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get authResetNewPasswordTitle => 'Créer un nouveau mot de passe';

  @override
  String get authLabelNewPassword => 'Nouveau mot de passe';

  @override
  String get authLabelConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get authBtnUpdatePassword => 'Mettre à jour le mot de passe';

  @override
  String get authBtnReturnToApp => 'Retourner à l\'application';

  @override
  String get authPasswordUpdatedSuccess =>
      'Mot de passe mis à jour avec succès.';

  @override
  String get authUnexpectedError =>
      'Une erreur est survenue. Réessayez ou contactez le support si le problème persiste.';

  @override
  String get asyncErrorTitle => 'Impossible de charger cette section';

  @override
  String get btnRetry => 'Réessayer';

  @override
  String get authProfileLoadErrorTitle => 'Impossible de charger votre profil.';

  @override
  String get authProfileLoadErrorBody =>
      'Il s\'agit généralement d\'un problème de connexion temporaire. Veuillez réessayer.';

  @override
  String get authAccountDeactivated =>
      'Ce compte a été désactivé. Contactez votre administrateur pour y accéder.';

  @override
  String get settingsPayloadInvalidJson =>
      'La charge utile doit être un objet JSON.';

  @override
  String exportDownloadStarted(String fileName) {
    return 'Téléchargement de $fileName commencé';
  }

  @override
  String exportSaved(String fileName, String path) {
    return '$fileName enregistré dans $path';
  }

  @override
  String settingsPendingSync(String count) {
    return 'Synchronisation en attente ($count)';
  }

  @override
  String get splashTagline => 'Solutions d\'hôtellerie durable';

  @override
  String get accountSaveFailed =>
      'Impossible d\'enregistrer votre profil. Réessayez.';

  @override
  String get accountPasswordChangeFailed =>
      'Impossible de changer votre mot de passe. Réessayez.';

  @override
  String get accountSignOutFailed =>
      'Impossible de se déconnecter. Vérifiez votre connexion et réessayez.';

  @override
  String get hotelCreateFailed => 'Impossible de créer l\'hôtel. Réessayez.';

  @override
  String get hotelUpdateFailed =>
      'Impossible de mettre à jour l\'hôtel. Réessayez.';

  @override
  String get teamInviteFailed =>
      'Impossible d\'envoyer l\'invitation. Réessayez.';

  @override
  String get teamHotelsUpdateFailed =>
      'Impossible de mettre à jour les affectations d\'hôtels. Réessayez.';

  @override
  String get roomsTooltipCreateTemplate => 'Créer un modèle de chambre';

  @override
  String get roomsNoRoomsFound => 'Aucune chambre ni produit trouvé.';

  @override
  String roomsScanConfirmFromCart(String product, String count) {
    return 'Le produit \"$product\" n\'est pas actuellement assigné à cette chambre, mais vous en avez $count dans votre panier. Souhaitez-vous en prendre 1 dans votre panier et l\'assigner à cette chambre ?';
  }

  @override
  String roomsScanConfirmFromHotel(String product, String count) {
    return 'Le produit \"$product\" n\'est pas dans cette chambre. Il y a $count bouteilles dans l\'inventaire de l\'hôtel. Souhaitez-vous en prendre 1 et l\'assigner à cette chambre ?';
  }

  @override
  String get roomsNoProducts => 'Aucun produit attribué à cette chambre.';

  @override
  String get roomsStatusNoProducts => 'Aucun produit';

  @override
  String get roomsSearchEmptyHint =>
      'Essayez de modifier votre recherche ou vos filtres.';

  @override
  String get roomsEmptyHotelWithTemplate =>
      'Ajoutez votre première chambre via le bouton de modèle ci-dessus.';

  @override
  String get roomsEmptyHotelNoTemplate =>
      'Aucune chambre n\'a encore été attribuée à cet hôtel.';

  @override
  String get roomsLabelRoom => 'Chambre';

  @override
  String get bottleStatusActive => 'Active';

  @override
  String get bottleStatusNeedsRefill => 'À recharger';

  @override
  String get bottleStatusRefilled => 'Rechargée';

  @override
  String get bottleStatusRefillLimitReached => 'Limite de recharge atteinte';

  @override
  String get bottleStatusTooOld => 'Trop ancienne';

  @override
  String get bottleStatusNeedsReplacement => 'À remplacer';

  @override
  String get bottleStatusRecycled => 'Recyclée';

  @override
  String get bottleStatusDamaged => 'Endommagée';

  @override
  String get bottleStatusLost => 'Perdue';

  @override
  String get roomsLabelFloor => 'Étage';

  @override
  String get roomsLabelRefills => 'Recharges';

  @override
  String get roomsLabelAge => 'Âge';

  @override
  String get roomsLabelDaysUnit => 'j';

  @override
  String get roomsRefillQueued => 'Recharge mise en attente pour la chambre';

  @override
  String get roomsRefillRecorded => 'Recharge enregistrée pour la chambre';

  @override
  String get roomsBtnBottleEdit => 'Modifier la bouteille';

  @override
  String get roomsBtnReplaceBottle => 'Remplacer la bouteille';

  @override
  String get roomsBtnRefillBottle => 'Remplir la bouteille';

  @override
  String get roomsBtnRoomEdit => 'Modifier la chambre';

  @override
  String get roomsBtnHistory => 'Historique';

  @override
  String get roomsBtnMoreActions => 'Plus d\'actions';

  @override
  String get roomsBtnMarkDamaged => 'Marquer comme endommagé';

  @override
  String get roomsBtnMarkLost => 'Marquer comme perdu';

  @override
  String get roomsLabelProofPhoto => 'Photo de preuve';

  @override
  String get roomsNotesOptional => 'Notes (Optionnel)';

  @override
  String get roomsLabelUploadedProof => 'Preuve téléchargée';

  @override
  String get roomsUploadProofAction => 'Télécharger une photo';

  @override
  String get roomsReplacementQueued =>
      'Remplacement de bouteille mis en attente pour la chambre';

  @override
  String get roomsReplacementRecorded => 'Bouteille remplacée pour la chambre';

  @override
  String get roomsReplacementNotes =>
      'Bouteille remplacée depuis le flux chambre';

  @override
  String get roomsStatusAllOk => 'Tout est OK';

  @override
  String get roomsStatusAttentionRequired => 'Attention requise';

  @override
  String get roomsStatusRefillNeeded => 'Recharge requise';

  @override
  String get roomsSearchPlaceholder => 'Rechercher une chambre...';

  @override
  String get roomsRecentTitle => 'Chambres récentes';

  @override
  String get roomsRecentClear => 'Effacer';

  @override
  String get roomsGestionExpressQr => 'Gestion Express (QR)';

  @override
  String get roomsGestionQr => 'Gestion des QR Codes';

  @override
  String get expressQrTitle => 'Gestion Express (QR)';

  @override
  String get expressQrSubtitle =>
      'Autoriser le scan direct des QR codes au niveau du distributeur';

  @override
  String get roomsSelectHotelFirst => 'Sélectionner un hôtel...';

  @override
  String get roomsViewDetailed => 'Vue détaillée';

  @override
  String get roomsViewCompact => 'Vue compacte';

  @override
  String get roomsCollapseAll => 'Tout réduire';

  @override
  String get roomsExpandAll => 'Tout développer';

  @override
  String get roomsBtnAddRoom => 'Ajouter une chambre';

  @override
  String get roomsDialogAddRoomTitle => 'Ajouter une chambre à l\'étage';

  @override
  String get roomsMsgRoomAdded => 'Chambre ajoutée';

  @override
  String get roomsMsgRoomAddQueued =>
      'Création de la chambre mise en file d\'attente';

  @override
  String get roomsHistoryRefill => 'Recharge';

  @override
  String get roomsHistoryNewBottle => 'Nouvelle bouteille placée';

  @override
  String roomsHistoryStatusChanged(String oldValue, String newValue) {
    return 'Statut modifié de $oldValue à $newValue';
  }

  @override
  String get roomsFilterAll => 'Tout';

  @override
  String get roomsDialogBottleEditTitle =>
      'Demander la modification de bouteille pour la chambre';

  @override
  String get roomsLabelBottleStatus => 'Statut de la bouteille';

  @override
  String get roomsLabelBottleStartDate => 'Date de début de la bouteille';

  @override
  String get roomsValidationEnterValidDate => 'Entrez une date valide';

  @override
  String get roomsMsgEditRequestQueued =>
      'Demande de modification de bouteille mise en attente';

  @override
  String get roomsMsgDetailsUpdated => 'Détails de la bouteille mis à jour';

  @override
  String get roomsMsgEditRequestSubmitted =>
      'Demande de modification de bouteille soumise';

  @override
  String get roomsDialogRoomEditTitle =>
      'Demander la modification pour la chambre';

  @override
  String get roomsLabelRoomNumber => 'Numéro de chambre';

  @override
  String get roomsLabelFloorNumber => 'Numéro d\'étage';

  @override
  String get roomsMsgRoomEditQueued =>
      'Demande de modification de chambre mise en attente';

  @override
  String get roomsMsgRoomDetailsUpdated => 'Détails de la chambre mis à jour';

  @override
  String get roomsMsgRoomEditSubmitted =>
      'Demande de modification de chambre soumise';

  @override
  String get roomsMsgRequestRoomEdit => 'Mettre à jour la chambre';

  @override
  String get roomsDialogHistoryTitle => 'historique';

  @override
  String get roomsNoHistoryRecorded =>
      'Aucun historique de recharge n\'a encore été enregistré.';

  @override
  String get roomsMsgUndoQueued => 'Annulation mise en attente';

  @override
  String get roomsMsgRefillUndone => 'Recharge annulée';

  @override
  String get roomsBtnClose => 'Fermer';

  @override
  String get qrScanTitle => 'Scanner le code QR';

  @override
  String get qrScanPlaceholder => 'Saisir le code QR manuellement...';

  @override
  String get qrDemoCodes => 'Codes QR de démonstration';

  @override
  String get qrActionPrompt => 'Choisir une action';

  @override
  String qrActionMessage(String product) {
    return 'Que voulez-vous faire pour $product ?';
  }

  @override
  String get qrActionRefill => 'Recharger la bouteille';

  @override
  String get qrActionReplace => 'Remplacer la bouteille';

  @override
  String get hotelNotFound => 'Hôtel introuvable';

  @override
  String get productNotFound => 'Produit introuvable';

  @override
  String get qrAccessDeniedMessage =>
      'Vous n\'êtes pas autorisé à effectuer des actions dans cet hôtel.';

  @override
  String get roomsFillCount => 'Nombre de recharges';

  @override
  String get roomsBottleStatus => 'État du distributeur';

  @override
  String get btnBack => 'Retour';

  @override
  String get qrActionSuccess => 'Action réussie';

  @override
  String get qrActionFailed => 'Échec de l\'action';

  @override
  String get qrUpdatedStatus => 'État du distributeur mis à jour :';

  @override
  String get qrScanAnother => 'Scanner un autre code QR';

  @override
  String get qrReturnRooms => 'Retour aux chambres';

  @override
  String get qrTryScanAgain => 'Réessayer le scan';

  @override
  String qrFloorRoom(String floor, String room) {
    return 'Étage $floor • Chambre $room';
  }

  @override
  String qrRoomFloor(String room, String floor) {
    return 'Chambre $room • Étage $floor';
  }

  @override
  String get qrCameraPermission => 'Permission caméra refusée';

  @override
  String get qrCameraUnavailable => 'Caméra non disponible';

  @override
  String qrHotelNotFoundMessage(String hotel) {
    return 'Impossible de trouver l\'hôtel : « $hotel »';
  }

  @override
  String qrProductNotFoundMessage(String room, String floor, String sku) {
    return 'La chambre $room (étage $floor) ne contient pas le produit SKU : « $sku »';
  }

  @override
  String get qrGenerateTabScan => 'Scanner code QR';

  @override
  String get qrGenerateTabGenerate => 'Générer codes QR';

  @override
  String get qrGenerateHotel => 'Hôtel';

  @override
  String get qrGenerateScope => 'Type d\'étiquette QR';

  @override
  String get qrGenerateScopeRoom => 'Porte de chambre (sans SKU)';

  @override
  String get qrGenerateScopeDispenser => 'Distributeur (avec SKU)';

  @override
  String get qrGenerateRoom => 'Chambre';

  @override
  String get qrGenerateProduct => 'Produit';

  @override
  String get qrGenerateAllRooms => 'Toutes les chambres';

  @override
  String get qrGenerateAllProducts => 'Tous les produits';

  @override
  String get qrGenerateBtnDownload => 'Générer & Télécharger le PDF';

  @override
  String get qrGenerateDownloading => 'Génération du PDF...';

  @override
  String get qrGenerateSuccess => 'PDF généré et téléchargé avec succès';

  @override
  String get settingsScannerHeader => 'Paramètres du scanner';

  @override
  String get settingsPrecisionScanTitle => 'Fenêtre de scan de précision';

  @override
  String get settingsPrecisionScanSubtitle =>
      'Scanner uniquement les codes alignés au centre du viseur';

  @override
  String get settingsTapToScanTitle => 'Appuyer pour scanner';

  @override
  String get settingsTapToScanSubtitle =>
      'Appuyez sur un cadre de code QR détecté pour le scanner';

  @override
  String get qrConfirmAssignTitle => 'Produit non placé';

  @override
  String qrConfirmAssignMessage(String product, String room) {
    return 'Le produit $product n\'est pas attribué à la chambre $room. Ajouter 1 pièce à l\'inventaire et l\'attribuer à la chambre ?';
  }

  @override
  String get qrAssignSuccess => 'Produit attribué et rechargé avec succès';

  @override
  String get qrActionCanceled => 'Opération annulée';

  @override
  String get qrActionCanceledMessage =>
      'Vous avez choisi de ne pas attribuer le produit. Vous pouvez scanner un autre code ou revenir aux chambres.';

  @override
  String get scanAssignTitle => 'Assigner le produit à la chambre';

  @override
  String get scanAssignSuccess => 'Produit assigné avec succès';

  @override
  String get scanAssignFailed => 'Échec de l\'assignation';

  @override
  String scanAssignInStock(String count) {
    return '$count en stock — 1 sera déduit et assigné à la chambre';
  }

  @override
  String get scanAssignOutOfStock =>
      'Rupture de stock — 1 unité sera auto-ajoutée à l\'inventaire puis assignée';

  @override
  String get scanAssignDescription =>
      'Ce produit n\'est pas encore assigné à cette chambre. Appuyez ci-dessous pour l\'assigner.';

  @override
  String get scanAssignButton => 'Assigner à la chambre';

  @override
  String get scanAssignAutoAdd => 'Ajouter à l\'inventaire et assigner';

  @override
  String get scanAssignAutoAddTitle => 'Ajouter à l\'inventaire ?';

  @override
  String scanAssignAutoAddMessage(String product) {
    return 'Le produit \"$product\" est en rupture de stock. Voulez-vous ajouter automatiquement 1 unité à l\'inventaire et l\'assigner à cette chambre ?';
  }

  @override
  String get scanAssignConfirm => 'Oui, ajouter et assigner';

  @override
  String scanAssignSuccessMessage(String product, String room, String floor) {
    return 'Le produit $product a été assigné à la chambre $room (Étage $floor).';
  }

  @override
  String get qrMultipleDetected =>
      'Plusieurs codes QR détectés. Appuyez pour sélectionner :';

  @override
  String qrUnknownSku(String sku) {
    return 'Le SKU \"$sku\" ne correspond à aucun produit connu.';
  }

  @override
  String get goToRoom => 'Aller à la chambre';

  @override
  String get errorLoadingProducts => 'Erreur de chargement des produits';

  @override
  String get errorLoadingInventory => 'Erreur de chargement de l\'inventaire';

  @override
  String get qrGenAllRoomProducts =>
      'Tous les produits de la chambre sélectionnée';

  @override
  String get qrGenAllInventoryProducts => 'Tous les produits de l\'inventaire';

  @override
  String get qrLabelScanInstructions =>
      'Scanner avec l\'application IVRA pour remplir ou remplacer';

  @override
  String get roomsSearchProductPlaceholder =>
      'Rechercher un produit par nom ou SKU...';

  @override
  String adjustStockForProduct(String product) {
    return 'Ajuster le stock pour $product';
  }

  @override
  String get roomsBtnRequestCorrection => 'Demander une correction';

  @override
  String get roomsLabelReason => 'Raison';

  @override
  String get roomsMsgCorrectionQueued =>
      'Demande de correction mise en attente';

  @override
  String get roomsMsgCorrectionSubmitted => 'Demande de correction soumise';

  @override
  String get roomsBtnCreateRooms => 'Créer les chambres';

  @override
  String get roomsLabelProductsInRoom => 'Produits dans chaque chambre';

  @override
  String get roomsMsgSelectOneProduct => 'Sélectionnez au moins un produit';

  @override
  String roomsMsgDuplicateRoomNumbers(String numbers) {
    return 'Ces numéros de chambre existent déjà dans cet hôtel : $numbers. Choisissez un numéro de départ ou un nombre différent.';
  }

  @override
  String get productsCatalogTitle => 'Catalogue des produits';

  @override
  String get productsBtnCreate => 'Créer un produit';

  @override
  String get productsNoProducts => 'Aucun produit dans le catalogue.';

  @override
  String get productsLabelBottleVolume => 'Volume de la bouteille';

  @override
  String get productsLabelBidonVolume => 'Volume de la bouteille de recharge';

  @override
  String get productsLabelMaxRefill => 'Limite de remplissage';

  @override
  String get productsLabelMaxAge => 'Âge max de la bouteille';

  @override
  String get productsLabelLowStock => 'Alerte de stock bas';

  @override
  String get productsBtnEdit => 'Modifier le produit';

  @override
  String get productsLabelSku => 'SKU';

  @override
  String get productsLabelNameEn => 'Nom Anglais';

  @override
  String get productsLabelNameFr => 'Nom Français';

  @override
  String get productsLabelNameAr => 'Nom Arabe';

  @override
  String get productsLabelNameIt => 'Nom Italien';

  @override
  String get productsLabelImage => 'Importer une image';

  @override
  String get productsLabelImageHint =>
      'Sélectionnez une image de votre appareil';

  @override
  String productsImageSelected(String name) {
    return 'Sélectionné : $name';
  }

  @override
  String get productsImageSet => 'Image définie (appuyez pour changer)';

  @override
  String get productsImageNone => 'Aucune image sélectionnée';

  @override
  String get productsImageRemove => 'Supprimer l\'image';

  @override
  String get productsImageUploadFailed =>
      'Échec du téléversement de l\'image. Veuillez réessayer.';

  @override
  String get productsImageInvalidType =>
      'Veuillez sélectionner un fichier image valide.';

  @override
  String productsImageTooLarge(String max) {
    return 'L\'image est trop volumineuse (max $max Mo).';
  }

  @override
  String get productsAddedSuccess => 'Produit ajouté avec succès';

  @override
  String get productsUpdatedSuccess => 'Produit mis à jour avec succès';

  @override
  String get productsLabelBottleMl => 'Bouteille ml';

  @override
  String get productsLabelBidonMl => 'Vol. bouteille de recharge (ml)';

  @override
  String get productsLabelMaxRefills => 'Recharges max';

  @override
  String get productsLabelMaxAgeDays => 'Âge max jours';

  @override
  String get productsLabelLowBottles => 'Bouteilles bas';

  @override
  String get productsLabelLowBidons => 'Bouteilles de recharge basses';

  @override
  String get productsLabelBottleType => 'Type de bouteille';

  @override
  String get productsLabelBottleWithPump => 'Bouteille avec pompe';

  @override
  String get productsLabelBottleWithoutPump => 'Bouteille sans pompe';

  @override
  String get productsLabelRefillType => 'Type de recharge';

  @override
  String get productsLabelRefillable => 'Rechargeable';

  @override
  String get productsLabelDirectReplacement => 'Remplacement direct';

  @override
  String get productsDialogCreateTitle => 'Créer un produit';

  @override
  String get productsDialogEditTitle => 'Modifier le produit';

  @override
  String get days => 'jours';

  @override
  String get refills => 'recharges';

  @override
  String get inventoryNoHotels => 'Aucun hôtel trouvé';

  @override
  String get inventoryAddHotelHint => 'Ajoutez un hôtel pour commencer.';

  @override
  String get inventoryNoItemsToAdjust =>
      'Aucun article de stock disponible à ajuster.';

  @override
  String get inventoryNoInventoryYet => 'Pas encore de stock';

  @override
  String get inventoryNoProductsInInventory =>
      'Il n\'y a pas de produits dans le stock.';

  @override
  String get inventoryNoSuggestedOrders => 'Aucune commande suggérée';

  @override
  String get inventoryLevelsSufficient =>
      'Vos niveaux de stock sont actuellement suffisants.';

  @override
  String get teamAccounts => 'Comptes d\'équipe';

  @override
  String get teamNoMembers => 'Aucun membre d\'équipe trouvé.';

  @override
  String get teamTableColumnName => 'Nom';

  @override
  String get teamTableColumnEmail => 'E-mail';

  @override
  String get teamTableColumnRole => 'Rôle';

  @override
  String get teamTableColumnHotel => 'Hôtel';

  @override
  String get teamTableColumnStatus => 'Statut';

  @override
  String get teamTableColumnActions => 'Actions';

  @override
  String get teamPendingInvitations => 'Invitations en attente';

  @override
  String get teamNoPendingInvitations => 'Aucune invitation en attente.';

  @override
  String get teamInviteTitle => 'Inviter un membre';

  @override
  String get teamLabelFullName => 'Nom complet';

  @override
  String get settingsOfflineMode => 'Mode hors ligne';

  @override
  String get settingsOfflineQueue => 'Mettre en file d\'attente';

  @override
  String get settingsOfflineSend => 'Envoyer les actions';

  @override
  String get settingsBiometricTitle => 'Déverrouillage biométrique';

  @override
  String get settingsBiometricHint =>
      'Utilisez votre empreinte ou votre visage pour vous connecter.';

  @override
  String get settingsBiometricUnavailable =>
      'Le déverrouillage biométrique n\'est pas disponible sur cet appareil.';

  @override
  String get authBtnBiometricLogin => 'Connexion biométrique';

  @override
  String get authBiometricReason => 'Authentifiez-vous pour accéder à Ivra';

  @override
  String get authBiometricNeedsLogin =>
      'Connectez-vous une fois pour activer la connexion biométrique.';

  @override
  String get authBiometricOfflineNoSession =>
      'Vous êtes hors ligne. Connectez-vous à Internet pour vous identifier.';

  @override
  String get authBiometricFailed => 'Échec de l\'authentification biométrique.';

  @override
  String get settingsBtnClear => 'Effacer';

  @override
  String get settingsBtnSyncNow => 'Synchroniser';

  @override
  String get settingsNoPendingActions => 'Aucune action en attente.';

  @override
  String get teamManageHotels => 'Gérer les hôtels';

  @override
  String get teamAssignHotelsTitle => 'Assigner des hôtels';

  @override
  String get teamNoHotelsAssigned => 'Aucun hôtel assigné';

  @override
  String get teamHotelsUpdated => 'Affectations mises à jour';

  @override
  String get teamSelectHotels => 'Sélectionner les hôtels';

  @override
  String get teamHotelsAssigned => 'hôtels assignés';

  @override
  String get accountTitle => 'Compte';

  @override
  String get accountProfile => 'Profil';

  @override
  String get accountProfileUpdated => 'Profil mis à jour';

  @override
  String get accountPassword => 'Mot de passe';

  @override
  String get accountPasswordUpdated => 'Mot de passe mis à jour';

  @override
  String get accountFullName => 'Nom complet';

  @override
  String get accountFullNameRequired => 'Le nom complet est requis';

  @override
  String get accountNewPassword => 'Nouveau mot de passe';

  @override
  String get accountConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get accountPasswordHintSupabase =>
      'Met à jour le mot de passe de votre compte.';

  @override
  String get accountPasswordHintDemo =>
      'Le mode démo accepte le changement localement.';

  @override
  String get accountSignOutHint =>
      'Terminer la session en cours sur cet appareil.';

  @override
  String get accountSignOut => 'Se déconnecter';

  @override
  String get accountEmail => 'E-mail';

  @override
  String get accountRole => 'Rôle';

  @override
  String get accountScope => 'Périmètre';

  @override
  String get accountStatus => 'Statut';

  @override
  String get accountActive => 'Actif';

  @override
  String get accountInactive => 'Inactif';

  @override
  String get accountIvraGlobal => 'Ivra global';

  @override
  String get accountTeamAccounts => 'Comptes de l\'équipe';

  @override
  String get accountNoOtherAccounts => 'Aucun autre compte trouvé.';

  @override
  String get accountYou => 'Vous';

  @override
  String get alertsRefreshSmart => 'Actualiser les alertes';

  @override
  String get alertsResolve => 'Résoudre';

  @override
  String get delete => 'Supprimer';

  @override
  String get approvalsEmpty => 'Aucune approbation en attente';

  @override
  String get approvalsEmptySubtitle =>
      'Toutes les demandes d\'approbation ont été traitées.';

  @override
  String get approvalsApprove => 'Approuver';

  @override
  String get approvalsReject => 'Rejeter';

  @override
  String get approvalsActionFailed => 'L\'action a échoué. Réessayez.';

  @override
  String get approvalsApproved => 'Demande approuvée.';

  @override
  String get approvalsRejected => 'Demande rejetée.';

  @override
  String get approvalsApproveQueued => 'Approbation mise en file d\'attente.';

  @override
  String get approvalsRejectQueued => 'Rejet mis en file d\'attente.';

  @override
  String get approvalsAccessDenied =>
      'Accès refusé. Seuls les admins peuvent approuver.';

  @override
  String get approvalsRequestNotFound => 'Demande introuvable ou déjà traitée.';

  @override
  String get inviteAcceptTitle => 'Accepter l\'invitation';

  @override
  String get inviteAlreadyHaveAccount => 'J\'ai déjà un compte';

  @override
  String get inviteBackToSignIn => 'Retour à la connexion';

  @override
  String get inviteEmail => 'E-mail';

  @override
  String get invitePassword => 'Mot de passe';

  @override
  String get inviteConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get settingsRetryAction => 'Réessayer l\'action';

  @override
  String get settingsRemoveAction => 'Supprimer l\'action';

  @override
  String get settingsActionUpdated => 'Action en file mise à jour';

  @override
  String get settingsActionRemoved => 'Action hors ligne supprimée';

  @override
  String get settingsQueueCleared => 'File hors ligne vidée';

  @override
  String get settingsTestAccessAs => 'Tester l\'accès en tant que';

  @override
  String get settingsDemoUserChanged => 'Utilisateur démo changé';

  @override
  String get settingsPayloadJson => 'Payload JSON en file';

  @override
  String get settingsSaveAndRetry => 'Sauvegarder et réessayer';

  @override
  String get settingsDemoUser => 'Utilisateur démo';

  @override
  String get settingsSupabaseConnected => 'Connecté';

  @override
  String get settingsSupabaseHint => 'L\'app utilise les données en direct.';

  @override
  String get settingsNoSupabaseHint =>
      'La connexion au serveur n\'est pas configurée.';

  @override
  String get settingsEditAction => 'Modifier l\'action en file';

  @override
  String get settingsResolveConflict => 'Résoudre le conflit de sync';

  @override
  String get settingsActionSynced => 'Action synchronisée';

  @override
  String get offlineBannerTitle => 'Vous êtes hors ligne';

  @override
  String get offlineBannerSubtitle => 'Les données peuvent ne pas être à jour';

  @override
  String get offlineBannerPending => 'actions en attente';

  @override
  String get offlineBannerSyncBtn => 'Synchroniser';

  @override
  String offlineBannerAutoSynced(String count) {
    return 'De retour en ligne ! $count actions synchronisées';
  }

  @override
  String get offlineBannerSyncFailed =>
      'La synchronisation a échoué pour certaines actions';

  @override
  String teamInvitationCancelled(String email) {
    return 'Invitation annulée pour $email';
  }

  @override
  String teamInvitationResent(String email) {
    return 'Invitation renvoyée à $email';
  }

  @override
  String teamInvitationCopied(String email) {
    return 'Lien d\'invitation copié pour $email';
  }

  @override
  String approvalsRequestedBy(String name) {
    return 'Demandé par $name';
  }

  @override
  String approvalsOldValue(String value) {
    return 'Ancien : $value';
  }

  @override
  String approvalsNewValue(String value) {
    return 'Nouveau : $value';
  }

  @override
  String alertsSeverityLabel(String severity) {
    return 'Sévérité $severity';
  }

  @override
  String get alertsStatusResolved => 'Résolu';

  @override
  String get alertsStatusOpen => 'Ouvert';

  @override
  String get alertsMetricCritical => 'Critique';

  @override
  String get alertsFilterTitle => 'Filtres';

  @override
  String get alertsFilterSeverity => 'Gravité';

  @override
  String get alertsFilterType => 'Type';

  @override
  String get alertsFilterHotel => 'Hôtel';

  @override
  String get alertsFilterProduct => 'Produit';

  @override
  String get alertsFilterAll => 'Tous';

  @override
  String get alertsFilterClear => 'Effacer les filtres';

  @override
  String get alertsFilterNoMatch =>
      'Aucune alerte ne correspond aux filtres actuels.';

  @override
  String alertsFilterShowing(String count, String total) {
    return 'Affichage de $count sur $total';
  }

  @override
  String get settingsActionEditTitle => 'Modifier l\'action en file d\'attente';

  @override
  String get settingsActionConflictTitle =>
      'Résoudre le conflit de synchronisation';

  @override
  String settingsActionAttempts(String count) {
    return 'Tentatives $count';
  }

  @override
  String settingsActionListAttempts(String count) {
    return 'Tentatives : $count';
  }

  @override
  String settingsActionListError(String message) {
    return 'Erreur : $message';
  }

  @override
  String get syncActionRefill => 'Recharge';

  @override
  String get syncActionUndoRefill => 'Annulation de recharge';

  @override
  String get syncActionCorrectionRequest => 'Demande de correction';

  @override
  String get syncActionBottleReplacement => 'Remplacement de bouteille';

  @override
  String get syncActionStockAdjustment => 'Ajustement du stock';

  @override
  String get syncActionPendingEdit => 'Modification en attente';

  @override
  String get userRoleAppAdmin => 'Admin appli';

  @override
  String get userRoleAppManager => 'Gérant de l\'appli';

  @override
  String get userRoleHotelManager => 'Gérant d\'hôtel';

  @override
  String get userRoleHotelStaff => 'Personnel de l\'hôtel';

  @override
  String get teamStatusActive => 'Actif';

  @override
  String get teamStatusInactive => 'Inactif';

  @override
  String get teamHotelAll => 'Tous les hôtels';

  @override
  String get teamHotelNone => '—';

  @override
  String get invitationStatusPending => 'En attente';

  @override
  String get invitationStatusAccepted => 'Acceptée';

  @override
  String get invitationStatusCancelled => 'Annulée';

  @override
  String get invitationStatusExpired => 'Expirée';

  @override
  String get alertResolvedToast => 'Alerte résolue';

  @override
  String get alertDeletedToast => 'Alerte supprimée';

  @override
  String get alertResolveFailedToast =>
      'Impossible de résoudre l\'alerte. Veuillez réessayer.';

  @override
  String get alertDeleteFailedToast =>
      'Impossible de supprimer l\'alerte. Veuillez réessayer.';

  @override
  String get notificationAcknowledgedToast => 'Confirmé';

  @override
  String get notificationMoreInfo => 'Plus d\'infos';

  @override
  String get bulkAdjustStockTitle => 'Ajustement en masse';

  @override
  String get bulkAdjustStockHint =>
      'Saisissez les ajustements qui s\'appliqueront à TOUS les produits.';

  @override
  String get bulkAdjustStockSuccess =>
      'Ajustement de stock en masse appliqué avec succès';

  @override
  String get bulkAdjustStockOfflineQueued =>
      'Ajustements en masse mis en file d\'attente pour la synchronisation hors ligne';

  @override
  String get resolveAll => 'Tout résoudre';

  @override
  String get deleteAll => 'Tout supprimer';

  @override
  String alertsRefreshedToast(String count) {
    return '$count alertes intelligentes créées';
  }

  @override
  String get alertsEmptyTitle => 'Aucune alerte pour le moment';

  @override
  String get alertsEmptyMessage =>
      'Actualisez les alertes intelligentes pour analyser le stock, les limites de recharge, l\'âge des bouteilles et les approbations en attente.';

  @override
  String get alertsEmptyAction => 'Actualiser les alertes';

  @override
  String get alertTypeLowBidonStock => 'Stock bas (bouteilles de recharge)';

  @override
  String alertLowBottleTitle(String product) {
    return 'Stock de bouteilles faible ($product)';
  }

  @override
  String alertLowBidonTitle(String product) {
    return 'Stock de bouteilles de recharge faible ($product)';
  }

  @override
  String alertLowBottleBody(String hotel, String remain, String threshold) {
    return '$hotel : il reste $remain bouteilles pleines. Le seuil est $threshold.';
  }

  @override
  String alertLowBidonBody(String hotel, String remain, String threshold) {
    return '$hotel : il reste $remain bouteilles de recharge pleines. Le seuil est $threshold.';
  }

  @override
  String get alertTypeLowBottleStock => 'Stock bas (bouteilles)';

  @override
  String get alertTypeBottleAgeLimit => 'Âge bouteille';

  @override
  String alertBottleAgeLimitTitle(String room, String product) {
    return 'Chambre $room : la bouteille de $product est trop vieille';
  }

  @override
  String alertBottleAgeLimitBody(String age, String limit) {
    return 'L\'âge de la bouteille est de $age jours. La limite est de $limit jours.';
  }

  @override
  String get alertTypeRefillLimit => 'Limite de recharges';

  @override
  String alertRefillLimitTitle(String room, String product) {
    return 'Chambre $room : $product a atteint la limite de recharges';
  }

  @override
  String alertRefillLimitBody(String used, String max) {
    return '$used/$max recharges utilisées. Remplacez et recyclez la bouteille.';
  }

  @override
  String get alertTypePendingApproval => 'Approbation';

  @override
  String alertPendingApprovalTitle(String request) {
    return 'Approbation en attente : $request';
  }

  @override
  String alertPendingApprovalBody(String name) {
    return 'Demandé par $name.';
  }

  @override
  String get alertTypeSuspiciousActivity => 'Activité suspecte';

  @override
  String get alertTypeInactiveHotel => 'Hôtel inactif';

  @override
  String get refillEventApproved => 'Approuvé';

  @override
  String get refillEventRejected => 'Rejeté';

  @override
  String get teamDeactivateAccountTooltip => 'Désactiver le compte';

  @override
  String get teamReactivateAccountTooltip => 'Réactiver le compte';

  @override
  String settingsSyncedSummary(String synced) {
    return '$synced actions synchronisées';
  }

  @override
  String settingsSyncedSummarySingular(String synced) {
    return '$synced action synchronisée';
  }

  @override
  String settingsSyncedWithFailures(String synced, String failed) {
    return '$synced synchronisées, $failed échec(s)';
  }

  @override
  String get inviteAcceptHeading => 'Accepter l\'invitation Ivra';

  @override
  String inviteSubtitleWithHotel(String name, String role, String hotel) {
    return '$name a été invité(e) en tant que $role pour $hotel.';
  }

  @override
  String inviteSubtitleNoHotel(String name, String role) {
    return '$name a été invité(e) en tant que $role.';
  }

  @override
  String get inviteEmailMismatch =>
      'Utilisez l\'adresse e-mail à laquelle cette invitation a été envoyée.';

  @override
  String get inviteAccountCreatedConfirm =>
      'Compte créé. Confirmez votre e-mail, puis revenez à ce lien d\'invitation et entrez le même mot de passe pour terminer.';

  @override
  String get inviteInvalidHeading => 'Invitation indisponible';

  @override
  String get inviteInvalidBody =>
      'Cette invitation a peut-être expiré, été annulée ou déjà acceptée.';

  @override
  String teamMemberReactivated(String name) {
    return '$name réactivé';
  }

  @override
  String teamMemberDeactivated(String name) {
    return '$name désactivé';
  }

  @override
  String settingsActionLastTried(String datetime) {
    return 'Dernière tentative $datetime';
  }

  @override
  String get settingsActionNeedsReview =>
      'L\'action nécessite encore une révision';

  @override
  String get teamInviteLinkUnavailable =>
      'Le lien d\'invitation n\'est pas disponible';

  @override
  String get teamCopyLink => 'Copier le lien d\'invitation';

  @override
  String get teamResendInvitation => 'Renvoyer l\'invitation';

  @override
  String get teamCancelInvitation => 'Annuler l\'invitation';

  @override
  String get teamCannotInviteSelf =>
      'Vous ne pouvez pas vous inviter vous-même';

  @override
  String get btnUpdate => 'Mettre à jour';

  @override
  String get notFoundTitle => 'Page Introuvable';

  @override
  String get notFoundBody =>
      'La page que vous recherchez n\'existe pas ou a été déplacée.';

  @override
  String get notFoundButton => 'Retour au Tableau de Bord';

  @override
  String get downloadAppBannerText =>
      'Pour une meilleure expérience, téléchargez notre application Android.';

  @override
  String get downloadAppBannerButton => 'Télécharger l\'App';

  @override
  String get sendPushTitle => 'Envoyer notification';

  @override
  String get teamViewAs => 'Voir en tant que';

  @override
  String impersonationBanner(String name) {
    return 'Affichage en tant que $name';
  }

  @override
  String get impersonationExit => 'Quitter';

  @override
  String get pdfHeaderType => 'Type';

  @override
  String get pdfHeaderPrevious => 'Précédent';

  @override
  String get pdfHeaderNew => 'Nouveau';

  @override
  String get pdfHeaderOccurredAt => 'Survenu à';

  @override
  String get pdfHeaderNotes => 'Notes';

  @override
  String get pdfHeaderProduct => 'Produit';

  @override
  String get pdfHeader1LBottles => 'Bouteilles 1L';

  @override
  String get pdfHeader5LBidons => 'Bidons 5L';

  @override
  String get pdfHeaderRecycle => 'Recycler';

  @override
  String get pdfHeaderFullBottles => 'Bouteilles pleines';

  @override
  String get pdfHeaderEmptyBottles => 'Bouteilles vides';

  @override
  String get pdfHeaderFullBidons => 'Bidons pleins';

  @override
  String get pdfHeaderOpenBidons => 'Bidons ouverts';

  @override
  String get pdfHeaderEmptyBidons => 'Bidons vides';

  @override
  String get pdfHeaderSeverity => 'Sévérité';

  @override
  String get pdfHeaderTitle => 'Titre';

  @override
  String get pdfHeaderCreatedAt => 'Créé le';

  @override
  String get approvalStatusApproved => 'Approuvé';

  @override
  String get approvalStatusRejected => 'Rejeté';

  @override
  String get approvalStatusCancelled => 'Annulé';

  @override
  String get approvalStatusPending => 'En attente';

  @override
  String get pdfTitleSuggestedOrders => 'Commandes suggérées Ivra';

  @override
  String get pdfTitleInventorySnapshot => 'Stock magasin Ivra';

  @override
  String get pdfTitleRefillHistory => 'Historique de recharge Ivra';

  @override
  String get pdfTitleOpenAlerts => 'Alertes ouvertes Ivra';

  @override
  String get productHistoryTitle => 'Historique du produit';

  @override
  String get productHistoryNoHistory =>
      'Aucun historique enregistré pour ce produit.';

  @override
  String productHistoryRefill(String roomNumber) {
    return 'Rempli dans la chambre $roomNumber';
  }

  @override
  String productHistoryReplacement(String roomNumber) {
    return 'Bouteille remplacée dans la chambre $roomNumber';
  }

  @override
  String get productHistoryAdjustment => 'Ajustement manuel du stock';

  @override
  String productHistoryActionBy(String user) {
    return 'Par $user';
  }

  @override
  String productHistoryReason(String reason) {
    return 'Raison: $reason';
  }

  @override
  String get productHistoryDeltaFullBottles => 'Bouteilles pleines';

  @override
  String get productHistoryDeltaUsedBottles => 'Bouteilles utilisées';

  @override
  String get productHistoryDeltaFullBidons => 'Bouteilles de recharge pleines';

  @override
  String get productHistoryDeltaOpenBidons =>
      'Bouteilles utilisées et ouvertes';

  @override
  String get productHistoryDeltaEmptyBidons => 'Bouteilles utilisées et vides';

  @override
  String productHistoryNewBottle(String roomNumber) {
    return 'Nouvelle bouteille placée dans la chambre $roomNumber';
  }

  @override
  String get productHistoryFilterAll => 'Tout';

  @override
  String get productHistoryFilterRoom => 'Événements de chambre';

  @override
  String get productHistoryFilterManual => 'Ajustements';

  @override
  String get productHistoryStatRefills => 'Recharges';

  @override
  String get productHistoryStatReplacements => 'Remplacements';

  @override
  String get productHistoryStatAdjustments => 'Ajustements';

  @override
  String get inventoryEnforceTitle => 'Stock insuffisant';

  @override
  String inventoryEnforceTemplateContent(
      String total, String product, String current, String needed) {
    return 'Placer $total bouteille(s) de $product nécessite du stock. L\'stock magasin n\'en a que $current. Souhaitez-vous ajouter automatiquement $needed bouteille(s) à l\'stock magasin et continuer?';
  }

  @override
  String inventoryEnforceReplaceContent(String product, String room) {
    return 'Remplacer la bouteille de $product dans la chambre $room nécessite 1 bouteille pleine. L\'stock magasin en a 0. Souhaitez-vous ajouter automatiquement 1 bouteille à l\'stock magasin et continuer?';
  }

  @override
  String housekeeperReplaceGetFromHotel(
      String product, String room, String count) {
    return 'Remplacer $product dans la chambre $room nécessite 1 bouteille pleine, mais vous ne l\'avez pas dans votre inventaire. Cependant, $count bouteilles sont disponibles dans l\'inventaire de l\'hôtel. Souhaitez-vous prendre 1 bouteille de l\'inventaire de l\'hôtel et continuer ?';
  }

  @override
  String housekeeperReplaceNotifyManager(String product, String room) {
    return 'Remplacer $product dans la chambre $room nécessite 1 bouteille pleine, mais vous ne l\'avez pas dans votre inventaire et elle n\'est pas disponible non plus dans l\'inventaire de l\'hôtel. Veuillez en informer le responsable de l\'hôtel.';
  }

  @override
  String housekeeperAddGetFromHotel(String product, String room, String count) {
    return 'Ajouter $product dans la chambre $room nécessite 1 bouteille pleine, mais vous ne l\'avez pas dans votre inventaire. Cependant, $count bouteilles sont disponibles dans l\'inventaire de l\'hôtel. Souhaitez-vous prendre 1 bouteille de l\'inventaire de l\'hôtel et continuer ?';
  }

  @override
  String housekeeperAddNotifyManager(String product, String room) {
    return 'Ajouter $product dans la chambre $room nécessite 1 bouteille pleine, mais vous ne l\'avez pas dans votre inventaire et elle n\'est pas disponible non plus dans l\'inventaire de l\'hôtel. Veuillez en informer le responsable de l\'hôtel.';
  }

  @override
  String housekeeperRefillGetFromHotel(
      String product, String room, String count) {
    return 'Remplir $product dans la chambre $room nécessite 1 bidon plein, mais vous n\'avez pas de bidon ouvert ou plein dans votre inventaire. Cependant, $count bidons sont disponibles dans l\'inventaire de l\'hôtel. Souhaitez-vous prendre 1 bidon de l\'inventaire de l\'hôtel et continuer ?';
  }

  @override
  String housekeeperRefillNotifyManager(String product, String room) {
    return 'Remplir $product dans la chambre $room nécessite 1 bidon plein, mais vous n\'avez pas de bidon ouvert ou plein dans votre inventaire et il n\'est pas disponible non plus dans l\'inventaire de l\'hôtel. Veuillez en informer le responsable de l\'hôtel.';
  }

  @override
  String get btnOk => 'OK';

  @override
  String get inventoryEnforceBtnProceed => 'Ajuster et continuer';

  @override
  String get inventoryEnforceReasonTemplate =>
      'Ajusté automatiquement pour le modèle de création de chambre';

  @override
  String get inventoryEnforceReasonReplace =>
      'Ajusté automatiquement pour le remplacement';

  @override
  String get inventoryEnforceOnboardingTitle => 'Initialiser l\'stock magasin';

  @override
  String inventoryEnforceOnboardingContent(String total) {
    return 'Puisqu\'il s\'agit d\'un nouvel hôtel, il n\'y a aucun produit dans l\'stock magasin. Souhaitez-vous initialiser automatiquement l\'stock magasin avec $total bouteilles à placer dans les chambres?';
  }

  @override
  String get authBtnCreateRole => 'Créer un Rôle';

  @override
  String get authCreateRoleTitle => 'Créer un Rôle Personnalisé';

  @override
  String get authRoleNameLabel => 'Nom du Rôle (minuscules snake_case)';

  @override
  String get authRoleNameError =>
      'Le nom du rôle doit être en minuscules snake_case (ex. night_auditor)';

  @override
  String get authRoleDisplayNameLabel =>
      'Nom d\'Affichage Convivial (ex. Night Auditor)';

  @override
  String get authRoleDisplayNameError =>
      'Le nom d\'affichage ne peut pas être vide';

  @override
  String get authRoleDescLabel => 'Description';

  @override
  String get authCategoryCore => 'Opérations de Base';

  @override
  String get authCategoryManagement => 'Gestion';

  @override
  String get authCategoryControl => 'Contrôle & Approbations';

  @override
  String get authCategoryAnalytics => 'Analyses & Diffusions';

  @override
  String get authCategorySecurity => 'Sécurité & Administration';

  @override
  String get authBulkGrantAll => 'Tout Accorder';

  @override
  String get authBulkRevokeAll => 'Tout Révoquer';

  @override
  String get authRoleCreatedSuccess => 'Rôle créé avec succès.';

  @override
  String get authSearchHint => 'Rechercher des permissions...';

  @override
  String get authorizationsTitle => 'Matrice des Autorisations';

  @override
  String get authorizationsHeader => 'Matrice des Autorisations';

  @override
  String get authorizationsSubtitle =>
      'Gérer les fonctionnalités de l\'application et les permissions d\'action par rôle d\'utilisateur.';

  @override
  String get authorizationsPermission => 'Permission';

  @override
  String get authorizationsUpdatedSuccessfully =>
      'Autorisations mises à jour avec succès.';

  @override
  String get roleAppAdmin => 'Admin de l\'App';

  @override
  String get roleAppManager => 'Manager de l\'App';

  @override
  String get roleHotelManager => 'Manager d\'Hôtel';

  @override
  String get roleHotelStaff => 'Personnel d\'Hôtel';

  @override
  String get permManageHotels => 'Gérer les Hôtels';

  @override
  String get permManageHotelsDesc =>
      'Créer, modifier et supprimer les établissements hôteliers';

  @override
  String get permManageRooms => 'Gérer les Chambres';

  @override
  String get permManageRoomsDesc =>
      'Ajouter, modifier et supprimer des chambres et des étages';

  @override
  String get permManageProducts => 'Gérer les Produits';

  @override
  String get permManageProductsDesc =>
      'Configurer les types de produits globaux et les catalogues';

  @override
  String get permManageTeam => 'Gérer l\'Équipe';

  @override
  String get permManageTeamDesc =>
      'Inviter et gérer les membres de l\'équipe et les rôles';

  @override
  String get permSubmitEditRequests => 'Soumettre des Demandes de Modification';

  @override
  String get permSubmitEditRequestsDesc =>
      'Soumettre des demandes de modification de chambres, de bouteilles et de stocks';

  @override
  String get permApproveCorrections => 'Approuver les Corrections';

  @override
  String get permApproveCorrectionsDesc =>
      'Approuver ou rejeter les demandes de modification et de correction en attente';

  @override
  String get permViewApprovals => 'Voir les Approbations';

  @override
  String get permViewApprovalsDesc =>
      'Accéder à l\'écran du tableau de bord des approbations';

  @override
  String get permViewAlerts => 'Voir les Alertes';

  @override
  String get permViewAlertsDesc =>
      'Visualiser et surveiller les alertes de fonctionnement';

  @override
  String get permViewReports => 'Voir les Rapports';

  @override
  String get permViewReportsDesc =>
      'Accéder aux rapports analytiques et aux graphiques de performance';

  @override
  String get permSendNotifications => 'Envoyer des Notifications Push';

  @override
  String get permSendNotificationsDesc =>
      'Rédiger et diffuser des notifications push de l\'application';

  @override
  String get permViewAuditLogs => 'Voir les Journaux d\'Audit de Sécurité';

  @override
  String get permViewAuditLogsDesc =>
      'Inspecter les journaux détaillés de l\'historique des opérations et des connexions';

  @override
  String get permViewRooms => 'Voir les Chambres';

  @override
  String get permViewRoomsDesc =>
      'Voir la liste des statuts de recharge des chambres et les détails';

  @override
  String get permViewInventory => 'Voir les Stocks';

  @override
  String get permViewInventoryDesc =>
      'Visualiser le statut des stocks de l\'hôtel et suggérer des commandes';

  @override
  String get permViewAuthorizations => 'Voir les Autorisations';

  @override
  String get permViewAuthorizationsDesc =>
      'Accéder et gérer l\'écran des paramètres d\'autorisation basés sur les rôles';

  @override
  String get dialogRefillTitle => 'Remplir le distributeur';

  @override
  String get dialogRefillSliderLabel =>
      'Pourcentage de recharge (volume ajouté) :';

  @override
  String get dialogRefillPreExisting => 'Liquide préexistant :';

  @override
  String get dialogRefillAdded => 'Liquide nouvellement ajouté :';

  @override
  String get dialogRefillNotes => 'Notes (optionnel)';

  @override
  String get dialogRefillConfirm => 'Confirmer la recharge';

  @override
  String get femmeDeChambre => 'Femme de chambre';

  @override
  String get checkoutStock => 'Sortie de stock';

  @override
  String get returnStock => 'Retour de stock';

  @override
  String get housekeeperCart => 'Mon chariot';

  @override
  String get noAllocations =>
      'Aucune allocation active. Sortez du stock pour commencer.';

  @override
  String get fullBottles => 'Bouteilles pleines';

  @override
  String get openBidonVolumeLeft => 'Volume restant';

  @override
  String get housekeeperStockCheckedOut => 'Stock sorti avec succès !';

  @override
  String get housekeeperStockReturned => 'Stock retourné avec succès !';

  @override
  String get housekeeperStockHistory => 'Historique';

  @override
  String get housekeeperStockHistoryEmpty =>
      'Aucun mouvement enregistré pour ce produit.';

  @override
  String get stockEventCheckout => 'Pris de l\'inventaire de l\'hôtel';

  @override
  String get stockEventReturn => 'Retourné à l\'inventaire de l\'hôtel';

  @override
  String get stockEventRoomPlacement => 'Placé dans la chambre';

  @override
  String get stockEventRefillUse => 'Utilisé pour le remplissage';

  @override
  String get stockEventReplaceUse =>
      'Utilisé pour le remplacement de bouteille';

  @override
  String housekeeperHotelStockAvailable(String bottles, String bidons) {
    return 'Inventaire de l\'hôtel : $bottles bouteilles pleines, $bidons bidons pleins disponibles';
  }

  @override
  String get sourceHousekeeperCart => 'Du chariot de la femme de chambre';

  @override
  String get sourceHotelInventory => 'De l\'inventaire de l\'hôtel';

  @override
  String get userRoleHousekeeper => 'Femme de chambre';

  @override
  String get roomsBtnAddProduct => 'Ajouter un produit';

  @override
  String roomsConfirmRemoveProduct(String productName, String roomNumber) {
    return 'Êtes-vous sûr de vouloir retirer le produit \'$productName\' de la chambre \'$roomNumber\' ?';
  }

  @override
  String get roomsProductRemoved => 'Produit retiré';

  @override
  String get roomsProductAdded => 'Produit ajouté';

  @override
  String get roomsAddProductTitle => 'Ajouter un produit à la chambre';

  @override
  String get roomsSelectProduct => 'Sélectionner un produit';

  @override
  String get myBasket => 'Mon Chariot';

  @override
  String get housekeepersTitle => 'Femmes de Chambre';

  @override
  String get allHistory => 'Tout l\'historique';

  @override
  String get changePicture => 'Changer la photo';

  @override
  String get inviteHousekeeper => 'Inviter une femme de chambre';

  @override
  String get removeHousekeeper => 'Supprimer';

  @override
  String get basketContent => 'Contenu du chariot';

  @override
  String get noHousekeepers => 'Aucune femme de chambre trouvée';

  @override
  String get btnClose => 'Fermer';

  @override
  String get deleteGeneric => 'Supprimer';

  @override
  String get teamDeactivate => 'Désactiver';

  @override
  String get teamReactivate => 'Réactiver';

  @override
  String get event_checkout => 'Stock Récupéré';

  @override
  String get event_returned => 'Stock Retourné';

  @override
  String get event_roomPlacement => 'Placé en Chambre';

  @override
  String get event_refillUse => 'Utilisé pour Recharger';

  @override
  String get event_replaceUse => 'Bouteille Remplacée';

  @override
  String get dialogRefillNotesHint => 'ex: recharge standard...';

  @override
  String get dateFormatHint => 'AAAA-MM-JJ';

  @override
  String errorWithArgs(String error) {
    return 'Erreur : $error';
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
    return '$label : $value';
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
    return 'Chambre $number';
  }

  @override
  String get onboardingStep1Title => 'Scanner un QR Code';

  @override
  String get onboardingStep1Desc =>
      'Scannez un code QR sur une bouteille ou une chambre pour commencer.';

  @override
  String get onboardingStep2Title => 'Recharger une Bouteille';

  @override
  String get onboardingStep2Desc =>
      'Suivez facilement les recharges de produits et maintenez l\'inventaire à jour.';

  @override
  String get onboardingStep3Title => 'Actions en Attente';

  @override
  String get onboardingStep3Desc =>
      'Consultez votre tableau de bord pour les alertes ou tâches en attente.';

  @override
  String get onboardingStep4Title => 'Changer de Langue';

  @override
  String get onboardingStep4Desc =>
      'Modifiez votre langue préférée dans le menu Paramètres à tout moment.';

  @override
  String get onboardingStep5Title => 'Voir l\'Inventaire';

  @override
  String get onboardingStep5Desc =>
      'Gardez une trace des niveaux de stock de votre hôtel et des commandes à venir.';

  @override
  String get onboardingStep6Title => 'Approuver les Demandes';

  @override
  String get onboardingStep6Desc =>
      'Examinez et approuvez les demandes de stock en attente de votre personnel.';

  @override
  String get onboardingStep7Title => 'Vérifier les Alertes';

  @override
  String get onboardingStep7Desc =>
      'Restez informé des alertes de stock faible ou opérationnelles.';

  @override
  String get onboardingStep8Title => 'Gérer les Hôtels';

  @override
  String get onboardingStep8Desc =>
      'Ajoutez et configurez plusieurs hôtels sous votre gestion.';

  @override
  String get onboardingStep9Title => 'Inviter l\'Équipe';

  @override
  String get onboardingStep9Desc =>
      'Invitez des gestionnaires et des membres du personnel à rejoindre votre espace de travail.';

  @override
  String get onboardingStep10Title => 'Voir les Rapports';

  @override
  String get onboardingStep10Desc =>
      'Générez des rapports détaillés et exportez les données de tous les hôtels.';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingDone => 'Terminé';

  @override
  String get onboardingResetMessage =>
      'Visite d\'intégration réinitialisée. Elle sera affichée sur le tableau de bord.';

  @override
  String get replayOnboarding => 'Rejouer la visite guidée';

  @override
  String get rolePermissionsGuide => 'Guide des Rôles & Permissions';

  @override
  String get help => 'Aide';

  @override
  String get helpContextDashboardTitle => 'Aperçu du Tableau de Bord';

  @override
  String get helpContextDashboardDesc =>
      'Cet écran affiche un résumé des opérations de recharge de votre hôtel pour aujourd\'hui. Vous pouvez voir rapidement les activités récentes, les approbations en attente et les alertes de stock faible.';

  @override
  String get helpContextInventoryTitle => 'Gestion de l\'Inventaire';

  @override
  String get helpContextInventoryDesc =>
      'Gérez les niveaux de stock de vos produits. Appuyez sur une carte de produit pour voir les détails ou ajuster les quantités.';

  @override
  String get helpContextRoomsTitle => 'Statut des Chambres';

  @override
  String get helpContextRoomsDesc =>
      'Affichez toutes les chambres et le statut de leurs produits. Appuyez sur une chambre pour recharger ou remplacer des bouteilles, ou scannez un QR code pour y accéder directement.';

  @override
  String get helpContextReportsTitle => 'Rapports & Exports';

  @override
  String get helpContextReportsDesc =>
      'Générez et exportez l\'historique des recharges, des instantanés d\'inventaire et des résumés d\'alertes.';

  @override
  String get noProductsFound => 'Aucun produit trouvé';

  @override
  String markDamagedTitle(String product, String room) {
    return 'Marquer comme endommagé - $product dans la chambre $room';
  }

  @override
  String markLostTitle(String product, String room) {
    return 'Marquer comme perdu - $product dans la chambre $room';
  }

  @override
  String get hkDeactivateWithStockTitle => 'Inventaire de la femme de chambre';

  @override
  String get hkDeactivateWithStockMessage =>
      'Cette femme de chambre a des produits dans son chariot. Voulez-vous retourner cet inventaire au stock central de l\'hôtel avant de désactiver son compte ?';

  @override
  String get btnReturnAndDeactivate => 'Retourner et désactiver';

  @override
  String get btnJustDeactivate => 'Juste désactiver';

  @override
  String hkDeleteWithStockMessage(String userName) {
    return 'Cette femme de chambre a des produits dans son chariot. La suppression de cette femme de chambre retournera automatiquement tout son inventaire au stock central de l\'hôtel.\n\nVoulez-vous vraiment supprimer le membre de l\'équipe \'$userName\' ? Cette action est irréversible et il perdra immédiatement l\'accès à l\'application.';
  }

  @override
  String get rolePermissionsNoPermissionsFound => 'Aucune permission trouvée.';

  @override
  String get rolePermissionsFeature => 'Fonctionnalité';

  @override
  String get settingsWhatsNew => 'Nouveautés';

  @override
  String settingsCurrentVersion(String version) {
    return 'Version actuelle : v$version';
  }

  @override
  String get settingsChangelogLoadFailed =>
      'Échec du chargement du journal des modifications.';
}
