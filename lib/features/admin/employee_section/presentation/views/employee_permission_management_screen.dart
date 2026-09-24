import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/helpers/app_failure_notice.dart';
import '../../../../../core/helpers/app_success_notice.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class EmployeePermissionManagementScreen extends StatefulWidget {
  const EmployeePermissionManagementScreen({
    Key? key,
    required this.employeeId,
    required this.employeeName,
  }) : super(key: key);

  final int employeeId;
  final String employeeName;

  @override
  State<EmployeePermissionManagementScreen> createState() =>
      _EmployeePermissionManagementScreenState();
}

class _EmployeePermissionManagementScreenState
    extends State<EmployeePermissionManagementScreen> {
  final DioConsumer _api = Get.find<DioConsumer>();
  final Set<int> _selectedIds = <int>{};
  List<Map<String, dynamic>> _permissions = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

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
      final response = await _api.get(
        EndPoints.employeePermissionContext(widget.employeeId),
      );
      final root = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final data = root['data'] is Map
          ? Map<String, dynamic>.from(root['data'] as Map)
          : <String, dynamic>{};
      final rows = data['permissions'] is List
          ? (data['permissions'] as List)
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList()
          : <Map<String, dynamic>>[];
      _selectedIds
        ..clear()
        ..addAll(rows
            .where((row) => row['selected'] == true)
            .map((row) => int.tryParse('${row['permission_id']}'))
            .whereType<int>());
      if (!mounted) return;
      setState(() {
        _permissions = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _message(error);
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _api.patch(
        EndPoints.syncEmployeePermissions(widget.employeeId),
        data: {'permission_ids': _selectedIds.toList()},
      );
      if (!mounted) return;
      AppSuccessNotice.show(
        title: 'success'.tr,
        message: 'تم تحديث صلاحيات الموظف بنجاح.',
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      AppFailureNotice.show(
        title: 'error'.tr,
        message: _message(error),
      );
      setState(() => _saving = false);
    }
  }

  String _message(Object error) => error is ServerException
      ? error.errorModel.errorMessage
      : error.toString();

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final permission in _permissions) {
      final group = permission['group_name']?.toString().trim();
      groups
          .putIfAbsent(
            group == null || group.isEmpty ? 'إعدادات عامة' : group,
            () => <Map<String, dynamic>>[],
          )
          .add(permission);
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'صلاحيات ${widget.employeeName}',
        action: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        SizedBox(height: 12.h),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 90.h),
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: .07),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: .2),
                        ),
                      ),
                      child: const Text(
                        'يمكنك تعديل الصلاحيات الموجودة لديك والقابلة للتفويض فقط. بقية صلاحيات الموظف محفوظة ولن تتأثر.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    ...groups.entries.map(
                      (entry) => Card(
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor
                            : Colors.white,
                        child: ExpansionTile(
                          initiallyExpanded:
                              entry.value.any((row) => row['selected'] == true),
                          title: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${entry.value.where((row) => _selectedIds.contains(int.tryParse('${row['permission_id']}'))).length}/${entry.value.length}',
                          ),
                          children: entry.value.map((permission) {
                            final id = int.tryParse(
                                  '${permission['permission_id']}',
                                ) ??
                                -1;
                            return CheckboxListTile(
                              value: _selectedIds.contains(id),
                              onChanged: permission['editable'] == false
                                  ? null
                                  : (selected) {
                                      setState(() {
                                        if (selected == true) {
                                          _selectedIds.add(id);
                                        } else {
                                          _selectedIds.remove(id);
                                        }
                                      });
                                    },
                              title: Text(
                                permission['permission_name']?.toString() ?? '',
                              ),
                              secondary: permission['admin_only'] == true
                                  ? const Icon(Icons.lock_outline_rounded)
                                  : null,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _loading || _error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('حفظ الصلاحيات'),
            ),
    );
  }
}
