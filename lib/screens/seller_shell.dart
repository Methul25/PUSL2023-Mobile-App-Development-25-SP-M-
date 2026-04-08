import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'seller_dashboard_screen.dart';
import 'seller_listings_screen.dart';
import 'seller_add_product_screen.dart';
import 'profile_screen.dart';

class SellerShell extends StatefulWidget {
  const SellerShell({super.key});

  @override
  State<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends State<SellerShell> {
  int _currentIndex = 0;
  final Map<int, Widget> _builtScreens = {};

  Widget _screenAt(int index) {
    return _builtScreens.putIfAbsent(index, () {
      switch (index) {
        case 0: return const SellerDashboardScreen();
        case 1: return const SellerListingsScreen();
        case 2: return SellerAddProductScreen(
          onPublished: () => setState(() => _currentIndex = 1),
          onBack: () => setState(() => _currentIndex = 0),
        );
        case 3: return const ProfileScreen();
        default: return const SizedBox.shrink();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _screenAt(_currentIndex);
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(4, (i) =>
          _builtScreens[i] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.bar_chart_rounded, 'Dashboard', 0),
              _navItem(Icons.inventory_2_outlined, 'Listings', 1),
              _navItem(Icons.add_box_outlined, 'Add Item', 2),
              _navItem(Icons.person_outline_rounded, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        _screenAt(index);
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0x142C2C2C)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: active ? const Color(0xFF2C2C2C) : Colors.grey.shade400,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color:
                    active ? const Color(0xFF2C2C2C) : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
