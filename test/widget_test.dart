import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Basic sanity', () {
    test('ProviderContainer initializes', () {
      final container = ProviderContainer();
      expect(container, isNotNull);
      container.dispose();
    });

    test('Duration parsing', () {
      const dur = Duration(seconds: 1);
      expect(dur.inSeconds, equals(1));
    });
  });
}