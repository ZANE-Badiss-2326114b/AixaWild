import 'package:intl/intl.dart';

/// Utilitaire de formatage de dates pour la couche présentation.
class DateFormatter {
  /// Formate une date courte (`dd/MM/yyyy`).
  ///
  /// [date] est la date à formater.
  /// Retourne la date formatée ou `Date inconnue` si `null`.
  static String toShortDate(DateTime? date) {
    String formattedDate;

    if (date == null) {
      formattedDate = 'Date inconnue';
    } else {
      formattedDate = DateFormat('dd/MM/yyyy').format(date);
    }

    return formattedDate;
  }

  /// Formate une date avec heure (`dd/MM/yyyy à HH:mm`).
  ///
  /// [date] est la date à formater.
  /// Retourne la date/heure formatée ou `Date inconnue` si `null`.
  static String toDateTime(DateTime? date) {
    String formattedDateTime;

    if (date == null) {
      formattedDateTime = 'Date inconnue';
    } else {
      formattedDateTime = DateFormat('dd/MM/yyyy à HH:mm').format(date);
    }

    return formattedDateTime;
  }

  /// Génère un libellé relatif de type "Il y a Xh".
  ///
  /// [date] est la date de référence.
  /// Retourne une chaîne relative, ou vide si `date` est `null`.
  static String timeAgo(DateTime? date) {
    String value;

    if (date == null) {
      value = '';
    } else {
      final duration = DateTime.now().difference(date);
      if (duration.inDays > 0) {
        value = 'Il y a ${duration.inDays}j';
      } else {
        if (duration.inHours > 0) {
          value = 'Il y a ${duration.inHours}h';
        } else {
          if (duration.inMinutes > 0) {
            value = 'Il y a ${duration.inMinutes}m';
          } else {
            value = "À l'instant";
          }
        }
      }
    }

    return value;
  }
}
