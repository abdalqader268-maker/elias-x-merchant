import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';
import '../../core/theme.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _ctrl    = TextEditingController();
  bool  _loading = false;
  String? _error;

  Future<void> _send() async {
    final phone = _ctrl.text.trim();
    if (phone.length < 9) {
      setState(() => _error = 'أدخل رقم هاتف صحيح');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final stripped = phone.startsWith('0') ? phone.substring(1) : phone;
      final full = stripped.startsWith('+') ? stripped : '+970$stripped';
      await api.post('/auth/send-otp', data: {'phone': full});
      if (mounted) context.push('/otp', extra: full);
    } catch (e) {
      setState(() => _error = 'تعذّر إرسال الرمز، حاول مجدداً');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Logo
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(.15),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: kPrimary.withOpacity(.4)),
                ),
                child: const Center(child: Text('🏪', style: TextStyle(fontSize: 38))),
              ),
              const SizedBox(height: 24),
              const Text('بوابة التجار', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('سجّل دخولك لإدارة منتجاتك وطلباتك', style: TextStyle(color: kMuted, fontSize: 14)),
              const SizedBox(height: 48),

              // Phone field
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 1.2),
                decoration: const InputDecoration(
                  hintText: '05X XXX XXXX',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('🇵🇸', style: TextStyle(fontSize: 20)),
                  ),
                  prefixText: '+970  ',
                  prefixStyle: TextStyle(color: kMuted, fontSize: 15),
                ),
                onSubmitted: (_) => _send(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ]),
                ),
              ],

              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _send,
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('إرسال رمز التحقق'),
              ),

              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kCard, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder),
                ),
                child: const Row(children: [
                  Text('💡', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'يجب أن يكون حسابك مسجلاً كتاجر من قِبل الإدارة أولاً',
                    style: TextStyle(color: kMuted, fontSize: 13),
                  )),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
