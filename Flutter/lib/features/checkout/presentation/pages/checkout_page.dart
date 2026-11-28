import 'package:flutter/material.dart';
import 'package:aplikasi_tokped/core/app_colors.dart';
import 'package:aplikasi_tokped/features/coin/data/coin_controller.dart';
import 'package:aplikasi_tokped/features/coin/presentation/widgets/coin_icon.dart';
import 'package:aplikasi_tokped/features/checkout/data/order_storage.dart';
import 'package:aplikasi_tokped/features/checkout/presentation/widgets/product_card.dart';
import 'package:aplikasi_tokped/features/profile/data/secure_storage.dart';
import 'package:aplikasi_tokped/features/profile/presentation/pages/register_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<CheckoutItem>? products;
  final List<CheckoutItem>? items;

  final String? title;
  final int? price;
  final String? brand;
  final String? thumbnail;

  const CheckoutPage({
    super.key,
    this.products,
    this.items,
    this.title,
    this.price,
    this.brand,
    this.thumbnail,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<CheckoutItem> items = [];

  int ongkir = 10000;
  String kurir = 'Reguler';

  bool isLoading = true;
  String username = '';
  String alamat = '';

  @override
  void initState() {
    super.initState();
    if (widget.products != null && widget.products!.isNotEmpty) {
      items = widget.products!;
    } else if (widget.items != null && widget.items!.isNotEmpty) {
      items = widget.items!;
    } else if (widget.title != null) {
      items.add(
        CheckoutItem(
          title: widget.title!,
          price: widget.price ?? 0,
          brand: widget.brand ?? '',
          thumbnail: widget.thumbnail ?? '',
        ),
      );
    }
    loadUser();
    CoinController.instance.addListener(_onCoinChanged);
  }

  @override
  void dispose() {
    CoinController.instance.removeListener(_onCoinChanged);
    super.dispose();
  }

  void _onCoinChanged() {
    if (mounted) setState(() {});
  }

  void loadUser() async {
    var data = await ProfileStorage.getProfile();
    var name = (data['username'] ?? '').trim();

    if (!mounted) return;

    // kalau belum login suruh daftar dulu
    if (name == '') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RegisterPage()),
      );
      return;
    }

    setState(() {
      username = name;
      alamat = (data['location'] ?? '').trim();
      isLoading = false;
    });
  }

  int getTotal() {
    int hasil = 0;
    for (var item in items) {
      hasil += item.price * item.quantity;
    }
    return hasil;
  }

  Duration getDurasiKurir(String namaKurir) {
    if (namaKurir == 'Instant') {
      return Duration(seconds: 30);
    } else if (namaKurir == 'Fast') {
      return Duration(minutes: 1);
    } else {
      return Duration(minutes: 2);
    }
  }

  void bayarSekarang(int totalBayar, int totalQty) async {
    var sekarang = DateTime.now();
    var durasi = getDurasiKurir(kurir);

    List<OrderItem> listBarang = [];
    for (var barang in items) {
      listBarang.add(
        OrderItem(
          title: barang.title,
          price: barang.price,
          brand: barang.brand,
          thumbnail: barang.thumbnail,
          quantity: barang.quantity,
        ),
      );
    }

    var order = OrderData(
      id: sekarang.millisecondsSinceEpoch.toString(),
      items: listBarang,
      kurir: kurir,
      ongkir: ongkir,
      totalBayar: totalBayar,
      alamat: alamat,
      createdAt: sekarang,
      arriveAt: sekarang.add(durasi),
    );

    await OrderStorage.saveOrder(order);

    // Mengurangi saldo koin yang kepakai buat potongan harga
    final coin = CoinController.instance;
    final potongan = coin.discountFor(getTotal());
    await coin.spend(coin.coinsForDiscount(potongan));
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pembayaran Berhasil'),
        content: Text('Pesanan untuk $totalQty barang berhasil dibuat!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.paleMint,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.deepGreen),
        ),
      );
    }

    int subtotal = getTotal();
    final coin = CoinController.instance;
    int coinDiscount = coin.discountFor(subtotal);
    int totalBayar = subtotal - coinDiscount + ongkir;
    int totalQty = 0;
    for (var x in items) {
      totalQty += x.quantity;
    }

    return Scaffold(
      backgroundColor: AppColors.paleMint,
      appBar: AppBar(
        title: Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 19,
                              color: AppColors.deepGreen,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Alamat Pengiriman',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkPine,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          username != '' ? username : 'Nama Penerima',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 3),
                        Text(
                          alamat != '' ? alamat : 'Belum ada alamat pengiriman',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),

                  for (var barang in items)
                    ProductCard(
                      item: barang,
                      onAdd: () {
                        setState(() {
                          barang.quantity++;
                        });
                      },
                      onRemove: () {
                        if (barang.quantity > 1) {
                          setState(() {
                            barang.quantity--;
                          });
                        }
                      },
                    ),

                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilihan Pengiriman',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 8),
                        opsiKurir('Reguler', 'Estimasi 2 menit', 10000),
                        opsiKurir('Fast', 'Estimasi 1 menit', 20000),
                        opsiKurir('Instant', 'Estimasi 30 detik', 30000),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),

                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan Pembayaran',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Harga ($totalQty barang)'),
                            Text('Rp ${formatRp(subtotal)}'),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Ongkos Kirim ($kurir)'),
                              Text('Rp ${formatRp(ongkir)}'),
                            ],
                          ),
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            CoinIcon(size: 22),
                            SizedBox(width: 8),
                            Expanded(child: Text('Pakai koin (${coin.balance})')),
                            Switch(
                              value: coin.useCoins,
                              activeColor: AppColors.deepGreen,
                              onChanged: coin.isLoggedIn && coin.balance > 0
                                  ? (v) => coin.setUseCoins(v)
                                  : null,
                            ),
                          ],
                        ),
                        if (coinDiscount > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Potongan Koin'),
                              Text(
                                '- Rp ${formatRp(coinDiscount)}',
                                style: TextStyle(color: AppColors.deepGreen),
                              ),
                            ],
                          ),
                        Divider(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Tagihan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Rp ${formatRp(totalBayar)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.deepGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Tagihan',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      'Rp ${formatRp(totalBayar)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepGreen,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    bayarSekarang(totalBayar, totalQty);
                  },
                  child: Text('Bayar Sekarang'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget opsiKurir(String nama, String estimasi, int harga) {
    bool dipilih = kurir == nama;
    return InkWell(
      onTap: () {
        setState(() {
          kurir = nama;
          ongkir = harga;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: dipilih ? AppColors.deepGreen : Colors.grey.shade300,
          ),
          color: dipilih ? AppColors.paleMint : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$nama (Rp ${formatRp(harga)})',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  estimasi,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (dipilih)
              Icon(Icons.check_circle, color: AppColors.deepGreen, size: 20),
          ],
        ),
      ),
    );
  }
}