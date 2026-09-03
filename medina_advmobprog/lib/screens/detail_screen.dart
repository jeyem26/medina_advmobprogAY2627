import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/product.dart';
import '../models/cart_service.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.productId, this.product});

  final int productId;
  final Product? product;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final Future<Product> _productFuture;
  final CartService _cartService = CartService();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _productFuture = widget.product == null
        ? ProductService().getProductById(widget.productId)
        : Future.value(widget.product);
  }

  Future<void> _addToCart(Product product) async {
    setState(() => _isAdding = true);

    try {
      // Enhancement 3: Add selected product to the user's cart using DummyJSON /carts/add.
      await _cartService.addToCart(
        userId: defaultUserId,
        productId: product.id,
        quantity: 1,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product added to cart')));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to add product: $error')));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('Unable to load product: ${snapshot.error}'),
            );
          }

          final product = snapshot.data!;
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  product.thumbnail,
                  width: double.infinity,
                  height: 240.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      SizedBox(height: 240.h, child: const Icon(Icons.image)),
                ),
                SizedBox(height: 16.h),
                CustomText(
                  text: product.title,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 8.h),
                CustomText(
                  text: '\$${product.price.toStringAsFixed(2)}',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 12.h),
                CustomText(text: product.description, fontSize: 14.sp),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isAdding ? null : () => _addToCart(product),
                    icon: _isAdding
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.add_shopping_cart),
                    label: Text(_isAdding ? 'Adding...' : 'Add to Cart'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
