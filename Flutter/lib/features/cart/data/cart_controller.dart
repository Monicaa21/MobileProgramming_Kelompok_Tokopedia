import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:aplikasi_tokped/models/shopping_item.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Mengatur format price menjadi ada . tiap 3 digit
String formatRupiah(int valueInThousands) {
  final digits = (valueInThousands * 1000).toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return 'Rp $buffer';
}

// Class di keranjang
class CartEntry {
  final ShoppingItem item;
  int quantity;
  bool isSelected;

  CartEntry({required this.item, this.quantity = 1, this.isSelected = false});

  // Harga satuan setelah diskon
  int get unitPrice =>
      (item.price * (1 - item.discountPercentage / 100)).round();

  int get subtotal => unitPrice * quantity;
}

// Penyimpan isi keranjang yang dipakai bersama oleh semua halaman
class CartController extends ChangeNotifier {
  CartController._();
  static final CartController instance = CartController._();

  static const _storage = FlutterSecureStorage();
  static const _kCart = 'cart_data';

  final List<CartEntry> _entries = [];

  // Dipanggil sekali di main bakal ada keranjang yang kesimpen
  Future<void> init() async {
    try {
      final text = await _storage.read(key: _kCart);
      if (text == null || text.trim().isEmpty) return;

      final decoded = jsonDecode(text) as List;
      _entries.clear();
      for (final raw in decoded) {
        final map = Map<String, dynamic>.from(raw as Map);
        final item = ShoppingItem.fromJson(
          Map<String, dynamic>.from(map['item'] as Map),
        );
        if (item.stock < 1) continue;
        // jumlah dijaga ga lebih dari stok
        final qty = ((map['quantity'] as num?)?.toInt() ?? 1).clamp(
          1,
          item.stock,
        );
        _entries.add(
          CartEntry(
            item: item,
            quantity: qty,
            isSelected: map['selected'] == true,
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      // kalo data rusak mulai dari keranjang kosong
      debugPrint('Gagal memuat keranjang: $e');
      _entries.clear();
    }
  }

  Future<void> _save() async {
    final data = _entries
        .map(
          (e) => {
            'item': e.item.toJson(),
            'quantity': e.quantity,
            'selected': e.isSelected,
          },
        )
        .toList();
    await _storage.write(key: _kCart, value: jsonEncode(data));
  }

  // notify + simpan tiap isi keranjang berubah
  void _changed() {
    notifyListeners();
    unawaited(_save());
  }

  List<CartEntry> get entries => List.unmodifiable(_entries);
  bool get isEmpty => _entries.isEmpty;

  // Total jumlah barang (badge di icon keranjang)
  int get totalQuantity => _entries.fold(0, (sum, e) => sum + e.quantity);

  // Barang yang checkboxnya dicentang
  List<CartEntry> get selectedEntries =>
      _entries.where((e) => e.isSelected).toList();
  int get selectedCount => selectedEntries.length;

  // Jumlah harga semua barang yang dicentang
  int get selectedTotal =>
      selectedEntries.fold(0, (sum, e) => sum + e.subtotal);

  bool get allSelected =>
      _entries.isNotEmpty && _entries.every((e) => e.isSelected);

  // Return false kalau gagal
  bool add(ShoppingItem item) {
    final index = _entries.indexWhere((e) => e.item.id == item.id);

    if (index == -1) {
      if (item.stock < 1) return false;
      _entries.add(CartEntry(item: item));
    } else {
      final entry = _entries[index];
      if (entry.quantity >= item.stock) return false;
      entry.quantity++;
    }

    _changed();
    return true;
  }

  void toggleSelected(CartEntry entry, bool value) {
    entry.isSelected = value;
    _changed();
  }

  void toggleAll(bool value) {
    for (final e in _entries) {
      e.isSelected = value;
    }
    _changed();
  }

  void increase(CartEntry entry) {
    if (entry.quantity >= entry.item.stock) return;
    entry.quantity++;
    _changed();
  }

  // Kalau jumlah barang yang dikeranjang tinggal 1 dan didelete, barangnya dihapus dari keranjang
  void decrease(CartEntry entry) {
    if (entry.quantity > 1) {
      entry.quantity--;
    } else {
      _entries.remove(entry);
    }
    _changed();
  }
}