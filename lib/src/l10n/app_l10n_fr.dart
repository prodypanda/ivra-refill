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
  String get inventory => 'Inventaire';

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
  String get inventoryTableEmptyBottles => 'Bouteilles vides';

  @override
  String get inventoryTableEmptyBidons => 'Bouteilles de recharge vides';

  @override
  String get inventoryTableFullBidons => 'Bouteilles de recharge pleines';

  @override
  String get inventoryTableOpenBidons => 'Bouteilles de recharge ouvertes';

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
  String get roomsBtnRoomEdit => 'Modifier la chambre';

  @override
  String get roomsBtnHistory => 'Historique';

  @override
  String get roomsBtnMoreActions => 'Plus d\'actions';

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
}
