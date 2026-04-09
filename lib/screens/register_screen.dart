import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';
import 'seller_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;
  int _step = 1; // 1 = form, 2 = role selection
  String? _pendingRole;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Step 1 — validate form, advance to role selection
  void _handleRegister() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _error = null;
      _step = 2;
    });
  }

  // Step 2 — create account with chosen role
  Future<void> _createAccount(String role) async {
    setState(() {
      _loading = true;
      _pendingRole = role;
      _error = null;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      await AuthService.instance.register(name, email, password, role: role);
      if (!mounted) return;
      final destination =
          role == 'seller' ? const SellerShell() : const MainShell();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _pendingRole = null;
        _error = 'Registration failed. Email may already be in use.';
        _step = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF272727),
      body: Stack(
        children: [
          // Background panels
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.44,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3D3D3D), Color(0xFF222222)],
                ),
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x0AFFFFFF),
              ),
            ),
          ),
          Positioned(
            top: 30,
            left: 20,
            right: 20,
            height: MediaQuery.of(context).size.height * 0.28,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.weekend_rounded,
                    size: 64,
                    color: Color(0x14FFFFFF),
                  ),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.30,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 40,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _step == 1
                            ? _buildFormCard(key: const ValueKey(1))
                            : _buildRoleCard(key: const ValueKey(2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: form ─────────────────────────────────────────────────────────
  Widget _buildFormCard({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FURN',
          style: GoogleFonts.montserrat(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2C2C2C),
            letterSpacing: 5,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'CREATE ACCOUNT',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5C3D2E),
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 26),
        _buildTextField(
          controller: _nameController,
          hint: 'Full Name',
          obscure: false,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _emailController,
          hint: 'Email',
          obscure: false,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passwordController,
          hint: 'Password',
          obscure: true,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _confirmController,
          hint: 'Confirm Password',
          obscure: true,
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C3D2E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            child: Text(
              'NEXT',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Log In',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5C3D2E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: role selection ────────────────────────────────────────────────
  Widget _buildRoleCard({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FURN',
          style: GoogleFonts.montserrat(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2C2C2C),
            letterSpacing: 5,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'CHOOSE YOUR ROLE',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5C3D2E),
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'How will you be using Furn?',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 24),
        _buildRoleTile(
          role: 'buyer',
          icon: Icons.shopping_bag_outlined,
          title: 'Buyer',
          subtitle: 'Browse and purchase furniture',
        ),
        const SizedBox(height: 14),
        _buildRoleTile(
          role: 'seller',
          icon: Icons.storefront_outlined,
          title: 'Seller',
          subtitle: 'List and manage your products',
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 20),
        // Back to form
        Center(
          child: GestureDetector(
            onTap: _loading ? null : () => setState(() => _step = 1),
            child: Text(
              '← Back',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleTile({
    required String role,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isBusy = _loading && _pendingRole == role;
    return GestureDetector(
      onTap: _loading ? null : () => _createAccount(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7EDE0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isBusy
                ? const Color(0xFF5C3D2E)
                : const Color(0x00000000),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF5C3D2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isBusy
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF5C3D2E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.montserrat(
        fontSize: 13,
        color: const Color(0xFF2C2C2C),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
          color: Colors.grey.shade400,
          fontSize: 13,
        ),
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF5C3D2E),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
