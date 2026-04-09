import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _fs = FirestoreService.instance;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String get _sellerEmail =>
      AuthService.instance.currentUser?.email ?? 'seller@furn.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EDE0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2C2C2C), size: 20),
        ),
        title: Text(
          'Orders',
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: const Color(0xFF2C2C2C)),
        ),
      ),
      body: StreamBuilder<List<SellerOrder>>(
        stream: _fs.ordersStream(_sellerEmail),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          final processing = orders.where((o) => o.status == 'Processing').toList();
          final shipped = orders.where((o) => o.status == 'Shipped').toList();
          final delivered = orders.where((o) => o.status == 'Delivered').toList();

          return Column(
            children: [
              TabBar(
                controller: _tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w500),
                labelColor: const Color(0xFF2C2C2C),
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: const Color(0xFF5C3D2E),
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  Tab(text: 'All (${orders.length})'),
                  Tab(text: 'Processing (${processing.length})'),
                  Tab(text: 'Shipped (${shipped.length})'),
                  Tab(text: 'Delivered (${delivered.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _OrderList(orders: orders),
                    _OrderList(orders: processing),
                    _OrderList(orders: shipped),
                    _OrderList(orders: delivered),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<SellerOrder> orders;
  const _OrderList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No orders here',
              style: GoogleFonts.montserrat(
                  fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: orders.length,
      itemBuilder: (context, i) => _OrderCard(order: orders[i]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final SellerOrder order;
  const _OrderCard({required this.order});

  void _updateStatus(BuildContext context, String newStatus) async {
    await FirestoreService.instance.updateOrderStatus(order.id!, newStatus);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order marked as $newStatus'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF5C3D2E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, hh:mm a').format(order.createdAt);
    final orderId = '#ORD-${order.id?.substring(0, 6).toUpperCase() ?? '000000'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon/Thumbnail
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7EDE0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: order.productImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          order.productImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.shopping_bag_outlined,
                                  color: Color(0xFF5C3D2E), size: 22),
                        ),
                      )
                    : const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFF5C3D2E),
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(orderId,
                        style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5C3D2E))),
                    Text(order.productName,
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2C2C2C))),
                  ],
                ),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          Text('Buyer: ${order.buyerEmail}',
              style: GoogleFonts.montserrat(
                  fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(dateStr,
              style: GoogleFonts.montserrat(
                  fontSize: 11, color: Colors.grey.shade500)),
          const Divider(height: 24, color: Color(0xFFF7EDE0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('QUANTITY',
                      style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                  Text('x${order.quantity}',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2C2C2C))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TOTAL AMOUNT',
                      style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                  Text('\$${order.lineTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2C2C2C))),
                ],
              ),
            ],
          ),
          if (order.status != 'Delivered') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  if (order.status == 'Processing') {
                    _updateStatus(context, 'Shipped');
                  } else if (order.status == 'Shipped') {
                    _updateStatus(context, 'Delivered');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  order.status == 'Processing'
                      ? 'MARK AS SHIPPED'
                      : 'MARK AS DELIVERED',
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1),
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
      child: Text(status,
          style: GoogleFonts.montserrat(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
