class JsonParser {
  static String asString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString().trim();
  }

  static DateTime? toDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
  
  // Utile pour mapper le type d'abonnement
  static String? toRole(dynamic value) {
    if (value == null) return 'FREE';
    return value.toString().toUpperCase();
  }
}