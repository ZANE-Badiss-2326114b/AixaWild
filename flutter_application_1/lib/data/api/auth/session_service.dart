import 'package:flutter_application_1/data/api/auth/auth_token_manager.dart';
import 'package:flutter_application_1/data/models/user_identity.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SessionService {
  SessionService({AuthTokenManager? tokenManager})
      : _tokenManager = tokenManager ?? AuthTokenManager.instance;

  final AuthTokenManager _tokenManager;

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
          identity = UserIdentity.fromToken(normalizedToken);
        } catch (_) {
          identity = null;
        }
      }
    }

    return identity;
  }
}
