import 'package:flutter/material.dart';
import '../theme/theme.dart';

class Toast {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final color = isError ? Colors.red[800] : Colors.black87;
    final icon = isError
        ? AppIcons.error(size: 20, color: Colors.white)
        : AppIcons.checkCircle(size: 20, color: Colors.white);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        duration: duration,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message, isError: false);
  }

  static void error(BuildContext context, String message) {
    show(context, message, isError: true);
  }
}
