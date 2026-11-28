import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aplikasi_tokped/core/app_colors.dart';
import 'package:aplikasi_tokped/features/coin/data/coin_controller.dart';
import 'package:aplikasi_tokped/features/coin/presentation/widgets/coin_icon.dart';

class ClaimCoinPage extends StatefulWidget {
  const ClaimCoinPage({super.key});

  @override
  State<ClaimCoinPage> createState() => _ClaimCoinPageState();
}

class _ClaimCoinPageState extends State<ClaimCoinPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // refresh tiap detik biar bisa hitung mundur
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _claim() async {
    final reward = await CoinController.instance.checkIn();
    if (!mounted || reward == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Check-in berhasil! +$reward koin'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CoinController.instance,
      builder: (context, _) {
        final coin = CoinController.instance;
        final day = coin.currentDay;
        final canClaim = coin.canCheckIn;

        String label;
        if (!coin.isLoggedIn) {
          label = 'Login dulu untuk klaim';
        } else if (canClaim) {
          label = 'Klaim koin sekarang';
        } else {
          label = 'Klaim koinmu lagi pada ${_fmt(coin.remaining)}';
        }

        return Scaffold(
          backgroundColor: AppColors.paleMint,
          appBar: AppBar(
            backgroundColor: AppColors.deepGreen,
            foregroundColor: Colors.white,
            title: const Text(
              'Klaim Koin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHero(coin, day, canClaim, label),
                const SizedBox(height: 16),
                _buildProgress(day),
                const SizedBox(height: 14),
                Text(
                  'Koin bisa dipakai untuk mengurangi harga barang di keranjang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // kartu besar: saldo, hadiah hari ini, tombol klaim
  Widget _buildHero(CoinController coin, int day, bool canClaim, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepGreen, AppColors.primaryGreen],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('Koin kamu', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CoinIcon(size: 36),
              const SizedBox(width: 10),
              Text(
                '${coin.balance}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Hari ke-${day + 1}',
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const CoinIcon(size: 84),
                const SizedBox(height: 8),
                Text(
                  '+${CoinController.rewards[day]} koin',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkPine,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: canClaim ? _claim : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.deepGreen,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7 lingkaran kecil penanda progres
  Widget _buildProgress(int day) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progres check-in',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                '$day/7 hari',
                style: const TextStyle(color: AppColors.mutedText),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < CoinController.rewards.length; i++)
                Expanded(child: _buildStep(i, day)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int i, int day) {
    final claimed = i < day;
    final isToday = i == day;
    final isLast = i == CoinController.rewards.length - 1;

    Widget circle;
    if (claimed) {
      circle = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.deepGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 18),
      );
    } else if (isLast) {
      // section buat hari ke 7
      circle = const CoinIcon(size: 40);
    } else {
      circle = Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isToday ? AppColors.paleMint : Colors.grey.shade200,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: AppColors.primaryGreen, width: 2)
              : null,
        ),
        child: Text(
          '${i + 1}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isToday ? AppColors.deepGreen : Colors.grey.shade600,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(height: 40, child: Center(child: circle)),
        const SizedBox(height: 6),
        Text(
          '+${CoinController.rewards[i]}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: (isToday || isLast) ? FontWeight.bold : FontWeight.normal,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }
}