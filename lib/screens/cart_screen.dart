import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/cart_manager.dart';
import 'browse_screen.dart';
import 'checkout_screen.dart';

const _categoryIcons = <String, IconData>{
  'Sofas': Icons.weekend_rounded,
  'Chairs': Icons.chair_rounded,
  'Tables': Icons.table_restaurant_rounded,
  'Lighting': Icons.light_rounded,
  'Beds': Icons.bed_rounded,
  'Storage': Icons.inventory_2_outlined,
};

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cart = CartManager.instance;

  @override
  void initState() {
    super.initState();
    _cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() => setState(() {});

  double get _subtotal => _cart.subtotal;
  double get _total => _subtotal;

  void _goToCheckout() {
    if (_cart.items.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _cart.items.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: _cart.items.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: Color(0xFFEEEEEE),
                    ),
                    itemBuilder: (_, i) => _buildCartRow(i),
                  ),
          ),
          _buildSummary(),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leadingWidth: 56,
      leading: const Padding(
        padding: EdgeInsets.only(left: 18),
        child: Icon(Icons.menu_rounded, color: Color(0xFF2C2C2C), size: 26),
      ),
      title: Text(
        'MY CART',
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF2C2C2C),
          letterSpacing: 4,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_cart.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: Text(
                      'Clear Cart?',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    content: Text(
                      'Remove all items from your cart?',
                      style: GoogleFonts.montserrat(fontSize: 13),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel',
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () {
                          _cart.clear();
                          Navigator.pop(ctx);
                        },
                        child: Text('Clear',
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                                color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: Color(0xFF5C3D2E), size: 22),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF5C3D2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_cart.count}',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Cart row ──────────────────────────────────────────────────────────────
  Widget _buildCartRow(int index) {
    final item = _cart.items[index];
    final icon =
        _categoryIcons[item.product.category] ?? Icons.inventory_2_outlined;
    return Dismissible(
      key: ValueKey('${item.product.id ?? item.product.name}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: const Color(0xFFFFEEEE),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.redAccent,
          size: 22,
        ),
      ),
      onDismissed: (_) => _cart.removeAt(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF7EDE0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: item.product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.product.imageUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          icon,
                          size: 28,
                          color: const Color(0xFFC9A880),
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      size: 28,
                      color: const Color(0xFFC9A880),
                    ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: const Color(0xFF2C2C2C),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Quantity stepper
                  Row(
                    children: [
                      _quantityBtn(
                        Icons.remove,
                        () => _cart.decrement(index),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${item.quantity}',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: const Color(0xFF2C2C2C),
                          ),
                        ),
                      ),
                      _quantityBtn(
                        Icons.add,
                        () => _cart.increment(index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Price
            Text(
              '\$${(item.product.price * item.quantity).toStringAsFixed(0)}',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: const Color(0xFF2C2C2C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: const Color(0xFF5C3D2E)),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 72,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            'YOUR CART IS EMPTY',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some furniture to get started',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              MainShellNavigator.of(context)?.switchTo(1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'BROWSE PRODUCTS',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Order summary ─────────────────────────────────────────────────────────
  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDER SUMMARY',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 14),
          _summaryRow('Subtotal', '\$${_subtotal.toStringAsFixed(2)}',
              isBold: false),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          _summaryRow('Total', '\$${_total.toStringAsFixed(2)}', isBold: true),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate back to Browse
                      MainShellNavigator.of(context)?.switchTo(1);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5C3D2E),
                      side: const BorderSide(color: Color(0xFFC4A882)),
                      backgroundColor: const Color(0xFFF7EDE0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'CONTINUE',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _cart.items.isEmpty ? null : _goToCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C2C),
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'CHECK OUT',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    required bool isBold,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: const Color(0xFF2C2C2C),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: const Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }
}