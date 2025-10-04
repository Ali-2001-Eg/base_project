part of "local_storage.dart";

class HiveServiceImpl implements IUserCache,ITokenCache{


  // ---------------------- Boxes ----------------------
  static const String userBoxName = 'user_box';
  static const String tokenBoxName = 'token_box';


  // ----------------------- Keys ----------------------
  static const String currentUserKey = 'current_user';
  static const String accessTokenKey = 'access_token';

  static Box<UserModel>? _userBox;
  static Box<String>? _tokenBox;

  HiveServiceImpl._();

  static final HiveServiceImpl instance = HiveServiceImpl._();

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserModelAdapter());
    //open boxes
    _userBox = await Hive.openBox<UserModel>(userBoxName);
    _tokenBox = await Hive.openBox<String>(tokenBoxName);
  }
  // ---------------------- User ----------------------
  @override
  Future<void> cacheUserModel(UserModel user) async {
    await _userBox?.put(currentUserKey, user);
  }

  @override
  UserModel? getCachedUserModel() {
    final user = _userBox?.get(currentUserKey);
    if (user != null) {
      loggerInfo('Retrieved user from cache: ${user.runtimeType}');
      loggerVerbose('User fields: ${user.toJson()}'); // Make sure toJson() exists
    }
    return user;
  }

  @override
  Future<void> updateCachedUserModel(UserModel user) async {
    final currentUser = _userBox?.get(currentUserKey);

    if (currentUser == null) {
      await _userBox?.put(currentUserKey, user);
      return;
    }

    UserModel updatedUser;


      updatedUser = currentUser.copyWith(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
      );


    await _userBox?.put(currentUserKey, updatedUser);

    // Debug log
    logger('Updated user in cache: ${updatedUser.toJson()}');
  }
  @override
  Future<void> clearUserModel() async {
    await _userBox?.delete(currentUserKey);
  }

// ---------------------- Token ----------------------
  @override
  Future<void> saveAccessToken(String token) async {
    await _tokenBox?.put(accessTokenKey, token);
  }

  @override
  String? getAccessToken() {
    return _tokenBox?.get(accessTokenKey);
  }

  @override
  Future<void> clearAccessToken() async {
    await _tokenBox?.delete(accessTokenKey);
  }

// ------------------- Paginated Cache ---------------------
  Future<void> _cachePage<T>(List<T> items, {required String cacheKey}) async {
    final box = await Hive.openBox<T>(cacheKey);
    await box.putAll(items.asMap());
  }

// Generic retrieval method
  Future<List<T>> _getCachedPage<T>({required String cacheKey}) async {
    final box = await Hive.openBox<T>(cacheKey);
    return box.values.toList();
  }

// Generic clear method
  Future<void> _clearCachedPage<T>({required String cacheKey}) async {
    final box = await Hive.openBox<T>(cacheKey);
    await box.clear();
  }

// ------------------ Generic ---------------------
  static Future<Box<E>> openBox<E>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) return Hive.box<E>(boxName);
    return await Hive.openBox<E>(boxName);
  }

  static Future<void> put<E>(String boxName, dynamic key, E value) async {
    final box = await openBox<E>(boxName);
    await box.put(key, value);
  }

  static Future<E?> get<E>(String boxName, dynamic key) async {
    final box = await openBox<E>(boxName);
    return box.get(key);
  }

  static Future<void> delete<E>(String boxName, dynamic key) async {
    final box = await openBox<E>(boxName);
    await box.delete(key);
  }

  static Future<void> clearBox<E>(String boxName) async {
    final box = await openBox<E>(boxName);
    await box.clear();
  }

  static Future<void> closeBox<E>(String boxName) async {
    final box = Hive.box<E>(boxName);
    await box.close();
  }

  Future<void> clearAll() async {
    await _userBox?.clear();
    await _tokenBox?.clear();
  }

}