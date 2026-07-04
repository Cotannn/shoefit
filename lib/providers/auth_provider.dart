import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shoefit/config/app_environment.dart';
import 'package:shoefit/models/user_model.dart';
import 'package:shoefit/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService})
    : _authService = authService {
    _subscription = _authService.authStateChanges().listen(_handleAuthChange);
    _authService.initialize();
  }

  final AuthService _authService;
  late final StreamSubscription<UserModel?> _subscription;
  final Completer<void> _initializationCompleter = Completer<void>();

  UserModel? _user;
  UserModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  UserModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isAdmin =>
      (_profile?.isAdmin ?? false) || AppEnvironment.isAdminEmail(_user?.email);

  Future<void> ensureInitialized() => _initializationCompleter.future;

  Future<void> _handleAuthChange(UserModel? user) async {
    _user = user;
    _errorMessage = null;

    if (user == null) {
      _profile = null;
      _completeInitialization();
      notifyListeners();
      return;
    }

    try {
      await _authService.ensureUserProfile(user);
      _profile = await _authService.fetchUserProfile(
        user.uid,
        forceServer: true,
      );
    } catch (error) {
      _profile = user;
      _errorMessage = _authService.explainError(error);
    }

    _completeInitialization();
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    await _runWithLoading(() async {
      _user = await _authService.login(email: email, password: password);
      _profile = _user;
    });
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _runWithLoading(() async {
      _user = await _authService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );
      _profile = _user;
    });
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    required String address,
    required String city,
    required String state,
    required String postcode,
  }) async {
    final currentUser = _user;
    if (currentUser == null) {
      throw Exception('Please sign in to continue.');
    }

    await _runWithLoading(() async {
      await _authService.updateProfile(
        uid: currentUser.uid,
        fullName: fullName,
        phone: phone,
        address: address,
        city: city,
        state: state,
        postcode: postcode,
      );
      _profile = await _authService.fetchUserProfile(currentUser.uid);
      _user = _profile;
    });
  }

  Future<UserModel?> refreshProfile({bool forceServer = false}) async {
    final currentUser = _user;
    if (currentUser == null) {
      return null;
    }
    try {
      _errorMessage = null;
      _profile = await _authService.fetchUserProfile(
        currentUser.uid,
        forceServer: forceServer,
      );
      _user = _profile;
      notifyListeners();
      return _profile;
    } catch (error) {
      _errorMessage = _authService.explainError(error);
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> _runWithLoading(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _errorMessage = _authService.explainError(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _completeInitialization() {
    if (!_initializationCompleter.isCompleted) {
      _initializationCompleter.complete();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _authService.dispose();
    super.dispose();
  }
}
