import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';
import '../../core/theme.dart';

final _ordersProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await api.get('/merchant/orders', queryParameters: {'limit': '30'});
  return res.data as Map<String, dynamic>;
});

const _statusLabel = {
  'pending':    'جديد',
  'accepted':   'مقبول',
  'preparing':  'يُحضَّر',
  'picked_up':  'تم الاستلام',
  'on_the_way': 'في الطريق',
  'delivered':  'تم التوصيل',
  'cancelled':  'ملغي',
  'refunded':   'مُسترجع',
};
const _statusColor = {
  'pending':    Color(0xFFF59E0B),
  'accepted':   Color(0xFF3B82F6),
  'preparing':  Color(0xFF8B5CF6),
  'picked_up':  Color(0xFF06B6D4),
  'on_the_way': Color(0xFFE8622A),
  'delivered':  Color(0xFF22C55E),
  'cancelled':  Color(0xFFEF4444),
  'refunded':   kMuted,
};

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات الواردة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_ordersProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: kMuted))),
        data: (data) {
          final orders = List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
          if (orders.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('📋', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 12),
              const Text('لا توجد طلبات بعد', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('ستظهر هنا طلبات زبائنك', style: TextStyle(color: kMuted)),
            ]));
          }
          return RefreshIndicator(
            color: kPrimary,
            onRefresh: () => ref.refresh(_ordersProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _OrderCard(
                order: orders[i],
                onStatusChange: (newStatus) async {
                  await api.patch('/merchant/orders/${orders[i]['id']}/status', data: {'status': newStatus});
                  ref.invalidate(_ordersProvider);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final ValueChanged<String> onStatusChange;
  const _OrderCard({required this.order, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final color  = _statusColor[status] ?? kMuted;
    final items  = List<Map<String, dynamic>>.from(order['items'] as List? ?? []);

    return Container(
      decoration: BoxDecoration(
        color: kCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('#${order['orderNumber'] ?? ''}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(order['customerName'] ?? '—',
                  style: const TextStyle(color: kMuted, fontSize: 13)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(.15), borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel[status] ?? status,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text('₪${((order['total'] ?? 0) as num).toStringAsFixed(2)}',
                  style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ),

        // Items
        if (items.isNotEmpty) ...[
          const Divider(color: kBorder, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(children: items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${item['quantity']}× ${item['name']}',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text('₪${((item['total'] ?? 0) as num).toStringAsFixed(2)}',
                    style: const TextStyle(color: kMuted, fontSize: 13)),
              ]),
            )).toList()),
          ),
        ],

        // Notes
        if (order['notes'] != null) ...[
          const Divider(color: kBorder, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              const Text('📝 ', style: TextStyle(fontSize: 14)),
              Expanded(child: Text(order['notes'] as String,
                  style: const TextStyle(color: kMuted, fontSize: 13))),
            ]),
          ),
        ],

        // Action buttons
        if (status == 'pending' || status == 'accepted') ...[
          const Divider(color: kBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              if (status == 'pending')
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => onStatusChange('accepted'),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('قبول الطلب'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                )),
              if (status == 'accepted') ...[
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => onStatusChange('preparing'),
                  icon: const Icon(Icons.restaurant, size: 16),
                  label: const Text('بدء التحضير'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                )),
              ],
            ]),
          ),
        ],
      ]),
    );
  }
}
