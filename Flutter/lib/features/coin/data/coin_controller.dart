import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aplikasi_tokped/features/profile/data/secure_storage.dart';

// Penyimpan saldo koin dan status check-in
class CoinController extends ChangeNotifier {
  CoinController._();
  static final CoinController instance = CoinController._();

  // Reward check-in dari hari ke 1 sampe ke 7
  static const List<int> rewards = [100, 300, 100, 100, 100, 400, 1200];

  // Kondisi bisa check in lagi
  static const Duration checkInCooldown = Duration(days: 1);

  // Kondisi buat streaknya abis
  static const Duration streakWindow = Duration(days: 2);

  static const int rupiahPerCoin = 1;

  static const _storage = FlutterSecureStorage();
  static const _kBalance = 'coin_balance';
  static const _kClaimed = 'coin_claimed_days';
  static const _kLast = 'coin_last_checkin';

  bool _initialized = false;
  bool _loggedIn = false;
  int _balance = 0;
  int _claimedDays = 0;
  DateTime? _lastCheckIn;
  bool _useCoins = false;

  bool get isLoggedIn => _loggedIn;
  int get balance => _balance;
  bool get useCoins => _useCoins;

  // Hari ke yang bisa diklaim sekarang
  int get currentDay {
    final last = _lastCheckIn;
    if (last != null && DateTime.now().difference(last) > streakWindow) {
      return 0;
    }
    return _claimedDays;
  }

  // Sisa waktu sampe bisa check in lagi
  Duration get remaining {
    final last = _lastCheckIn;
    if (last == null) return Duration.zero;
    final left = checkInCooldown - DateTime.now().difference(last);
    return left.isNegative ? Duration.zero : left;
  }

  bool get canCheckIn => _loggedIn && remaining == Duration.zero;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // login / logout / daftar ulang itu bakal muat ulang data koin
    ProfileStorage.profileVersion.addListener(load);
    await load();
  }

  Future<void> load() async {
    final username = (await ProfileStorage.getUsername())?.trim() ?? '';
    _loggedIn = username.isNotEmpty;

    if (_loggedIn) {
      _balance = int.tryParse(await _storage.read(key: _kBalance) ?? '') ?? 0;
      _claimedDays =
          int.tryParse(await _storage.read(key: _kClaimed) ?? '') ?? 0;
      final last = await _storage.read(key: _kLast);
      _lastCheckIn = last == null ? null : DateTime.tryParse(last);
    } else {
      _balance = 0;
      _claimedDays = 0;
      _lastCheckIn = null;
      _useCoins = false;
    }
    notifyListeners();
  }

  Future<void> _save() async {
    await _storage.write(key: _kBalance, value: '$_balance');
    await _storage.write(key: _kClaimed, value: '$_claimedDays');
    if (_lastCheckIn != null) {
      await _storage.write(key: _kLast, value: _lastCheckIn!.toIso8601String());
    }
  }

  // Return jumlah koin yang didapat, null kalau gagal
  Future<int?> checkIn() async {
    if (!canCheckIn) return null;

    final day = currentDay;
    final reward = rewards[day];

    _balance += reward;
    // habis day 7 balik ke day 1
    _claimedDays = (day + 1) % rewards.length;
    _lastCheckIn = DateTime.now();
    notifyListeners();

    await _save();
    return reward;
  }

  void setUseCoins(bool value) {
    if (_useCoins == value) return;
    _useCoins = value;
    notifyListeners();
  }

  // Potongan dari subtotal barang, ongkir tidak ikut dipotong
  int discountFor(int subtotalRupiah) {
    if (!_useCoins || !_loggedIn || _balance <= 0 || subtotalRupiah <= 0) {
      return 0;
    }
    return min(_balance * rupiahPerCoin, subtotalRupiah);
  }

  // Berapa koin yang kepakai buat potongan segitu
  int coinsForDiscount(int discountRupiah) =>
      (discountRupiah + rupiahPerCoin - 1) ~/ rupiahPerCoin;

  // Kurangi saldo setelah mau pembayaran
  Future<void> spend(int coins) async {
    if (coins <= 0) return;
    _balance = max(0, _balance - coins);
    _useCoins = false;
    notifyListeners();
    await _save();
  }
}
