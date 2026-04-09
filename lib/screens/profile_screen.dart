import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/order.dart';
import 'login_screen.dart';
import 'buyer_orders_screen.dart';
import 'main_shell.dart';
import 'seller_shell.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _switching = false;

  String get _userEmail => AuthService.instance.currentUser?.email ?? '';

  Future<void> _handleSwitchRole() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final isSeller = user.isSeller;
    final newRole = isSeller ? 'buyer' : 'seller';
    final label = isSeller ? 'Buyer' : 'Seller';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Switch to $label Mode',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'You will be switched to the $label dashboard.',
          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Switch',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C3D2E))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _switching = true);
    try {
      await AuthService.instance.switchRole(newRole);
      if (!mounted) return;
      final destination =
          newRole == 'seller' ? const SellerShell() : const MainShell();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (_) => false,
      );
    } catch (_) {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: StreamBuilder<List<SellerOrder>>(
          stream: FirestoreService.instance.buyerOrdersStream(_userEmail),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];
            final inProgress = orders.where((o) => o.status != 'Delivered').length;
            final delivered = orders.where((o) => o.status == 'Delivered').length;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 4),
                  _buildStatRow(inProgress, delivered),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildMenuSection(context, 'MY ACCOUNT', [
                    _MenuItem(
                      Icons.shopping_bag_outlined,
                      'My Orders',
                      inProgress > 0
                          ? '$inProgress order${inProgress == 1 ? '' : 's'} in progress'
                          : 'No orders in progress',  
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const BuyerOrdersScreen())),
                    ),
                  ]),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildMenuSection(context, 'SETTINGS', [
                    _MenuItem(
                      AuthService.instance.currentUser?.isSeller == true
                          ? Icons.person_outline_rounded
                          : Icons.storefront_outlined,
                      AuthService.instance.currentUser?.isSeller == true
                          ? 'Switch to Buyer Mode'
                          : 'Switch to Seller Mode',
                      AuthService.instance.currentUser?.isSeller == true
                          ? 'Browse and shop for furniture'
                          : 'List and manage your products',
                      onTap: _switching ? null : _handleSwitchRole,
                      trailing: _switching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF5C3D2E),
                              ),
                            )
                          : null,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await AuthService.instance.signOut();
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                        },
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: Text(
                          'LOG OUT',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            fontSize: 12,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(color: Colors.red.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            );
          }),
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
        'PROFILE',
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF2C2C2C),
          letterSpacing: 4,
        ),
      ),
      centerTitle: true,
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 18),
          child: Icon(Icons.edit_outlined, color: Color(0xFF2C2C2C), size: 22),
        ),
      ],
    );
  }

  // ── Profile header ────────────────────────────────────────────────────────
  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF7EDE0),
                  border: Border.all(color: const Color(0xFFC4A882), width: 2.5),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 52,
                  color: Color(0xFFC4A882),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF5C3D2E),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AuthService.instance.currentUser?.name ?? 'Guest',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            AuthService.instance.currentUser?.email ?? '',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────
  Widget _buildStatRow(int inProgress, int delivered) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _buildStat(inProgress.toString(), 'In Progress'),
            Container(width: 1, height: 36, color: const Color(0xFFE0E0E0)),
            _buildStat(delivered.toString(), 'Delivered'),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Menu section ──────────────────────────────────────────────────────────
  Widget _buildMenuSection(
      BuildContext context, String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
              letterSpacing: 2.5,
            ),
          ),
        ),
        ...items.map((i) => _buildMenuItem(context, i)),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF7EDE0),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(item.icon, size: 20, color: const Color(0xFF5C3D2E)),
      ),
      title: Text(
        item.title,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF2C2C2C),
        ),
      ),
      subtitle: Text(
        item.subtitle,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          color: Colors.grey.shade500,
        ),
      ),
      trailing: item.trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey,
            size: 22,
          ),
      onTap: item.onTap,
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.title, this.subtitle, {this.onTap, this.trailing});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
}
