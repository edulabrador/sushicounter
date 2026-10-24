import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sushiscore/core/theme/app_theme.dart';
import 'package:sushiscore/l10n/l10n.dart';

/// A MaterialApp with the app's localizations, for testing single screens.
MaterialApp localizedTestApp(Widget home, {Locale? locale}) => MaterialApp(
  theme: AppTheme.darkTheme,
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);
