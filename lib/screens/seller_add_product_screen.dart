import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class SellerAddProductScreen extends StatefulWidget {
  /// Called after a successful publish (only when embedded as a tab).
  final VoidCallback? onPublished;
  /// Called when the back button is pressed while embedded as a tab.
  final VoidCallback? onBack;
  const SellerAddProductScreen({super.key, this.onPublished, this.onBack});

  @override
  State<SellerAddProductScreen> createState() =>
      _SellerAddProductScreenState();
}

class _SellerAddProductScreenState extends State<SellerAddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  String _category = 'Sofas';
  XFile? _pickedFile;
  Uint8List? _previewBytes;

  static const _categories = [
    'Sofas',
    'Chairs',
    'Tables',
    'Lighting',
    'Beds',
    'Storage'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  bool _submitting = false;

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _descCtrl.clear();
    _priceCtrl.clear();
    _stockCtrl.clear();
    setState(() {
      _category = 'Sofas';
      _pickedFile = null;
      _previewBytes = null;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedFile = image;
        _previewBytes = bytes;
      });
    }
  }

  void _submit(bool publish) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      String? imageUrl;

      // 1. Upload image if picked
      if (_pickedFile != null) {
        final bytes = await _pickedFile!.readAsBytes();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}';
        try {
          imageUrl = await FirestoreService.instance.uploadProductImage(
            bytes,
            fileName,
          );
        } catch (uploadError) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image upload failed: $uploadError',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 6),
            ),
          );
          setState(() => _submitting = false);
          return;
        }
      }

      // 2. Create product with image URL
      final product = Product(
        imageUrl: imageUrl,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        stock: int.parse(_stockCtrl.text.trim()),
        category: _category,
        active: publish,
        sellerEmail:
            AuthService.instance.currentUser?.email ?? 'seller@furn.com',
        createdAt: DateTime.now(),
      );

      await FirestoreService.instance.addProduct(product);

      if (!mounted) return;
      final label = publish ? 'Published' : 'Saved as Draft';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label successfully!',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
          backgroundColor:
              publish ? const Color(0xFF2C8A5F) : const Color(0xFF5C3D2E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      if (publish) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          // Embedded as a tab — reset form and notify shell
          _resetForm();
          widget.onPublished?.call();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EDE0),
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        widget.onBack?.call();
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: Color(0xFF2C2C2C)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Add New Product',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2C2C2C),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image upload
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0x80C4A882),
                              width: 1.5,
                            ),
                          ),
                          child: _previewBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(_previewBytes!,
                                      fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7EDE0),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: Color(0xFF5C3D2E),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Tap to upload product image',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    Text(
                                      'PNG, JPG up to 10MB',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _label('Product Name'),
                      _field(
                        controller: _nameCtrl,
                        hint: 'e.g. Oslo Lounge Chair',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Enter a name' : null,
                      ),
                      const SizedBox(height: 16),

                      _label('Description'),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        style: GoogleFonts.montserrat(fontSize: 14),
                        decoration: _inputDeco('Describe material, dimensions, style…'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter a description'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Price (\$)'),
                                TextFormField(
                                  controller: _priceCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  style: GoogleFonts.montserrat(fontSize: 14),
                                  decoration: _inputDeco('0.00'),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    if (double.tryParse(v) == null) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Stock'),
                                TextFormField(
                                  controller: _stockCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: GoogleFonts.montserrat(fontSize: 14),
                                  decoration: _inputDeco('0'),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    if (int.tryParse(v) == null) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _label('Category'),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c,
                                      style: GoogleFonts.montserrat(
                                          fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v!),
                        decoration: _inputDeco(''),
                        style: GoogleFonts.montserrat(
                            fontSize: 14, color: const Color(0xFF2C2C2C)),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      const SizedBox(height: 24),

                      const SizedBox(height: 36),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting ? null : () => _submit(false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(
                                    color: Color(0xFF5C3D2E), width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                'Save Draft',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF5C3D2E),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : () => _submit(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2C2C2C),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: Text(
                                'Publish',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C2C2C),
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
  }) =>
      TextFormField(
        controller: controller,
        style: GoogleFonts.montserrat(fontSize: 14),
        decoration: _inputDeco(hint),
        validator: validator,
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
            fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF5C3D2E), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      );
}
