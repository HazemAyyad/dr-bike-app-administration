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
  var homes = <SmartEmployeeScopePermissionModel>[];
  var rooms = <SmartEmployeeScopePermissionModel>[];
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
      setState(() {
        homes = result.homes;
        rooms = result.rooms;
        devices = result.devices;
      });
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

  void _replaceScope(
      bool isHome, int index, SmartEmployeeScopePermissionModel item) {
    setState(() => (isHome ? homes : rooms)[index] = item);
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await api.saveEmployeeDevices(
        employeeId: widget.employeeId,
        homes: homes,
        rooms: rooms,
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
        title: const Text('صلاحيات المنزل الذكي'),
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
              : homes.isEmpty && rooms.isEmpty && devices.isEmpty
                  ? const Center(child: Text('لا توجد أماكن أو أجهزة متاحة.'))
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.info_outline_rounded),
                            title: Text('الصلاحيات تراكمية'),
                            subtitle: Text(
                              'صلاحية المكان تشمل كل غرفه وأجهزته، وصلاحية الغرفة تشمل كل أجهزتها.',
                            ),
                          ),
                        ),
                        const _SectionTitle('أماكن وشركات'),
                        ...homes.asMap().entries.map((entry) => _PermissionCard(
                              name: entry.value.name,
                              subtitle: entry.value.subtitle,
                              icon: entry.value.type == 'company'
                                  ? Icons.business_rounded
                                  : Icons.home_rounded,
                              canView: entry.value.canView,
                              canControl: entry.value.canControl,
                              canSchedule: entry.value.canSchedule,
                              saving: saving,
                              onChanged: (view, control, schedule) =>
                                  _replaceScope(
                                      true,
                                      entry.key,
                                      entry.value.copyWith(
                                          canView: view,
                                          canControl: control,
                                          canSchedule: schedule)),
                            )),
                        const _SectionTitle('الغرف'),
                        ...rooms.asMap().entries.map((entry) => _PermissionCard(
                              name: entry.value.name,
                              subtitle: entry.value.subtitle,
                              icon: Icons.meeting_room_rounded,
                              canView: entry.value.canView,
                              canControl: entry.value.canControl,
                              canSchedule: entry.value.canSchedule,
                              saving: saving,
                              onChanged: (view, control, schedule) =>
                                  _replaceScope(
                                      false,
                                      entry.key,
                                      entry.value.copyWith(
                                          canView: view,
                                          canControl: control,
                                          canSchedule: schedule)),
                            )),
                        const _SectionTitle('أجهزة منفردة'),
                        ...devices.asMap().entries.map((entry) {
                          final item = entry.value;
                          return _PermissionCard(
                            name: item.name,
                            subtitle: [
                              item.roomName,
                              item.homeName,
                              item.ownerName
                            ].where((value) => value.isNotEmpty).join(' • '),
                            icon: Icons.devices_rounded,
                            canView: item.canView,
                            canControl: item.canControl,
                            canSchedule: item.canSchedule,
                            saving: saving,
                            onChanged: (view, control, schedule) => _replace(
                                entry.key,
                                item.copyWith(
                                    canView: view,
                                    canControl: control,
                                    canSchedule: schedule)),
                          );
                        }),
                      ],
                    ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      );
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard(
      {required this.name,
      required this.subtitle,
      required this.icon,
      required this.canView,
      required this.canControl,
      required this.canSchedule,
      required this.saving,
      required this.onChanged});
  final String name;
  final String subtitle;
  final IconData icon;
  final bool canView;
  final bool canControl;
  final bool canSchedule;
  final bool saving;
  final void Function(bool, bool, bool) onChanged;

  @override
  Widget build(BuildContext context) => Card(
        child: Column(children: [
          CheckboxListTile(
            value: canView,
            title: Text(name),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
            secondary: Icon(icon),
            onChanged: saving
                ? null
                : (value) => onChanged(
                    value == true,
                    value == true ? canControl : false,
                    value == true ? canSchedule : false),
          ),
          if (canView)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Expanded(
                    child: SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('تحكم'),
                        value: canControl,
                        onChanged: saving
                            ? null
                            : (value) => onChanged(true, value, canSchedule))),
                const SizedBox(width: 12),
                Expanded(
                    child: SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('جدولة'),
                        value: canSchedule,
                        onChanged: saving
                            ? null
                            : (value) => onChanged(true, canControl, value))),
              ]),
            ),
        ]),
      );
}
