import 'package:flutter/material.dart';

import '../../../../core/helpers/app_failure_notice.dart';
import '../../../../core/helpers/app_success_notice.dart';
import '../../data/smart_home_api_service.dart';

class EmployeeSmartDevicePermissionsScreen extends StatefulWidget {
  const EmployeeSmartDevicePermissionsScreen({
    Key? key,
    required this.employeeId,
    required this.employeeName,
  }) : super(key: key);

  final int employeeId;
  final String employeeName;

  @override
  State<EmployeeSmartDevicePermissionsScreen> createState() =>
      _EmployeeSmartDevicePermissionsScreenState();
}

class _EmployeeSmartDevicePermissionsScreenState
    extends State<EmployeeSmartDevicePermissionsScreen> {
  final api = SmartHomeApiService();
  var devices = <SmartEmployeeDevicePermissionModel>[];
  var loading = true;
  var saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await api.getEmployeeDevices(widget.employeeId);
      if (!mounted) return;
      setState(() => devices = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _replace(int index, SmartEmployeeDevicePermissionModel item) {
    setState(() => devices[index] = item);
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await api.saveEmployeeDevices(
        employeeId: widget.employeeId,
        devices: devices,
      );
      if (!mounted) return;
      AppSuccessNotice.show(
        context: context,
        title: 'تم الحفظ',
        message: 'تم تحديث أجهزة ${widget.employeeName}',
      );
    } catch (e) {
      if (!mounted) return;
      AppFailureNotice.show(
        context: context,
        title: 'تعذر حفظ الصلاحيات',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أجهزة المنزل الذكي'),
        actions: [
          TextButton.icon(
            onPressed: saving || loading || error != null ? null : _save,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: const Text('حفظ'),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        loading = true;
                        error = null;
                      });
                      _load();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                )
              : devices.isEmpty
                  ? const Center(child: Text('لا توجد أجهزة متاحة.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = devices[index];
                        return Card(
                          child: Column(
                            children: [
                              CheckboxListTile(
                                value: item.canView,
                                title: Text(item.name),
                                subtitle: Text(item.roomName.isEmpty
                                    ? 'بدون غرفة'
                                    : item.roomName),
                                secondary: const Icon(Icons.devices_rounded),
                                onChanged: saving
                                    ? null
                                    : (value) => _replace(
                                          index,
                                          item.copyWith(
                                            canView: value == true,
                                            canControl: value == true
                                                ? item.canControl
                                                : false,
                                            canSchedule: value == true
                                                ? item.canSchedule
                                                : false,
                                          ),
                                        ),
                              ),
                              if (item.canView)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: SwitchListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('تحكم'),
                                          value: item.canControl,
                                          onChanged: saving
                                              ? null
                                              : (value) => _replace(
                                                    index,
                                                    item.copyWith(
                                                      canControl: value,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SwitchListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('جدولة'),
                                          value: item.canSchedule,
                                          onChanged: saving
                                              ? null
                                              : (value) => _replace(
                                                    index,
                                                    item.copyWith(
                                                      canSchedule: value,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
