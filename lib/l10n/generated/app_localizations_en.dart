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
  String startedLabel(String time) {
    return 'Started: $time';
  }

  @override
  String endedLabel(String time) {
    return 'Ended: $time';
  }

  @override
  String countLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Count: $count taps',
      one: 'Count: 1 tap',
    );
    return '$_temp0';
  }

  @override
  String paceLabel(String pace) {
    return 'Pace: $pace per minute';
  }

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
  String get exportSubtitle => 'Copy a backup of your history to the clipboard';

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
  String get importSubtitle => 'Replace all data with a pasted backup';

  @override
  String get importDialogTitle => 'Import backup';

  @override
  String get importDialogBody =>
      'Paste a Sushi Tracker backup. This replaces all current history and totals.';

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
}
