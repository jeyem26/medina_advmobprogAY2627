import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<int, StreamController<List<CartProduct>>> _localCartStreams =
      {};

  Stream<List<CartProduct>> watchCurrentCart() async* {
    final preferences = await SharedPreferences.getInstance();
    final authMethod = preferences.getString(authMethodKey);

    if (authMethod == dummyJsonAuthMethod) {
      final userId = preferences.getInt(userIdKey);
      if (userId == null) {
        throw StateError('DummyJSON user session is missing its user ID.');
      }
      yield* watchDummyJsonCart(userId);
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw StateError('No signed-in user was found.');
    }
    yield* watchCart(firebaseUser.uid);
  }

  Stream<List<CartProduct>> watchDummyJsonCart(int userId) {
    final controller = _localCartStreams.putIfAbsent(
      userId,
      () => StreamController<List<CartProduct>>.broadcast(),
    );

    return Stream<List<CartProduct>>.multi((streamController) {
      final subscription = controller.stream.listen(
        streamController.add,
        onError: streamController.addError,
      );
      streamController.onCancel = subscription.cancel;
      unawaited(
        _loadDummyJsonCart(
          userId,
        ).then(streamController.add).catchError(streamController.addError),
      );
    });
  }

  Future<List<CartProduct>> _loadDummyJsonCart(int userId) async {
    final preferences = await SharedPreferences.getInstance();
    final encodedCart = preferences.getString(_dummyCartKey(userId));
    if (encodedCart == null || encodedCart.isEmpty) return [];

    final decoded = jsonDecode(encodedCart) as List<dynamic>;
    return decoded
        .map((item) => CartProduct.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  String _dummyCartKey(int userId) => 'dummyJsonCart_$userId';

  Future<void> _saveDummyJsonCart(
    int userId,
    List<CartProduct> products,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _dummyCartKey(userId),
      jsonEncode(products.map((product) => product.toJson()).toList()),
    );
    _localCartStreams[userId]?.add(products);
  }

  CollectionReference<Map<String, dynamic>> _itemsFor(String uid) =>
      _firestore.collection('carts').doc(uid).collection('items');

  Stream<List<CartProduct>> watchCart(String uid) {
    return _itemsFor(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((document) => CartProduct.fromJson(document.data()))
          .toList();
    });
  }

  Future<void> addProductToCart(Product product) async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getString(authMethodKey) == dummyJsonAuthMethod) {
      final userId = preferences.getInt(userIdKey);
      if (userId == null) {
        throw StateError('DummyJSON user session is missing its user ID.');
      }

      final products = await _loadDummyJsonCart(userId);
      final existingIndex = products.indexWhere(
        (item) => item.id == product.id,
      );
      if (existingIndex >= 0) {
        final existing = products[existingIndex];
        products[existingIndex] = _withQuantity(
          existing,
          existing.quantity + 1,
        );
      } else {
        products.add(
          CartProduct(
            id: product.id,
            title: product.title,
            price: product.price,
            quantity: 1,
            total: product.price,
            discountPercentage: product.discountPercentage,
            discountedTotal:
                product.price * (1 - product.discountPercentage / 100),
            thumbnail: product.thumbnail,
          ),
        );
      }
      await _saveDummyJsonCart(userId, products);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Please sign in before adding items to your cart.');
    }

    final item = _itemsFor(uid).doc(product.id.toString());
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(item);
      final quantity = existing.exists
          ? ((existing.data()?['quantity'] as num?)?.toInt() ?? 0) + 1
          : 1;
      final total = product.price * quantity;
      final discountedTotal = total * (1 - product.discountPercentage / 100);

      transaction.set(item, {
        'id': product.id,
        'title': product.title,
        'price': product.price,
        'quantity': quantity,
        'total': total,
        'discountPercentage': product.discountPercentage,
        'discountedTotal': discountedTotal,
        'thumbnail': product.thumbnail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> setProductQuantity({
    required String uid,
    required CartProduct product,
    required int quantity,
  }) async {
    if (quantity < 1 || quantity > 999) {
      throw RangeError.range(quantity, 1, 999, 'quantity');
    }

    final total = product.price * quantity;
    final discountedTotal = total * (1 - product.discountPercentage / 100);
    await _itemsFor(uid).doc(product.id.toString()).update({
      'quantity': quantity,
      'total': total,
      'discountedTotal': discountedTotal,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setCurrentProductQuantity({
    required CartProduct product,
    required int quantity,
  }) async {
    if (quantity < 1 || quantity > 999) {
      throw RangeError.range(quantity, 1, 999, 'quantity');
    }

    final preferences = await SharedPreferences.getInstance();
    if (preferences.getString(authMethodKey) == dummyJsonAuthMethod) {
      final userId = preferences.getInt(userIdKey);
      if (userId == null) {
        throw StateError('DummyJSON user session is missing its user ID.');
      }
      final products = await _loadDummyJsonCart(userId);
      final index = products.indexWhere((item) => item.id == product.id);
      if (index < 0) return;
      products[index] = _withQuantity(products[index], quantity);
      await _saveDummyJsonCart(userId, products);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user was found.');
    await setProductQuantity(uid: uid, product: product, quantity: quantity);
  }

  CartProduct _withQuantity(CartProduct product, int quantity) {
    final total = product.price * quantity;
    return CartProduct(
      id: product.id,
      title: product.title,
      price: product.price,
      quantity: quantity,
      total: total,
      discountPercentage: product.discountPercentage,
      discountedTotal: total * (1 - product.discountPercentage / 100),
      thumbnail: product.thumbnail,
    );
  }
}
