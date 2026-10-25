import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/dio_consumer.dart';

class AdminSectionPermissionsScreen extends StatefulWidget {
  const AdminSectionPermissionsScreen({
    Key? key,
    required this.adminId,
    required this.adminName,
  }) : super(key: key);

  final int adminId;
  final String adminName;

  @override
  State<AdminSectionPermissionsScreen> createState() =>
      _AdminSectionPermissionsScreenState();
}

class _AdminSectionPermissionsScreenState
    extends State<AdminSectionPermissionsScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _fullAccess = false;
  bool _canEdit = false;
  String? _error;
  List<Map<String, dynamic>> _available = [];
  final Set<String> _selected = {};

  String get _endpoint => 'admin/users/${widget.adminId}/sections';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await Get.find<DioConsumer>().get(_endpoint);
      final data = response.data as Map;
      if (data['status'] != 'success') {
        throw StateError(data['message']?.toString() ?? 'تعذر تحميل الصلاحيات');
      }
      if (!mounted) return;
      setState(() {
        _fullAccess = data['full_access'] == true;
        _canEdit = data['can_edit'] == true;
        _selected
          ..clear()
          ..addAll((data['sections'] as List).map((e) => e.toString()));
        _available = (data['available_sections'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذر تحميل الصلاحيات. حاول مجددًا.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !_canEdit) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await Get.find<DioConsumer>().put(_endpoint, data: {
        'full_access': _fullAccess,
        'sections': _selected.toList(),
      });
      final data = response.data as Map;
      if (data['status'] != 'success') {
        throw StateError(data['message']?.toString() ?? 'تعذر حفظ الصلاحيات');
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر حفظ الصلاحيات. حاول مجددًا.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7052A3);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F6),
        appBar: AppBar(
          title: Text('صلاحيات ${widget.adminName}'),
          backgroundColor: const Color(0xFFF4F4F6),
          foregroundColor: const Color(0xFF252631),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: accent))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      if (_error != null)
                        ListTile(
                          title: Text(_error!,
                              style: const TextStyle(color: Colors.red)),
                          trailing: _available.isEmpty
                              ? TextButton(
                                  onPressed: _load,
                                  child: const Text('إعادة المحاولة'))
                              : null,
                        ),
                      if (_available.isNotEmpty) ...[
                        SwitchListTile(
                          title: const Text('مدير كامل الصلاحيات',
                              style: TextStyle(color: Color(0xFF252631))),
                          subtitle: const Text(
                            'يشاهد كل الأقسام ويستطيع إدارة حسابات الأدمن وصلاحياتهم.',
                            style: TextStyle(color: Color(0xFF50515D)),
                          ),
                          value: _fullAccess,
                          activeThumbColor: accent,
                          onChanged: !_canEdit || _saving
                              ? null
                              : (value) => setState(() => _fullAccess = value),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            !_canEdit
                                ? 'لا يمكنك تعديل صلاحيات حسابك الحالي.'
                                : _fullAccess
                                    ? 'أوقف الصلاحيات الكاملة لتحديد أقسام معينة.'
                                    : 'حدد الأقسام المتاحة. عدم تحديد أي قسم يمنع الوصول لجميع الأقسام.',
                            style: const TextStyle(color: Color(0xFF50515D)),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _available.length,
                            itemBuilder: (context, index) {
                              final section = _available[index];
                              final key = section['key'].toString();
                              return CheckboxListTile(
                                title: Text(section['name'].toString(),
                                    style: const TextStyle(
                                        color: Color(0xFF252631))),
                                activeColor: accent,
                                value: _fullAccess || _selected.contains(key),
                                onChanged: !_canEdit || _saving || _fullAccess
                                    ? null
                                    : (value) => setState(() {
                                          value == true
                                              ? _selected.add(key)
                                              : _selected.remove(key);
                                        }),
                              );
                            },
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _canEdit && !_saving ? _save : null,
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: accent),
                                child: Text(
                                    _saving ? 'جارٍ الحفظ…' : 'حفظ الصلاحيات'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
