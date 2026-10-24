import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/format/money.dart';

import 'test_app.dart';

void main() {
  group('parsePriceCents', () {
    test('accepts comma or dot decimals and whole amounts', () {
      expect(parsePriceCents('24,90'), 2490);
      expect(parsePriceCents('24.9'), 2490);
      expect(parsePriceCents(' 24 '), 2400);
      expect(parsePriceCents('0'), 0);
      expect(parsePriceCents('0,05'), 5);
      expect(parsePriceCents('1 234,50'), 123450);
      expect(parsePriceCents('100000'), maxPriceCents);
    });

    test('rejects anything ambiguous, negative or absurd', () {
      for (final input in [
        '',
        'abc',
        '-5',
        '24,999',
        '1.234,50',
        '24,',
        ',5',
        '100000,01',
        '1e3',
      ]) {
        expect(parsePriceCents(input), isNull, reason: input);
      }
    });
  });

  testWidgets('money follows the device region and round-trips', (
    tester,
  ) async {
    late BuildContext captured;
    await tester.pumpWidget(
      localizedTestApp(
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
        locale: const Locale('es'),
      ),
    );
    expect(
      formatMoney(captured, 2490, localeOverride: 'es_ES'),
      '24,90\u00A0€',
    );
    expect(formatMoney(captured, 2490, localeOverride: 'en_US'), r'$24.90');
    // An unknown region still shows a readable two-decimal amount.
    expect(formatMoney(captured, 2490, localeOverride: 'zz_ZZ'), '24,90');
    expect(priceInputText(captured, 123450), '1234,50');
    expect(parsePriceCents(priceInputText(captured, 123450)), 123450);
  });
}
