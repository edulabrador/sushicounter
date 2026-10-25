// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sushi Tracker';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get navCounter => 'Counter';

  @override
  String get navHistory => 'History';

  @override
  String get navStats => 'Stats';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get reset => 'Reset';

  @override
  String get undo => 'Undo';

  @override
  String get storageError => 'Could not open your saved data.';

  @override
  String get tryAgain => 'Try again';

  @override
  String currentSessionSemantics(int count) {
    return 'Current session: $count sushi';
  }

  @override
  String get tapToStart => 'Tap the sushi to start';

  @override
  String get tapHint => 'Tap to add · Long press or Undo to remove';

  @override
  String get sushiButtonLabel => 'Add one sushi';

  @override
  String get sushiButtonHint =>
      'Double tap to add one. Long press to remove one.';

  @override
  String get endSession => 'End Session';

  @override
  String get thisSession => 'This session';

  @override
  String get lifetimeTotal => 'Lifetime total';

  @override
  String get elapsed => 'Elapsed';

  @override
  String get errorSaveOngoing => 'Could not save the current session.';

  @override
  String get errorResetCurrent => 'Could not reset the current session.';

  @override
  String get errorCompleteSession =>
      'Could not save this session. Please try again.';

  @override
  String get discardSession => 'Discard session';

  @override
  String get discardSessionTitle => 'Discard this session?';

  @override
  String get discardSessionBody => 'Its taps will not be saved to history.';

  @override
  String get discard => 'Discard';

  @override
  String get sessionDiscarded => 'Session discarded.';

  @override
  String get historyTitle => 'SESSION HISTORY';

  @override
  String get noSessions => 'No sessions yet.';

  @override
  String durationLabel(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get beforeReset => 'Before lifetime reset';

  @override
  String get deleteSessionTooltip => 'Delete session';

  @override
  String get deleteSessionTitle => 'Delete Session?';

  @override
  String get deleteSessionBody =>
      'This removes it from history. It updates the lifetime total when it belongs to the current lifetime.';

  @override
  String sessionsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions deleted',
      one: 'Session deleted',
    );
    return '$_temp0';
  }

  @override
  String get couldNotDelete =>
      'Could not delete this session. Please try again.';

  @override
  String get couldNotRestore => 'Could not restore this session.';

  @override
  String get sessionDetails => 'Session Details';

  @override
  String get beforeResetDetail =>
      'Recorded before the last lifetime reset, so it is not part of the current lifetime totals.';

  @override
  String get statsTitle => 'STATISTICS';

  @override
  String get lifetimeTaps => 'Lifetime Taps';

  @override
  String get lifetimeSessions => 'Lifetime Sessions';

  @override
  String averageKpi(String range) {
    return 'Average ($range)';
  }

  @override
  String bestKpi(String range) {
    return 'Best ($range)';
  }

  @override
  String get filterLast7 => '7 sessions';

  @override
  String get filterLast30 => '30 sessions';

  @override
  String get filterAll => 'All sessions';

  @override
  String get rangeSemantics => 'Session range in number of sessions';

  @override
  String get sessionTrend => 'Session trend';

  @override
  String get noTrend => 'Complete a session to see your trend.';

  @override
  String chartSemantics(int count) {
    return 'Session trend chart for $count sessions. Tap a point to see its date and tap count.';
  }

  @override
  String tapsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count taps',
      one: '1 tap',
    );
    return '$_temp0';
  }

  @override
  String sinceReset(String date) {
    return 'Since the lifetime reset on $date';
  }

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get resetCurrentTitle => 'Reset Current Session';

  @override
  String get resetCurrentSubtitle => 'Clear active taps without saving';

  @override
  String get resetCurrentDialogTitle => 'Reset Current Session?';

  @override
  String get resetCurrentDialogBody =>
      'This will clear your ongoing taps without saving.';

  @override
  String get currentSessionReset => 'Current session reset.';

  @override
  String get resetLifetimeTitle => 'Reset Lifetime Global';

  @override
  String get resetLifetimeSubtitle =>
      'Permanently reset all-time taps and sessions to 0';

  @override
  String get finishSessionFirst => 'End or reset the current session first.';

  @override
  String get permanentReset => 'PERMANENT RESET';

  @override
  String permanentResetBody(String keyword) {
    return 'This action permanently wipes your lifetime stats. Session history remains intact but totals return to 0.\n\nType \"$keyword\" to confirm.';
  }

  @override
  String get resetKeyword => 'RESET';

  @override
  String get confirmReset => 'CONFIRM RESET';

  @override
  String get lifetimeResetDone => 'Global lifetime stats reset.';

  @override
  String get couldNotResetLifetime =>
      'Could not reset lifetime stats. Please try again.';

  @override
  String get keepScreenOnTitle => 'Keep screen on during a session';

  @override
  String get keepScreenOnSubtitle =>
      'Uses a little more battery while you count';

  @override
  String get couldNotSaveSetting => 'Could not save this setting.';

  @override
  String get exportTitle => 'Export data';

  @override
  String get exportSubtitle => 'Save a backup of your history and totals';

  @override
  String exportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Backup of $count sessions copied to the clipboard.',
      one: 'Backup of 1 session copied to the clipboard.',
    );
    return '$_temp0';
  }

  @override
  String get importTitle => 'Import data';

  @override
  String get importSubtitle => 'Replace all data with a backup';

  @override
  String get importDialogTitle => 'Import backup';

  @override
  String get importDialogBody => 'Paste a Sushi Tracker backup.';

  @override
  String get importPaste => 'Paste';

  @override
  String get importConfirm => 'Replace data';

  @override
  String get importInvalid => 'This is not a valid Sushi Tracker backup.';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count sessions.',
      one: 'Imported 1 session.',
    );
    return '$_temp0';
  }

  @override
  String get importFailed => 'Could not import the backup.';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get privacyBody =>
      'Sushi Tracker does not collect, transmit, or share personal data. It has no accounts, analytics, ads, or network services.\n\nYour counts, session history, and lifetime totals are stored on this device. If Android backup is turned on for your Google account, Android may include this data in that backup and restore it when you reinstall the app or set up a new device. That backup is handled by Google under your account; the developer never receives it.\n\nClearing the app data removes it from this device. You can export your own copy from Settings.\n\nThe app requests no special device permissions.\n\nFor questions, contact labradorsantoseduardo@gmail.com.';

  @override
  String get sessionAlreadySaved =>
      'This session had already been saved to history.';

  @override
  String exportSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Backup of $count sessions saved.',
      one: 'Backup of 1 session saved.',
    );
    return '$_temp0';
  }

  @override
  String get couldNotSaveFile => 'Could not save the file.';

  @override
  String get couldNotReadFile => 'Could not read the file.';

  @override
  String get importNext => 'Continue';

  @override
  String get importConfirmTitle => 'Replace all data?';

  @override
  String importConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Your current history and totals will be replaced by the backup, which has $count sessions.',
      one:
          'Your current history and totals will be replaced by the backup, which has 1 session.',
    );
    return '$_temp0';
  }

  @override
  String get setPrice => 'Add price';

  @override
  String get editPrice => 'Edit price';

  @override
  String get priceDialogTitle => 'What did this meal cost?';

  @override
  String get priceHint => 'e.g. 24.90';

  @override
  String get priceInvalid => 'Enter an amount between 0 and 100,000.';

  @override
  String get save => 'Save';

  @override
  String get removePrice => 'Remove price';

  @override
  String get couldNotSavePrice => 'Could not save the price.';

  @override
  String costPerPiece(String range) {
    return 'Cost per piece ($range)';
  }

  @override
  String get recordsTitle => 'Records';

  @override
  String get bestEver => 'Best session';

  @override
  String get weeklyStreak => 'Weekly streak';

  @override
  String weeksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
      zero: 'No streak',
    );
    return '$_temp0';
  }

  @override
  String get sessionsThisMonth => 'Sessions this month';

  @override
  String get piecesThisMonth => 'Pieces this month';

  @override
  String recordToBeat(int best, int remaining) {
    return 'Record $best · $remaining to go';
  }

  @override
  String recordTied(int best) {
    return 'You matched your record of $best!';
  }

  @override
  String newRecord(int best) {
    return 'New record! Previous best: $best';
  }

  @override
  String get emptyHistoryHint => 'End a session and it will show up here.';

  @override
  String monthSummary(int sessions, int pieces) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions sessions',
      one: '1 session',
    );
    String _temp1 = intl.Intl.pluralLogic(
      pieces,
      locale: localeName,
      other: '$pieces pieces',
      one: '1 piece',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get recordBadge => 'Record';

  @override
  String get summaryTitle => 'Summary';

  @override
  String averageLine(String value) {
    return 'Avg $value';
  }

  @override
  String get weeklyTitle => 'Pieces per week';

  @override
  String weeklySemantics(int weeks) {
    return 'Bar chart of pieces eaten in each of the last $weeks weeks.';
  }

  @override
  String piecesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pieces',
      one: '1 piece',
    );
    return '$_temp0';
  }

  @override
  String piecesUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pieces',
      one: 'piece',
    );
    return '$_temp0';
  }

  @override
  String get settingsSectionSession => 'Session';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsSectionData => 'Your data';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsTagline => 'Your sushi, counted on this device.';

  @override
  String get loadingData => 'Getting your sushi ready…';

  @override
  String timeRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get detailPieces => 'Pieces';

  @override
  String get detailDuration => 'Duration';

  @override
  String get detailPace => 'Pace';

  @override
  String get detailPrice => 'Price';

  @override
  String paceValue(String pace) {
    return '$pace/min';
  }

  @override
  String get noValue => '—';

  @override
  String get addRestaurant => 'Add restaurant';

  @override
  String get editRestaurant => 'Change restaurant';

  @override
  String get restaurantDialogTitle => 'Where did you eat?';

  @override
  String get restaurantHint => 'e.g. Sushi Zen';

  @override
  String get removeRestaurant => 'Remove';

  @override
  String get couldNotSaveRestaurant => 'Could not save the restaurant.';

  @override
  String get byRestaurantTitle => 'By restaurant';

  @override
  String restaurantSummary(int sessions, String average) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions sessions',
      one: '1 session',
    );
    return '$_temp0 · avg $average';
  }

  @override
  String perPiece(String value) {
    return '$value/piece';
  }

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String achievementsCount(int unlocked, int total) {
    return '$unlocked of $total';
  }

  @override
  String achievementUnlocked(String name) {
    return 'Achievement unlocked: $name';
  }

  @override
  String achievementProgress(int progress, int target) {
    return '$progress/$target';
  }

  @override
  String get achFirstSession => 'First bite';

  @override
  String get achFirstSessionDesc => 'Save your first session';

  @override
  String get achTenSessions => 'Regular customer';

  @override
  String get achTenSessionsDesc => 'Save 10 sessions';

  @override
  String get achFiftySessions => 'Sushi veteran';

  @override
  String get achFiftySessionsDesc => 'Save 50 sessions';

  @override
  String get achBigAppetite => 'Big appetite';

  @override
  String get achBigAppetiteDesc => '30 pieces in one session';

  @override
  String get achSushiMaster => 'Sushi master';

  @override
  String get achSushiMasterDesc => '50 pieces in one session';

  @override
  String get achHundredPieces => 'Century';

  @override
  String get achHundredPiecesDesc => '100 pieces in total';

  @override
  String get achThousandPieces => 'Thousand club';

  @override
  String get achThousandPiecesDesc => '1,000 pieces in total';

  @override
  String get achRegular => 'Every week';

  @override
  String get achRegularDesc => '4 weeks in a row with a session';

  @override
  String get achPriceWatcher => 'Bargain hunter';

  @override
  String get achPriceWatcherDesc => 'Add the price to 5 sessions';

  @override
  String get achExplorer => 'Explorer';

  @override
  String get achExplorerDesc => 'Eat at 3 different restaurants';

  @override
  String get showAsList => 'Show as list';

  @override
  String get showAsChart => 'Show as chart';

  @override
  String weekOf(String date) {
    return 'Week of $date';
  }

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceSystem => 'System';

  @override
  String get editSession => 'Edit session';

  @override
  String get sessionStart => 'Start';

  @override
  String countInvalid(int max) {
    return 'Enter a whole number from 1 to $max.';
  }

  @override
  String get sessionInFuture => 'A session cannot end in the future.';

  @override
  String get couldNotSaveSession => 'Could not save the changes.';
}
