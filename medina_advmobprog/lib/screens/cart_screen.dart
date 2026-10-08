import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../models/cart_service.dart';
import 'detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<Cart>> _cartsFuture;

  final CartService _cartService = CartService();

  final Map<int, int> _quantities = {};

  // DummyJSON uses an integer user ID.
  // Firebase uses a String UID, so they cannot be passed directly
  // to the DummyJSON cart endpoint.
  static const int _dummyJsonUserId = 1;

  @override
  void initState() {
    super.initState();

    _cartsFuture = _loadCartForSignedInUser();
  }

  Future<List<Cart>> _loadCartForSignedInUser() async {
    // Check Firebase authentication instead of SharedPreferences.
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception('No signed-in user was found');
    }

    debugPrint('Firebase user: ${firebaseUser.email}');
    debugPrint('Firebase UID: ${firebaseUser.uid}');
    debugPrint('DummyJSON cart userId: $_dummyJsonUserId');

    return _cartService.getCartsByUserId(_dummyJsonUserId);
  }

  Future<void> _refreshCart() async {
    setState(() {
      _cartsFuture = _loadCartForSignedInUser();
    });

    await _cartsFuture;
  }

  void _changeQuantity(CartProduct product, int change) {
    final current =
        _quantities[product.id] ?? product.quantity;

    final next = (current + change).clamp(1, 999);

    setState(() {
      _quantities[product.id] = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F3FC),
      child: SafeArea(
        top: false,
        child: FutureBuilder<List<Cart>>(
          future: _cartsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              final errorMessage = snapshot.error
                      .toString()
                      .contains('No signed-in user')
                  ? 'Please sign in to view your cart.'
                  : 'Unable to load your cart.';

              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(errorMessage),
                      SizedBox(height: 12.h),
                      FilledButton(
                        onPressed: _refreshCart,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final carts = snapshot.data ?? [];

            final products = carts
                .expand((cart) => cart.products)
                .toList();

            debugPrint(
              'CartScreen carts received: ${carts.length}',
            );

            debugPrint(
              'CartScreen products received: ${products.length}',
            );

            if (products.isEmpty) {
              return const Center(
                child: Text('Your cart is empty.'),
              );
            }

            final cart = carts.first;

            final subtotal = products.fold<double>(
              0,
              (sum, product) =>
                  sum +
                  product.price *
                      (_quantities[product.id] ??
                          product.quantity),
            );

            final discountedTotal = products.fold<double>(
              0,
              (sum, product) =>
                  sum +
                  (product.quantity == 0
                          ? 0
                          : product.discountedTotal /
                              product.quantity) *
                      (_quantities[product.id] ??
                          product.quantity),
            );

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16.w,
                18.h,
                16.w,
                18.h,
              ),
              itemCount: products.length + 1,
              separatorBuilder: (_, index) =>
                  SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                if (index == products.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Column(
                      children: [
                        _TotalRow(
                          label: 'Subtotal',
                          value: cart.total == 0
                              ? subtotal
                              : cart.total,
                        ),
                        _TotalRow(
                          label: 'Discounted total',
                          value: cart.discountedTotal == 0
                              ? discountedTotal
                              : cart.discountedTotal,
                        ),
                        SizedBox(height: 8.h),
                        SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: FilledButton(
                            onPressed: () {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Order confirmed'),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFFFB52D),
                              foregroundColor:
                                  const Color(0xFF2F2D35),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(11.r),
                              ),
                            ),
                            child:
                                const Text('Confirm Order'),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final product = products[index];

                final quantity =
                    _quantities[product.id] ??
                        product.quantity;

                return Card(
                  margin: EdgeInsets.zero,
                  color: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14.r),
                  ),
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(14.r),
                    onTap: () async {
                      final added =
                          await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DetailScreen(
                            productId: product.id,
                          ),
                        ),
                      );

                      if (added == true && mounted) {
                        await _refreshCart();
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        12.w,
                        16.h,
                        10.w,
                        16.h,
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          Image.network(
                            product.thumbnail,
                            width: 82.w,
                            height: 96.h,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) {
                              return Container(
                                width: 82.w,
                                height: 96.h,
                                color:
                                    const Color(0xFFF0EFF6),
                                child: const Icon(
                                  Icons.image_outlined,
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        const Color(
                                      0xFF29283A,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight:
                                        FontWeight.w600,
                                    color:
                                        const Color(
                                      0xFF383749,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  '${product.discountPercentage.toStringAsFixed(0)}% off '
                                  '• \$${product.total.toStringAsFixed(2)} total',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color:
                                        const Color(
                                      0xFF777584,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Column(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              _QuantityButton(
                                icon: Icons.add,
                                backgroundColor:
                                    const Color(
                                  0xFFFFB52D,
                                ),
                                iconColor: Colors.white,
                                onPressed: () =>
                                    _changeQuantity(
                                  product,
                                  1,
                                ),
                              ),
                              SizedBox(height: 25.h),
                              Center(
                                child: Text(
                                  '$quantity',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        const Color(
                                      0xFF393746,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 25.h),
                              _QuantityButton(
                                icon: Icons.remove,
                                backgroundColor:
                                    const Color(
                                  0xFFF0F0F3,
                                ),
                                iconColor:
                                    const Color(
                                  0xFF64636D,
                                ),
                                onPressed: () =>
                                    _changeQuantity(
                                  product,
                                  -1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36.w,
      height: 36.w,
      child: IconButton(
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(9.r),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 19.sp,
          color: iconColor,
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64626F),
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF302F3A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}