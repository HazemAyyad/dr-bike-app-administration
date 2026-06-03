import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
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
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: CustomAppBar(
        title: 'fingerprintDeviceUsers',
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
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
                  Icon(Icons.error_outline, size: 40.sp, color: Colors.red.shade400),
                  SizedBox(height: 12.h),
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

        return RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_deviceName.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Text(
                            _deviceName,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      Text(
                        'fingerprintDeviceUsersDesc'.tr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryTile(
                              label: 'total'.tr,
                              value: '$_total',
                              color: const Color(0xFF2563EB),
                              bg: const Color(0xFFEFF6FF),
                              icon: Icons.grid_view_rounded,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _SummaryTile(
                              label: 'fingerprintLinked'.tr,
                              value: '$_linked',
                              color: const Color(0xFF059669),
                              bg: const Color(0xFFECFDF5),
                              icon: Icons.link_rounded,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _SummaryTile(
                              label: 'fingerprintUnlinked'.tr,
                              value: '$_unlinked',
                              color: const Color(0xFF6B7280),
                              bg: const Color(0xFFF3F4F6),
                              icon: Icons.link_off_rounded,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      TextField(
                        onChanged: (v) => _query.value = v,
                        decoration: InputDecoration(
                          hintText: 'search'.tr,
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: cardBg,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Obx(() {
                        final f = _filter.value;
                        return Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            _FilterChip(
                              label: 'all'.tr,
                              selected: f == 'all',
                              onTap: () => _filter.value = 'all',
                            ),
                            _FilterChip(
                              label: 'fingerprintLinked'.tr,
                              selected: f == 'linked',
                              onTap: () => _filter.value = 'linked',
                            ),
                            _FilterChip(
                              label: 'fingerprintUnlinked'.tr,
                              selected: f == 'unlinked',
                              onTap: () => _filter.value = 'unlinked',
                            ),
                          ],
                        );
                      }),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
              ),
              if (rows.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.badge_outlined, size: 48.sp, color: textSecondary),
                        SizedBox(height: 8.h),
                        Text('noData'.tr, style: TextStyle(color: textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final u = rows[i];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: _UserCard(
                            user: u,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onLink: () => _link(u['device_user_id']?.toString() ?? ''),
                            onUnlink: () => _unlink(u['device_user_id']?.toString() ?? ''),
                          ),
                        );
                      },
                      childCount: rows.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final Color bg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(height: 6.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryColor : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primaryColor : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onLink,
    required this.onUnlink,
  });

  final Map<String, dynamic> user;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onLink;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final id = user['device_user_id']?.toString() ?? '';
    final name = user['name']?.toString().trim() ?? '';
    final emp = user['linked_employee_name']?.toString().trim();
    final linked = user['status']?.toString() == 'linked';
    final statusColor =
        linked ? const Color(0xFF059669) : const Color(0xFF9CA3AF);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5.w,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadiusDirectional.horizontal(
                  start: Radius.circular(16.r),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44.w,
                          height: 44.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            id,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isNotEmpty ? name : 'PIN $id',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              if (name.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 2.h),
                                  child: Text(
                                    'PIN: $id',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 6.h),
                              Row(
                                children: [
                                  Icon(
                                    linked ? Icons.link_rounded : Icons.link_off_rounded,
                                    size: 14.sp,
                                    color: statusColor,
                                  ),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      linked && emp != null && emp.isNotEmpty
                                          ? '${'fingerprintLinkedWith'.tr}: $emp'
                                          : 'fingerprintUnlinked'.tr,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: linked ? statusColor : textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(linked: linked),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onLink,
                            icon: Icon(
                              linked ? Icons.swap_horiz_rounded : Icons.person_add_alt_1_rounded,
                              size: 18,
                            ),
                            label: Text(
                              linked ? 'changeLink'.tr : 'linkToEmployee'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: linked ? onUnlink : null,
                            icon: const Icon(Icons.link_off_rounded, size: 18),
                            label: Text('unlinkEmployee'.tr),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    final text = linked ? 'fingerprintLinked'.tr : 'fingerprintUnlinked'.tr;
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
                  'selectEmployee'.tr,
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
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEFF6FF),
                          child: Text(
                            '${e.id}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('#${e.id}'),
                        trailing: const Icon(Icons.chevron_right_rounded),
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

