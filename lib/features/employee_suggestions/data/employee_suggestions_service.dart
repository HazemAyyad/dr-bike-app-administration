import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';

class EmployeeSuggestionItem {
  final int id;
  final String category;
  final String title;
  final String message;
  final bool isAnonymous;
  final String employeeName;
  final String status;
  final String adminNote;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  const EmployeeSuggestionItem({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.isAnonymous,
    required this.employeeName,
    required this.status,
    required this.adminNote,
    required this.reviewedAt,
    required this.createdAt,
  });

  factory EmployeeSuggestionItem.fromJson(Map<String, dynamic> json) {
    return EmployeeSuggestionItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      category: json['category']?.toString() ?? 'suggestion',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isAnonymous: json['is_anonymous'] == true ||
          json['is_anonymous']?.toString() == '1',
      employeeName: json['employee_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'new',
      adminNote: json['admin_note']?.toString() ?? '',
      reviewedAt: _parseDate(json['reviewed_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}

class EmployeeSuggestionsService {
  final DioConsumer api;

  const EmployeeSuggestionsService({required this.api});

  Future<List<EmployeeSuggestionItem>> getSuggestions({
    required bool isAdmin,
    String? status,
  }) async {
    final response = await api.get(
      isAdmin
          ? EndPoints.adminEmployeeSuggestions
          : EndPoints.employeeSuggestions,
      queryParameters: {if (status != null) 'status': status},
    );
    final list = _extractList(response.data, const ['suggestions', 'data']);
    return list
        .whereType<Map>()
        .map((e) => EmployeeSuggestionItem.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .where((e) => e.id > 0)
        .toList();
  }

  Future<void> createSuggestion({
    required String category,
    required String title,
    required String message,
    required bool isAnonymous,
  }) async {
    await api.post(
      EndPoints.employeeSuggestions,
      data: {
        'category': category,
        'title': title,
        'message': message,
        'is_anonymous': isAnonymous,
      },
    );
  }

  Future<void> updateMySuggestion({
    required int id,
    required String category,
    required String title,
    required String message,
    required bool isAnonymous,
  }) async {
    await api.put(
      EndPoints.employeeSuggestion(id),
      data: {
        'category': category,
        'title': title,
        'message': message,
        'is_anonymous': isAnonymous,
      },
    );
  }

  Future<void> deleteMySuggestion(int id) async {
    await api.delete(EndPoints.employeeSuggestion(id));
  }

  Future<void> updateSuggestion({
    required int id,
    required String status,
    String? adminNote,
  }) async {
    await api.put(
      EndPoints.adminEmployeeSuggestion(id),
      data: {
        'status': status,
        if (adminNote != null) 'admin_note': adminNote,
      },
    );
  }

  List<dynamic> _extractList(dynamic raw, List<String> keys) {
    dynamic current = raw;
    for (final key in keys) {
      if (current is Map && current[key] != null) {
        current = current[key];
      }
    }
    if (current is List) return current;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return const [];
  }
}
