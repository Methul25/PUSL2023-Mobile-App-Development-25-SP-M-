import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/product.dart';

// ---------------------------------------------------------------------------

const _apiKey = 'AIzaSyCZhh411fhu2DmG2CBv8xd-z6jljTcNPB8';

const _model = 'gemini-3-flash-preview';
const _endpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

class GeminiMessage {
  final String role; // 'user' or 'model'
  final String text;
  const GeminiMessage({required this.role, required this.text});
}

class GeminiService {
  GeminiService._();
  static final instance = GeminiService._();

  /// Send a user message along with the current product catalog.
  /// Optionally include product images keyed by product id for vision understanding.
  /// Returns the model's text reply.
  Future<String> send({
    required String userMessage,
    required List<Product> products,
    required List<GeminiMessage> history,
    Map<String, Uint8List>? productImages,
  }) async {
    if (_apiKey.isEmpty) {
      return '⚠️ Please add your Gemini API key in lib/services/gemini_service.dart';
    }

    // Build catalog parts — interleave text + image for each product
    final introText =
        'You are a helpful furniture store assistant for FURN store. '
        'You help customers find the right products based on their needs. '
        'Below is the product catalog. Each product entry may be followed by an image so you can recognize it visually (color, style, shape, etc.).\n\n'
        'IMPORTANT: When the user asks to add a product to their cart, you MUST include '
        'the following tag on a new line at the very end of your response, using the exact product name from the catalog: '
        '[ACTION:ADD_TO_CART:<exact_product_name>]\n'
        'Example: [ACTION:ADD_TO_CART:White Sofa]\n'
        'Only include this tag when the user explicitly asks to add something to their cart. '
        'Do not include the tag for recommendations or other requests.\n\n'
        'IMPORTANT: When the user asks to filter, show, or hide products based on any criteria '
        '(stock availability, price range, category, etc.), you MUST include the following tag '
        'on a new line at the very end of your response: '
        '[ACTION:FILTER:<CRITERIA>]\n'
        'Supported filter criteria:\n'
        '  IN_STOCK — show only products with stock > 0\n'
        '  OUT_OF_STOCK — show only products with stock = 0\n'
        '  PRICE_UNDER:<amount> — products priced below the given amount (e.g. PRICE_UNDER:200)\n'
        '  PRICE_OVER:<amount> — products priced above the given amount (e.g. PRICE_OVER:500)\n'
        '  CATEGORY:<name> — products in the given category (e.g. CATEGORY:Sofas)\n'
        '  CLEAR — remove all active filters and show all products\n'
        'Examples: [ACTION:FILTER:IN_STOCK]  [ACTION:FILTER:PRICE_UNDER:300]  [ACTION:FILTER:CLEAR]\n'
        'Only include this tag when the user explicitly asks to filter or show/hide products. '
        'Do not include it for general questions or recommendations.\n\n'
        'Product catalog:';

    const colorNames = [
      'Charcoal/Black',
      'Brown',
      'Tan/Camel',
      'Cream/Light Beige',
      'Forest Green',
      'Gray',
    ];

    final List<Map<String, dynamic>> systemParts = [{'text': introText}];
    for (final p in products) {
      final colorLabel = (p.colorIndex != null && p.colorIndex! < colorNames.length)
          ? colorNames[p.colorIndex!]
          : null;
      systemParts.add({
        'text': '\nProduct: ${p.name} | Category: ${p.category} | '
            'Price: \$${p.price.toStringAsFixed(0)} | Stock: ${p.stock}'
            '${colorLabel != null ? ' | Color: $colorLabel' : ''} | '
            'Description: ${p.description}'
      });
      if (productImages != null && p.id != null && productImages.containsKey(p.id)) {
        systemParts.add({
          'inlineData': {
            'mimeType': 'image/jpeg',
            'data': base64Encode(productImages[p.id]!),
          }
        });
      }
    }

    // Build conversation turns including the system message as first user/model pair
    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': systemParts,
      },
      {
        'role': 'model',
        'parts': [
          {'text': 'Got it! I\'m ready to help customers find furniture from our catalog.'}
        ]
      },
      // Conversation history
      ...history.map((m) => {
            'role': m.role,
            'parts': [
              {'text': m.text}
            ]
          }),
      // Current user message
      {
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ]
      },
    ];

    final body = jsonEncode({
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 512,
      },
    });

    final uri = Uri.parse('$_endpoint?key=$_apiKey');

    // Retry up to 3 times on 503 (overloaded) with exponential backoff
    late http.Response response;
    for (var attempt = 0; attempt < 3; attempt++) {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode != 503 || attempt == 2) break;
      await Future.delayed(Duration(seconds: (attempt + 1) * 2));
    }

    if (response.statusCode != 200) {
      throw Exception('Gemini error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final text = json['candidates']?[0]?['content']?['parts']?[0]?['text']
        as String? ??
        'Sorry, I could not generate a response.';
    return text;
  }
}
