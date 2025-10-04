part of 'local_storage.dart';
abstract interface class ITokenCache {
  Future<void> saveAccessToken(String token);
  String? getAccessToken();
  Future<void> clearAccessToken();
}