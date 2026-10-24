import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

const maxPriceCents = 10000000; // 100,000.00

/// Parses what a user types as a price ("24,90", "24.9", "24") into cents.
/// Returns null for anything else, including negative or absurd amounts.
int? parsePriceCents(String input) {
  final normalized = input.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized)) return null;
  final parts = normalized.split('.');
  final whole = int.parse(parts[0]);
  final fraction = parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0'));
  final cents = whole * 100 + fraction;
  return cents > maxPriceCents ? null : cents;
}

/// Shows an amount in the device region's currency (es_ES -> €, en_US -> $),
/// falling back to a plain two-decimal number when the region is unknown.
String formatMoney(BuildContext context, num cents, {String? localeOverride}) {
  final region =
      localeOverride ?? View.of(context).platformDispatcher.locale.toString();
  final amount = cents / 100;
  try {
    return NumberFormat.simpleCurrency(locale: region).format(amount);
  } catch (_) {
    return NumberFormat.decimalPatternDigits(
      locale: Localizations.localeOf(context).toString(),
      decimalDigits: 2,
    ).format(amount);
  }
}

/// The editable form of a stored price, in the app language's decimal style.
/// No grouping separators, so [parsePriceCents] reads it back unchanged.
String priceInputText(BuildContext context, int cents) => NumberFormat(
  '0.00',
  Localizations.localeOf(context).toString(),
).format(cents / 100);
