import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import '../models/order.dart';
import '../models/review.dart';

typedef PeriodRevenue = ({double total, List<({String label, double revenue})> bars});

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  // ── Images ────────────────────────────────────────────────────────────────

  /// Upload a product image and return the download URL.
  /// Uses the Firebase Storage REST API directly to avoid Windows C++ SDK bugs.
  Future<String> uploadProductImage(Uint8List bytes, String fileName) async {
    const bucket = 'furn-app-819aa.firebasestorage.app';
    final objectPath = 'products/$fileName';

    final uri = Uri(
      scheme: 'https',
      host: 'firebasestorage.googleapis.com',
      path: '/v0/b/$bucket/o',
      queryParameters: {'name': objectPath},
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'image/jpeg'},
      body: bytes,
    );

    if (response.statusCode != 200) {
      throw Exception('Storage upload failed (${response.statusCode}): ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final token = (json['downloadTokens'] as String?)?.split(',').first ?? '';
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(objectPath)}?alt=media&token=$token';
  }

  // ── Products ──────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  /// Stream active products (for buyer browse).
  Stream<List<Product>> streamProducts() {
    return _products
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Product.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream all products for a specific seller (for seller listings).
  Stream<List<Product>> streamAllProducts(String sellerEmail) {
    return _products
        .where('sellerEmail', isEqualTo: sellerEmail)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(Product.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Add a new product. Returns the document ID.
  Future<String> addProduct(Product product) async {
    final doc = await _products.add(product.toFirestore());
    return doc.id;
  }

  /// Toggle active / draft status.
  Future<void> toggleProduct(String id, bool active) {
    return _products.doc(id).update({'active': active});
  }

  /// Delete a product.
  Future<void> deleteProduct(String id) {
    return _products.doc(id).delete();
  }

  /// Decrement a product's stock by [quantity] using atomic server increment.
  Future<void> decrementStock(String productId, int quantity) {
    return _products.doc(productId).update({
      'stock': FieldValue.increment(-quantity),
    });
  }

  /// Set a product's stock to an absolute value.
  Future<void> updateStock(String productId, int stock) {
    return _products.doc(productId).update({'stock': stock});
  }

  // ── Dashboard helpers ─────────────────────────────────────────────────────

  /// Get total product count + active count in one read for a seller.
  Future<({int total, int active})> productCounts(String sellerEmail) async {
    final snap = await _products.where('sellerEmail', isEqualTo: sellerEmail).get();
    final all = snap.docs.map(Product.fromFirestore).toList();
    return (total: all.length, active: all.where((p) => p.active).length);
  }

  /// Real-time stream of product counts for a seller.
  Stream<({int total, int active})> productCountsStream(String sellerEmail) {
    return _products
        .where('sellerEmail', isEqualTo: sellerEmail)
        .snapshots()
        .map((snap) {
      final all = snap.docs.map(Product.fromFirestore).toList();
      return (total: all.length, active: all.where((p) => p.active).length);
    });
  }

  // ── Orders ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  /// Create a new order document.
  Future<String> createOrder(SellerOrder order) async {
    final doc = await _orders.add(order.toFirestore());
    return doc.id;
  }

  /// Real-time stream of recent orders for a seller (latest first, max 10).
  Stream<List<SellerOrder>> ordersStream(String sellerEmail) {
    return _orders
        .where('sellerEmail', isEqualTo: sellerEmail)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => SellerOrder.fromFirestore(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list.take(10).toList();
        });
  }

  /// Real-time total revenue stream for a seller.
  /// Returns (totalRevenue, monthRevenue, previousMonthRevenue).
  Stream<({double total, double thisMonth, double lastMonth})> revenueStream(
      String sellerEmail) {
    return _orders
        .where('sellerEmail', isEqualTo: sellerEmail)
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);

      double total = 0;
      double thisMonth = 0;
      double lastMonth = 0;

      for (final doc in snap.docs) {
        final order = SellerOrder.fromFirestore(doc.id, doc.data());
        final lineTotal = order.lineTotal;
        total += lineTotal;

        if (order.createdAt.isAfter(startOfMonth)) {
          thisMonth += lineTotal;
        } else if (order.createdAt.isAfter(startOfLastMonth) &&
            order.createdAt.isBefore(startOfMonth)) {
          lastMonth += lineTotal;
        }
      }

      return (total: total, thisMonth: thisMonth, lastMonth: lastMonth);
    });
  }

  /// Real-time stream of daily revenue for the last 7 days.
  /// Returns a list of 7 entries: (dayLabel, revenue).
  Stream<List<({String day, double revenue})>> weeklyRevenueStream(
      String sellerEmail) {
    final now = DateTime.now();

    return _orders
        .where('sellerEmail', isEqualTo: sellerEmail)
        .snapshots()
        .map((snap) {
      // Build a map of day-of-week → total
      final dailyTotals = <int, double>{};
      for (int i = 0; i < 7; i++) {
        dailyTotals[i] = 0;
      }

      for (final doc in snap.docs) {
        final order = SellerOrder.fromFirestore(doc.id, doc.data());
        final daysAgo = now.difference(order.createdAt).inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          dailyTotals[6 - daysAgo] =
              (dailyTotals[6 - daysAgo] ?? 0) + order.lineTotal;
        }
      }

      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      return List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        final dayName = dayNames[date.weekday - 1];
        return (day: dayName, revenue: dailyTotals[i] ?? 0);
      });
    });
  }

  /// Revenue for today broken into 6 four-hour slots (12am 4am 8am 12pm 4pm 8pm).
  Stream<PeriodRevenue> dailyPeriodStream(String sellerEmail) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _orders
        .where('sellerEmail', isEqualTo: sellerEmail)
        .snapshots()
        .map((snap) {
      const slotLabels = ['12am', '4am', '8am', '12pm', '4pm', '8pm'];
      final totals = List<double>.filled(6, 0);
      double total = 0;
      for (final doc in snap.docs) {
        final order = SellerOrder.fromFirestore(doc.id, doc.data());
        if (!order.createdAt.isBefore(startOfDay)) {
          final slot = (order.createdAt.hour ~/ 4).clamp(0, 5);
          totals[slot] += order.lineTotal;
          total += order.lineTotal;
        }
      }
      return (
        total: total,
        bars: List.generate(6, (i) => (label: slotLabels[i], revenue: totals[i])),
      );
    });
  }

  /// Revenue for the current week (last 7 days), daily breakdown.
  Stream<PeriodRevenue> weeklyPeriodStream(String sellerEmail) {
    final now = DateTime.now();
    return _orders
        .where('sellerEmail', isEqualTo: sellerEmail)
        .snapshots()
        .map((snap) {
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final totals = List<double>.filled(7, 0);
      double total = 0;
      for (final doc in snap.docs) {
        final order = SellerOrder.fromFirestore(doc.id, doc.data());
        final daysAgo = now.difference(order.createdAt).inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          totals[6 - daysAgo] += order.lineTotal;
          total += order.lineTotal;
        }
      }
      return (
        total: total,
        bars: List.generate(7, (i) {
          final date = now.subtract(Duration(days: 6 - i));
          return (label: dayNames[date.weekday - 1], revenue: totals[i]);
        }),
      );
    });
  }

  /// Revenue for the current month, broken into weeks (W1–W5).
  Stream<PeriodRevenue> monthlyPeriodStream(String sellerEmail) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _orders
        .where('sellerEmail', isEqualTo: sellerEmail)
        .snapshots()
        .map((snap) {
      final totals = List<double>.filled(5, 0);
      double total = 0;
      for (final doc in snap.docs) {
        final order = SellerOrder.fromFirestore(doc.id, doc.data());
        if (!order.createdAt.isBefore(startOfMonth)) {
          final weekIdx = ((order.createdAt.day - 1) ~/ 7).clamp(0, 4);
          totals[weekIdx] += order.lineTotal;
          total += order.lineTotal;
        }
      }
      return (
        total: total,
        bars: List.generate(5, (i) => (label: 'W${i + 1}', revenue: totals[i])),
      );
    });
  }

  /// Revenue for the current year, broken into months (Jan–Dec).
  Stream<PeriodRevenue> yearlyPeriodStream(String sellerEmail) {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    return _orders
        .where('sellerEmail', isEqualTo: sellerEmail)
        .snapshots()
        .map((snap) {
      const monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final totals = List<double>.filled(12, 0);
      double total = 0;
      for (final doc in snap.docs) {
        final order = SellerOrder.fromFirestore(doc.id, doc.data());
        if (!order.createdAt.isBefore(startOfYear)) {
          totals[order.createdAt.month - 1] += order.lineTotal;
          total += order.lineTotal;
        }
      }
      return (
        total: total,
        bars: List.generate(12, (i) => (label: monthNames[i], revenue: totals[i])),
      );
    });
  }

  /// Real-time stream of pending order count for a seller.
  Stream<int> pendingOrderCountStream(String sellerEmail) {
    return _orders
        .where('sellerEmail', isEqualTo: sellerEmail)
        .snapshots()
        .map((snap) => snap.docs
            .where((doc) => (doc.data()['status'] as String?) == 'Processing')
            .length);
  }

  /// Update the status of an order.
  Future<void> updateOrderStatus(String orderId, String status) {
    return _orders.doc(orderId).update({'status': status});
  }

  /// Real-time stream of all orders for a specific buyer.
  Stream<List<SellerOrder>> buyerOrdersStream(String buyerEmail) {
    return _orders
        .where('buyerEmail', isEqualTo: buyerEmail)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => SellerOrder.fromFirestore(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Reviews ───────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection('reviews');

  /// Stream all reviews for a product, newest first.
  Stream<List<Review>> reviewsStream(String productId) {
    return _reviews
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => Review.fromFirestore(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Add a new review. Returns the new document ID.
  Future<String> addReview(Review review) async {
    final doc = await _reviews.add(review.toFirestore());
    return doc.id;
  }

  /// Check if a user has already reviewed a product.
  Future<bool> hasReviewed(String productId, String userEmail) async {
    final snap = await _reviews
        .where('productId', isEqualTo: productId)
        .get();
    return snap.docs.any((doc) => doc.data()['userEmail'] == userEmail);
  }
}
