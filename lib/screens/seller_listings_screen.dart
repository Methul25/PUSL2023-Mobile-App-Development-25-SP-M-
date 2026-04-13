import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'seller_add_product_screen.dart';

class SellerListingsScreen extends StatefulWidget {
  const SellerListingsScreen({super.key});

  @override
  State<SellerListingsScreen> createState() => _SellerListingsScreenState();
}

class _SellerListingsScreenState extends State<SellerListingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _fs = FirestoreService.instance;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EDE0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Listings',
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2C2C2C),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SellerAddProductScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Add',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stream-driven tabs + list
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _fs.streamAllProducts(
                    AuthService.instance.currentUser?.email ?? ''),
                builder: (context, snapshot) {
                  final listings = snapshot.data ?? [];
                  final active = listings.where((p) => p.active).toList();
                  final draft = listings.where((p) => !p.active).toList();

                  return Column(
                    children: [
                      Container(
                        color: const Color(0xFFF7EDE0),
                        child: TabBar(
                          controller: _tab,
                          labelStyle: GoogleFonts.montserrat(
                              fontSize: 12, fontWeight: FontWeight.w700),
                          unselectedLabelStyle: GoogleFonts.montserrat(
                              fontSize: 12, fontWeight: FontWeight.w500),
                          labelColor: const Color(0xFF2C2C2C),
                          unselectedLabelColor: Colors.grey.shade500,
                          indicatorColor: const Color(0xFF5C3D2E),
                          indicatorWeight: 2.5,
                          indicatorSize: TabBarIndicatorSize.label,
                          tabs: [
                            Tab(text: 'All (${listings.length})'),
                            Tab(text: 'Active (${active.length})'),
                            Tab(text: 'Draft (${draft.length})'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : TabBarView(
                                controller: _tab,
                                children: [
                                  _ProductList(items: listings, fs: _fs),
                                  _ProductList(items: active, fs: _fs),
                                  _ProductList(items: draft, fs: _fs),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── List widget ─────────────────────────────────────────────────────────────

class _ProductList extends StatelessWidget {
  final List<Product> items;
  final FirestoreService fs;

  const _ProductList({required this.items, required this.fs});

  void _showUpdateStockDialog(BuildContext context, Product product) {
    final controller = TextEditingController(text: product.stock.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Update Stock',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New stock quantity',
                labelStyle: GoogleFonts.montserrat(fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              style: GoogleFonts.montserrat(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value < 0) return;
              fs.updateStock(product.id!, value);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${product.name} stock updated to $value',
                    style: GoogleFonts.montserrat(fontSize: 13),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF2C8A5F),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Text('Save',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C3D2E))),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Product?',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to remove "${product.name}"? This action cannot be undone.',
          style: GoogleFonts.montserrat(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              fs.deleteProduct(product.id!);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} removed'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF2C2C2C),
                ),
              );
            },
            child: Text('Delete',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700, color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No listings here',
          style: GoogleFonts.montserrat(
              fontSize: 14, color: Colors.grey.shade500),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final product = items[i];
        return Dismissible(
          key: ValueKey(product.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 24),
          ),
          confirmDismiss: (_) async {
            _showDeleteDialog(context, product);
            return false; // Let the dialog handle deletion
          },
          onDismissed: (_) => fs.deleteProduct(product.id!),
          child: _ListingCard(
            product: product,
            onToggle: () => fs.toggleProduct(product.id!, !product.active),
            onDelete: () => _showDeleteDialog(context, product),
            onUpdateStock: () => _showUpdateStockDialog(context, product),
          ),
        );
      },
    );
  }
}

// ─── Listing Card ─────────────────────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final Product product;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onUpdateStock;

  const _ListingCard({
    required this.product,
    required this.onToggle,
    required this.onDelete,
    required this.onUpdateStock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF7EDE0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.chair_outlined,
                              color: Color(0xFF5C3D2E), size: 28),
                    ),
                  )
                : const Icon(Icons.chair_outlined,
                    color: Color(0xFF5C3D2E), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.category}  ·  Stock: ${product.stock}',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5C3D2E),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onUpdateStock,
                    icon: const Icon(Icons.inventory_2_outlined,
                        color: Color(0xFF5C3D2E), size: 20),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Update stock',
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                  Switch(
                    value: product.active,
                    onChanged: (_) => onToggle(),
                    activeThumbColor: const Color(0xFF2C8A5F),
                    inactiveThumbColor: Colors.grey.shade400,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              Text(
                product.active ? 'Active' : 'Draft',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: product.active
                      ? const Color(0xFF2C8A5F)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
