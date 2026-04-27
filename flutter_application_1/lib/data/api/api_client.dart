import 'package:flutter_application_1/data/api/core/dio_client.dart';

/// Alias de client API concret utilisé par la couche Data.
///
/// Cette classe permet d'exposer un point d'instanciation stable tout en
/// conservant l'implémentation détaillée dans [DioApiClient].
class ApiClient extends DioApiClient {
  /// Construit un client API basé sur la configuration par défaut de Dio.
  ApiClient();
}
