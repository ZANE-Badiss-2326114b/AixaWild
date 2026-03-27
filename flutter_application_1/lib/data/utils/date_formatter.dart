import 'package:intl/intl.dart';

class DateFormatter {
  // Format standard : 24/03/2024
  static String toShortDate(DateTime? date) {
    String formattedDate;

    if (date == null) {
      formattedDate = 'Date inconnue';
    } else {
      formattedDate = DateFormat('dd/MM/yyyy').format(date);
    }

    return formattedDate;
  }

  // Format avec heure : 24/03/2024 à 14:30
  static String toDateTime(DateTime? date) {
    String formattedDateTime;

    if (date == null) {
      formattedDateTime = 'Date inconnue';
    } else {
      formattedDateTime = DateFormat('dd/MM/yyyy à HH:mm').format(date);
    }

    return formattedDateTime;
  }

  // Pour l'affichage des posts : "Il y a 2 heures"
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