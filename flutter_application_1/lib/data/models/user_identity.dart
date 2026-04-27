import 'package:jwt_decoder/jwt_decoder.dart';

/// Projection légère de l'identité authentifiée extraite du JWT.
class UserIdentity {
  final String email;
  final List<String> roles;

  /// Construit une identité utilisateur.
  ///
  /// [email] identifiant principal (claim `sub`).
  /// [roles] liste des rôles/authorities.
  const UserIdentity({required this.email, required this.roles});

  /// Construit une [UserIdentity] depuis un token JWT.
  ///
  /// [token] JWT brut.
  /// Retourne une identité normalisée.
  factory UserIdentity.fromToken(String token) {
    final claims = JwtDecoder.decode(token);

    final emailClaim = claims['sub'];
    final authoritiesClaim = claims['authorities'];
    final rolesClaim = claims['roles'];
    final rawRolesClaim = authoritiesClaim ?? rolesClaim;

    String email;
    List<String> roles;

    if (emailClaim is String) {
      email = emailClaim;
    } else {
      email = '';
    }

    if (rawRolesClaim is List) {
      roles = rawRolesClaim.whereType<String>().map((role) => role.trim()).where((role) => role.isNotEmpty).toList(growable: false);
    } else {
      if (rawRolesClaim is String) {
        roles = rawRolesClaim.split(',').map((role) => role.trim()).where((role) => role.isNotEmpty).toList(growable: false);
      } else {
        roles = const <String>[];
      }
    }

    return UserIdentity(email: email, roles: roles);
  }

  /// Vérifie la présence d'un rôle.
  ///
  /// [roleName] est comparé en mode insensible à la casse.
  /// Retourne `true` si le rôle est présent.
  bool hasRole(String roleName) {
    bool hasRequestedRole;
    final normalizedRoleName = roleName.trim().toLowerCase();

    if (normalizedRoleName.isEmpty) {
      hasRequestedRole = false;
    } else {
      hasRequestedRole = roles.any((role) => role.trim().toLowerCase() == normalizedRoleName);
    }

    return hasRequestedRole;
  }

  /// Indique si l'utilisateur possède le rôle administrateur.
  bool get isAdmin => hasRole('ROLE_ADMIN');
}
