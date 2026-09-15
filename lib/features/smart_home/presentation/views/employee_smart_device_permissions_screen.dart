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
  final searchController = TextEditingController();
  var homes = <SmartEmployeeScopePermissionModel>[];
  var rooms = <SmartEmployeeScopePermissionModel>[];
  var devices = <SmartEmployeeDevicePermissionModel>[];
  var loading = true;
  var saving = false;
  String? error;
  var searchQuery = '';
  var homesExpanded = true;
  var roomsExpanded = false;
  var devicesExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool _matches(String name, String subtitle) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    return '$name $subtitle'.toLowerCase().contains(query);
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
    final filteredHomes = homes.asMap().entries.where(
          (entry) => _matches(entry.value.name, entry.value.subtitle),
        );
    final filteredRooms = rooms.asMap().entries.where(
          (entry) => _matches(entry.value.name, entry.value.subtitle),
        );
    final filteredDevices = devices.asMap().entries.where((entry) {
      final item = entry.value;
      return _matches(
        item.name,
        [item.roomName, item.homeName, item.ownerName].join(' '),
      );
    });
    final hasSearchResults = filteredHomes.isNotEmpty ||
        filteredRooms.isNotEmpty ||
        filteredDevices.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
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
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: .55),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الصلاحيات تراكمية',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'المكان يشمل غرفه وأجهزته، والغرفة تشمل جميع أجهزتها.',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: searchController,
                          onChanged: (value) => setState(() {
                            searchQuery = value;
                            if (value.trim().isNotEmpty) {
                              homesExpanded = true;
                              roomsExpanded = true;
                              devicesExpanded = true;
                            }
                          }),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن مكان، غرفة أو جهاز',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'مسح البحث',
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() => searchQuery = '');
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!hasSearchResults)
                          const _EmptySearchResult()
                        else ...[
                          if (searchQuery.isEmpty || filteredHomes.isNotEmpty)
                            _PermissionSection(
                              title: 'أماكن وشركات',
                              icon: Icons.home_work_outlined,
                              totalCount: filteredHomes.length,
                              selectedCount: filteredHomes
                                  .where((entry) => entry.value.canView)
                                  .length,
                              expanded: searchQuery.isNotEmpty || homesExpanded,
                              onExpansionChanged: (value) =>
                                  setState(() => homesExpanded = value),
                              children: filteredHomes
                                  .map((entry) => _PermissionCard(
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
                                      ))
                                  .toList(growable: false),
                            ),
                          if (searchQuery.isEmpty || filteredRooms.isNotEmpty)
                            _PermissionSection(
                              title: 'الغرف',
                              icon: Icons.meeting_room_outlined,
                              totalCount: filteredRooms.length,
                              selectedCount: filteredRooms
                                  .where((entry) => entry.value.canView)
                                  .length,
                              expanded: searchQuery.isNotEmpty || roomsExpanded,
                              onExpansionChanged: (value) =>
                                  setState(() => roomsExpanded = value),
                              children: filteredRooms
                                  .map((entry) => _PermissionCard(
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
                                      ))
                                  .toList(growable: false),
                            ),
                          if (searchQuery.isEmpty || filteredDevices.isNotEmpty)
                            _PermissionSection(
                              title: 'أجهزة منفردة',
                              icon: Icons.devices_other_outlined,
                              totalCount: filteredDevices.length,
                              selectedCount: filteredDevices
                                  .where((entry) => entry.value.canView)
                                  .length,
                              expanded:
                                  searchQuery.isNotEmpty || devicesExpanded,
                              onExpansionChanged: (value) =>
                                  setState(() => devicesExpanded = value),
                              children: filteredDevices.map((entry) {
                                final item = entry.value;
                                return _PermissionCard(
                                  name: item.name,
                                  subtitle: [
                                    item.roomName,
                                    item.homeName,
                                    item.ownerName
                                  ]
                                      .where((value) => value.isNotEmpty)
                                      .join(' • '),
                                  icon: Icons.devices_rounded,
                                  canView: item.canView,
                                  canControl: item.canControl,
                                  canSchedule: item.canSchedule,
                                  saving: saving,
                                  onChanged: (view, control, schedule) =>
                                      _replace(
                                          entry.key,
                                          item.copyWith(
                                              canView: view,
                                              canControl: control,
                                              canSchedule: schedule)),
                                );
                              }).toList(growable: false),
                            ),
                        ],
                      ],
                    ),
    );
  }
}

class _PermissionSection extends StatelessWidget {
  const _PermissionSection({
    required this.title,
    required this.icon,
    required this.totalCount,
    required this.selectedCount,
    required this.expanded,
    required this.onExpansionChanged,
    required this.children,
  });

  final String title;
  final IconData icon;
  final int totalCount;
  final int selectedCount;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: ExpansionTile(
          key: ValueKey('$title:$expanded'),
          initiallyExpanded: expanded,
          onExpansionChanged: onExpansionChanged,
          leading: CircleAvatar(child: Icon(icon, size: 20)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(
            selectedCount == 0
                ? '$totalCount متاح'
                : '$selectedCount محدد من $totalCount',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          children: children.isEmpty
              ? const [
                  Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('لا توجد نتائج في هذا التصنيف'),
                  ),
                ]
              : children,
        ),
      );
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 44),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 46,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 10),
            const Text(
              'لا توجد نتائج مطابقة',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
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
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: canView
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: .22)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: canView
                ? Theme.of(context).colorScheme.primary.withValues(alpha: .25)
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(children: [
          CheckboxListTile(
            value: canView,
            title: Text(name),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
            secondary: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              child: Icon(icon, size: 20),
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            onChanged: saving
                ? null
                : (value) => onChanged(
                    value == true,
                    value == true ? canControl : false,
                    value == true ? canSchedule : false),
          ),
          if (canView)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
