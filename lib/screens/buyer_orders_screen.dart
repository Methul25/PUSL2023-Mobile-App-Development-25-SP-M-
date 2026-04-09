import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';
import '../models/review.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class BuyerOrdersScreen extends StatelessWidget {
  const BuyerOrdersScreen({super.key});

  String get _userEmail => AuthService.instance.currentUser?.email ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2C2C2C), size: 20),
        ),
        title: Text(
          'My Orders',
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: const Color(0xFF2C2C2C)),
        ),
      ),
      body: StreamBuilder<List<SellerOrder>>(
        stream: FirestoreService.instance.buyerOrdersStream(_userEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF5C3D2E)));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 64, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text(
                    'No orders placed yet',
                    style: GoogleFonts.montserrat(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your purchases will appear here.',
                    style: GoogleFonts.montserrat(
                        color: Colors.grey.shade300, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, i) => _OrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final SellerOrder order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _confirming = false;

  Future<void> _confirmDelivery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Delivery',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text(
          'Have you received your order? This action cannot be undone.',
          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C8A5F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Yes, Received',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );

    if (confirmed != true || widget.order.id == null) return;

    setState(() => _confirming = true);
    try {
      await FirestoreService.instance
          .updateOrderStatus(widget.order.id!, 'Delivered');
      if (mounted) {
        await _promptReview();
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _promptReview() async {
    final productId = widget.order.productId;
    if (productId == null || !mounted) return;

    final userEmail = AuthService.instance.currentUser?.email ?? '';
    final alreadyReviewed =
        await FirestoreService.instance.hasReviewed(productId, userEmail);
    if (alreadyReviewed || !mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ReviewSheet(
        productId: productId,
        productName: widget.order.productName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(widget.order.createdAt);
    final orderId =
        '#ORD-${widget.order.id?.substring(0, 8).toUpperCase() ?? '00000000'}';
    final canConfirm = widget.order.status != 'Delivered';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(orderId,
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
                      letterSpacing: 0.5)),
              _StatusBadge(status: widget.order.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7EDE0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: widget.order.productImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.order.productImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.chair_rounded,
                                  color: Color(0xFFC4A882), size: 30),
                        ),
                      )
                    : const Icon(Icons.chair_rounded,
                        color: Color(0xFFC4A882), size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.order.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2C2C2C))),
                    const SizedBox(height: 4),
                    Text('Qty: ${widget.order.quantity}',
                        style: GoogleFonts.montserrat(
                            fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 2),
                    Text(dateStr,
                        style: GoogleFonts.montserrat(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Text('\$${widget.order.lineTotal.toStringAsFixed(2)}',
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF5C3D2E))),
            ],
          ),
          if (canConfirm) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _confirming ? null : _confirmDelivery,
                  icon: _confirming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(
                    _confirming ? 'Confirming...' : 'Confirm Delivery',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C8A5F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Delivered':
        color = const Color(0xFF2C8A5F);
        break;
      case 'Shipped':
        color = const Color(0xFF5C3D2E);
        break;
      default:
        color = const Color(0xFFB87333);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.toUpperCase(),
          style: GoogleFonts.montserrat(
              fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 1)),
    );
  }
}

// ── Review Sheet ─────────────────────────────────────────────────────────────

class _ReviewSheet extends StatefulWidget {
  final String productId;
  final String productName;
  const _ReviewSheet({required this.productId, required this.productName});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _ctrl = TextEditingController();
  double _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _userEmail => AuthService.instance.currentUser?.email ?? '';
  String get _userName =>
      AuthService.instance.currentUser?.name ??
      _userEmail.split('@').first;

  Future<void> _submit() async {
    final comment = _ctrl.text.trim();
    if (comment.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await FirestoreService.instance.addReview(Review(
        productId: widget.productId,
        userEmail: _userEmail,
        userName: _userName,
        rating: _rating,
        comment: comment,
        createdAt: DateTime.now(),
      ));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review posted!',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF2C8A5F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('How was ${widget.productName}?',
              style: GoogleFonts.montserrat(
                  fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF2C2C2C))),
          const SizedBox(height: 4),
          Text('Verified purchase · share your experience',
              style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1.0;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: Icon(
                  star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFFC107),
                  size: 34,
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your thoughts...',
              hintStyle:
                  GoogleFonts.montserrat(fontSize: 13, color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF9F4EF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            style: GoogleFonts.montserrat(fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('POST REVIEW',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Center(
              child: Text('Skip',
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
