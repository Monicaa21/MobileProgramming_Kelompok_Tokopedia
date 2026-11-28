import 'package:flutter/material.dart';
import 'package:aplikasi_tokped/models/shopping_item.dart';
import 'package:aplikasi_tokped/utils.dart';
import 'package:aplikasi_tokped/features/product/presentation/pages/product_detail_page.dart';
import 'package:aplikasi_tokped/features/cart/data/cart_controller.dart';
import 'package:aplikasi_tokped/features/cart/presentation/pages/cart_page.dart';
import 'package:aplikasi_tokped/features/coin/presentation/widgets/coin_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // data produk dari items-seed.js
  late Future<List<ShoppingItem>> _itemsFuture = fetchShoppingItem();

  @override
  void dispose() {
    // kalo udh dihalaman yang bukan homepage, searchControllernya dibersihin
    _searchController.dispose();
    super.dispose();
  }

  // cari produk berdasarkan title produk
  List<ShoppingItem> _filter(List<ShoppingItem> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) => item.title.toLowerCase().contains(q)).toList();
  }

  // harga setelah diskon
  int _discounted(ShoppingItem item) =>
      (item.price * (1 - item.discountPercentage / 100)).round();

  MockProductItem _toDetail(ShoppingItem item) {
    return MockProductItem(
      title: item.title,
      description: item.description,
      price: item.price,
      discountPercentage: item.discountPercentage,
      rating: item.rating,
      stock: item.stock,
      brand: item.brand,
      category: item.category,
      sku: item.sku,
      thumbnail: item.thumbnail,
      images: item.images.isNotEmpty ? item.images : [item.thumbnail],
    );
  }

  // Menambahkan barang ke keranjang
  void _addToCart(ShoppingItem item) {
    final success = CartController.instance.add(item);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Produk berhasil ditambahkan ke keranjang'
              : 'Jumlah di keranjang sudah mencapai stok',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _reload() {
    setState(() {
      _itemsFuture = fetchShoppingItem();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: const Color(0xFF165F42),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: _buildSearchBar(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            // Badge keupdate tiap isi keranjang berubah
            child: ListenableBuilder(
              listenable: CartController.instance,
              builder: (context, _) {
                final count = CartController.instance.totalQuantity;
                return IconButton(
                  tooltip: 'Keranjang',
                  icon: Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartPage()),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // tampilin produk di halamannya
      // periksa apakah produk masih ada
      body: Column(
        children: [
          // baris koin (klaim koin) di bawah navbar
          const CoinBar(),
          Expanded(
            child: FutureBuilder<List<ShoppingItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          // loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // menampilkan error
          if (snapshot.hasError) {
            debugPrint('ERROR FETCH: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Gagal memuat produk'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            );
          }

          final products = _filter(snapshot.data ?? []);

          if (products.isEmpty) {
            return const Center(
              child: Text('Produk yang dicari tidak ditemukan'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _itemsFuture;
            },
            // Menampilkan produk dengan view grid
            child: GridView.builder(
              padding: const EdgeInsets.all(5),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.60,
              ),
              itemBuilder: (context, i) => _buildProductCard(products[i]),
            ),
          );
        },
      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ShoppingItem p) {
    final hasDiscount = p.discountPercentage > 0;

    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailPage(product: _toDetail(p), shoppingItem: p),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // gambar
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                p.thumbnail,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // nama produk
                    Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 17),
                    ),
                    const SizedBox(height: 2),
                    // brand
                    Text(
                      p.brand,
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Rp ${p.price}.000',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: p.stock > 0 ? () => _addToCart(p) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
