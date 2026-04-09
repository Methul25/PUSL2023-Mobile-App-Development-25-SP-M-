import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';
import 'seller_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Basic client-side validation
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
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

    setState(() { _loading = true; _error = null; });

    try {
      final user = await AuthService.instance.signIn(email, password);
      if (!mounted) return;
      final destination = user.isSeller
          ? const SellerShell()
          : const MainShell();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Invalid email or password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF272727),
      body: Stack(
        children: [
          // Decorative background panels simulating a room interior
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
          // Geometric accent — large dim circle top-right
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
          // Interior silhouette accent
          Positioned(
            top: 30,
            left: 20,
            right: 20,
            height: MediaQuery.of(context).size.height * 0.30,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // White login card
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
                    child: Column(
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
                          'FURNITURE STORE',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5C3D2E),
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 26),
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
                            onPressed: _loading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5C3D2E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'LOG IN',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 3,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Register link
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                                children: [
                                  const TextSpan(
                                      text: "Don't have an account? "),
                                  TextSpan(
                                    text: 'Register',
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
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
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
