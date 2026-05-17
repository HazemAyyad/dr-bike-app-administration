import 'package:get/get.dart';

import '../databases/api/api_consumer.dart';
import '../databases/api/dio_consumer.dart';
import '../databases/api/end_points.dart';
import '../helpers/json_safe_parser.dart';

class BankItem {
  BankItem({
    required this.id,
    required this.name,
    this.shortcut,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final String? shortcut;
  final int sortOrder;

  factory BankItem.fromJson(Map<String, dynamic> json) {
    return BankItem(
      id: asInt(json['id']),
      name: asString(json['name']),
      shortcut: asNullableString(json['shortcut']),
      sortOrder: asInt(json['sort_order']),
    );
  }
}

class BanksService extends GetxService {
  static BanksService get to => Get.find<BanksService>();

  final RxList<BankItem> banks = <BankItem>[].obs;
  final RxBool isLoading = false.obs;

  ApiConsumer get _api => Get.find<DioConsumer>();

  Future<void> loadBanks() async {
    isLoading.value = true;
    try {
      final res = await _api.get(EndPoints.banks);
      final data = res.data;
      final list = data is Map ? data['banks'] : null;
      if (list is List) {
        banks.assignAll(
          list.map((e) => BankItem.fromJson(Map<String, dynamic>.from(e))),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<BankItem?> findOrCreateByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final existing = banks.firstWhereOrNull(
      (b) => b.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (existing != null) return existing;

    final res = await _api.post(
      EndPoints.banksFindOrCreate,
      data: {'name': trimmed},
    );
    final data = res.data;
    if (data is Map && data['bank'] != null) {
      final item = BankItem.fromJson(Map<String, dynamic>.from(data['bank']));
      if (!banks.any((b) => b.id == item.id)) {
        banks.add(item);
      }
      return item;
    }
    return null;
  }

  Future<bool> addBank({required String name}) async {
    final res = await _api.post(
      EndPoints.banks,
      data: {'name': name.trim()},
    );
    final data = res.data;
    if (data is Map && data['status'] == 'success') {
      await loadBanks();
      return true;
    }
    return false;
  }

  Future<bool> updateBank({
    required int id,
    required String name,
  }) async {
    await _api.put(
      '${EndPoints.banks}/$id',
      data: {'name': name.trim()},
    );
    await loadBanks();
    return true;
  }

  Future<bool> deleteBank(int id) async {
    await _api.delete('${EndPoints.banks}/$id');
    await loadBanks();
    return true;
  }

  List<String> matchNames(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return banks.map((b) => b.name).toList();

    return banks
        .where((b) {
          final n = b.name.toLowerCase();
          final s = (b.shortcut ?? '').toLowerCase();
          if (s.isNotEmpty &&
              (s.startsWith(q) || q.startsWith(s) || s == q)) {
            return true;
          }
          if (n.startsWith(q) || n.contains(q)) return true;
          // مطابقة أول حرف/حروف من اسم البنك (مثلاً "ف" → فلسطين)
          final words = n.split(RegExp(r'\s+'));
          if (words.isNotEmpty && words.first.startsWith(q)) return true;
          if (q.length <= 3 && n.replaceAll(' ', '').startsWith(q)) {
            return true;
          }
          return false;
        })
        .map((b) => b.name)
        .toList();
  }
}
