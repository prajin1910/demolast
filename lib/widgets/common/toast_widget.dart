import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/toast_provider.dart';
import '../../utils/app_theme.dart';

class ToastWidget extends StatelessWidget {
  const ToastWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ToastProvider>(
      builder: (context, toastProvider, child) {
        if (toastProvider.toasts.isEmpty) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: toastProvider.toasts.map((toast) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(toast.type),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getBorderColor(toast.type)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getIcon(toast.type),
                        color: _getIconColor(toast.type),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          toast.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _getTextColor(toast.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => toastProvider.removeToast(toast.id),
                        icon: Icon(
                          LucideIcons.x,
                          color: _getIconColor(toast.type),
                          size: 16,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  IconData _getIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return LucideIcons.checkCircle;
      case ToastType.error:
        return LucideIcons.xCircle;
      case ToastType.warning:
        return LucideIcons.alertCircle;
      case ToastType.info:
        return LucideIcons.info;
    }
  }

  Color _getBackgroundColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return AppTheme.successColor.withOpacity(0.1);
      case ToastType.error:
        return AppTheme.errorColor.withOpacity(0.1);
      case ToastType.warning:
        return AppTheme.warningColor.withOpacity(0.1);
      case ToastType.info:
        return AppTheme.primaryColor.withOpacity(0.1);
    }
  }

  Color _getBorderColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return AppTheme.successColor.withOpacity(0.3);
      case ToastType.error:
        return AppTheme.errorColor.withOpacity(0.3);
      case ToastType.warning:
        return AppTheme.warningColor.withOpacity(0.3);
      case ToastType.info:
        return AppTheme.primaryColor.withOpacity(0.3);
    }
  }

  Color _getIconColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return AppTheme.successColor;
      case ToastType.error:
        return AppTheme.errorColor;
      case ToastType.warning:
        return AppTheme.warningColor;
      case ToastType.info:
        return AppTheme.primaryColor;
    }
  }

  Color _getTextColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return AppTheme.successColor;
      case ToastType.error:
        return AppTheme.errorColor;
      case ToastType.warning:
        return AppTheme.warningColor;
      case ToastType.info:
        return AppTheme.primaryColor;
    }
  }
}