import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../services/gemini_service.dart';
import '../services/cart_manager.dart';

class GeminiChatSheet extends StatefulWidget {
  final List<Product> products;
  /// Called when Gemini requests a filter change.
  /// [filter] is null when the user asks to clear filters.
  /// [label] is a human-readable description of the active filter.
  final void Function(List<Product> Function(List<Product>)? filter, String label)? onFilterApplied;

  const GeminiChatSheet({super.key, required this.products, this.onFilterApplied});

  @override
  State<GeminiChatSheet> createState() => _GeminiChatSheetState();
}

class _GeminiChatSheetState extends State<GeminiChatSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<GeminiMessage> _history = [];
  final List<_ChatBubble> _bubbles = [];
  bool _loading = false;
  final Map<String, Uint8List> _productImages = {};
  late Future<void> _imagesPrefetch;

  @override
  void initState() {
    super.initState();
    _imagesPrefetch = _prefetchProductImages();
  }

  Future<void> _prefetchProductImages() async {
    final futures = widget.products
        .where((p) => p.id != null && p.imageUrl != null && p.imageUrl!.isNotEmpty)
        .map((p) async {
          try {
            final res = await http.get(Uri.parse(p.imageUrl!));
            if (res.statusCode == 200) {
              _productImages[p.id!] = res.bodyBytes;
            }
          } catch (_) {}
        });
    await Future.wait(futures);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _bubbles.add(_ChatBubble(text: text, isUser: true));
      _history.add(GeminiMessage(role: 'user', text: text));
      _loading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      // Wait for images to finish loading (already done if user is slow)
      await _imagesPrefetch.timeout(const Duration(seconds: 5), onTimeout: () {});

      final reply = await GeminiService.instance.send(
        userMessage: text,
        products: widget.products,
        history: List.from(_history)..removeLast(), // exclude current
        productImages: _productImages.isNotEmpty ? _productImages : null,
      );
      if (!mounted) return;

      // Parse and handle cart action tag
      final actionPattern = RegExp(r'\[ACTION:ADD_TO_CART:(.+?)\]', caseSensitive: false);
      final actionMatch = actionPattern.firstMatch(reply);
      String cleanReply = reply.replaceAll(actionPattern, '').trim();

      // Parse and handle filter action tag
      final filterPattern = RegExp(r'\[ACTION:FILTER:([^\]]+)\]', caseSensitive: false);
      final filterMatch = filterPattern.firstMatch(cleanReply);
      cleanReply = cleanReply.replaceAll(filterPattern, '').trim();

      if (filterMatch != null && widget.onFilterApplied != null) {
        final criteria = filterMatch.group(1)!.trim().toUpperCase();
        _applyFilterCriteria(criteria);
      }

      if (actionMatch != null) {
        final productName = actionMatch.group(1)!.trim();
        try {
          final found = widget.products.firstWhere(
            (p) =>
                p.name.toLowerCase() == productName.toLowerCase() ||
                p.name.toLowerCase().contains(productName.toLowerCase()) ||
                productName.toLowerCase().contains(p.name.toLowerCase()),
          );
          CartManager.instance.add(found);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${found.name} added to cart!',
                  style: GoogleFonts.montserrat(fontSize: 13),
                ),
                backgroundColor: const Color(0xFF5C3D2E),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (_) {
          // Product not found in catalog — ignore silently
        }
      }

      setState(() {
        _bubbles.add(_ChatBubble(text: cleanReply.isEmpty ? reply : cleanReply, isUser: false));
        _history.add(GeminiMessage(role: 'model', text: reply));
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bubbles.add(_ChatBubble(
            text: 'Error: ${e.toString().replaceAll('Exception: ', '')}',
            isUser: false,
            isError: true));
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _applyFilterCriteria(String criteria) {
    if (criteria == 'CLEAR') {
      widget.onFilterApplied!(null, '');
      return;
    }
    if (criteria == 'IN_STOCK') {
      widget.onFilterApplied!((list) => list.where((p) => p.stock > 0).toList(), 'In stock only');
      return;
    }
    if (criteria == 'OUT_OF_STOCK') {
      widget.onFilterApplied!((list) => list.where((p) => p.stock == 0).toList(), 'Out of stock');
      return;
    }
    if (criteria.startsWith('PRICE_UNDER:')) {
      final amount = double.tryParse(criteria.split(':')[1]) ?? 0;
      widget.onFilterApplied!(
        (list) => list.where((p) => p.price < amount).toList(),
        'Under \$${amount.toStringAsFixed(0)}',
      );
      return;
    }
    if (criteria.startsWith('PRICE_OVER:')) {
      final amount = double.tryParse(criteria.split(':')[1]) ?? 0;
      widget.onFilterApplied!(
        (list) => list.where((p) => p.price > amount).toList(),
        'Over \$${amount.toStringAsFixed(0)}',
      );
      return;
    }
    if (criteria.startsWith('CATEGORY:')) {
      final cat = criteria.substring('CATEGORY:'.length);
      final catCapitalized = cat[0].toUpperCase() + cat.substring(1).toLowerCase();
      widget.onFilterApplied!(
        (list) => list.where((p) => p.category.toLowerCase() == cat.toLowerCase()).toList(),
        catCapitalized,
      );
      return;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C3D2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FURN Assistant',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                    Text(
                      'Powered by Gemini AI',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          // Messages
          SizedBox(
            height: 320,
            child: _bubbles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Ask me anything!\ne.g. "I need a sofa under \$200"',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _bubbles.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_loading && i == _bubbles.length) {
                        return _buildTypingIndicator();
                      }
                      final b = _bubbles[i];
                      return _buildBubble(b);
                    },
                  ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          // Input row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.montserrat(
                        fontSize: 13, color: const Color(0xFF2C2C2C)),
                    decoration: InputDecoration(
                      hintText: 'Describe what you\'re looking for...',
                      hintStyle: GoogleFonts.montserrat(
                          fontSize: 13, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF7F7F7),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _loading
                          ? Colors.grey.shade300
                          : const Color(0xFF5C3D2E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatBubble b) {
    return Align(
      alignment: b.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: b.isError
              ? Colors.red.shade50
              : b.isUser
                  ? const Color(0xFF5C3D2E)
                  : const Color(0xFFF7EDE0),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(b.isUser ? 14 : 4),
            bottomRight: Radius.circular(b.isUser ? 4 : 14),
          ),
        ),
        child: Text(
          b.text,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: b.isError
                ? Colors.red
                : b.isUser
                    ? Colors.white
                    : const Color(0xFF2C2C2C),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7EDE0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return _Dot(delay: Duration(milliseconds: i * 150));
          }),
        ),
      ),
    );
  }
}

class _ChatBubble {
  final String text;
  final bool isUser;
  final bool isError;
  const _ChatBubble(
      {required this.text, required this.isUser, this.isError = false});
}

// Animated typing dot
class _Dot extends StatefulWidget {
  final Duration delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: const BoxDecoration(
          color: Color(0xFF5C3D2E),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
