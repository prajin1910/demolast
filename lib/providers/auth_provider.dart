import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _user != null && _token != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('token');
      final storedUser = prefs.getString('user');

      if (storedToken != null && storedUser != null) {
        // Check if token is expired
        if (!JwtDecoder.isExpired(storedToken)) {
          _token = storedToken;
          _user = User.fromJson(jsonDecode(storedUser));
          notifyListeners();
        } else {
          // Token expired, clear storage
          await _clearAuth();
        }
      }
    } catch (e) {
      debugPrint('Error loading stored auth: $e');
      await _clearAuth();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);
      
      _token = response['accessToken'];
      _user = User(
        id: response['id'],
        name: response['name'],
        email: response['email'],
        role: response['role'],
      );

      // Store in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user', jsonEncode(_user!.toJson()));

      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.register(userData);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.verifyOtp(email, otp);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _clearAuth();
  }

  Future<void> _clearAuth() async {
    _user = null;
    _token = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    
    notifyListeners();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await ApiService.changePassword(currentPassword, newPassword);
    } catch (e) {
      rethrow;
    }
  }
}