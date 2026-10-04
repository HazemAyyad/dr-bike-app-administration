import 'package:flutter/material.dart';

class OnlineStoreStateView extends StatelessWidget {
  const OnlineStoreStateView({
    Key? key,
    required this.loading,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    required this.child,
  }) : super(key: key);

  final bool loading;
  final String? error;
  final bool isEmpty;
  final VoidCallback onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error?.isNotEmpty == true) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 8),
          Text(error!, textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ]),
      );
    }
    if (isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.inbox_outlined, size: 42),
          const SizedBox(height: 8),
          const Text('لا توجد بيانات حالياً'),
          TextButton(onPressed: onRetry, child: const Text('تحديث')),
        ]),
      );
    }
    return child;
  }
}
