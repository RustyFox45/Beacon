import 'package:flutter/material.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.black, fontSize: 16),
                child: content,
              ),
            ),
            const SizedBox(height: 32),
            if (actions != null)
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!
                      .expand((a) => [a, const SizedBox(width: 8)])
                      .toList()
                    ..removeLast(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget>? actions,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => AppDialog(
      title: title,
      content: content,
      actions: actions,
    ),
  );
}
