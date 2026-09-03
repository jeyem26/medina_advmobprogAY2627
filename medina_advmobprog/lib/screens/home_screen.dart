import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'product_screen.dart';
import 'cart_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: _selectedIndex == 1 ? const Color(0xFF6356C7) : null,
          foregroundColor: _selectedIndex == 1 ? Colors.white : null,
          elevation: _selectedIndex == 1 ? 0 : null,
          title: _selectedIndex == 0
              ? Image.asset(
                  'assets/images/nubdexchange_logo.png',
                  scale: 11.5.sp,
                )
              : CustomText(
                  text: _selectedIndex == 1 ? 'Cart' : 'Profile',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
          children: const [ProductScreen(), CartScreen(), ProfileScreen()],
        ),
        // Enhancement 2: Hide the chat FloatingActionButton while on cart_screen.
        floatingActionButton: _selectedIndex == 1
            ? null
            : FloatingActionButton(
                tooltip: 'Open chat',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                ),
                child: const Icon(Icons.chat),
              ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFFCFBFF),
          selectedItemColor: const Color(0xFF6356C7),
          unselectedItemColor: const Color(0xFF8C8998),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
        ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });

    _pageController.jumpToPage(value);
  }
}
