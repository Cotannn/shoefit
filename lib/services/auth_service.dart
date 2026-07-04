import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoefit/models/user_model.dart';
import 'package:shoefit/services/api_client.dart';
import 'package:shoefit/services/api_readers.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static const _sessionKey = 'shoefit_api_user';
  static const _legacySessionKey = 'shoefit_mysql_user';

  final ApiClient _apiClient;
  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();

  UserModel? _currentUser;

  Stream<UserModel?> authStateChanges() => _authStateController.stream;

  UserModel? get currentUser => _currentUser;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded =
        preferences.getString(_sessionKey) ??
        preferences.getString(_legacySessionKey);
    if (encoded == null || encoded.isEmpty) {
      _authStateController.add(null);
      return;
    }

    try {
      _currentUser = UserModel.fromMap(readObject(jsonDecode(encoded)));
      _authStateController.add(_currentUser);
    } catch (_) {
      await preferences.remove(_sessionKey);
      _currentUser = null;
      _authStateController.add(null);
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final data = readObject(
      await _apiClient.post(
        '/login.php',
        body: {'email': email, 'password': password},
      ),
    );
    final user = UserModel.fromMap(_readUserPayload(data));
    await _setCurrentUser(user);
    return user;
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = readObject(
      await _apiClient.post(
        '/register.php',
        body: {
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'password': password,
        },
      ),
    );
    final user = UserModel.fromMap(_readUserPayload(data));
    await _setCurrentUser(user);
    return user;
  }

  Future<void> ensureUserProfile(UserModel user) async {
    _currentUser = user;
  }

  Future<UserModel?> fetchUserProfile(
    String uid, {
    bool forceServer = false,
  }) async {
    final data = readObject(
      await _apiClient.get('/profile.php', queryParameters: {'user_id': uid}),
    );
    final user = UserModel.fromMap(_readUserPayload(data));
    if (_currentUser?.uid == uid) {
      await _setCurrentUser(user, notify: false);
    }
    return user;
  }

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String address,
    required String city,
    required String state,
    required String postcode,
  }) async {
    final data = readObject(
      await _apiClient.post(
        '/profile_update.php',
        body: {
          'user_id': uid,
          'full_name': fullName,
          'phone': phone,
          'address': address,
          'city': city,
          'state': state,
          'postcode': postcode,
        },
      ),
    );
    final userPayload = _tryReadUserPayload(data);
    final user = userPayload == null
        ? await fetchUserProfile(uid, forceServer: true)
        : UserModel.fromMap(userPayload);
    if (user == null) {
      throw Exception('The ShoeFit API did not return an updated profile.');
    }
    await _setCurrentUser(user);
  }

  Future<int> fetchTotalUsers() async {
    final data = readObject(await _apiClient.get('/test.php'));
    return readNum(readFirst(data, ['totalUsers', 'total_users'])).toInt();
  }

  Future<void> signOut() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
    await preferences.remove(_legacySessionKey);
    _currentUser = null;
    _authStateController.add(null);
  }

  String explainError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty || message == 'Error') {
      return 'We could not finish the request. Please check API/database connection.';
    }
    return message;
  }

  Future<void> _setCurrentUser(UserModel user, {bool notify = true}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, jsonEncode(user.toMap()));
    await preferences.remove(_legacySessionKey);
    _currentUser = user;
    if (notify) {
      _authStateController.add(user);
    }
  }

  Map<String, dynamic> _readUserPayload(Map<String, dynamic> data) {
    return _tryReadUserPayload(data) ?? readObject(data, label: 'user');
  }

  Map<String, dynamic>? _tryReadUserPayload(Map<String, dynamic> data) {
    final rawUser = readFirst(data, ['user', 'data']);
    if (rawUser is Map) {
      return readObject(rawUser, label: 'user');
    }
    return null;
  }

  void dispose() {
    _authStateController.close();
  }
}
