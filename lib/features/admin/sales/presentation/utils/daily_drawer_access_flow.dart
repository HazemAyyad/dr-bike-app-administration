import '../../data/models/daily_session_model.dart';

/// Resolves a pending closing before opening the drawer for a waiting sale.
Future<DailySessionPayload?> prepareDailyDrawer({
  required Future<DailySessionPayload?> Function() loadPayload,
  required Future<bool> Function(int requestId) reviewClosing,
  required Future<bool> Function() openDrawer,
}) async {
  var payload = await loadPayload();
  if (payload == null || payload.allowsSales) return payload;

  if (payload.isClosingRequested &&
      payload.canFinalizeClosing &&
      payload.pendingClosingRequestId != null) {
    if (!await reviewClosing(payload.pendingClosingRequestId!)) return null;
    payload = await loadPayload();
    if (payload == null || payload.allowsSales) return payload;
  }

  if (payload.canRequestOpen || payload.needsManualOpen) {
    if (!await openDrawer()) return null;
    payload = await loadPayload();
  }
  return payload;
}
