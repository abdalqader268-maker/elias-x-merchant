import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/api.dart';
import '../../core/theme.dart';
import 'add_product_screen.dart';

final productsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await api.get('/merchant/products');
  return List<Map<String, dynamic>>.from(res.data as List);
});

const _statusLabel = {'pending': 'بانتظار الموافقة', 'active': 'نشط', 'rejected': 'مرفوض'};
const _statusColor = {
  'pending': Color(0xFFF59E0B),
  'active':  Color(0xFF22C55E),
  'rejected': Color(0xFFEF4444),
};

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('منتجاتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(productsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
          if (added == true) ref.invalidate(productsProvider);
        },
        backgroundColor: kPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة منتج', style: TextStyle(color: Colors.white)),
      ),
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary)),
        error: (e, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('⚠️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text('$e', style: const TextStyle(color: kMuted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => ref.invalidate(productsProvider), child: const Text('إعادة المحاولة')),
          ]),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('📦', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 12),
              const Text('لا توجد منتجات بعد', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('اضغط + لإضافة منتجك الأول', style: TextStyle(color: kMuted)),
            ]));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _ProductCard(
              product: list[i],
              onToggle: (available) async {
                await api.patch('/merchant/products/${list[i]['id']}', data: {'isAvailable': available});
                ref.invalidate(productsProvider);
              },
              onDelete: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: kCard,
                    title: const Text('حذف المنتج؟', style: TextStyle(color: Colors.white)),
                    content: const Text('لن يمكن استرجاعه', style: TextStyle(color: kMuted)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء', style: TextStyle(color: kMuted))),
                      TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('حذف', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (ok == true) {
                  await api.delete('/merchant/products/${list[i]['id']}');
                  ref.invalidate(productsProvider);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  const _ProductCard({required this.product, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final status    = product['status'] as String? ?? 'pending';
    final available = product['isAvailable'] as bool? ?? true;
    final color     = _statusColor[status] ?? kMuted;

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16), bottomRight: Radius.circular(16),
          ),
          child: product['imageUrl'] != null
              ? CachedNetworkImage(
                  imageUrl: product['imageUrl'] as String,
                  width: 90, height: 90, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _noImage(),
                )
              : _noImage(),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              product['nameAr'] ?? product['name'] ?? '',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text('₪${((product['price'] ?? 0) as num).toStringAsFixed(2)}',
                style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel[status] ?? status,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ]),
          ]),
        )),
        // Actions
        Column(children: [
          Switch(value: available, onChanged: status == 'active' ? onToggle : null,
              activeColor: kPrimary),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: onDelete),
        ]),
        const SizedBox(width: 4),
      ]),
    );
  }

  Widget _noImage() => Container(
    width: 90, height: 90, color: kNav,
    child: const Center(child: Text('📦', style: TextStyle(fontSize: 30))),
  );
}
