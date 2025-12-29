import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GuestService {
  static const String _cartKey = 'guest_cart';
  static const String _wishlistKey = 'guest_wishlist';

  // --- CART METHODS ---

  // Get Cart Items
  static Future<List<Map<String, dynamic>>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    String? cartString = prefs.getString(_cartKey);
    if (cartString != null && cartString.isNotEmpty) {
      List<dynamic> jsonList = jsonDecode(cartString);
      return jsonList.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  // Add Item to Cart
  static Future<void> addToCart(Map<String, dynamic> product) async {
    List<Map<String, dynamic>> cart = await getCart();
    String prodId = product['id'] ?? product['name'];

    int index = cart.indexWhere(
      (item) => (item['id'] ?? item['name']) == prodId,
    );

    if (index != -1) {
      // Update Quantity
      int currentQty = cart[index]['quantity'] ?? 1;
      cart[index]['quantity'] = currentQty + 1;
    } else {
      // Add New Item
      var newItem = Map<String, dynamic>.from(product);
      newItem['quantity'] = 1;
      newItem['added_at'] = DateTime.now().toString();
      cart.add(newItem);
    }
    await _saveCart(cart);
  }

  // Remove Item from Cart
  static Future<void> removeFromCart(String prodId) async {
    List<Map<String, dynamic>> cart = await getCart();
    cart.removeWhere((item) => (item['id'] ?? item['name']) == prodId);
    await _saveCart(cart);
  }

  // Update Cart Item Quantity
  static Future<void> updateCartQty(String prodId, int newQty) async {
    List<Map<String, dynamic>> cart = await getCart();
    int index = cart.indexWhere(
      (item) => (item['id'] ?? item['name']) == prodId,
    );
    if (index != -1) {
      if (newQty <= 0) {
        cart.removeAt(index);
      } else {
        cart[index]['quantity'] = newQty;
      }
      await _saveCart(cart);
    }
  }

  // Clear Cart
  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  static Future<void> _saveCart(List<Map<String, dynamic>> cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(cart));
  }

  // --- WISHLIST METHODS ---

  // Get Wishlist Items
  static Future<List<Map<String, dynamic>>> getWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    String? wishString = prefs.getString(_wishlistKey);
    if (wishString != null && wishString.isNotEmpty) {
      List<dynamic> jsonList = jsonDecode(wishString);
      return jsonList.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  // Toggle Wishlist Item
  static Future<bool> toggleWishlist(Map<String, dynamic> product) async {
    List<Map<String, dynamic>> wishlist = await getWishlist();
    String prodId = product['id'] ?? product['name'];

    int index = wishlist.indexWhere(
      (item) => (item['id'] ?? item['name']) == prodId,
    );
    bool isAdded = false;

    if (index != -1) {
      // Remove
      wishlist.removeAt(index);
      isAdded = false;
    } else {
      // Add
      wishlist.add(product);
      isAdded = true;
    }
    await _saveWishlist(wishlist);
    return isAdded;
  }

  // Check if Wishlisted
  static Future<bool> isWishlisted(String prodId) async {
    List<Map<String, dynamic>> wishlist = await getWishlist();
    return wishlist.any((item) => (item['id'] ?? item['name']) == prodId);
  }

  static Future<void> _saveWishlist(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wishlistKey, jsonEncode(list));
  }
}
