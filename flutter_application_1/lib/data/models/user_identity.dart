import 'package:jwt_decoder/jwt_decoder.dart';

class UserIdentity {
  final String email;
  final List<String> roles;

  const UserIdentity({
    required this.email,
    required this.roles,
  });

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
      roles = rawRolesClaim
          .whereType<String>()
          .map((role) => role.trim())
          .where((role) => role.isNotEmpty)
          .toList(growable: false);
    } else {
      if (rawRolesClaim is String) {
        roles = rawRolesClaim
            .split(',')
            .map((role) => role.trim())
            .where((role) => role.isNotEmpty)
            .toList(growable: false);
      } else {
        roles = const <String>[];
      }
    }

    return UserIdentity(
      email: email,
      roles: roles,
    );
  }

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

  bool get isAdmin => hasRole('ROLE_ADMIN');
}
