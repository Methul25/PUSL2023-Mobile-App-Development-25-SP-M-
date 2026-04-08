import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String? id;
  final String productId;
  final String userEmail;
  final String userName;
  final double rating; // 1–5
  final String comment;
  final DateTime createdAt;

  const Review({
    this.id,
    required this.productId,
    required this.userEmail,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(String id, Map<String, dynamic> d) {
    return Review(
      id: id,
      productId: d['productId'] as String? ?? '',
      userEmail: d['userEmail'] as String? ?? '',
      userName: d['userName'] as String? ?? 'Anonymous',
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      comment: d['comment'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'productId': productId,
        'userEmail': userEmail,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
