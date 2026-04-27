/// Fabrique centralisée des endpoints API.
///
/// Cette classe évite la duplication des chemins et garantit un encodage
/// cohérent des segments dynamiques.
class ApiEndpoints {
  static const String authLogin = '/auth/login';
  static const String users = '/users';
  static const String posts = '/posts';
  static const String opinions = '/opinions';
  static const String subscriptionTypes = '/subscription-types';
  static const String subscriptionTypesFallback = '/subscriptionTypes';

  /// Retourne l'endpoint de détail d'un utilisateur.
  ///
  /// [email] est encodé pour produire un segment URL sûr.
  /// Retourne le chemin relatif API.
  static String userDetails(String email) => '/users/${Uri.encodeComponent(email)}';

  /// Retourne l'endpoint d'abonnement courant d'un utilisateur.
  ///
  /// [encodedEmail] doit être déjà encodé côté appelant.
  /// Retourne le chemin relatif API.
  static String currentSubscriptionByUser(String encodedEmail) => '/subscriptions/user/$encodedEmail/current';

  /// Retourne l'endpoint d'historique d'abonnements d'un utilisateur.
  ///
  /// [encodedEmail] doit être déjà encodé côté appelant.
  /// Retourne le chemin relatif API.
  static String subscriptionsByUser(String encodedEmail) => '/subscriptions/user/$encodedEmail';

  /// Retourne l'endpoint d'un post par identifiant.
  ///
  /// [postId] identifie la ressource.
  /// Retourne le chemin relatif API.
  static String postById(int postId) => '/posts/$postId';

  /// Retourne l'endpoint média d'un post.
  ///
  /// [postId] identifie la ressource parent.
  /// Retourne le chemin relatif API.
  static String postMedia(int postId) => '/posts/$postId/media';

  /// Retourne l'endpoint d'un média par identifiant.
  ///
  /// [mediaId] identifie la ressource.
  /// Retourne le chemin relatif API.
  static String mediaById(int mediaId) => '/media/$mediaId';

  /// Retourne l'endpoint d'opinion d'un utilisateur sur un post.
  ///
  /// [postId] identifie le post.
  /// [userEmail] est encodé automatiquement.
  /// Retourne le chemin relatif API.
  static String opinionByPostAndUser(int postId, String userEmail) => '/opinions/posts/$postId/users/${Uri.encodeComponent(userEmail)}';

  /// Retourne l'endpoint de suppression de like.
  ///
  /// [postId] identifie le post.
  /// [userEmail] est encodé automatiquement.
  /// Retourne le chemin relatif API.
  static String opinionLikeByPostAndUser(int postId, String userEmail) => '/opinions/posts/$postId/users/${Uri.encodeComponent(userEmail)}/like';

  /// Retourne l'endpoint de suppression de signalement.
  ///
  /// [postId] identifie le post.
  /// [userEmail] est encodé automatiquement.
  /// Retourne le chemin relatif API.
  static String opinionSignalementByPostAndUser(int postId, String userEmail) => '/opinions/posts/$postId/users/${Uri.encodeComponent(userEmail)}/signalement';
}
