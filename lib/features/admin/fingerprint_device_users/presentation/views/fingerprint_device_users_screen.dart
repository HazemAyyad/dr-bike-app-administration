import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../employee_section/data/models/employee_model.dart';
import '../../../employee_section/data/repositorie_imp/employee_implement.dart';

class FingerprintDeviceUsersScreen extends StatefulWidget {
  const FingerprintDeviceUsersScreen({Key? key}) : super(key: key);

  @override
  State<FingerprintDeviceUsersScreen> createState() =>
      _FingerprintDeviceUsersScreenState();
}

class _FingerprintDeviceUsersScreenState
    extends State<FingerprintDeviceUsersScreen> {
  final RxBool _loading = true.obs;
  final RxString _error = ''.obs;
  final RxList<Map<String, dynamic>> _users = <Map<String, dynamic>>[].obs;
  final RxString _query = ''.obs;
  final RxString _filter = 'all'.obs; // all|linked|unlinked

  int _deviceId = 0;
  String _deviceName = '';

  DioConsumer? get _api =>
      Get.isRegistered<DioConsumer>() ? Get.find<DioConsumer>() : null;

  EmployeeImplement? get _employeeRepo =>
      Get.isRegistered<EmployeeImplement>() ? Get.find<EmployeeImplement>() : null;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _deviceId = int.tryParse(args['deviceId']?.toString() ?? '') ?? 0;
    _deviceName = args['deviceName']?.toString() ?? '';
    _load();
  }

  Future<void> _load() async {
    final api = _api;
    _error.value = '';
    if (api == null || _deviceId <= 0) {
      _loading.value = false;
      _error.value = 'بيانات الجهاز غير مكتملة';
      return;
    }
    _loading.value = true;
    try {
      final res = await api.get(
        'admin/fingerprint/users',
        queryParameters: {'device_id': _deviceId},
      );
      final data = res.data;
      if (data is Map && data['status']?.toString() == 'success') {
        final list = data['users'];
        if (list is List) {
          _users.assignAll(list.map((e) => Map<String, dynamic>.from(e)));
        } else {
          _users.clear();
        }
        final dev = data['device'];
        if (dev is Map) {
          _deviceName = dev['name']?.toString() ?? _deviceName;
        }
      } else {
        _error.value = (data is Map ? data['message']?.toString() : null) ??
            'فشل تحميل المستخدمين';
      }
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _loading.value = false;
    }
  }

  int get _total => _users.length;
  int get _linked =>
      _users.where((u) => u['status']?.toString() == 'linked').length;
  int get _unlinked =>
      _users.where((u) => u['status']?.toString() != 'linked').length;

  List<Map<String, dynamic>> get _filtered {
    final q = _query.value.trim().toLowerCase();
    final f = _filter.value;
    return _users.where((u) {
      final status = u['status']?.toString() ?? '';
      if (f == 'linked' && status != 'linked') return false;
      if (f == 'unlinked' && status == 'linked') return false;
      if (q.isEmpty) return true;
      final id = u['device_user_id']?.toString().toLowerCase() ?? '';
      final name = u['name']?.toString().toLowerCase() ?? '';
      final emp = u['linked_employee_name']?.toString().toLowerCase() ?? '';
      return id.contains(q) || name.contains(q) || emp.contains(q);
    }).toList();
  }

  Future<void> _unlink(String deviceUserId) async {
    final api = _api;
    if (api == null) return;
    try {
      final res = await api.post(
        'admin/fingerprint/users/$deviceUserId/unlink',
        data: {'device_id': _deviceId},
      );
      final data = res.data;
      final ok = data is Map && data['status']?.toString() == 'success';
      Get.snackbar(
        ok ? 'success'.tr : 'error'.tr,
        ok ? 'تم فك الربط' : (data is Map ? data['message']?.toString() : null) ?? 'فشل فك الربط',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
        colorText: Colors.white,
      );
      await _load();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _link(String deviceUserId) async {
    final repo = _employeeRepo;
    final api = _api;
    if (repo == null || api == null) {
      Get.snackbar('error'.tr, 'تعذر تحميل قائمة الموظفين', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    List<EmployeeModel> employees = [];
    try {
      employees = await repo.getEmployees();
    } catch (_) {}
    if (!mounted) return;

    final selected = await showModalBottomSheet<EmployeeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EmployeePickerSheet(employees: employees),
    );
    if (selected == null) return;

    try {
      final res = await api.post(
        'admin/fingerprint/users/$deviceUserId/link',
        data: {'employee_id': selected.id, 'device_id': _deviceId},
      );
      final data = res.data;
      final ok = data is Map && data['status']?.toString() == 'success';
      Get.snackbar(
        ok ? 'success'.tr : 'error'.tr,
        ok ? 'تم الربط' : (data is Map ? data['message']?.toString() : null) ?? 'فشل الربط',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
        colorText: Colors.white,
      );
      await _load();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(_deviceName.isNotEmpty ? _deviceName : 'fingerprintDeviceUsers'.tr),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'refresh'.tr,
          ),
        ],
      ),
      body: Obx(() {
        if (_loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error.value, textAlign: TextAlign.center),
                  SizedBox(height: 12.h),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: Text('tryAgain'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        final rows = _filtered;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                children: [
                  Expanded(child: _StatCard(title: 'الإجمالي', value: '$_total')),
                  SizedBox(width: 8.w),
                  Expanded(child: _StatCard(title: 'مربوط', value: '$_linked')),
                  SizedBox(width: 8.w),
                  Expanded(child: _StatCard(title: 'غير مربوط', value: '$_unlinked')),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: TextField(
                onChanged: (v) => _query.value = v,
                decoration: InputDecoration(
                  hintText: 'search'.tr,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Obx(() {
                final f = _filter.value;
                return Row(
                  children: [
                    _Chip(
                      label: 'الكل',
                      selected: f == 'all',
                      onTap: () => _filter.value = 'all',
                    ),
                    SizedBox(width: 8.w),
                    _Chip(
                      label: 'مربوط',
                      selected: f == 'linked',
                      onTap: () => _filter.value = 'linked',
                    ),
                    SizedBox(width: 8.w),
                    _Chip(
                      label: 'غير مربوط',
                      selected: f == 'unlinked',
                      onTap: () => _filter.value = 'unlinked',
                    ),
                  ],
                );
              }),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: rows.isEmpty
                  ? Center(child: Text('noData'.tr))
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      itemBuilder: (_, i) {
                        final u = rows[i];
                        final id = u['device_user_id']?.toString() ?? '';
                        final name = u['name']?.toString() ?? '';
                        final emp = u['linked_employee_name']?.toString();
                        final linked = u['status']?.toString() == 'linked';
                        return Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$id • $name',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                  _StatusBadge(linked: linked),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                emp == null || emp.isEmpty ? 'غير مربوط' : emp,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _link(id),
                                      child: Text(linked ? 'تغيير الربط' : 'ربط بموظف'),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: linked ? () => _unlink(id) : null,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red.shade700,
                                      ),
                                      child: const Text('فك الربط'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                      itemCount: rows.length,
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF6B7280)),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.linked});
  final bool linked;

  @override
  Widget build(BuildContext context) {
    final color = linked ? const Color(0xFF059669) : const Color(0xFF6B7280);
    final text = linked ? 'مربوط' : 'غير مربوط';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmployeePickerSheet extends StatefulWidget {
  const _EmployeePickerSheet({required this.employees});

  final List<EmployeeModel> employees;

  @override
  State<_EmployeePickerSheet> createState() => _EmployeePickerSheetState();
}

class _EmployeePickerSheetState extends State<_EmployeePickerSheet> {
  final TextEditingController _q = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<EmployeeModel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.employees;
    return widget.employees.where((e) {
      final name = e.employeeName.toLowerCase();
      final id = e.id.toString();
      return name.contains(q) || id.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 14.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'اختر موظف',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          TextField(
            controller: _q,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'searchEmployee'.tr,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            height: 420.h,
            child: rows.isEmpty
                ? Center(child: Text('noData'.tr))
                : ListView.separated(
                    itemBuilder: (_, i) {
                      final e = rows[i];
                      final title = e.employeeName;
                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        title: Text(title),
                        subtitle: Text('#${e.id}'),
                        onTap: () => Navigator.pop(context, e),
                      );
                    },
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemCount: rows.length,
                  ),
          ),
        ],
      ),
    );
  }
}

