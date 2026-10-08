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
    if (loading) return const OnlineStoreListSkeleton();
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

class OnlineStoreListSkeleton extends StatelessWidget {
  const OnlineStoreListSkeleton({Key? key, this.compact = false})
      : super(key: key);
  final bool compact;

  @override
  Widget build(BuildContext context) => ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: compact ? 4 : 7,
        itemBuilder: (_, index) => Container(
          height: compact ? 72 : 92,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: OnlineStoreAdminUi.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OnlineStoreAdminUi.border),
          ),
          child: Row(children: [
            Container(
              width: compact ? 48 : 64,
              decoration: BoxDecoration(
                color: OnlineStoreAdminUi.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: .72,
                  child: Container(height: 12, decoration: _skeletonBox),
                ),
                const SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: .45,
                  child: Container(height: 9, decoration: _skeletonBox),
                ),
              ],
            )),
          ]),
        ),
      );

  BoxDecoration get _skeletonBox => BoxDecoration(
        color: OnlineStoreAdminUi.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      );
}
