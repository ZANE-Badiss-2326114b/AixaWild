class ApiEndpoints {
  static const String authLogin = '/auth/login';
  static const String users = '/users';
  static const String posts = '/posts';
  static const String opinions = '/opinions';
  static const String subscriptionTypes = '/subscription-types';
  static const String subscriptionTypesFallback = '/subscriptionTypes';

  // Retourne l'URL pour un utilisateur spécifique
  static String userDetails(String email) => '/users/${Uri.encodeComponent(email)}';

  static String currentSubscriptionByUser(String encodedEmail) => '/subscriptions/user/$encodedEmail/current';

  static String subscriptionsByUser(String encodedEmail) => '/subscriptions/user/$encodedEmail';

  static String postById(int postId) => '/posts/$postId';

  static String postMedia(int postId) => '/posts/$postId/media';

  static String mediaById(int mediaId) => '/media/$mediaId';

  static String opinionByPostAndUser(int postId, String userEmail) => '/opinions/posts/$postId/users/${Uri.encodeComponent(userEmail)}';

  static String opinionLikeByPostAndUser(int postId, String userEmail) => '/opinions/posts/$postId/users/${Uri.encodeComponent(userEmail)}/like';

  static String opinionSignalementByPostAndUser(int postId, String userEmail) => '/opinions/posts/$postId/users/${Uri.encodeComponent(userEmail)}/signalement';
}
