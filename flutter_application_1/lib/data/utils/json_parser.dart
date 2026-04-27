/// Utilitaire de conversion défensive des valeurs JSON.
class JsonParser {
  /// Convertit une valeur dynamique en chaîne normalisée.
  ///
  /// [value] est la valeur source.
  /// [defaultValue] est utilisée si la valeur est `null`.
  /// Retourne une chaîne trimée.
  static String asString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString().trim();
  }

  /// Convertit une valeur dynamique en [DateTime].
  ///
  /// [value] doit être une chaîne ISO8601.
  /// Retourne la date parsée ou `null` si invalide.
  static DateTime? toDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Convertit une valeur en rôle normalisé (uppercase).
  ///
  /// [value] est la valeur source.
  /// Retourne `FREE` si `null`, sinon la valeur en majuscules.
  static String? toRole(dynamic value) {
    if (value == null) return 'FREE';
    return value.toString().toUpperCase();
  }
}
