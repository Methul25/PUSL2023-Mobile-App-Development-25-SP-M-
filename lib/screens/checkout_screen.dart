import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/cart_manager.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cart = CartManager.instance;
  bool _placing = false;

  // Delivery
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();

  // Payment
  final _cardCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    _cardCtrl.dispose();
    _cardNameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _placing = true);
    try {
      await _cart.checkout();
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _SuccessDialog(
          onDone: () {
            Navigator.pop(ctx);    // close dialog
            Navigator.pop(context); // back to cart (now empty)
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order failed: $e',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2C2C2C), size: 20),
        ),
        title: Text(
          'CHECKOUT',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2C2C2C),
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            // ── Delivery ─────────────────────────────────────────────────
            _sectionHeader('DELIVERY INFORMATION'),
            const SizedBox(height: 12),
            _inputField(_nameCtrl, 'Full Name', Icons.person_outline_rounded),
            const SizedBox(height: 12),
            _inputField(
                _addressCtrl, 'Street Address', Icons.home_outlined),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _inputField(
                      _cityCtrl, 'City', Icons.location_city_outlined),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: _inputField(
                    _zipCtrl,
                    'ZIP Code',
                    Icons.local_post_office_outlined,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),

            // ── Payment ───────────────────────────────────────────────────
            const SizedBox(height: 28),
            _sectionHeader('PAYMENT DETAILS'),
            const SizedBox(height: 12),
            _cardNumberField(),
            const SizedBox(height: 12),
            _inputField(
                _cardNameCtrl, 'Name on Card', Icons.badge_outlined),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _inputField(
                    _expiryCtrl,
                    'MM / YY',
                    Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    inputFormatters: [_ExpiryFormatter()],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v.trim())) {
                        return 'Use MM/YY';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: _inputField(
                    _cvvCtrl,
                    'CVV',
                    Icons.lock_outline_rounded,
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    obscureText: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 3) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            // ── Order summary ─────────────────────────────────────────────
            const SizedBox(height: 28),
            _sectionHeader('ORDER SUMMARY'),
            const SizedBox(height: 12),
            _buildOrderSummary(),

            // ── Place Order button ─────────────────────────────────────────
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed:
                    _placing || _cart.items.isEmpty ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C),
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _placing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'PLACE ORDER',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 2.5,
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon:
            Icon(icon, size: 18, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFC4A882))),
        hintStyle: GoogleFonts.montserrat(
            fontSize: 13, color: Colors.grey.shade400),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        errorStyle: GoogleFonts.montserrat(fontSize: 10),
      ),
      style: GoogleFonts.montserrat(
          fontSize: 13, fontWeight: FontWeight.w600),
      validator:
          validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  Widget _cardNumberField() {
    return TextFormField(
      controller: _cardCtrl,
      keyboardType: TextInputType.number,
      maxLength: 19,
      inputFormatters: [_CardNumberFormatter()],
      decoration: InputDecoration(
        hintText: '1234  5678  9012  3456',
        prefixIcon: const Icon(Icons.credit_card_rounded,
            size: 20, color: Color(0xFFC4A882)),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFC4A882))),
        hintStyle: GoogleFonts.montserrat(
            fontSize: 13, color: Colors.grey.shade400),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        errorStyle: GoogleFonts.montserrat(fontSize: 10),
      ),
      style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 2),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        if (v.replaceAll(' ', '').length < 16) return 'Enter 16-digit card number';
        return null;
      },
    );
  }

  Widget _buildOrderSummary() {
    final items = _cart.items;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7EDE0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: item.product.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                  Icons.chair_rounded,
                                  color: Color(0xFFC4A882),
                                  size: 22),
                            ),
                          )
                        : const Icon(Icons.chair_rounded,
                            color: Color(0xFFC4A882), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2C2C2C)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Qty: ${item.quantity}',
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C2C2C)),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 20, color: Color(0xFFEEEEEE)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: GoogleFonts.montserrat(
                      fontSize: 14, fontWeight: FontWeight.w800)),
              Text(
                '\$${_cart.subtotal.toStringAsFixed(2)}',
                style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5C3D2E)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Input Formatters ──────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue v) {
    final digits = v.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue v) {
    final digits = v.text.replaceAll(RegExp(r'\D'), '');
    String text = digits;
    if (digits.length >= 2) {
      text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    if (text.length > 5) text = text.substring(0, 5);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ── Success Dialog ────────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessDialog({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF4CAF50), size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Order Placed!',
              style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2C2C2C)),
            ),
            const SizedBox(height: 10),
            Text(
              'Your order has been placed\nsuccessfully. Track it in My Orders.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  height: 1.6),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'DONE',
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w800, letterSpacing: 2.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}