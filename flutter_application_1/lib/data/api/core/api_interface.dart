/// Contrat d'accès réseau pour la couche Data.
///
/// Cette interface encapsule les opérations HTTP utilisées par les repositories
/// et services API afin de découpler la logique métier de l'implémentation Dio.
abstract class IApiClient {
  /// Exécute une requête HTTP GET.
  ///
  /// [endpoint] est le chemin relatif API.
  /// [headers] permet d'ajouter des en-têtes spécifiques à l'appel.
  /// [includeAuthorization] indique si le token d'accès doit être injecté.
  /// Retourne le payload décodé (Map/List/dynamic).
  Future<dynamic> get(String endpoint, {Map<String, String>? headers, bool includeAuthorization = true});

  /// Exécute une requête HTTP POST.
  ///
  /// [endpoint] est le chemin relatif API.
  /// [data] représente le corps JSON ou FormData.
  /// [headers] permet d'ajouter des en-têtes spécifiques à l'appel.
  /// [includeAuthorization] indique si le token d'accès doit être injecté.
  /// Retourne le payload décodé (Map/List/dynamic).
  Future<dynamic> post(String endpoint, dynamic data, {Map<String, String>? headers, bool includeAuthorization = true});

  /// Exécute une requête HTTP PUT.
  ///
  /// [endpoint] est le chemin relatif API.
  /// [data] représente le corps JSON ou FormData.
  /// [headers] permet d'ajouter des en-têtes spécifiques à l'appel.
  /// [includeAuthorization] indique si le token d'accès doit être injecté.
  /// Retourne le payload décodé (Map/List/dynamic).
  Future<dynamic> put(String endpoint, dynamic data, {Map<String, String>? headers, bool includeAuthorization = true});

  /// Exécute une requête HTTP DELETE.
  ///
  /// [endpoint] est le chemin relatif API.
  /// [headers] permet d'ajouter des en-têtes spécifiques à l'appel.
  /// [includeAuthorization] indique si le token d'accès doit être injecté.
  /// Retourne le payload décodé (Map/List/dynamic).
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers, bool includeAuthorization = true});

  /// Exécute un upload multipart.
  ///
  /// [endpoint] est le chemin relatif API.
  /// [bytes] contient le contenu binaire du fichier.
  /// [fileName] est le nom logique du fichier envoyé.
  /// [mimeType] est le type MIME explicite, sinon inféré.
  /// [headers] permet d'ajouter des en-têtes spécifiques à l'appel.
  /// [includeAuthorization] indique si le token d'accès doit être injecté.
  /// [onSendProgress] notifie la progression `(sent, total)`.
  /// Retourne le payload décodé (Map/List/dynamic).
  Future<dynamic> upload(String endpoint, List<int> bytes, {required String fileName, String? mimeType, Map<String, String>? headers, bool includeAuthorization = true, void Function(int sent, int total)? onSendProgress});
}
