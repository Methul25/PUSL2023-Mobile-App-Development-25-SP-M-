import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}

/// Simple in-memory cart shared across screens.
class CartManager extends ChangeNotifier {
  CartManager._();
  static final instance = CartManager._();

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int get count => _items.fold(0, (s, i) => s + i.quantity);

  double get subtotal =>
      _items.fold(0, (s, i) => s + i.product.price * i.quantity);

  void add(Product product) {
    final idx = _items.indexWhere((c) => c.product.id == product.id);
    if (idx != -1) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void increment(int index) {
    _items[index].quantity++;
    notifyListeners();
  }

  void decrement(int index) {
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Checkout: create a Firestore order document for each cart item,
  /// then clear the cart.
  Future<void> checkout() async {
    final buyerEmail =
        AuthService.instance.currentUser?.email ?? 'unknown@furn.com';
    final fs = FirestoreService.instance;
    final now = DateTime.now();

    for (final item in _items) {
      final order = SellerOrder(
        sellerEmail: item.product.sellerEmail,
        buyerEmail: buyerEmail,
        productName: item.product.name,
        productId: item.product.id,
        productImageUrl: item.product.imageUrl,
        amount: item.product.price,
        quantity: item.quantity,
        status: 'Processing',
        createdAt: now,
      );
      await fs.createOrder(order);
      if (item.product.id != null) {
        await fs.decrementStock(item.product.id!, item.quantity);
      }
    }

    _items.clear();
    notifyListeners();
  }
}
