import 'package:flutter_application_1/data/models/media.dart';
import 'package:flutter_application_1/data/models/opinion.dart';
import 'package:flutter_application_1/data/models/post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Post.fromJson', () {
    test('maps API camelCase payload', () {
      final post = Post.fromJson({
        'id': 7,
        'authorEmail': 'alice@example.com',
        'title': 'Sanglier',
        'content': 'Catégorie: Faune',
        'likesCount': 5,
        'reportingCount': 1,
        'createdAt': '2026-03-27T10:15:30',
      });

      expect(post.id, 7);
      expect(post.authorEmail, 'alice@example.com');
      expect(post.title, 'Sanglier');
      expect(post.likesCount, 5);
      expect(post.reportingCount, 1);
      expect(post.createdAt, isNotNull);
    });

    test('maps snake_case payload', () {
      final post = Post.fromJson({
        'post_id': 9,
        'author_email': 'bob@example.com',
        'title': 'Olivier',
        'content': 'Catégorie: Flore',
        'likes_count': 2,
        'reporting_count': 0,
        'created_at': '2026-03-27T12:00:00',
      });

      expect(post.id, 9);
      expect(post.authorEmail, 'bob@example.com');
      expect(post.likesCount, 2);
    });

    test('maps optional location payload', () {
      final post = Post.fromJson({
        'id': 12,
        'authorEmail': 'carol@example.com',
        'title': 'Rencontre',
        'locationName': 'Parc Jourdan',
        'latitude': 43.5232,
        'longitude': 5.4475,
      });

      expect(post.locationName, 'Parc Jourdan');
      expect(post.latitude, closeTo(43.5232, 0.0001));
      expect(post.longitude, closeTo(5.4475, 0.0001));
      expect(post.hasLocation, isTrue);
    });
  });

  group('Opinion.fromJson', () {
    test('maps opinion payload', () {
      final opinion = Opinion.fromJson({
        'userEmail': 'alice@example.com',
        'postId': 7,
        'isLike': true,
        'labelSignalisation': null,
      });

      expect(opinion.userEmail, 'alice@example.com');
      expect(opinion.postId, 7);
      expect(opinion.isLike, isTrue);
      expect(opinion.labelSignalisation, isNull);
    });
  });

  group('Media.fromJson', () {
    test('maps media payload', () {
      final media = Media.fromJson({
        'id': 3,
        'postId': 7,
        'url': 'https://example.com/media.jpg',
      });

      expect(media.id, 3);
      expect(media.postId, 7);
      expect(media.url, 'https://example.com/media.jpg');
    });
  });
}
