import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';
import '../../core/theme.dart';

final _statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await api.get('/merchant/stats');
  return res.data as Map<String, dynamic>;
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(_statsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: kPrimary,
          onRefresh: () => ref.refresh(_statsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('مرحباً 👋', style: TextStyle(color: kMuted, fontSize: 14)),
                    stats.when(
                      data: (d) => Text(
                        (d['merchant'] as Map?)?['nameAr'] ?? (d['merchant'] as Map?)?['name'] ?? 'متجرك',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      loading: () => const Text('...', style: TextStyle(color: Colors.white, fontSize: 22)),
                      error:   (_, __) => const Text('متجرك', style: TextStyle(color: Colors.white, fontSize: 22)),
                    ),
                  ]),
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: kCard, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBorder),
                    ),
                    child: const Center(child: Text('🏪', style: TextStyle(fontSize: 22))),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats grid
              stats.when(
                loading: () => _shimmerGrid(),
                error:   (_, __) => const Center(child: Text('تعذّر تحميل البيانات', style: TextStyle(color: kMuted))),
                data: (d) {
                  final cards = [
                    _StatCard(icon: '📦', label: 'المنتجات', value: '${d['totalProducts'] ?? 0}', color: const Color(0xFF3B82F6)),
                    _StatCard(icon: '✅', label: 'نشطة',     value: '${d['activeProducts'] ?? 0}', color: const Color(0xFF22C55E)),
                    _StatCard(icon: '⏳', label: 'بانتظار',  value: '${d['pendingProducts'] ?? 0}', color: const Color(0xFFF59E0B)),
                    _StatCard(icon: '📋', label: 'طلبات اليوم', value: '${d['todayOrders'] ?? 0}', color: kPrimary),
                    _StatCard(icon: '💰', label: 'الإيرادات', value: '₪${((d['totalRevenue'] ?? 0) as num).toStringAsFixed(0)}', color: const Color(0xFF22C55E)),
                    _StatCard(icon: '🛒', label: 'إجمالي الطلبات', value: '${d['totalOrders'] ?? 0}', color: const Color(0xFF8B5CF6)),
                  ];
                  return GridView.count(
                    crossAxisCount: 2, shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12, crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: cards,
                  );
                },
              ),

              const SizedBox(height: 24),

              // Status banner
              stats.when(
                data: (d) {
                  final m = d['merchant'] as Map?;
                  final isActive = m?['status'] == 'active';
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF22C55E).withOpacity(.1) : const Color(0xFFF59E0B).withOpacity(.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive ? const Color(0xFF22C55E).withOpacity(.3) : const Color(0xFFF59E0B).withOpacity(.3),
                      ),
                    ),
                    child: Row(children: [
                      Text(isActive ? '🟢' : '⏳', style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          isActive ? 'متجرك نشط' : 'بانتظار تفعيل الحساب',
                          style: TextStyle(
                            color: isActive ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isActive
                              ? 'طلباتك مرئية للزبائن'
                              : 'سيتواصل معك الفريق قريباً',
                          style: const TextStyle(color: kMuted, fontSize: 13),
                        ),
                      ])),
                    ]),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerGrid() {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: List.generate(6, (_) => Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
      )),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon, label, value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Container(height: 3, decoration: BoxDecoration(
          color: color.withOpacity(.2), borderRadius: BorderRadius.circular(2),
        ), child: FractionallySizedBox(
          widthFactor: .6,
          child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        )),
      ]),
    );
  }
}
