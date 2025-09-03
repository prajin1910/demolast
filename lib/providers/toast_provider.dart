import 'package:flutter/foundation.dart';

class ToastMessage {
  final String id;
  final String message;
  final ToastType type;
  final DateTime timestamp;

  ToastMessage({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

enum ToastType {
  success,
  error,
  warning,
  info,
}

class ToastProvider with ChangeNotifier {
  final List<ToastMessage> _toasts = [];

  List<ToastMessage> get toasts => List.unmodifiable(_toasts);

  void showToast(String message, ToastType type) {
    final toast = ToastMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );

    _toasts.add(toast);
    notifyListeners();

    // Auto remove after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      removeToast(toast.id);
    });
  }

  void removeToast(String id) {
    _toasts.removeWhere((toast) => toast.id == id);
    notifyListeners();
  }

  void clearAll() {
    _toasts.clear();
    notifyListeners();
  }
}