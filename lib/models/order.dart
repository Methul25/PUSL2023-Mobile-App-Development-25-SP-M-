import 'package:cloud_firestore/cloud_firestore.dart';

class SellerOrder {
  final String? id;
  final String sellerEmail;
  final String buyerEmail;
  final String productName;
  final String? productId;
  final String? productImageUrl;
  final double amount;
  final int quantity;
  final String status; // 'Processing', 'Shipped', 'Delivered'
  final DateTime createdAt;

  const SellerOrder({
    this.id,
    required this.sellerEmail,
    required this.buyerEmail,
    required this.productName,
    this.productId,
    this.productImageUrl,
    required this.amount,
    this.quantity = 1,
    this.status = 'Processing',
    required this.createdAt,
  });

  factory SellerOrder.fromFirestore(String id, Map<String, dynamic> d) {
    return SellerOrder(
      id: id,
      sellerEmail: d['sellerEmail'] as String? ?? '',
      buyerEmail: d['buyerEmail'] as String? ?? '',
      productName: d['productName'] as String? ?? '',
      productId: d['productId'] as String?,
      productImageUrl: d['productImageUrl'] as String?,
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      quantity: (d['quantity'] as num?)?.toInt() ?? 1,
      status: d['status'] as String? ?? 'Processing',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'sellerEmail': sellerEmail,
        'buyerEmail': buyerEmail,
        'productName': productName,
        'productId': productId,
        'productImageUrl': productImageUrl,
        'amount': amount,
        'quantity': quantity,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Total line amount (price × quantity).
  double get lineTotal => amount * quantity;
}
