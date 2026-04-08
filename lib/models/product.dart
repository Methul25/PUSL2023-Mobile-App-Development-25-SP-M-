import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String category;
  final int? colorIndex;
  final bool active;
  final String? imageUrl;
  final String sellerEmail;
  final DateTime createdAt;

  const Product({
    this.id,
    this.imageUrl,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.category,
    this.colorIndex,
    this.active = true,
    this.sellerEmail = 'seller@furn.com',
    required this.createdAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return Product(
      id: doc.id,
      imageUrl: d['imageUrl'] as String?,
      name: d['name'] as String? ?? '',
      description: d['description'] as String? ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0,
      stock: (d['stock'] as num?)?.toInt() ?? 0,
      category: d['category'] as String? ?? '',
      colorIndex: d['colorIndex'] as int?,
      active: d['active'] as bool? ?? true,
      sellerEmail: d['sellerEmail'] as String? ?? 'seller@furn.com',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'imageUrl': imageUrl,
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'category': category,
        'colorIndex': colorIndex,
        'active': active,
        'sellerEmail': sellerEmail,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Product copyWith({bool? active, int? stock, String? sellerEmail, String? imageUrl}) => Product(
        id: id,
        imageUrl: imageUrl ?? this.imageUrl,
        name: name,
        description: description,
        price: price,
        stock: stock ?? this.stock,
        category: category,
        colorIndex: colorIndex,
        active: active ?? this.active,
        sellerEmail: sellerEmail ?? this.sellerEmail,
        createdAt: createdAt,
      );
}
