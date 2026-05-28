import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/api.dart';
import '../../core/theme.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _nameArCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _priceCtrl  = TextEditingController();
  final _catCtrl    = TextEditingController();

  File?   _image;
  String? _imageUrl;
  bool    _uploading = false;
  bool    _saving    = false;
  String? _error;

  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() { _image = File(picked.path); _uploading = true; _error = null; });

    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path, filename: 'product.jpg'),
      });
      final res = await api.post('/upload/image', data: form);
      _imageUrl = res.data['url'] as String;
    } catch (e) {
      setState(() => _error = 'فشل رفع الصورة');
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await api.post('/merchant/products', data: {
        'name':        _nameCtrl.text.trim(),
        'nameAr':      _nameArCtrl.text.trim().isEmpty ? null : _nameArCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty  ? null : _descCtrl.text.trim(),
        'price':       double.parse(_priceCtrl.text.trim()),
        'imageUrl':    _imageUrl,
        'category':    _catCtrl.text.trim().isEmpty   ? null : _catCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = 'تعذّر حفظ المنتج');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [

            // Image picker
            GestureDetector(
              onTap: _uploading ? null : _pickImage,
              child: Container(
                width: double.infinity, height: 180,
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorder, style: BorderStyle.solid),
                ),
                child: _uploading
                    ? const Center(child: CircularProgressIndicator(color: kPrimary))
                    : _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_photo_alternate_outlined, color: kMuted, size: 48),
                            SizedBox(height: 8),
                            Text('اضغط لإضافة صورة المنتج', style: TextStyle(color: kMuted)),
                          ]),
              ),
            ),
            const SizedBox(height: 20),

            // Name AR
            TextFormField(
              controller: _nameArCtrl,
              decoration: const InputDecoration(labelText: 'اسم المنتج بالعربية *'),
              style: const TextStyle(color: Colors.white),
              validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 14),

            // Name EN
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Product Name (English) *'),
              style: const TextStyle(color: Colors.white),
              textDirection: TextDirection.ltr,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Price
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'السعر (₪) *',
                prefixText: '₪ ',
                prefixStyle: TextStyle(color: kPrimary),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (v) {
                if (v!.trim().isEmpty) return 'مطلوب';
                if (double.tryParse(v) == null) return 'رقم غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Category
            TextFormField(
              controller: _catCtrl,
              decoration: const InputDecoration(labelText: 'الفئة (مثل: برغر، بيتزا، مشروبات)'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 14),

            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'الوصف (اختياري)'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),

            // Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(.3)),
              ),
              child: const Row(children: [
                Text('⏳', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'المنتج سيُرسل للمراجعة — سيُنشر بعد موافقة الإدارة',
                  style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13),
                )),
              ]),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving || _uploading ? null : _save,
              child: _saving
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('حفظ وإرسال للمراجعة'),
            ),
          ]),
        ),
      ),
    );
  }
}
