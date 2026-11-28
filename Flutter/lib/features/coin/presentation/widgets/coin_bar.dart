import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aplikasi_tokped/features/coin/data/coin_controller.dart';
import 'package:aplikasi_tokped/features/coin/presentation/pages/claim_coin_page.dart';
import 'package:aplikasi_tokped/features/coin/presentation/widgets/coin_icon.dart';
import 'package:aplikasi_tokped/features/profile/presentation/pages/register_page.dart';

// Baris koin di home, tepat di bawah navbar (search bar + keranjang)
class CoinBar extends StatefulWidget {
  const CoinBar({super.key});

  @override
  State<CoinBar> createState() => _CoinBarState();
}

class _CoinBarState extends State<CoinBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Cek tiap detik biar badge merah muncul lagi pas cooldownnya habis
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _open() {
    final coin = CoinController.instance;

    // kalau belum login, direct daftar/login dulu
    if (!coin.isLoggedIn) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login dulu untuk klaim koin'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RegisterPage(onRegisterSuccess: () => Navigator.pop(context)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClaimCoinPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CoinController.instance,
      builder: (context, _) {
        final coin = CoinController.instance;
        // badge merah muncul jika belum check in atau belum login
        final showBadge = !coin.isLoggedIn || coin.canCheckIn;

        return Material(
          color: Colors.white,
          child: InkWell(
            onTap: _open,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const CoinIcon(size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Klaim Koin',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (showBadge) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${coin.balance} koin',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
