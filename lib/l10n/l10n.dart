import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Locale name for `intl` formatters, matching the active app language.
  String get localeName => AppLocalizations.of(this).localeName;
}
