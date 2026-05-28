import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';

final _profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await api.get('/merchant/profile');
  return res.data as Map<String, dynamic>;
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(_profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: kMuted))),
        data: (m) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar
            Center(child: Column(children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kPrimary.withOpacity(.4), width: 2),
                ),
                child: const Center(child: Text('🏪', style: TextStyle(fontSize: 40))),
              ),
              const SizedBox(height: 14),
              Text(m['nameAr'] ?? m['name'] ?? 'متجرك',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _statusBadge(m['status'] as String? ?? 'pending'),
            ])),
            const SizedBox(height: 28),

            // Info cards
            _InfoCard(items: [
              _InfoRow(icon: '📍', label: 'المدينة',    value: m['city'] as String? ?? '—'),
              _InfoRow(icon: '🏠', label: 'العنوان',   value: m['address'] as String? ?? '—'),
              _InfoRow(icon: '📞', label: 'الهاتف',    value: m['phone'] as String? ?? '—'),
              _InfoRow(icon: '⭐', label: 'التقييم',   value: '${((m['rating'] ?? 0) as num).toStringAsFixed(1)} / 5.0'),
              _InfoRow(icon: '⏱',  label: 'وقت التحضير', value: '${m['avgPrepTime'] ?? 30} دقيقة'),
            ]),
            const SizedBox(height: 16),

            // Logout
            GestureDetector(
              onTap: () async {
                await clearToken();
                if (context.mounted) context.go('/login');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withOpacity(.3)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final colors = {'pending': const Color(0xFFF59E0B), 'active': const Color(0xFF22C55E), 'suspended': const Color(0xFFF97316), 'banned': const Color(0xFFEF4444)};
    final labels = {'pending': 'بانتظار التفعيل', 'active': 'نشط', 'suspended': 'موقوف', 'banned': 'محظور'};
    final color  = colors[status] ?? kMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(20)),
      child: Text(labels[status] ?? status, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(children: items.asMap().entries.map((e) {
        final last = e.key == items.length - 1;
        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              Text(e.value.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(e.value.label, style: const TextStyle(color: kMuted, fontSize: 14)),
              const Spacer(),
              Text(e.value.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (!last) const Divider(color: kBorder, height: 1),
        ]);
      }).toList()),
    );
  }
}

class _InfoRow {
  final String icon, label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
}
