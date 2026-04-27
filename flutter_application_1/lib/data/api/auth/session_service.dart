import 'package:flutter_application_1/data/api/auth/auth_token_manager.dart';
import 'package:flutter_application_1/data/models/user_identity.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Service de session basé sur JWT côté client.
///
/// Ce service interprète le token d'accès pour exposer l'identité courante
/// sans appel réseau supplémentaire.
class SessionService {
  /// Construit le service de session.
  ///
  /// [tokenManager] fournit l'accès au token persistant.
  SessionService({AuthTokenManager? tokenManager}) : _tokenManager = tokenManager ?? AuthTokenManager.instance;

  final AuthTokenManager _tokenManager;

  /// Retourne l'identité utilisateur courante.
  ///
  /// Retourne [UserIdentity] si token présent, non expiré et décodable,
  /// sinon `null`.
  Future<UserIdentity?> currentUser() async {
    UserIdentity? identity;
    final token = await _tokenManager.getAccessToken();
    final normalizedToken = token?.trim();

    if (normalizedToken == null || normalizedToken.isEmpty) {
      identity = null;
    } else {
      if (JwtDecoder.isExpired(normalizedToken)) {
        identity = null;
      } else {
        try {
          // Parsing défensif des claims pour éviter de propager une erreur de format JWT.
          identity = UserIdentity.fromToken(normalizedToken);
        } catch (_) {
          identity = null;
        }
      }
    }

    return identity;
  }
}
