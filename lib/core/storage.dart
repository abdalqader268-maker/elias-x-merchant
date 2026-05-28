import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();

Future<String?> getToken()    => _storage.read(key: 'merchant_token');
Future<void>    saveToken(String t) => _storage.write(key: 'merchant_token', value: t);
Future<void>    clearToken()  => _storage.delete(key: 'merchant_token');
Future<bool>    hasToken()    async => (await getToken()) != null;
