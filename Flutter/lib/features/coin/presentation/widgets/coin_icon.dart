import 'package:flutter/material.dart';

class CoinIcon extends StatelessWidget {
  final double size;
  const CoinIcon({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/coin.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}