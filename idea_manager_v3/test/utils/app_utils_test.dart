// test/utils/app_utils_test.dart
// Unit tests for AppDateUtils formatting helpers.

import 'package:flutter_test/flutter_test.dart';
import 'package:idea_manager/core/utils/app_utils.dart';

void main() {
  group('AppDateUtils', () {
    final fixed = DateTime(2024, 3, 5, 14, 7, 9); // 5 Mar 2024 14:07

    test('formatShort returns human-readable date', () {
      expect(AppDateUtils.formatShort(fixed), equals('Mar 5, 2024'));
    });

    test('formatRelative returns "Today" for today', () {
      final now = DateTime.now();
      final result = AppDateUtils.formatRelative(now);
      expect(result, startsWith('Today'));
    });

    test('formatRelative returns "Yesterday" for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(AppDateUtils.formatRelative(yesterday), equals('Yesterday'));
    });

    test('formatRelative returns short date for older dates', () {
      final old = DateTime(2022, 1, 15);
      expect(AppDateUtils.formatRelative(old), equals('Jan 15, 2022'));
    });

    test('formatIso returns ISO 8601 string without milliseconds', () {
      expect(AppDateUtils.formatIso(fixed), equals('2024-03-05T14:07:09'));
    });
  });
}
