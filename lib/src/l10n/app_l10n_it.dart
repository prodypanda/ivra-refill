// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppL10nIt extends AppL10n {
  AppL10nIt([String locale = 'it']) : super(locale);

  @override
  String get markAsRead => 'Segna come letto';

  @override
  String confirmDeleteHotel(String hotelName) {
    return 'Sei sicuro di voler eliminare l\'hotel \'$hotelName\'? Questa azione è permanente, non può essere annullata ed eliminerà tutte le camere, assegnazioni del personale e record associati.';
  }

  @override
  String confirmDeleteRoom(String roomNumber) {
    return 'Sei sicuro di voler eliminare la camera \'$roomNumber\'? Questa azione è permanente, non può essere annullata ed eliminerà tutti i prodotti e la cronologia associati.';
  }

  @override
  String confirmDeleteFloor(String floorNumber) {
    return 'Sei sicuro di voler eliminare il piano \'$floorNumber\' e tutte le sue camere? Questa azione è permanente e non può essere annullata.';
  }

  @override
  String confirmDeleteUser(String userName) {
    return 'Sei sicuro di voler eliminare il membro del team \'$userName\'? Questa azione è permanente, non può essere annullata e perderà immediatamente l\'accesso all\'applicazione.';
  }

  @override
  String confirmDeleteProduct(String productName) {
    return 'Sei sicuro di voler eliminare il prodotto \'$productName\'? Questa azione è permanente, non può essere annullata e influirà sul tracciamento dell\'inventario.';
  }

  @override
  String get confirmDeleteAlert =>
      'Sei sicuro di voler eliminare questo avviso? Questa azione è permanente e non può essere annullata.';

  @override
  String get confirmDeleteAllAlerts =>
      'Sei sicuro di voler eliminare tutti gli avvisi? Questa azione è permanente, non può essere annullata e cancellerà tutte le notifiche correnti.';

  @override
  String get clearAuditLogs => 'Cancella registri';

  @override
  String get confirmAction => 'Conferma azione';

  @override
  String get confirmClearLogs =>
      'Sei sicuro di voler cancellare tutti i registri di controllo? Questa azione è permanente e non può essere annullata.';

  @override
  String get btnConfirm => 'Conferma';

  @override
  String get composeMessage => 'Componi messaggio';

  @override
  String get notificationTitle => 'Titolo della notifica';

  @override
  String get notificationDefaultTitle => 'Nuova notifica';

  @override
  String get notificationChannelName => 'Notifiche importanti';

  @override
  String get notificationChannelDescription =>
      'Questo canale è utilizzato per le notifiche importanti.';

  @override
  String get notificationTitleHint => 'es: Nuova funzione!';

  @override
  String get notificationBody => 'Corpo della notifica';

  @override
  String get notificationBodyHint => 'Inserisci il messaggio qui...';

  @override
  String get actionButtons => 'Pulsanti di azione';

  @override
  String get actionButtonsHint => 'es: Ignora, Apri l\'app';

  @override
  String get pageToOpen => 'Pagina da aprire';

  @override
  String get menuSendPush => 'Invia Push';

  @override
  String get actionAndRouting => 'Azioni e Routing';

  @override
  String get openSpecificPage => 'Apri Pagina Specifica (Opzionale)';

  @override
  String get defaultNoPage => 'Predefinito (Nessuna pagina)';

  @override
  String get dashboard => 'Cruscotto';

  @override
  String get dashboardOpsAnalytics => 'Analisi delle operazioni';

  @override
  String get dashboardExport => 'Esporta';

  @override
  String get dashboardDaily => 'Giornaliero';

  @override
  String get dashboardWeekly => 'Settimanale';

  @override
  String get dashboardMonthly => 'Mensile';

  @override
  String get dashboardRoomsAttention => 'Camere che richiedono attenzione';

  @override
  String get dashboardProductUsage => 'Utilizzo del prodotto';

  @override
  String get dashboardUsageByFloor => 'Utilizzo per piano';

  @override
  String get dashboardStockForecast => 'Previsione esaurimento scorte';

  @override
  String get dashboardUnusualPatterns => 'Modelli insoliti';

  @override
  String get dashboardNoStockData => 'Nessun dato sulle scorte';

  @override
  String dashboardRoomsRequireReview(String count) {
    return '$count camere richiedono revisione';
  }

  @override
  String get dashboardNoUnusualPatterns => 'Nessun modello insolito rilevato';

  @override
  String get dashboardHighPriority => 'Alta';

  @override
  String get dashboardStable => 'Stabile';

  @override
  String get errorLoadingHotels => 'Errore nel caricamento degli hotel';

  @override
  String get sending => 'Invio in corso...';

  @override
  String roomsEditRoomTitle(String roomNumber) {
    return 'Aggiorna camera $roomNumber';
  }

  @override
  String roomsEditProductTitle(String productName, String roomNumber) {
    return 'Aggiorna bottiglia di $productName nella camera $roomNumber';
  }

  @override
  String get inventory => 'Inventario';

  @override
  String get alerts => 'Avvisi';

  @override
  String get approvals => 'Approvazioni';

  @override
  String get actionButtonsAndroid => 'Pulsanti di azione (Solo Android)';

  @override
  String get dismiss => 'Ignora';

  @override
  String get acknowledge => 'Conferma';

  @override
  String get openApp => 'Apri App';

  @override
  String get sendNotification => 'Invia Notifica';

  @override
  String get targetAudience => 'Destinatari';

  @override
  String get allUsers => 'Tutti gli utenti';

  @override
  String get byRole => 'Per Ruolo';

  @override
  String get byHotel => 'Per Hotel';

  @override
  String get byUserEmail => 'Per email';

  @override
  String get selectRole => 'Seleziona ruolo';

  @override
  String get selectHotel => 'Seleziona hotel';

  @override
  String get userEmail => 'Email dell\'utente';

  @override
  String get menuAuditLogs => 'Registri di Controllo';

  @override
  String get auditLogs => 'Registri di Controllo';

  @override
  String get auditAction => 'Azione';

  @override
  String get auditDevice => 'Dispositivo / OS';

  @override
  String get auditIpAddress => 'Indirizzo IP';

  @override
  String get auditTimestamp => 'Ora';

  @override
  String get auditUser => 'Utente';

  @override
  String get enterSpecificUserEmail => 'Inserisci un\'email specifica';

  @override
  String get dispatchNotification => 'Invia la notifica';

  @override
  String get pleaseEnterTitleBody => 'Inserisci un titolo e un corpo';

  @override
  String get pleaseSelectTarget => 'Seleziona un valore di destinazione';

  @override
  String notificationSent(String successCount, String failureCount) {
    return 'Inviato: $successCount successi, $failureCount falliti';
  }

  @override
  String get dashboardShort => 'Pannello';

  @override
  String get dashboardHeroTitle => 'Oggi in Ivra';

  @override
  String get dashboardRefillActivity => 'Attività ricariche (ultimi 7 giorni)';

  @override
  String get refillActivity => 'Attività ricariche';

  @override
  String get last7Days => 'Ultimi 7 giorni';

  @override
  String get lastMonth => 'Ultimo mese';

  @override
  String get lastYear => 'Ultimo anno';

  @override
  String get allHotels => 'Tutti gli hotel';

  @override
  String get monthJan => 'Gen';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'Mag';

  @override
  String get monthJun => 'Giu';

  @override
  String get monthJul => 'Lug';

  @override
  String get monthAug => 'Ago';

  @override
  String get monthSep => 'Set';

  @override
  String get monthOct => 'Ott';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dic';

  @override
  String get dayMon => 'Lun';

  @override
  String get dayTue => 'Mar';

  @override
  String get dayWed => 'Mer';

  @override
  String get dayThu => 'Gio';

  @override
  String get dayFri => 'Ven';

  @override
  String get daySat => 'Sab';

  @override
  String get daySun => 'Dom';

  @override
  String get chartRefills => 'ricariche';

  @override
  String get teamEditProfile => 'Modifica profilo';

  @override
  String get teamEditProfileSuccess => 'Profilo aggiornato';

  @override
  String get hotels => 'Hotel';

  @override
  String get rooms => 'Camere';

  @override
  String get products => 'Prodotti';

  @override
  String get team => 'Squadra';

  @override
  String get account => 'Account';

  @override
  String get reports => 'Rapporti';

  @override
  String get settings => 'Impostazioni';

  @override
  String get more => 'Altro';

  @override
  String get refill => 'Ricaricare';

  @override
  String get undo => 'Annulla';

  @override
  String get correction => 'Correzione';

  @override
  String get pending => 'In attesa';

  @override
  String get suggestedOrders => 'Ordini suggeriti';

  @override
  String get bottles => 'Bottiglie';

  @override
  String get bidons => 'Bottiglie di ricarica';

  @override
  String get language => 'Lingua';

  @override
  String get demoMode => 'Modalità demo';

  @override
  String get downloadCsv => 'Scarica CSV';

  @override
  String get downloadPdf => 'Scarica PDF';

  @override
  String get reportRefillHistoryTitle => 'Cronologia ricariche';

  @override
  String get reportRefillHistoryBody =>
      'Esporta le recenti attività di ricarica per hotel, camera, prodotto, utente e ora.';

  @override
  String get reportSuggestedOrdersBody =>
      'Esporta bottiglie, bottiglie di ricarica e raccomandazioni di riciclaggio.';

  @override
  String get reportInventorySnapshotTitle => 'Istantanea inventario';

  @override
  String get reportInventorySnapshotBody =>
      'Esporta lo stock attuale di bottiglie e bottiglie di ricarica per hotel e prodotto.';

  @override
  String get reportOpenAlertsTitle => 'Avvisi aperti';

  @override
  String get reportOpenAlertsBody =>
      'Esporta avvisi di stock basso, sostituzione, inattività e attività sospette.';

  @override
  String get scheduleReportEmail =>
      'Pianifica l\'invio del rapporto via e-mail';

  @override
  String get scheduleReportEmailHint =>
      'Invieremo un riepilogo di questo rapporto a questo indirizzo ogni lunedì.';

  @override
  String get scheduledReportEmailDrafted =>
      'Rapporto via e-mail pianificato con successo';

  @override
  String get reportFilterDateRange => 'Filtra per intervallo di date';

  @override
  String get reportAllProducts => 'Tutti i prodotti';

  @override
  String get reportAllRooms => 'Tutte le camere';

  @override
  String get reportClearFilters => 'Cancella filtri';

  @override
  String get reportFiltersApplyExports =>
      'Nota: I filtri si applicano sia alle metriche sullo schermo che alle esportazioni scaricate.';

  @override
  String get reportAnalyticsTitle => 'Panoramica delle analisi';

  @override
  String get reportKpiRefills => 'Ricariche totali';

  @override
  String get reportKpiCorrections => 'Correzioni di magazzino';

  @override
  String get reportKpiReplacements => 'Sostituzioni';

  @override
  String get reportKpiActiveRooms => 'Camere attive';

  @override
  String get reportTrendChart =>
      'Andamento dell\'attività di ricarica (ultimi 14 giorni)';

  @override
  String get reportUsageByProduct => 'Ricariche per prodotto';

  @override
  String get reportUsageByRoom => 'Ricariche per camera';

  @override
  String get reportNoAnalyticsData =>
      'Nessuna attività registrata per questo periodo.';

  @override
  String get exportFailed => 'Esportazione fallita';

  @override
  String get metricHotels => 'Hotel';

  @override
  String get metricRooms => 'Camere';

  @override
  String get metricPendingApprovals => 'Approvazioni in attesa';

  @override
  String get metricOpenAlerts => 'Avvisi aperti';

  @override
  String get metricBottlesToReplace => 'Bottiglie da sostituire';

  @override
  String get metricLowStockProducts => 'Prodotti sottoscorta';

  @override
  String get inventoryTableProduct => 'Prodotto';

  @override
  String get inventoryTableFullBottles => 'Bottiglie piene';

  @override
  String get inventoryTableFullBottlesWithPump => 'Bottiglie piene con pompa';

  @override
  String get inventoryTableFullBottlesWithoutPump =>
      'Bottiglie piene senza pompa';

  @override
  String get inventoryCollapseHeader => 'Bottiglie vuote e aperte';

  @override
  String get inventoryTableEmptyBottles => 'Bottiglie vuote';

  @override
  String get inventoryTableEmptyBidons => 'Bottiglie di ricarica vuote';

  @override
  String get inventoryTableFullBidons => 'Bottiglie di ricarica piene';

  @override
  String get inventoryTableOpenBidons => 'Bottiglie di ricarica aperte';

  @override
  String get inventoryTableStatus => 'Stato';

  @override
  String get errorUniqueViolation => 'Questo record esiste già.';

  @override
  String get errorForeignKeyViolation => 'Record correlato non trovato.';

  @override
  String get errorPermissionDenied =>
      'Non hai il permesso per eseguire questa azione.';

  @override
  String get errorGeneric => 'Si è verificato un errore imprevisto. Riprova.';

  @override
  String get inventoryStatusHealthy => 'Ottimo';

  @override
  String get inventoryStatusLowStock => 'Stock basso';

  @override
  String get auditFilterAllActions => 'Tutte le azioni';

  @override
  String get sortNameAsc => 'Nome (A-Z)';

  @override
  String get sortNameDesc => 'Nome (Z-A)';

  @override
  String get sortMostFullBottles => 'Più bottiglie piene';

  @override
  String get sortMostEmptyBottles => 'Più bottiglie vuote';

  @override
  String get bulkAdjustSelectProducts => 'Seleziona prodotti';

  @override
  String get bulkAdjustSelectAll => 'Seleziona tutto';

  @override
  String get bulkAdjustDeselectAll => 'Deseleziona tutto';

  @override
  String get bulkAdjustNoProductsSelected => 'Seleziona almeno un prodotto.';

  @override
  String orderNewBottlesText(String count) {
    return 'Ordina $count nuove bottiglie da 1L';
  }

  @override
  String orderNewBidonsText(String count) {
    return 'Ordina $count nuove bottiglie di ricarica da 5L';
  }

  @override
  String recycleBottlesText(String count) {
    return 'Ricicla $count bottiglie';
  }

  @override
  String get bottleCannotRefillRecycled =>
      'Questa bottiglia è stata riciclata e non può essere ricaricata. Si prega di sostituirla.';

  @override
  String get adjustStockTitle => 'Regola stock';

  @override
  String get hotelRoomsTracked => 'camere tracciate';

  @override
  String get hotelPendingChip => 'in attesa';

  @override
  String get hotelLabelName => 'Nome hotel';

  @override
  String get hotelLabelLegalName => 'Ragione sociale';

  @override
  String get hotelLabelState => 'Provincia (Stato)';

  @override
  String get hotelLabelCountry => 'Paese';

  @override
  String get hotelLabelContactName => 'Nome contatto';

  @override
  String get hotelLabelEmail => 'Email';

  @override
  String get hotelLabelPhone => 'Telefono';

  @override
  String get hotelLabelAddress => 'Indirizzo';

  @override
  String get hotelLabelNotes => 'Note';

  @override
  String get btnCreate => 'Crea';

  @override
  String get btnCancel => 'Annulla';

  @override
  String get btnSave => 'Salva';

  @override
  String get btnSubmitRequest => 'Invia richiesta';

  @override
  String get demoModeDescription =>
      'Simulazioni locali che utilizzano database offline.';

  @override
  String get offlineModeDescription =>
      'Mette in coda le azioni offline e le sincronizza in seguito.';

  @override
  String get syncQueueHeader => 'Coda di sincronizzazione';

  @override
  String get syncNow => 'Sincronizza ora';

  @override
  String get itemsToSync => 'azioni in attesa di sincronizzazione';

  @override
  String get editRequestQueued => 'Richiesta di modifica in coda';

  @override
  String get editRequestSubmitted => 'Richiesta di modifica inviata';

  @override
  String get hotelUpdated => 'Informazioni dell\'hotel aggiornate';

  @override
  String get hotelCreatedSuccessfully => 'Hotel creato con successo';

  @override
  String get requiredField => 'Obbligatorio';

  @override
  String get enterNumberError => 'Inserisci un numero';

  @override
  String get createHotel => 'Crea hotel';

  @override
  String get requestHotelEdit => 'Richiedi modifica hotel';

  @override
  String get authTitleCannotAccess =>
      'Questo account richiede un invito per accedere a Ivra.';

  @override
  String get authBtnGoogleSignIn => 'Accedi con Google';

  @override
  String get authBtnSignOut => 'Disconnettersi';

  @override
  String get authLabelEmail => 'E-mail';

  @override
  String get authLabelPassword => 'Password';

  @override
  String get authShowPassword => 'Mostra password';

  @override
  String get authHidePassword => 'Nascondi password';

  @override
  String get authBtnSignIn => 'Accedi';

  @override
  String get authBtnForgotPassword => 'Password dimenticata?';

  @override
  String get authResetPasswordTitle => 'Reimposta la password';

  @override
  String get setPasswordTitle => 'Imposta la tua password';

  @override
  String get setPasswordBody =>
      'Imposta una password sicura per il tuo account per completare la registrazione.';

  @override
  String get setPasswordButton => 'Imposta password';

  @override
  String get authBtnSendResetLink => 'Invia link di ripristino';

  @override
  String get authResetLinkSent =>
      'Link di reimpostazione della password inviato a';

  @override
  String get authValidationEmailRequired => 'L\'e-mail è richiesta';

  @override
  String get authValidationEmailInvalid =>
      'Inserisci un indirizzo e-mail valido';

  @override
  String get authValidationPasswordRequired => 'La password è richiesta';

  @override
  String get authValidationPasswordTooShort =>
      'La password deve contenere almeno 8 caratteri';

  @override
  String get authValidationPasswordsDoNotMatch =>
      'Le password non corrispondono';

  @override
  String get authResetNewPasswordTitle => 'Crea una nuova password';

  @override
  String get authLabelNewPassword => 'Nuova password';

  @override
  String get authLabelConfirmPassword => 'Conferma password';

  @override
  String get authBtnUpdatePassword => 'Aggiorna password';

  @override
  String get authBtnReturnToApp => 'Torna all\'applicazione';

  @override
  String get authPasswordUpdatedSuccess => 'Password aggiornata con successo.';

  @override
  String get authUnexpectedError =>
      'Si è verificato un errore. Riprova o contatta l\'assistenza se il problema persiste.';

  @override
  String get asyncErrorTitle => 'Impossibile caricare questa sezione';

  @override
  String get btnRetry => 'Riprova';

  @override
  String get authProfileLoadErrorTitle =>
      'Impossibile caricare il tuo profilo.';

  @override
  String get authProfileLoadErrorBody =>
      'Di solito è un problema di connessione temporaneo. Riprova.';

  @override
  String get authAccountDeactivated =>
      'Questo account è stato disattivato. Contatta l\'amministratore per riaccedere.';

  @override
  String get settingsPayloadInvalidJson =>
      'Il payload deve essere un oggetto JSON.';

  @override
  String exportDownloadStarted(String fileName) {
    return 'Download di $fileName avviato';
  }

  @override
  String exportSaved(String fileName, String path) {
    return '$fileName salvato in $path';
  }

  @override
  String settingsPendingSync(String count) {
    return 'Sincronizzazione in attesa ($count)';
  }

  @override
  String get splashTagline => 'Soluzioni di ospitalità sostenibile';

  @override
  String get accountSaveFailed => 'Impossibile salvare il profilo. Riprova.';

  @override
  String get accountPasswordChangeFailed =>
      'Impossibile cambiare la password. Riprova.';

  @override
  String get accountSignOutFailed =>
      'Impossibile uscire. Controlla la connessione e riprova.';

  @override
  String get hotelCreateFailed => 'Impossibile creare l\'hotel. Riprova.';

  @override
  String get hotelUpdateFailed => 'Impossibile aggiornare l\'hotel. Riprova.';

  @override
  String get teamInviteFailed => 'Impossibile inviare l\'invito. Riprova.';

  @override
  String get teamHotelsUpdateFailed =>
      'Impossibile aggiornare le assegnazioni hotel. Riprova.';

  @override
  String get roomsTooltipCreateTemplate => 'Crea modello camera';

  @override
  String get roomsNoRoomsFound => 'Nessuna camera o prodotto trovato.';

  @override
  String get roomsSearchEmptyHint =>
      'Prova a modificare la ricerca o i filtri.';

  @override
  String get roomsEmptyHotelWithTemplate =>
      'Aggiungi la tua prima camera con il pulsante modello in alto.';

  @override
  String get roomsEmptyHotelNoTemplate =>
      'Nessuna camera è ancora stata assegnata a questo hotel.';

  @override
  String get roomsLabelRoom => 'Camera';

  @override
  String get roomsLabelFloor => 'Piano';

  @override
  String get roomsLabelRefills => 'Ricariche';

  @override
  String get roomsLabelAge => 'Età';

  @override
  String get roomsLabelDaysUnit => 'g';

  @override
  String get roomsRefillQueued => 'Ricarica in coda per la camera';

  @override
  String get roomsRefillRecorded => 'Ricarica registrata per la camera';

  @override
  String get roomsBtnBottleEdit => 'Modifica bottiglia';

  @override
  String get roomsBtnReplaceBottle => 'Sostituisci bottiglia';

  @override
  String get roomsBtnRoomEdit => 'Modifica camera';

  @override
  String get roomsBtnHistory => 'Cronologia';

  @override
  String get roomsBtnMoreActions => 'Altre azioni';

  @override
  String get roomsReplacementQueued =>
      'Sostituzione bottiglia in coda per la camera';

  @override
  String get roomsReplacementRecorded => 'Bottiglia sostituita per la camera';

  @override
  String get roomsReplacementNotes => 'Bottiglia sostituita dal flusso camera';

  @override
  String get roomsStatusAllOk => 'Tutto OK';

  @override
  String get roomsStatusAttentionRequired => 'Richiesto intervento';

  @override
  String get roomsStatusRefillNeeded => 'Ricarica necessaria';

  @override
  String get roomsSearchPlaceholder => 'Cerca camera...';

  @override
  String get roomsRecentTitle => 'Camere recenti';

  @override
  String get roomsRecentClear => 'Cancella';

  @override
  String get roomsSelectHotelFirst => 'Seleziona hotel...';

  @override
  String get roomsViewDetailed => 'Vista dettagliata';

  @override
  String get roomsViewCompact => 'Vista compatta';

  @override
  String get roomsCollapseAll => 'Comprimi tutto';

  @override
  String get roomsExpandAll => 'Espandi tutto';

  @override
  String get roomsBtnAddRoom => 'Aggiungi camera';

  @override
  String get roomsDialogAddRoomTitle => 'Aggiungi camera al piano';

  @override
  String get roomsMsgRoomAdded => 'Camera aggiunta';

  @override
  String get roomsMsgRoomAddQueued => 'Creazione camera in coda';

  @override
  String get roomsHistoryRefill => 'Ricaricato';

  @override
  String get roomsHistoryNewBottle => 'Nuova bottiglia posizionata';

  @override
  String get roomsFilterAll => 'Tutti';

  @override
  String get roomsDialogBottleEditTitle =>
      'Richiesta modifica bottiglia per camera';

  @override
  String get roomsLabelBottleStatus => 'Stato bottiglia';

  @override
  String get roomsLabelBottleStartDate => 'Data inizio bottiglia';

  @override
  String get roomsValidationEnterValidDate => 'Inserisci una data valida';

  @override
  String get roomsMsgEditRequestQueued =>
      'Richiesta modifica bottiglia in coda';

  @override
  String get roomsMsgDetailsUpdated => 'Dettagli bottiglia aggiornati';

  @override
  String get roomsMsgEditRequestSubmitted =>
      'Richiesta modifica bottiglia inviata';

  @override
  String get roomsDialogRoomEditTitle => 'Richiesta modifica camera per';

  @override
  String get roomsLabelRoomNumber => 'Numero camera';

  @override
  String get roomsLabelFloorNumber => 'Numero piano';

  @override
  String get roomsMsgRoomEditQueued => 'Richiesta modifica camera in coda';

  @override
  String get roomsMsgRoomDetailsUpdated => 'Dettagli camera aggiornati';

  @override
  String get roomsMsgRoomEditSubmitted => 'Richiesta modifica camera inviata';

  @override
  String get roomsMsgRequestRoomEdit => 'Aggiorna camera';

  @override
  String get roomsDialogHistoryTitle => 'cronologia';

  @override
  String get roomsNoHistoryRecorded =>
      'Nessuna cronologia ricariche registrata.';

  @override
  String get roomsMsgUndoQueued => 'Annullamento in coda';

  @override
  String get roomsMsgRefillUndone => 'Ricarica annullata';

  @override
  String get roomsBtnClose => 'Chiudi';

  @override
  String get qrScanTitle => 'Scansiona codice QR';

  @override
  String get qrScanPlaceholder => 'Inserisci codice QR manualmente...';

  @override
  String get qrDemoCodes => 'Codici QR dimostrativi';

  @override
  String get qrActionPrompt => 'Seleziona Azione';

  @override
  String qrActionMessage(String product) {
    return 'Cosa vorresti fare per $product?';
  }

  @override
  String get qrActionRefill => 'Ricarica bottiglia';

  @override
  String get qrActionReplace => 'Sostituisci bottiglia';

  @override
  String get roomsSearchProductPlaceholder =>
      'Cerca prodotto per nome o SKU...';

  @override
  String adjustStockForProduct(String product) {
    return 'Regola stock per $product';
  }

  @override
  String get roomsBtnRequestCorrection => 'Richiedi correzione';

  @override
  String get roomsLabelReason => 'Motivo';

  @override
  String get roomsMsgCorrectionQueued => 'Richiesta correzione in coda';

  @override
  String get roomsMsgCorrectionSubmitted => 'Richiesta correzione inviata';

  @override
  String get roomsBtnCreateRooms => 'Crea camere';

  @override
  String get roomsLabelProductsInRoom => 'Prodotti in ciascuna camera';

  @override
  String get roomsMsgSelectOneProduct => 'Seleziona almeno un prodotto';

  @override
  String roomsMsgDuplicateRoomNumbers(String numbers) {
    return 'Questi numeri di camera esistono già in questo hotel: $numbers. Scegli un numero iniziale o un conteggio diverso.';
  }

  @override
  String get productsCatalogTitle => 'Catalogo Prodotti';

  @override
  String get productsBtnCreate => 'Crea prodotto';

  @override
  String get productsNoProducts => 'Nessun prodotto nel catalogo ancora.';

  @override
  String get productsLabelBottleVolume => 'Volume della bottiglia';

  @override
  String get productsLabelBidonVolume => 'Volume bottiglia di ricarica';

  @override
  String get productsLabelMaxRefill => 'Limite di ricariche';

  @override
  String get productsLabelMaxAge => 'Età massima della bottiglia';

  @override
  String get productsLabelLowStock => 'Avviso stock basso';

  @override
  String get productsBtnEdit => 'Modifica prodotto';

  @override
  String get productsLabelSku => 'SKU';

  @override
  String get productsLabelNameEn => 'Nome Inglese';

  @override
  String get productsLabelNameFr => 'Nome Francese';

  @override
  String get productsLabelNameAr => 'Nome Arabo';

  @override
  String get productsLabelNameIt => 'Nome Italiano';

  @override
  String get productsLabelImage => 'Carica Immagine';

  @override
  String get productsLabelImageHint =>
      'Seleziona un\'immagine dal tuo dispositivo';

  @override
  String productsImageSelected(String name) {
    return 'Selezionato: $name';
  }

  @override
  String get productsImageSet => 'Immagine impostata (tocca per cambiare)';

  @override
  String get productsImageNone => 'Nessuna immagine selezionata';

  @override
  String get productsImageRemove => 'Rimuovi immagine';

  @override
  String get productsImageUploadFailed =>
      'Caricamento immagine non riuscito. Riprova.';

  @override
  String get productsImageInvalidType => 'Seleziona un file immagine valido.';

  @override
  String productsImageTooLarge(String max) {
    return 'L\'immagine è troppo grande (max $max MB).';
  }

  @override
  String get productsAddedSuccess => 'Prodotto aggiunto con successo';

  @override
  String get productsUpdatedSuccess => 'Prodotto aggiornato con successo';

  @override
  String get productsLabelBottleMl => 'Bottiglia ml';

  @override
  String get productsLabelBidonMl => 'Bottiglia di ricarica ml';

  @override
  String get productsLabelMaxRefills => 'Ricariche max';

  @override
  String get productsLabelMaxAgeDays => 'Età max giorni';

  @override
  String get productsLabelLowBottles => 'Soglia bottiglie';

  @override
  String get productsLabelLowBidons => 'Soglia bottiglie di ricarica';

  @override
  String get productsLabelBottleType => 'Tipo di bottiglia';

  @override
  String get productsLabelBottleWithPump => 'Bottiglia con pompa';

  @override
  String get productsLabelBottleWithoutPump => 'Bottiglia senza pompa';

  @override
  String get productsLabelRefillType => 'Tipo di ricarica';

  @override
  String get productsLabelRefillable => 'Ricaricabile';

  @override
  String get productsLabelDirectReplacement => 'Sostituzione diretta';

  @override
  String get productsDialogCreateTitle => 'Crea prodotto';

  @override
  String get productsDialogEditTitle => 'Modifica prodotto';

  @override
  String get days => 'giorni';

  @override
  String get refills => 'ricariche';

  @override
  String get inventoryNoHotels => 'Nessun hotel trovato';

  @override
  String get inventoryAddHotelHint => 'Aggiungi un hotel per iniziare.';

  @override
  String get inventoryNoItemsToAdjust =>
      'Nessun articolo di inventario disponibile da regolare.';

  @override
  String get inventoryNoInventoryYet => 'Nessun inventario ancora';

  @override
  String get inventoryNoProductsInInventory =>
      'Non ci sono prodotti nell\'inventario.';

  @override
  String get inventoryNoSuggestedOrders => 'Nessun ordine suggerito';

  @override
  String get inventoryLevelsSufficient =>
      'I tuoi livelli di inventario sono attualmente sufficienti.';

  @override
  String get teamAccounts => 'Account del team';

  @override
  String get teamNoMembers => 'Nessun membro del team trovato.';

  @override
  String get teamTableColumnName => 'Nome';

  @override
  String get teamTableColumnEmail => 'Email';

  @override
  String get teamTableColumnRole => 'Ruolo';

  @override
  String get teamTableColumnHotel => 'Hotel';

  @override
  String get teamTableColumnStatus => 'Stato';

  @override
  String get teamTableColumnActions => 'Azioni';

  @override
  String get teamPendingInvitations => 'Inviti in attesa';

  @override
  String get teamNoPendingInvitations => 'Nessun invito in attesa.';

  @override
  String get teamInviteTitle => 'Invita membro';

  @override
  String get teamLabelFullName => 'Nome e cognome';

  @override
  String get settingsOfflineMode => 'Modalità offline';

  @override
  String get settingsOfflineQueue => 'Metti in coda';

  @override
  String get settingsOfflineSend => 'Invia azioni';

  @override
  String get settingsBiometricTitle => 'Sblocco biometrico';

  @override
  String get settingsBiometricHint =>
      'Usa la tua impronta o il volto per accedere.';

  @override
  String get settingsBiometricUnavailable =>
      'Lo sblocco biometrico non è disponibile su questo dispositivo.';

  @override
  String get authBtnBiometricLogin => 'Accesso biometrico';

  @override
  String get authBiometricReason => 'Autenticati per accedere a Ivra';

  @override
  String get authBiometricNeedsLogin =>
      'Accedi una volta per abilitare l\'accesso biometrico.';

  @override
  String get authBiometricOfflineNoSession =>
      'Sei offline. Connettiti a Internet per accedere.';

  @override
  String get authBiometricFailed => 'Autenticazione biometrica non riuscita.';

  @override
  String get settingsBtnClear => 'Pulisci';

  @override
  String get settingsBtnSyncNow => 'Sincronizza';

  @override
  String get settingsNoPendingActions => 'Nessuna azione in attesa.';

  @override
  String get teamManageHotels => 'Gestisci hotel';

  @override
  String get teamAssignHotelsTitle => 'Assegna hotel';

  @override
  String get teamNoHotelsAssigned => 'Nessun hotel assegnato';

  @override
  String get teamHotelsUpdated => 'Assegnazioni aggiornate';

  @override
  String get teamSelectHotels => 'Seleziona hotel';

  @override
  String get teamHotelsAssigned => 'hotel assegnati';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountProfile => 'Profilo';

  @override
  String get accountProfileUpdated => 'Profilo aggiornato';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountPasswordUpdated => 'Password aggiornata';

  @override
  String get accountFullName => 'Nome completo';

  @override
  String get accountFullNameRequired => 'Il nome completo è obbligatorio';

  @override
  String get accountNewPassword => 'Nuova password';

  @override
  String get accountConfirmPassword => 'Conferma nuova password';

  @override
  String get accountPasswordHintSupabase =>
      'Aggiorna la password di accesso del tuo account.';

  @override
  String get accountPasswordHintDemo =>
      'La modalità demo accetta la modifica localmente.';

  @override
  String get accountSignOutHint =>
      'Termina la sessione corrente su questo dispositivo.';

  @override
  String get accountSignOut => 'Esci';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountRole => 'Ruolo';

  @override
  String get accountScope => 'Ambito';

  @override
  String get accountStatus => 'Stato';

  @override
  String get accountActive => 'Attivo';

  @override
  String get accountInactive => 'Inattivo';

  @override
  String get accountIvraGlobal => 'Ivra globale';

  @override
  String get accountTeamAccounts => 'Account del team';

  @override
  String get accountNoOtherAccounts => 'Nessun altro account trovato.';

  @override
  String get accountYou => 'Tu';

  @override
  String get alertsRefreshSmart => 'Aggiorna avvisi intelligenti';

  @override
  String get alertsResolve => 'Risolvi';

  @override
  String get delete => 'Elimina';

  @override
  String get approvalsEmpty => 'Nessuna approvazione in sospeso';

  @override
  String get approvalsEmptySubtitle =>
      'Tutte le richieste di approvazione sono state elaborate.';

  @override
  String get approvalsApprove => 'Approva';

  @override
  String get approvalsReject => 'Rifiuta';

  @override
  String get approvalsActionFailed => 'L\'azione non è riuscita. Riprova.';

  @override
  String get approvalsApproved => 'Richiesta approvata.';

  @override
  String get approvalsRejected => 'Richiesta rifiutata.';

  @override
  String get approvalsApproveQueued =>
      'Approvazione in coda per la sincronizzazione.';

  @override
  String get approvalsRejectQueued =>
      'Rifiuto in coda per la sincronizzazione.';

  @override
  String get approvalsAccessDenied =>
      'Accesso negato. Solo gli admin possono approvare.';

  @override
  String get approvalsRequestNotFound =>
      'Richiesta non trovata o già elaborata.';

  @override
  String get inviteAcceptTitle => 'Accetta l\'invito';

  @override
  String get inviteAlreadyHaveAccount => 'Ho già un account';

  @override
  String get inviteBackToSignIn => 'Torna al login';

  @override
  String get inviteEmail => 'Email';

  @override
  String get invitePassword => 'Password';

  @override
  String get inviteConfirmPassword => 'Conferma password';

  @override
  String get settingsRetryAction => 'Riprova azione';

  @override
  String get settingsRemoveAction => 'Rimuovi azione';

  @override
  String get settingsActionUpdated => 'Azione in coda aggiornata';

  @override
  String get settingsActionRemoved => 'Azione offline rimossa';

  @override
  String get settingsQueueCleared => 'Coda offline svuotata';

  @override
  String get settingsTestAccessAs => 'Testa accesso come';

  @override
  String get settingsDemoUserChanged => 'Utente demo cambiato';

  @override
  String get settingsPayloadJson => 'Payload JSON in coda';

  @override
  String get settingsSaveAndRetry => 'Salva e riprova';

  @override
  String get settingsDemoUser => 'Utente demo';

  @override
  String get settingsSupabaseConnected => 'Connesso';

  @override
  String get settingsSupabaseHint => 'L\'app utilizza dati live.';

  @override
  String get settingsNoSupabaseHint =>
      'La connessione al server non è configurata.';

  @override
  String get settingsEditAction => 'Modifica azione in coda';

  @override
  String get settingsResolveConflict => 'Risolvi conflitto di sync';

  @override
  String get settingsActionSynced => 'Azione sincronizzata';

  @override
  String get offlineBannerTitle => 'Sei offline';

  @override
  String get offlineBannerSubtitle => 'I dati potrebbero non essere aggiornati';

  @override
  String get offlineBannerPending => 'azioni in sospeso';

  @override
  String get offlineBannerSyncBtn => 'Sincronizza ora';

  @override
  String offlineBannerAutoSynced(String count) {
    return 'Di nuovo online! $count azioni sincronizzate';
  }

  @override
  String get offlineBannerSyncFailed =>
      'Sincronizzazione fallita per alcune azioni';

  @override
  String teamInvitationCancelled(String email) {
    return 'Invito annullato per $email';
  }

  @override
  String teamInvitationResent(String email) {
    return 'Invito reinviato a $email';
  }

  @override
  String teamInvitationCopied(String email) {
    return 'Link di invito copiato per $email';
  }

  @override
  String approvalsRequestedBy(String name) {
    return 'Richiesto da $name';
  }

  @override
  String approvalsOldValue(String value) {
    return 'Vecchio: $value';
  }

  @override
  String approvalsNewValue(String value) {
    return 'Nuovo: $value';
  }

  @override
  String alertsSeverityLabel(String severity) {
    return 'Gravità $severity';
  }

  @override
  String get alertsStatusResolved => 'Risolto';

  @override
  String get alertsStatusOpen => 'Aperto';

  @override
  String get alertsMetricCritical => 'Critico';

  @override
  String get alertsFilterTitle => 'Filtri';

  @override
  String get alertsFilterSeverity => 'Gravità';

  @override
  String get alertsFilterType => 'Tipo';

  @override
  String get alertsFilterHotel => 'Hotel';

  @override
  String get alertsFilterProduct => 'Prodotto';

  @override
  String get alertsFilterAll => 'Tutti';

  @override
  String get alertsFilterClear => 'Cancella filtri';

  @override
  String get alertsFilterNoMatch =>
      'Nessun avviso corrisponde ai filtri correnti.';

  @override
  String alertsFilterShowing(String count, String total) {
    return 'Mostrando $count di $total';
  }

  @override
  String get settingsActionEditTitle => 'Modifica azione in coda';

  @override
  String get settingsActionConflictTitle =>
      'Risolvi conflitto di sincronizzazione';

  @override
  String settingsActionAttempts(String count) {
    return 'Tentativi $count';
  }

  @override
  String settingsActionListAttempts(String count) {
    return 'Tentativi: $count';
  }

  @override
  String settingsActionListError(String message) {
    return 'Errore: $message';
  }

  @override
  String get syncActionRefill => 'Ricarica';

  @override
  String get syncActionUndoRefill => 'Annulla ricarica';

  @override
  String get syncActionCorrectionRequest => 'Richiesta di correzione';

  @override
  String get syncActionBottleReplacement => 'Sostituzione bottiglia';

  @override
  String get syncActionStockAdjustment => 'Aggiustamento del magazzino';

  @override
  String get syncActionPendingEdit => 'Modifica in attesa';

  @override
  String get userRoleAppAdmin => 'Amministratore app';

  @override
  String get userRoleAppManager => 'Responsabile app';

  @override
  String get userRoleHotelManager => 'Responsabile hotel';

  @override
  String get userRoleHotelStaff => 'Personale hotel';

  @override
  String get teamStatusActive => 'Attivo';

  @override
  String get teamStatusInactive => 'Inattivo';

  @override
  String get teamHotelAll => 'Tutti gli hotel';

  @override
  String get teamHotelNone => '—';

  @override
  String get invitationStatusPending => 'In attesa';

  @override
  String get invitationStatusAccepted => 'Accettato';

  @override
  String get invitationStatusCancelled => 'Annullato';

  @override
  String get invitationStatusExpired => 'Scaduto';

  @override
  String get alertResolvedToast => 'Avviso risolto';

  @override
  String get alertDeletedToast => 'Avviso eliminato';

  @override
  String get alertResolveFailedToast =>
      'Impossibile risolvere l\'avviso. Riprova.';

  @override
  String get alertDeleteFailedToast =>
      'Impossibile eliminare l\'avviso. Riprova.';

  @override
  String get notificationAcknowledgedToast => 'Confermato';

  @override
  String get notificationMoreInfo => 'Più info';

  @override
  String get bulkAdjustStockTitle => 'Regolazione di massa';

  @override
  String get bulkAdjustStockHint =>
      'Inserisci le regolazioni che si applicheranno a TUTTI i prodotti.';

  @override
  String get bulkAdjustStockSuccess =>
      'Regolazione di massa applicata con successo';

  @override
  String get bulkAdjustStockOfflineQueued =>
      'Regolazioni di massa messe in coda per la sincronizzazione offline';

  @override
  String get resolveAll => 'Risolvi tutti';

  @override
  String get deleteAll => 'Elimina tutti';

  @override
  String alertsRefreshedToast(String count) {
    return '$count avvisi intelligenti creati';
  }

  @override
  String get alertsEmptyTitle => 'Nessun avviso al momento';

  @override
  String get alertsEmptyMessage =>
      'Aggiorna gli avvisi intelligenti per scansionare scorte, limiti di ricarica, età delle bottiglie e approvazioni in sospeso.';

  @override
  String get alertsEmptyAction => 'Aggiorna avvisi';

  @override
  String get alertTypeLowBidonStock => 'Scorte basse (bottiglie di ricarica)';

  @override
  String alertLowBottleTitle(String product) {
    return 'Scorte basse di bottiglie di $product';
  }

  @override
  String alertLowBidonTitle(String product) {
    return 'Scorte basse di bottiglie di ricarica di $product';
  }

  @override
  String alertLowBottleBody(String hotel, String remain, String threshold) {
    return '$hotel: rimangono $remain bottiglie piene. La soglia è $threshold.';
  }

  @override
  String alertLowBidonBody(String hotel, String remain, String threshold) {
    return '$hotel: rimangono $remain bottiglie di ricarica piene. La soglia è $threshold.';
  }

  @override
  String get alertTypeLowBottleStock => 'Scorte basse (bottiglie)';

  @override
  String get alertTypeBottleAgeLimit => 'Età bottiglia';

  @override
  String alertBottleAgeLimitTitle(String room, String product) {
    return 'Camera $room: la bottiglia di $product è troppo vecchia';
  }

  @override
  String alertBottleAgeLimitBody(String age, String limit) {
    return 'L\'età della bottiglia è di $age giorni. Il limite è di $limit giorni.';
  }

  @override
  String get alertTypeRefillLimit => 'Limite ricariche';

  @override
  String alertRefillLimitTitle(String room, String product) {
    return 'Camera $room: $product ha raggiunto il limite di ricariche';
  }

  @override
  String alertRefillLimitBody(String used, String max) {
    return '$used/$max ricariche utilizzate. Sostituisci e ricicla la bottiglia.';
  }

  @override
  String get alertTypePendingApproval => 'Approvazione';

  @override
  String alertPendingApprovalTitle(String request) {
    return 'Approvazione in sospeso: $request';
  }

  @override
  String alertPendingApprovalBody(String name) {
    return 'Richiesto da $name.';
  }

  @override
  String get alertTypeSuspiciousActivity => 'Attività sospetta';

  @override
  String get alertTypeInactiveHotel => 'Hotel inattivo';

  @override
  String get refillEventApproved => 'Approvato';

  @override
  String get refillEventRejected => 'Rifiutato';

  @override
  String get teamDeactivateAccountTooltip => 'Disattiva account';

  @override
  String get teamReactivateAccountTooltip => 'Riattiva account';

  @override
  String settingsSyncedSummary(String synced) {
    return '$synced azioni sincronizzate';
  }

  @override
  String settingsSyncedSummarySingular(String synced) {
    return '$synced azione sincronizzata';
  }

  @override
  String settingsSyncedWithFailures(String synced, String failed) {
    return '$synced sincronizzate, $failed fallite';
  }

  @override
  String get inviteAcceptHeading => 'Accetta invito Ivra';

  @override
  String inviteSubtitleWithHotel(String name, String role, String hotel) {
    return '$name è stato/a invitato/a come $role per $hotel.';
  }

  @override
  String inviteSubtitleNoHotel(String name, String role) {
    return '$name è stato/a invitato/a come $role.';
  }

  @override
  String get inviteEmailMismatch =>
      'Usa l\'indirizzo email a cui è stato inviato questo invito.';

  @override
  String get inviteAccountCreatedConfirm =>
      'Account creato. Conferma la tua email, poi torna a questo link di invito e inserisci la stessa password per completare.';

  @override
  String get inviteInvalidHeading => 'Invito non disponibile';

  @override
  String get inviteInvalidBody =>
      'Questo invito potrebbe essere scaduto, annullato o già accettato.';

  @override
  String teamMemberReactivated(String name) {
    return '$name riattivato';
  }

  @override
  String teamMemberDeactivated(String name) {
    return '$name disattivato';
  }

  @override
  String settingsActionLastTried(String datetime) {
    return 'Ultimo tentativo $datetime';
  }

  @override
  String get settingsActionNeedsReview => 'Azione ancora da rivedere';

  @override
  String get teamInviteLinkUnavailable =>
      'Il link dell\'invito non è disponibile';

  @override
  String get teamCopyLink => 'Copia il link dell\'invito';

  @override
  String get teamResendInvitation => 'Rinvia l\'invito';

  @override
  String get teamCancelInvitation => 'Annulla l\'invito';

  @override
  String get teamCannotInviteSelf => 'Non puoi invitare te stesso';

  @override
  String get btnUpdate => 'Aggiorna';

  @override
  String get notFoundTitle => 'Pagina Non Trovata';

  @override
  String get notFoundBody =>
      'La pagina che stai cercando non esiste o è stata spostata.';

  @override
  String get notFoundButton => 'Torna alla Dashboard';

  @override
  String get downloadAppBannerText =>
      'Per la migliore esperienza, scarica la nostra App Android.';

  @override
  String get downloadAppBannerButton => 'Scarica App';

  @override
  String get sendPushTitle => 'Invia notifica';

  @override
  String get teamViewAs => 'Visualizza come';

  @override
  String impersonationBanner(String name) {
    return 'Visualizzazione come $name';
  }

  @override
  String get impersonationExit => 'Esci';

  @override
  String get pdfHeaderType => 'Tipo';

  @override
  String get pdfHeaderPrevious => 'Precedente';

  @override
  String get pdfHeaderNew => 'Nuovo';

  @override
  String get pdfHeaderOccurredAt => 'Verificatosi il';

  @override
  String get pdfHeaderNotes => 'Note';

  @override
  String get pdfHeaderProduct => 'Prodotto';

  @override
  String get pdfHeader1LBottles => 'Bottiglie 1L';

  @override
  String get pdfHeader5LBidons => 'Bidoni 5L';

  @override
  String get pdfHeaderRecycle => 'Riciclare';

  @override
  String get pdfHeaderFullBottles => 'Bottiglie piene';

  @override
  String get pdfHeaderEmptyBottles => 'Bottiglie vuote';

  @override
  String get pdfHeaderFullBidons => 'Bidoni pieni';

  @override
  String get pdfHeaderOpenBidons => 'Bidoni aperti';

  @override
  String get pdfHeaderEmptyBidons => 'Bidoni vuoti';

  @override
  String get pdfHeaderSeverity => 'Gravità';

  @override
  String get pdfHeaderTitle => 'Titolo';

  @override
  String get pdfHeaderCreatedAt => 'Creato il';

  @override
  String get approvalStatusApproved => 'Approvato';

  @override
  String get approvalStatusRejected => 'Rifiutato';

  @override
  String get approvalStatusCancelled => 'Annullato';

  @override
  String get approvalStatusPending => 'In attesa';

  @override
  String get pdfTitleSuggestedOrders => 'Ordini suggeriti Ivra';

  @override
  String get pdfTitleInventorySnapshot => 'Stato inventario Ivra';

  @override
  String get pdfTitleRefillHistory => 'Cronologia ricariche Ivra';

  @override
  String get pdfTitleOpenAlerts => 'Avvisi aperti Ivra';

  @override
  String get productHistoryTitle => 'Cronologia del prodotto';

  @override
  String get productHistoryNoHistory =>
      'Nessuna cronologia registrata per questo prodotto.';

  @override
  String productHistoryRefill(String roomNumber) {
    return 'Ricaricato nella camera $roomNumber';
  }

  @override
  String productHistoryReplacement(String roomNumber) {
    return 'Bottiglia sostituita nella camera $roomNumber';
  }

  @override
  String get productHistoryAdjustment => 'Regolazione manuale delle scorte';

  @override
  String productHistoryActionBy(String user) {
    return 'Da $user';
  }

  @override
  String productHistoryReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get productHistoryDeltaFullBottles => 'Bottiglie piene';

  @override
  String get productHistoryDeltaUsedBottles => 'Bottiglie usate';

  @override
  String get productHistoryDeltaFullBidons => 'Bottiglie di ricarica piene';

  @override
  String get productHistoryDeltaOpenBidons => 'Bottiglie usate e aperte';

  @override
  String get productHistoryDeltaEmptyBidons => 'Bottiglie usate e vuote';

  @override
  String productHistoryNewBottle(String roomNumber) {
    return 'Nuova bottiglia posizionata nella camera $roomNumber';
  }

  @override
  String get productHistoryFilterAll => 'Tutti';

  @override
  String get productHistoryFilterRoom => 'Eventi camera';

  @override
  String get productHistoryFilterManual => 'Regolazioni';

  @override
  String get productHistoryStatRefills => 'Ricariche';

  @override
  String get productHistoryStatReplacements => 'Sostituzioni';

  @override
  String get productHistoryStatAdjustments => 'Regolazioni';
}
