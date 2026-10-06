import 'package:flutter/material.dart';

import '../utils/online_store_admin_ui.dart';

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
        child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: OnlineStoreAdminUi.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: OnlineStoreAdminUi.border),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 42, color: OnlineStoreAdminUi.danger),
              const SizedBox(height: 8),
              Text(error!, textAlign: TextAlign.center),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ])),
      );
    }
    if (isEmpty) {
      return Center(
        child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: OnlineStoreAdminUi.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: OnlineStoreAdminUi.border),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 44, color: OnlineStoreAdminUi.accent),
              const SizedBox(height: 8),
              const Text('لا توجد بيانات حالياً'),
              TextButton(onPressed: onRetry, child: const Text('تحديث')),
            ])),
      );
    }
    return child;
  }
}
