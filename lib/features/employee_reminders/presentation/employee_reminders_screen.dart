import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_tab_bar.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:doctorbike/core/helpers/scroll_date_picker_sheet.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:doctorbike/core/services/theme_service.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:doctorbike/features/admin/create_tasks/presentation/widgets/horizontal_time_picker_sheet.dart';
import 'package:doctorbike/features/admin/create_tasks/presentation/widgets/task_form_section_card.dart';
import 'package:doctorbike/features/employee_reminders/data/employee_reminder_models.dart';
import 'package:doctorbike/features/employee_reminders/data/employee_reminders_datasource.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EmployeeRemindersScreen extends StatefulWidget {
  final bool isAdmin;

  const EmployeeRemindersScreen({Key? key, required this.isAdmin})
      : super(key: key);

  @override
  State<EmployeeRemindersScreen> createState() =>
      _EmployeeRemindersScreenState();
}

class _EmployeeRemindersScreenState extends State<EmployeeRemindersScreen> {
  static const Color alertColor = Color(0xff0f766e);
  static const Color alertLightColor = Color(0xffe6f4f1);

  late final EmployeeRemindersDatasource datasource;
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final selectedEmployees = <int>{};
  final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  List<EmployeeReminderItem> reminders = [];
  List<ReminderEmployeeOption> employees = [];
  DateTime scheduledAt = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay scheduledTime =
      TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
  String repeatType = 'once';
  final repeatDays = <String>{};
  final currentTab = 0.obs;
  final tabs = ['activeReminders', 'completedReminders'].obs;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    datasource = EmployeeRemindersDatasource(api: Get.find<DioConsumer>());
    _load();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        widget.isAdmin
            ? datasource.getAdminReminders(
                status: currentTab.value == 1 ? 'done' : 'active',
              )
            : datasource.getMyReminders(
                status: currentTab.value == 1 ? 'done' : null,
              ),
        if (widget.isAdmin) datasource.getEmployees(),
      ]);
      reminders = results.first as List<EmployeeReminderItem>;
      if (widget.isAdmin && results.length > 1) {
        employees = results[1] as List<ReminderEmployeeOption>;
      }
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _mergeScheduledDateTime() {
    scheduledAt = DateTime(
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );
  }

  Future<void> _pickScheduledDate(
      BuildContext context, StateSetter setSheet) async {
    final picked = await ScrollDatePickerSheet.show(
      context,
      initial: scheduledAt,
      title: 'date',
    );
    if (picked == null) return;
    setState(() {
      scheduledAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );
    });
    setSheet(() {});
  }

  Future<void> _pickScheduledTime(
      BuildContext context, StateSetter setSheet) async {
    final picked = await HorizontalTimePickerSheet.show(
      context,
      initial: scheduledTime,
    );
    if (picked == null) return;
    setState(() {
      scheduledTime = picked;
      _mergeScheduledDateTime();
    });
    setSheet(() {});
  }

  Future<void> _createReminder() async {
    if (saving) return;
    if (!(formKey.currentState?.validate() ?? false) ||
        selectedEmployees.isEmpty) {
      _message('reminderRequiredFields'.tr);
      return;
    }

    setState(() => saving = true);
    try {
      await datasource.createReminder(
        employeeIds: selectedEmployees.toList(),
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        scheduledAt: scheduledAt,
        repeatType: repeatType,
        repeatDays: repeatDays.toList(),
      );
      titleController.clear();
      descriptionController.clear();
      selectedEmployees.clear();
      repeatType = 'once';
      repeatDays.clear();
      scheduledAt = DateTime.now().add(const Duration(hours: 1));
      scheduledTime = TimeOfDay.fromDateTime(scheduledAt);
      await _load();
      if (mounted) Navigator.pop(context);
      _message('reminderSaved'.tr);
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _deleteReminder(int id) async {
    try {
      await datasource.deleteReminder(id);
      await _load();
      _message('reminderDeleted'.tr);
    } catch (e) {
      _message(e.toString());
    }
  }

  Future<void> _confirmDeleteReminder(EmployeeReminderItem reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('deleteReminderTitle'.tr),
        content: Text(
          'deleteReminderMessage'.trParams({'title': reminder.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteReminder(reminder.id);
    }
  }

  Future<void> _doneReminder(int id) async {
    try {
      await datasource.markDone(id);
      await _load();
      _message('reminderDone'.tr);
    } catch (e) {
      _message(e.toString());
    }
  }

  Future<void> _snoozeReminder(int id, {int minutes = 30}) async {
    try {
      await datasource.snooze(id, minutes: minutes);
      await _load();
      _message('reminderSnoozed'.tr);
    } catch (e) {
      _message(e.toString());
    }
  }

  void _changeTab(int index) {
    currentTab.value = index;
    _load();
  }

  Future<void> _showSnoozeSheet(EmployeeReminderItem reminder) async {
    final minutes = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'snoozeUntil'.tr,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.operationalNavy,
                ),
              ),
              SizedBox(height: 10.h),
              for (final option in const [10, 30, 60, 120])
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(
                    'snoozeMinutes'.trParams({'minutes': '$option'}),
                  ),
                  onTap: () => Navigator.pop(context, option),
                ),
            ],
          ),
        ),
      ),
    );
    if (minutes != null) {
      await _snoozeReminder(reminder.id, minutes: minutes);
    }
  }

  Future<void> _showHistory(EmployeeReminderItem reminder) async {
    try {
      final items = await datasource.getHistory(reminder.id);
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .65,
          minChildSize: .35,
          maxChildSize: .9,
          builder: (context, scrollController) => ListView.separated(
            controller: scrollController,
            padding: EdgeInsets.all(14.w),
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => Divider(height: 14.h),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  'reminderHistory'.tr,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.operationalNavy,
                  ),
                );
              }
              final item = items[index - 1];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: alertLightColor,
                  child: Icon(Icons.history, color: alertColor, size: 18.sp),
                ),
                title: Text(item.title.isEmpty ? item.event.tr : item.title),
                subtitle: Text(
                  [
                    if (item.employeeName.isNotEmpty) item.employeeName,
                    if (item.actorName.isNotEmpty) item.actorName,
                    dateFormat.format(item.createdAt),
                  ].join(' · '),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      _message(e.toString());
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.92,
                ),
                decoration: BoxDecoration(
                  color: AppColors.operationalSurface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(18.r)),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: const Color(0xffd1d5db),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 10.h, 6.w, 4.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'addEmployeeReminder'.tr,
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.operationalNavy,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: Icon(Icons.close_rounded, size: 24.sp),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 12.h),
                          child: Column(
                            children: [
                              TaskFormSectionCard(
                                compact: true,
                                title: 'taskInfo',
                                child: Column(
                                  children: [
                                    CustomTextField(
                                      isRequired: true,
                                      label: 'reminderTitle',
                                      hintText: 'reminderTitle',
                                      controller: titleController,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: TextInputAction.newline,
                                      minLines: 2,
                                      maxLines: 5,
                                    ),
                                    SizedBox(height: 6.h),
                                    CustomTextField(
                                      label: 'reminderDescription',
                                      hintText: 'reminderDescription',
                                      controller: descriptionController,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: TextInputAction.newline,
                                      minLines: 2,
                                      maxLines: 6,
                                      validator: (_) => null,
                                    ),
                                  ],
                                ),
                              ),
                              TaskFormSectionCard(
                                compact: true,
                                title: 'employeeName',
                                child: _ReminderEmployeeSelector(
                                  employees: employees,
                                  selectedEmployees: selectedEmployees,
                                  onChanged: () {
                                    setState(() {});
                                    setSheetState(() {});
                                  },
                                ),
                              ),
                              TaskFormSectionCard(
                                compact: true,
                                title: 'taskReminder',
                                child: _ReminderDateTimeField(
                                  date: scheduledAt,
                                  time: scheduledTime,
                                  onDateTap: () => _pickScheduledDate(
                                      context, setSheetState),
                                  onTimeTap: () => _pickScheduledTime(
                                      context, setSheetState),
                                ),
                              ),
                              TaskFormSectionCard(
                                compact: true,
                                title: 'taskRepeat',
                                child: _RepeatSelector(
                                  value: repeatType,
                                  selectedDays: repeatDays,
                                  onChanged: (value) {
                                    setState(() => repeatType = value);
                                    setSheetState(() {});
                                  },
                                  onDaysChanged: () {
                                    setState(() {});
                                    setSheetState(() {});
                                  },
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton(
                                      text: 'cancel',
                                      onPressed: () =>
                                          Navigator.pop(sheetContext),
                                      color: const Color(0xffd1d5db),
                                      textColor: AppColors.operationalNavy,
                                      height: 42.h,
                                      isSafeArea: false,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: AppButton(
                                      text: 'saveReminder',
                                      onPressed:
                                          saving ? null : _createReminder,
                                      color: Colors.black,
                                      height: 42.h,
                                      isSafeArea: false,
                                      widget: saving
                                          ? SizedBox(
                                              width: 16.w,
                                              height: 16.w,
                                              child:
                                                  const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Icon(
                                              Icons.save_rounded,
                                              size: 17.sp,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.operationalSurface,
      appBar: CustomAppBar(
        title: 'employeeReminders',
        action: false,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: _openCreateSheet,
              backgroundColor: Colors.black,
              child: const Icon(Icons.add),
            )
          : null,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: AppTabs(
                      tabs: tabs,
                      currentTab: currentTab,
                      changeTab: _changeTab,
                    ),
                  ),
                  if (reminders.isEmpty)
                    SliverFillRemaining(
                      child: ListView(
                        children: [
                          SizedBox(height: 140.h),
                          Icon(
                            Icons.notifications_none,
                            size: 64.sp,
                            color: Colors.grey.shade500,
                          ),
                          SizedBox(height: 12.h),
                          Center(child: Text('noReminders'.tr)),
                        ],
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      sliver: SliverList.separated(
                        itemCount: reminders.length,
                        separatorBuilder: (_, __) => SizedBox(height: 6.h),
                        itemBuilder: (context, index) => _ReminderCard(
                          reminder: reminders[index],
                          isAdmin: widget.isAdmin,
                          dateFormat: dateFormat,
                          onDelete: () =>
                              _confirmDeleteReminder(reminders[index]),
                          onDone: () => _doneReminder(reminders[index].id),
                          onSnooze: () => _showSnoozeSheet(reminders[index]),
                          onHistory: () => _showHistory(reminders[index]),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(child: SizedBox(height: 72.h)),
                ],
              ),
            ),
    );
  }
}

class _ReminderEmployeeSelector extends StatelessWidget {
  const _ReminderEmployeeSelector({
    required this.employees,
    required this.selectedEmployees,
    required this.onChanged,
  });

  final List<ReminderEmployeeOption> employees;
  final Set<int> selectedEmployees;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) {
      return Center(child: Text('noData'.tr));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'selectMultipleEmployeesHint'.tr,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  color: AppColors.customGreyColor5,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                if (selectedEmployees.length == employees.length) {
                  selectedEmployees.clear();
                } else {
                  selectedEmployees
                    ..clear()
                    ..addAll(employees.map((e) => e.id));
                }
                onChanged();
              },
              icon: Icon(Icons.done_all, size: 16.sp),
              label: Text(
                selectedEmployees.length == employees.length
                    ? 'clearSelection'.tr
                    : 'selectAll'.tr,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 72.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: employees.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final employee = employees[index];
              final selected = selectedEmployees.contains(employee.id);
              return _EmployeeAvatarTile(
                name: employee.name,
                image: employee.image,
                selected: selected,
                onTap: () {
                  if (selected) {
                    selectedEmployees.remove(employee.id);
                  } else {
                    selectedEmployees.add(employee.id);
                  }
                  onChanged();
                },
              );
            },
          ),
        ),
        if (selectedEmployees.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(
            'employeesSelectedCount'
                .tr
                .replaceAll('@count', '${selectedEmployees.length}'),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: _EmployeeRemindersScreenState.alertColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmployeeAvatarTile extends StatelessWidget {
  const _EmployeeAvatarTile({
    required this.name,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _EmployeeRemindersScreenState.alertColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: SizedBox(
          width: 60.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 52.w,
                height: 52.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? color
                              : AppColors.operationalCardBorder,
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: selected
                            ? _EmployeeRemindersScreenState.alertLightColor
                            : AppColors.operationalSurface,
                        backgroundImage: ShowNetImage.getPhoto(image).isNotEmpty
                            ? CachedNetworkImageProvider(
                                ShowNetImage.getPhoto(image),
                              )
                            : null,
                        child: ShowNetImage.getPhoto(image).isEmpty
                            ? Icon(
                                Icons.person,
                                color: selected
                                    ? color
                                    : AppColors.customGreyColor5,
                                size: 19.sp,
                              )
                            : null,
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 18.w,
                          height: 18.w,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check,
                              size: 11.sp, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? color : AppColors.customGreyColor5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderDateTimeField extends StatelessWidget {
  const _ReminderDateTimeField({
    required this.date,
    required this.time,
    required this.onDateTap,
    required this.onTimeTap,
  });

  final DateTime date;
  final TimeOfDay time;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'reminderTime'.tr,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.operationalNavy,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Expanded(
              child: _PickerTile(
                icon: Icons.calendar_today_outlined,
                value: showData(date),
                onTap: onDateTap,
              ),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: _PickerTile(
                icon: Icons.access_time_rounded,
                value: _formatTime(time),
                onTap: onTimeTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'morning'.tr : 'evening'.tr;
    return '${hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')} $period';
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.whiteColor,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.operationalCardBorder),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16.sp,
                color: _EmployeeRemindersScreenState.alertColor,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.operationalNavy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepeatSelector extends StatelessWidget {
  const _RepeatSelector({
    required this.value,
    required this.selectedDays,
    required this.onChanged,
    required this.onDaysChanged,
  });

  final String value;
  final Set<String> selectedDays;
  final ValueChanged<String> onChanged;
  final VoidCallback onDaysChanged;

  static const types = ['once', 'daily', 'weekly', 'monthly'];
  static const weekdays = [
    'saturday',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          children: types.map((type) {
            final selected = value == type;
            return GestureDetector(
              onTap: () => onChanged(type),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: selected
                      ? _EmployeeRemindersScreenState.alertColor
                      : AppColors.operationalSurface,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: selected
                        ? _EmployeeRemindersScreenState.alertColor
                        : AppColors.operationalCardBorder,
                  ),
                ),
                child: Text(
                  ('repeat_$type').tr,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.operationalNavy,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (value == 'weekly') ...[
          SizedBox(height: 10.h),
          Text(
            'selectWeekdays'.tr,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.customGreyColor5,
            ),
          ),
          SizedBox(height: 6.h),
          _WeekdayDragSelector(
            weekdays: weekdays,
            selectedDays: selectedDays,
            onChanged: onDaysChanged,
          ),
        ],
      ],
    );
  }

  static String _weekdayShort(String day) {
    switch (day) {
      case 'saturday':
        return 'sat'.tr;
      case 'sunday':
        return 'sun'.tr;
      case 'monday':
        return 'mon'.tr;
      case 'tuesday':
        return 'tue'.tr;
      case 'wednesday':
        return 'wed'.tr;
      case 'thursday':
        return 'thu'.tr;
      case 'friday':
        return 'fri'.tr;
      default:
        return day.tr;
    }
  }
}

class _WeekdayDragSelector extends StatefulWidget {
  const _WeekdayDragSelector({
    required this.weekdays,
    required this.selectedDays,
    required this.onChanged,
  });

  final List<String> weekdays;
  final Set<String> selectedDays;
  final VoidCallback onChanged;

  @override
  State<_WeekdayDragSelector> createState() => _WeekdayDragSelectorState();
}

class _WeekdayDragSelectorState extends State<_WeekdayDragSelector> {
  bool _dragShouldSelect = true;

  void _applyAt(Offset localPosition, double width, {bool start = false}) {
    if (width <= 0 || widget.weekdays.isEmpty) return;
    final index = (localPosition.dx / width * widget.weekdays.length)
        .floor()
        .clamp(0, widget.weekdays.length - 1);
    final day = widget.weekdays[index];

    if (start) {
      _dragShouldSelect = !widget.selectedDays.contains(day);
    }

    final changed = _dragShouldSelect
        ? widget.selectedDays.add(day)
        : widget.selectedDays.remove(day);
    if (changed) {
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _applyAt(
            details.localPosition,
            constraints.maxWidth,
            start: true,
          ),
          onPanUpdate: (details) =>
              _applyAt(details.localPosition, constraints.maxWidth),
          child: Row(
            children: widget.weekdays.map((day) {
              final selected = widget.selectedDays.contains(day);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.r),
                    onTap: () {
                      if (selected) {
                        widget.selectedDays.remove(day);
                      } else {
                        widget.selectedDays.add(day);
                      }
                      widget.onChanged();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: selected
                            ? _EmployeeRemindersScreenState.alertColor
                            : AppColors.operationalSurface,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: selected
                              ? _EmployeeRemindersScreenState.alertColor
                              : AppColors.operationalCardBorder,
                        ),
                      ),
                      child: Text(
                        _RepeatSelector._weekdayShort(day),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? Colors.white
                              : AppColors.operationalNavy,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final EmployeeReminderItem reminder;
  final bool isAdmin;
  final DateFormat dateFormat;
  final VoidCallback onDelete;
  final VoidCallback onDone;
  final VoidCallback onSnooze;
  final VoidCallback onHistory;

  const _ReminderCard({
    required this.reminder,
    required this.isAdmin,
    required this.dateFormat,
    required this.onDelete,
    required this.onDone,
    required this.onSnooze,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final isSnoozed = reminder.status == 'snoozed';
    final color = isSnoozed
        ? const Color(0xfff59f00)
        : _EmployeeRemindersScreenState.alertColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.customGreyColor : AppColors.whiteColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.operationalCardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.operationalNavy.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 16.r,
                    backgroundColor: AppColors.operationalSurface,
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: color,
                      size: 17.sp,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                reminder.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  color: isDark
                                      ? AppColors.whiteColor
                                      : AppColors.operationalNavy,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            _TimeLeftLabel(
                              scheduledAt: _displayDate(reminder),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          [
                            if (isAdmin && reminder.employeeName.isNotEmpty)
                              reminder.employeeName,
                            '${_dateLabel(reminder)}: ${dateFormat.format(_displayDate(reminder))}',
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            height: 1.2,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin) ...[
                    SizedBox(width: 4.w),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'reminderHistory'.tr,
                      onPressed: onHistory,
                      icon: Icon(
                        Icons.history,
                        color: _EmployeeRemindersScreenState.alertColor,
                        size: 20.sp,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'delete'.tr,
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ],
              ),
              if (reminder.description.isNotEmpty) ...[
                SizedBox(height: 6.h),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    reminder.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.customGreyColor5,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 6.h),
              Row(
                children: [
                  _MiniChip(
                    label: ('reminderStatus_${reminder.status}').tr,
                    color: color,
                  ),
                  SizedBox(width: 4.w),
                  _MiniChip(
                    label: ('repeat_${reminder.repeatType}').tr,
                    color: AppColors.operationalNavy,
                    icon: Icons.repeat,
                  ),
                  const Spacer(),
                  if (!isAdmin) ...[
                    _SmallActionButton(
                      icon: Icons.schedule,
                      label: 'snooze'.tr,
                      onTap: onSnooze,
                    ),
                    SizedBox(width: 5.w),
                    _SmallActionButton(
                      icon: Icons.check,
                      label: 'markDone'.tr,
                      color: _EmployeeRemindersScreenState.alertColor,
                      onTap: onDone,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static DateTime _displayDate(EmployeeReminderItem reminder) {
    if (reminder.status == 'snoozed' && reminder.snoozedUntil != null) {
      return reminder.snoozedUntil!;
    }
    return reminder.scheduledAt;
  }

  static String _dateLabel(EmployeeReminderItem reminder) {
    return reminder.status == 'snoozed' && reminder.snoozedUntil != null
        ? 'snoozedUntil'.tr
        : 'dueDate'.tr;
  }
}

class _TimeLeftLabel extends StatelessWidget {
  const _TimeLeftLabel({required this.scheduledAt});

  final DateTime scheduledAt;

  @override
  Widget build(BuildContext context) {
    final label = _formatTimeLeft(scheduledAt);
    final color = _colorFor(scheduledAt);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  static String _formatTimeLeft(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.inSeconds <= 0) return 'overdue'.tr;
    if (diff.inDays >= 1) return '${diff.inDays} ${'days'.tr}';
    if (diff.inHours >= 1) return '${diff.inHours} ${'hours'.tr}';
    final mins = diff.inMinutes.clamp(1, 59);
    return '$mins ${'minute'.tr}';
  }

  static Color _colorFor(DateTime date) {
    final hours = date.difference(DateTime.now()).inHours;
    if (hours <= 0) return AppColors.redColor;
    if (hours <= 24) return AppColors.customOrange3;
    return AppColors.customGreen1;
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10.sp, color: color),
            SizedBox(width: 2.w),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.customGreyColor5;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: effectiveColor.withValues(alpha: .35)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 11.sp, color: effectiveColor),
            SizedBox(width: 2.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5.sp,
                fontWeight: FontWeight.w700,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
