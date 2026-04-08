import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // 'buyer' or 'seller'
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      role: d['role'] as String? ?? 'buyer',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'role': role,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get isBuyer => role == 'buyer';
  bool get isSeller => role == 'seller';
}
