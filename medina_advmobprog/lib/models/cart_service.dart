import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';

class CartService {
  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  // Enhancement 3: Retrieve cart by user ID and add products using DummyJSON /carts/add
  Future<List<Cart>> getCartsByUserId(int userId) async {
    final url = '$host/carts/user/$userId';
    debugPrint('Cart userId: $userId');
    debugPrint('Cart request URL: $url');

    final response = await http.get(Uri.parse(url));

    debugPrint('Cart response status: ${response.statusCode}');
    debugPrint('Cart response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] as List? ?? [];

      final carts = cartsJson.map((json) => Cart.fromJson(json)).toList();
      debugPrint('Number of carts: ${carts.length}');
      for (final cart in carts) {
        debugPrint(
          'Number of products in cart ${cart.id}: ${cart.products.length}',
        );
      }
      return carts;
    }

    throw Exception('Failed to load cart for user $userId');
  }

  Future<Cart> addToCart({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': productId, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Cart.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to add product to cart');
  }
}
