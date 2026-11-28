import 'package:flutter/material.dart';
import 'package:aplikasi_tokped/features/navigation/presentation/pages/navigation_menu.dart';
import 'package:aplikasi_tokped/features/coin/data/coin_controller.dart';
import 'package:aplikasi_tokped/features/cart/data/cart_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CoinController.instance.init();
  await CartController.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Toko E-Commerce',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF30CF8F),
        ),
        scaffoldBackgroundColor: const Color(0xFFEAFAF4),
      ),
      home: const NavigationMenu(),
    );
  }
}
