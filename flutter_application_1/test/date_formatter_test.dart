import 'package:flutter_application_1/data/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateFormatter.toShortDate', () {
    test('retourne Date inconnue si null', () {
      final result = DateFormatter.toShortDate(null);

      expect(result, 'Date inconnue');
    });

    test('formate une date valide', () {
      final date = DateTime(2026, 3, 27);
      final result = DateFormatter.toShortDate(date);

      expect(result, '27/03/2026');
    });
  });

  group('DateFormatter.toDateTime', () {
    test('retourne Date inconnue si null', () {
      final result = DateFormatter.toDateTime(null);

      expect(result, 'Date inconnue');
    });

    test('formate une date et heure valides', () {
      final date = DateTime(2026, 3, 27, 14, 30);
      final result = DateFormatter.toDateTime(date);

      expect(result, '27/03/2026 à 14:30');
    });
  });

  group('DateFormatter.timeAgo', () {
    test('retourne chaine vide si null', () {
      final result = DateFormatter.timeAgo(null);

      expect(result, '');
    });

    test('retourne un format en jours', () {
      final date = DateTime.now().subtract(const Duration(days: 2, minutes: 1));
      final result = DateFormatter.timeAgo(date);

      expect(result, 'Il y a 2j');
    });

    test('retourne un format en heures', () {
      final date = DateTime.now().subtract(const Duration(hours: 3, minutes: 1));
      final result = DateFormatter.timeAgo(date);

      expect(result, 'Il y a 3h');
    });

    test('retourne un format en minutes', () {
      final date = DateTime.now().subtract(const Duration(minutes: 7));
      final result = DateFormatter.timeAgo(date);

      expect(result, 'Il y a 7m');
    });
  });
}
