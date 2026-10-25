import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Sushi Tracker'**
  String get appTitle;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @navCounter.
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get navCounter;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @storageError.
  ///
  /// In en, this message translates to:
  /// **'Could not open your saved data.'**
  String get storageError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @currentSessionSemantics.
  ///
  /// In en, this message translates to:
  /// **'Current session: {count} sushi'**
  String currentSessionSemantics(int count);

  /// No description provided for @tapToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap the sushi to start'**
  String get tapToStart;

  /// No description provided for @tapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to add · Long press or Undo to remove'**
  String get tapHint;

  /// No description provided for @sushiButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Add one sushi'**
  String get sushiButtonLabel;

  /// No description provided for @sushiButtonHint.
  ///
  /// In en, this message translates to:
  /// **'Double tap to add one. Long press to remove one.'**
  String get sushiButtonHint;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End Session'**
  String get endSession;

  /// No description provided for @thisSession.
  ///
  /// In en, this message translates to:
  /// **'This session'**
  String get thisSession;

  /// No description provided for @lifetimeTotal.
  ///
  /// In en, this message translates to:
  /// **'Lifetime total'**
  String get lifetimeTotal;

  /// No description provided for @elapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed'**
  String get elapsed;

  /// No description provided for @errorSaveOngoing.
  ///
  /// In en, this message translates to:
  /// **'Could not save the current session.'**
  String get errorSaveOngoing;

  /// No description provided for @errorResetCurrent.
  ///
  /// In en, this message translates to:
  /// **'Could not reset the current session.'**
  String get errorResetCurrent;

  /// No description provided for @errorCompleteSession.
  ///
  /// In en, this message translates to:
  /// **'Could not save this session. Please try again.'**
  String get errorCompleteSession;

  /// No description provided for @discardSession.
  ///
  /// In en, this message translates to:
  /// **'Discard session'**
  String get discardSession;

  /// No description provided for @discardSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this session?'**
  String get discardSessionTitle;

  /// No description provided for @discardSessionBody.
  ///
  /// In en, this message translates to:
  /// **'Its taps will not be saved to history.'**
  String get discardSessionBody;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @sessionDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Session discarded.'**
  String get sessionDiscarded;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'SESSION HISTORY'**
  String get historyTitle;

  /// No description provided for @noSessions.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet.'**
  String get noSessions;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String durationLabel(String duration);

  /// No description provided for @beforeReset.
  ///
  /// In en, this message translates to:
  /// **'Before lifetime reset'**
  String get beforeReset;

  /// No description provided for @deleteSessionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete session'**
  String get deleteSessionTooltip;

  /// No description provided for @deleteSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Session?'**
  String get deleteSessionTitle;

  /// No description provided for @deleteSessionBody.
  ///
  /// In en, this message translates to:
  /// **'This removes it from history. It updates the lifetime total when it belongs to the current lifetime.'**
  String get deleteSessionBody;

  /// No description provided for @sessionsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Session deleted} other{{count} sessions deleted}}'**
  String sessionsDeleted(int count);

  /// No description provided for @couldNotDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete this session. Please try again.'**
  String get couldNotDelete;

  /// No description provided for @couldNotRestore.
  ///
  /// In en, this message translates to:
  /// **'Could not restore this session.'**
  String get couldNotRestore;

  /// No description provided for @sessionDetails.
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get sessionDetails;

  /// No description provided for @beforeResetDetail.
  ///
  /// In en, this message translates to:
  /// **'Recorded before the last lifetime reset, so it is not part of the current lifetime totals.'**
  String get beforeResetDetail;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'STATISTICS'**
  String get statsTitle;

  /// No description provided for @lifetimeTaps.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Taps'**
  String get lifetimeTaps;

  /// No description provided for @lifetimeSessions.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Sessions'**
  String get lifetimeSessions;

  /// No description provided for @averageKpi.
  ///
  /// In en, this message translates to:
  /// **'Average ({range})'**
  String averageKpi(String range);

  /// No description provided for @bestKpi.
  ///
  /// In en, this message translates to:
  /// **'Best ({range})'**
  String bestKpi(String range);

  /// No description provided for @filterLast7.
  ///
  /// In en, this message translates to:
  /// **'7 sessions'**
  String get filterLast7;

  /// No description provided for @filterLast30.
  ///
  /// In en, this message translates to:
  /// **'30 sessions'**
  String get filterLast30;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All sessions'**
  String get filterAll;

  /// No description provided for @rangeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Session range in number of sessions'**
  String get rangeSemantics;

  /// No description provided for @sessionTrend.
  ///
  /// In en, this message translates to:
  /// **'Session trend'**
  String get sessionTrend;

  /// No description provided for @noTrend.
  ///
  /// In en, this message translates to:
  /// **'Complete a session to see your trend.'**
  String get noTrend;

  /// No description provided for @chartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Session trend chart for {count} sessions. Tap a point to see its date and tap count.'**
  String chartSemantics(int count);

  /// No description provided for @tapsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tap} other{{count} taps}}'**
  String tapsCount(int count);

  /// No description provided for @sinceReset.
  ///
  /// In en, this message translates to:
  /// **'Since the lifetime reset on {date}'**
  String sinceReset(String date);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// No description provided for @resetCurrentTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Current Session'**
  String get resetCurrentTitle;

  /// No description provided for @resetCurrentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear active taps without saving'**
  String get resetCurrentSubtitle;

  /// No description provided for @resetCurrentDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Current Session?'**
  String get resetCurrentDialogTitle;

  /// No description provided for @resetCurrentDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This will clear your ongoing taps without saving.'**
  String get resetCurrentDialogBody;

  /// No description provided for @currentSessionReset.
  ///
  /// In en, this message translates to:
  /// **'Current session reset.'**
  String get currentSessionReset;

  /// No description provided for @resetLifetimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Lifetime Global'**
  String get resetLifetimeTitle;

  /// No description provided for @resetLifetimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently reset all-time taps and sessions to 0'**
  String get resetLifetimeSubtitle;

  /// No description provided for @finishSessionFirst.
  ///
  /// In en, this message translates to:
  /// **'End or reset the current session first.'**
  String get finishSessionFirst;

  /// No description provided for @permanentReset.
  ///
  /// In en, this message translates to:
  /// **'PERMANENT RESET'**
  String get permanentReset;

  /// No description provided for @permanentResetBody.
  ///
  /// In en, this message translates to:
  /// **'This action permanently wipes your lifetime stats. Session history remains intact but totals return to 0.\n\nType \"{keyword}\" to confirm.'**
  String permanentResetBody(String keyword);

  /// No description provided for @resetKeyword.
  ///
  /// In en, this message translates to:
  /// **'RESET'**
  String get resetKeyword;

  /// No description provided for @confirmReset.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM RESET'**
  String get confirmReset;

  /// No description provided for @lifetimeResetDone.
  ///
  /// In en, this message translates to:
  /// **'Global lifetime stats reset.'**
  String get lifetimeResetDone;

  /// No description provided for @couldNotResetLifetime.
  ///
  /// In en, this message translates to:
  /// **'Could not reset lifetime stats. Please try again.'**
  String get couldNotResetLifetime;

  /// No description provided for @keepScreenOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on during a session'**
  String get keepScreenOnTitle;

  /// No description provided for @keepScreenOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses a little more battery while you count'**
  String get keepScreenOnSubtitle;

  /// No description provided for @couldNotSaveSetting.
  ///
  /// In en, this message translates to:
  /// **'Could not save this setting.'**
  String get couldNotSaveSetting;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportTitle;

  /// No description provided for @exportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a backup of your history and totals'**
  String get exportSubtitle;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Backup of 1 session copied to the clipboard.} other{Backup of {count} sessions copied to the clipboard.}}'**
  String exportDone(int count);

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importTitle;

  /// No description provided for @importSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace all data with a backup'**
  String get importSubtitle;

  /// No description provided for @importDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importDialogTitle;

  /// No description provided for @importDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Paste a Sushi Tracker backup.'**
  String get importDialogBody;

  /// No description provided for @importPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get importPaste;

  /// No description provided for @importConfirm.
  ///
  /// In en, this message translates to:
  /// **'Replace data'**
  String get importConfirm;

  /// No description provided for @importInvalid.
  ///
  /// In en, this message translates to:
  /// **'This is not a valid Sushi Tracker backup.'**
  String get importInvalid;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 session.} other{Imported {count} sessions.}}'**
  String importDone(int count);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not import the backup.'**
  String get importFailed;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Sushi Tracker does not collect, transmit, or share personal data. It has no accounts, analytics, ads, or network services.\n\nYour counts, session history, and lifetime totals are stored on this device. If Android backup is turned on for your Google account, Android may include this data in that backup and restore it when you reinstall the app or set up a new device. That backup is handled by Google under your account; the developer never receives it.\n\nClearing the app data removes it from this device. You can export your own copy from Settings.\n\nThe app requests no special device permissions.\n\nFor questions, contact labradorsantoseduardo@gmail.com.'**
  String get privacyBody;

  /// No description provided for @sessionAlreadySaved.
  ///
  /// In en, this message translates to:
  /// **'This session had already been saved to history.'**
  String get sessionAlreadySaved;

  /// No description provided for @exportSaved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Backup of 1 session saved.} other{Backup of {count} sessions saved.}}'**
  String exportSaved(int count);

  /// No description provided for @couldNotSaveFile.
  ///
  /// In en, this message translates to:
  /// **'Could not save the file.'**
  String get couldNotSaveFile;

  /// No description provided for @couldNotReadFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read the file.'**
  String get couldNotReadFile;

  /// No description provided for @importNext.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get importNext;

  /// No description provided for @importConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace all data?'**
  String get importConfirmTitle;

  /// No description provided for @importConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Your current history and totals will be replaced by the backup, which has 1 session.} other{Your current history and totals will be replaced by the backup, which has {count} sessions.}}'**
  String importConfirmBody(int count);

  /// No description provided for @setPrice.
  ///
  /// In en, this message translates to:
  /// **'Add price'**
  String get setPrice;

  /// No description provided for @editPrice.
  ///
  /// In en, this message translates to:
  /// **'Edit price'**
  String get editPrice;

  /// No description provided for @priceDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'What did this meal cost?'**
  String get priceDialogTitle;

  /// No description provided for @priceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 24.90'**
  String get priceHint;

  /// No description provided for @priceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount between 0 and 100,000.'**
  String get priceInvalid;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @removePrice.
  ///
  /// In en, this message translates to:
  /// **'Remove price'**
  String get removePrice;

  /// No description provided for @couldNotSavePrice.
  ///
  /// In en, this message translates to:
  /// **'Could not save the price.'**
  String get couldNotSavePrice;

  /// No description provided for @costPerPiece.
  ///
  /// In en, this message translates to:
  /// **'Cost per piece ({range})'**
  String costPerPiece(String range);

  /// No description provided for @recordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get recordsTitle;

  /// No description provided for @bestEver.
  ///
  /// In en, this message translates to:
  /// **'Best session'**
  String get bestEver;

  /// No description provided for @weeklyStreak.
  ///
  /// In en, this message translates to:
  /// **'Weekly streak'**
  String get weeklyStreak;

  /// No description provided for @weeksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No streak} =1{1 week} other{{count} weeks}}'**
  String weeksCount(int count);

  /// No description provided for @sessionsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Sessions this month'**
  String get sessionsThisMonth;

  /// No description provided for @piecesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Pieces this month'**
  String get piecesThisMonth;

  /// No description provided for @recordToBeat.
  ///
  /// In en, this message translates to:
  /// **'Record {best} · {remaining} to go'**
  String recordToBeat(int best, int remaining);

  /// No description provided for @recordTied.
  ///
  /// In en, this message translates to:
  /// **'You matched your record of {best}!'**
  String recordTied(int best);

  /// No description provided for @newRecord.
  ///
  /// In en, this message translates to:
  /// **'New record! Previous best: {best}'**
  String newRecord(int best);

  /// No description provided for @emptyHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'End a session and it will show up here.'**
  String get emptyHistoryHint;

  /// No description provided for @monthSummary.
  ///
  /// In en, this message translates to:
  /// **'{sessions, plural, =1{1 session} other{{sessions} sessions}} · {pieces, plural, =1{1 piece} other{{pieces} pieces}}'**
  String monthSummary(int sessions, int pieces);

  /// No description provided for @recordBadge.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recordBadge;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryTitle;

  /// No description provided for @averageLine.
  ///
  /// In en, this message translates to:
  /// **'Avg {value}'**
  String averageLine(String value);

  /// No description provided for @weeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'Pieces per week'**
  String get weeklyTitle;

  /// No description provided for @weeklySemantics.
  ///
  /// In en, this message translates to:
  /// **'Bar chart of pieces eaten in each of the last {weeks} weeks.'**
  String weeklySemantics(int weeks);

  /// No description provided for @piecesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 piece} other{{count} pieces}}'**
  String piecesCount(int count);

  /// No description provided for @piecesUnit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{piece} other{pieces}}'**
  String piecesUnit(int count);

  /// No description provided for @settingsSectionSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get settingsSectionSession;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsSectionData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get settingsSectionData;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsTagline.
  ///
  /// In en, this message translates to:
  /// **'Your sushi, counted on this device.'**
  String get settingsTagline;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Getting your sushi ready…'**
  String get loadingData;

  /// No description provided for @timeRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String timeRange(String start, String end);

  /// No description provided for @detailPieces.
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get detailPieces;

  /// No description provided for @detailDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get detailDuration;

  /// No description provided for @detailPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get detailPace;

  /// No description provided for @detailPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get detailPrice;

  /// No description provided for @paceValue.
  ///
  /// In en, this message translates to:
  /// **'{pace}/min'**
  String paceValue(String pace);

  /// No description provided for @noValue.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get noValue;

  /// No description provided for @addRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Add restaurant'**
  String get addRestaurant;

  /// No description provided for @editRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Change restaurant'**
  String get editRestaurant;

  /// No description provided for @restaurantDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Where did you eat?'**
  String get restaurantDialogTitle;

  /// No description provided for @restaurantHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sushi Zen'**
  String get restaurantHint;

  /// No description provided for @removeRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeRestaurant;

  /// No description provided for @couldNotSaveRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Could not save the restaurant.'**
  String get couldNotSaveRestaurant;

  /// No description provided for @byRestaurantTitle.
  ///
  /// In en, this message translates to:
  /// **'By restaurant'**
  String get byRestaurantTitle;

  /// No description provided for @restaurantSummary.
  ///
  /// In en, this message translates to:
  /// **'{sessions, plural, =1{1 session} other{{sessions} sessions}} · avg {average}'**
  String restaurantSummary(int sessions, String average);

  /// No description provided for @perPiece.
  ///
  /// In en, this message translates to:
  /// **'{value}/piece'**
  String perPiece(String value);

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// No description provided for @achievementsCount.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} of {total}'**
  String achievementsCount(int unlocked, int total);

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked: {name}'**
  String achievementUnlocked(String name);

  /// No description provided for @achievementProgress.
  ///
  /// In en, this message translates to:
  /// **'{progress}/{target}'**
  String achievementProgress(int progress, int target);

  /// No description provided for @achFirstSession.
  ///
  /// In en, this message translates to:
  /// **'First bite'**
  String get achFirstSession;

  /// No description provided for @achFirstSessionDesc.
  ///
  /// In en, this message translates to:
  /// **'Save your first session'**
  String get achFirstSessionDesc;

  /// No description provided for @achTenSessions.
  ///
  /// In en, this message translates to:
  /// **'Regular customer'**
  String get achTenSessions;

  /// No description provided for @achTenSessionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Save 10 sessions'**
  String get achTenSessionsDesc;

  /// No description provided for @achFiftySessions.
  ///
  /// In en, this message translates to:
  /// **'Sushi veteran'**
  String get achFiftySessions;

  /// No description provided for @achFiftySessionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Save 50 sessions'**
  String get achFiftySessionsDesc;

  /// No description provided for @achBigAppetite.
  ///
  /// In en, this message translates to:
  /// **'Big appetite'**
  String get achBigAppetite;

  /// No description provided for @achBigAppetiteDesc.
  ///
  /// In en, this message translates to:
  /// **'30 pieces in one session'**
  String get achBigAppetiteDesc;

  /// No description provided for @achSushiMaster.
  ///
  /// In en, this message translates to:
  /// **'Sushi master'**
  String get achSushiMaster;

  /// No description provided for @achSushiMasterDesc.
  ///
  /// In en, this message translates to:
  /// **'50 pieces in one session'**
  String get achSushiMasterDesc;

  /// No description provided for @achHundredPieces.
  ///
  /// In en, this message translates to:
  /// **'Century'**
  String get achHundredPieces;

  /// No description provided for @achHundredPiecesDesc.
  ///
  /// In en, this message translates to:
  /// **'100 pieces in total'**
  String get achHundredPiecesDesc;

  /// No description provided for @achThousandPieces.
  ///
  /// In en, this message translates to:
  /// **'Thousand club'**
  String get achThousandPieces;

  /// No description provided for @achThousandPiecesDesc.
  ///
  /// In en, this message translates to:
  /// **'1,000 pieces in total'**
  String get achThousandPiecesDesc;

  /// No description provided for @achRegular.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get achRegular;

  /// No description provided for @achRegularDesc.
  ///
  /// In en, this message translates to:
  /// **'4 weeks in a row with a session'**
  String get achRegularDesc;

  /// No description provided for @achPriceWatcher.
  ///
  /// In en, this message translates to:
  /// **'Bargain hunter'**
  String get achPriceWatcher;

  /// No description provided for @achPriceWatcherDesc.
  ///
  /// In en, this message translates to:
  /// **'Add the price to 5 sessions'**
  String get achPriceWatcherDesc;

  /// No description provided for @achExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get achExplorer;

  /// No description provided for @achExplorerDesc.
  ///
  /// In en, this message translates to:
  /// **'Eat at 3 different restaurants'**
  String get achExplorerDesc;

  /// No description provided for @showAsList.
  ///
  /// In en, this message translates to:
  /// **'Show as list'**
  String get showAsList;

  /// No description provided for @showAsChart.
  ///
  /// In en, this message translates to:
  /// **'Show as chart'**
  String get showAsChart;

  /// No description provided for @weekOf.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String weekOf(String date);

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceSystem;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
