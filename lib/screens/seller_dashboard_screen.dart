import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'seller_orders_screen.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  String get _sellerEmail =>
      AuthService.instance.currentUser?.email ?? 'seller@furn.com';

  @override
  Widget build(BuildContext context) {
    final sellerEmail = _sellerEmail;

    return Scaffold(
      backgroundColor: const Color(0xFFF7EDE0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: GoogleFonts.montserrat(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2C2C2C),
                        ),
                      ),
                      Text(
                        'Welcome back, ${AuthService.instance.currentUser?.name ?? 'Seller'}',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Revenue section with period tabs â€” live from Firestore
              _RevenueSection(sellerEmail: sellerEmail),
              const SizedBox(height: 20),

              // Stats row – live counts from Firestore
              StreamBuilder<({int total, int active})>(
                stream: FirestoreService.instance.productCountsStream(sellerEmail),
                builder: (context, snap) {
                  final active = snap.data?.active ?? 0;
                  final total = snap.data?.total ?? 0;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _StatCard(label: 'Total Products', value: '$total', icon: Icons.shopping_bag_outlined, color: const Color(0xFF5C3D2E))),
                          const SizedBox(width: 12),
                          Expanded(child: _StatCard(label: 'Active Listings', value: '$active', icon: Icons.inventory_2_outlined, color: const Color(0xFF2C8A5F))),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              // Pending orders + rating row
              StreamBuilder<int>(
                stream: FirestoreService.instance
                    .pendingOrderCountStream(sellerEmail),
                builder: (context, snap) {
                  final pending = snap.data ?? 0;
                  return Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              label: 'Pending Orders',
                              value: '$pending',
                              icon: Icons.pending_actions_outlined,
                              color: const Color(0xFFB87333))),
                      const SizedBox(width: 12),
                      const Expanded(
                          child: _StatCard(
                              label: 'Avg. Rating',
                              value: '-',
                              icon: Icons.star_outline_rounded,
                              color: Color(0xFF7B61FF))),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              const SizedBox(height: 8),

              // Recent orders â€” live
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Orders',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C2C2C),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SellerOrdersScreen()),
                    ),
                    child: Text(
                      'See all',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5C3D2E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _LiveRecentOrders(sellerEmail: sellerEmail),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Revenue Section (Daily / Weekly / Monthly / Yearly) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

enum _RevPeriod { daily, weekly, monthly, yearly }

class _RevenueSection extends StatefulWidget {
  final String sellerEmail;
  const _RevenueSection({required this.sellerEmail});

  @override
  State<_RevenueSection> createState() => _RevenueSectionState();
}

class _RevenueSectionState extends State<_RevenueSection> {
  _RevPeriod _period = _RevPeriod.weekly;

  Stream<({double total, List<({String label, double revenue})> bars})>
      get _stream {
    final fs = FirestoreService.instance;
    final email = widget.sellerEmail;
    switch (_period) {
      case _RevPeriod.daily:
        return fs.dailyPeriodStream(email);
      case _RevPeriod.weekly:
        return fs.weeklyPeriodStream(email);
      case _RevPeriod.monthly:
        return fs.monthlyPeriodStream(email);
      case _RevPeriod.yearly:
        return fs.yearlyPeriodStream(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period tab row
        _PeriodTabBar(
          selected: _period,
          onSelect: (p) => setState(() => _period = p),
        ),
        const SizedBox(height: 14),
        // Revenue card + chart
        StreamBuilder<
            ({double total, List<({String label, double revenue})> bars})>(
          stream: _stream,
          builder: (context, snap) {
            final total = snap.data?.total ?? 0;
            final bars = snap.data?.bars ?? [];
            final maxRevenue =
                bars.fold<double>(0, (m, b) => b.revenue > m ? b.revenue : m);

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _periodLabel,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (bars.isNotEmpty) ...
                    _buildChart(bars, maxRevenue),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String get _periodLabel {
    switch (_period) {
      case _RevPeriod.daily:
        return 'Today\'s Revenue';
      case _RevPeriod.weekly:
        return 'This Week\'s Revenue';
      case _RevPeriod.monthly:
        return 'This Month\'s Revenue';
      case _RevPeriod.yearly:
        return 'This Year\'s Revenue';
    }
  }

  List<Widget> _buildChart(
      List<({String label, double revenue})> bars, double maxRevenue) {
    return [
      SizedBox(
        height: 90,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: bars.map((b) {
            final fraction = maxRevenue > 0 ? b.revenue / maxRevenue : 0.0;
            final isMax = fraction == 1.0 && maxRevenue > 0;
            return Tooltip(
              message: '\$${b.revenue.toStringAsFixed(0)}',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 22,
                height: (76 * fraction).clamp(3.0, 76.0),
                decoration: BoxDecoration(
                  color: isMax
                      ? const Color(0xFF5C8A70)
                      : Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: bars
            .map((b) => Text(
                  b.label,
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                  ),
                ))
            .toList(),
      ),
    ];
  }
}

// â”€â”€â”€ Period Tab Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PeriodTabBar extends StatelessWidget {
  final _RevPeriod selected;
  final ValueChanged<_RevPeriod> onSelect;
  const _PeriodTabBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _RevPeriod.values.map((p) {
        final isSelected = p == selected;
        final label = p.name[0].toUpperCase() + p.name.substring(1);
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2C2C2C)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// â”€â”€â”€ Stat Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2C2C2C),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Live Recent Orders â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LiveRecentOrders extends StatelessWidget {
  final String sellerEmail;
  const _LiveRecentOrders({required this.sellerEmail});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SellerOrder>>(
      stream: FirestoreService.instance.ordersStream(sellerEmail),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Color(0xFF5C3D2E),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final orders = snap.data ?? [];

        if (orders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'No orders yet',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: orders.map((o) => _OrderTile(order: o)).toList(),
        );
      },
    );
  }
}

// â”€â”€â”€ Order tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OrderTile extends StatelessWidget {
  final SellerOrder order;

  const _OrderTile({required this.order});

  Color get _statusColor {
    switch (order.status) {
      case 'Delivered':
        return const Color(0xFF2C8A5F);
      case 'Shipped':
        return const Color(0xFF5C3D2E);
      default:
        return const Color(0xFFB87333);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd').format(order.createdAt);
    final orderId = '#ORD-${order.id?.substring(0, 4).toUpperCase() ?? '0000'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Icon
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
                Text(
                  order.productName,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$orderId  Â·  $dateStr',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${(order.amount * order.quantity).toStringAsFixed(2)}',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
