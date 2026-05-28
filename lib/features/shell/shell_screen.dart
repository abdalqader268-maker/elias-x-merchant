import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../home/home_screen.dart';
import '../products/products_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';

final _tabProvider = StateProvider<int>((_) => 0);

class ShellScreen extends ConsumerWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  static const _tabs = [
    HomeScreen(),
    ProductsScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  static const _items = [
    BottomNavigationBarItem(icon: Icon(Icons.home_rounded),       label: 'الرئيسية'),
    BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'منتجاتي'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded),label: 'الطلبات'),
    BottomNavigationBarItem(icon: Icon(Icons.person_rounded),     label: 'حسابي'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_tabProvider);
    return Scaffold(
      body: _tabs[tab],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: kBorder, width: .8)),
        ),
        child: BottomNavigationBar(
          currentIndex: tab,
          onTap: (i) => ref.read(_tabProvider.notifier).state = i,
          backgroundColor: kNav,
          selectedItemColor: kPrimary,
          unselectedItemColor: kMuted,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: _items,
        ),
      ),
    );
  }
}
