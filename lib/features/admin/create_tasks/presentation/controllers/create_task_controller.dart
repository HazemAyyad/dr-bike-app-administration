import 'dart:io';
import 'package:doctorbike/core/helpers/helpers.dart';
import 'package:flutter/material.dart';
import '../../../../../core/helpers/haptic_helper.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/helpers/audio_helper.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../core/helpers/proof_media_type.dart';
import '../../../../../core/services/app_settings_service.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../employee_section/domain/usecases/get_all_employee.dart';
import '../../../employee_section/presentation/controllers/employee_service.dart';
import '../../../employee_tasks/presentation/controllers/employee_task_service.dart';
import '../../../special_tasks/presentation/controllers/special_tasks_controller.dart';
import '../../../special_tasks/presentation/controllers/special_tasks_service.dart';
import '../../domain/usecases/creat_special_tasks_usecase.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../../employee_tasks/domain/entities/task_details_entiny.dart';
import '../../../employee_tasks/presentation/controllers/employee_tasks_controller.dart';
import '../../../employee_tasks/presentation/helpers/recurrence_arabic_summary.dart';
import '../helpers/recurrence_config_helper.dart';
import '../widgets/horizontal_time_picker_sheet.dart';

class CreateTaskController extends GetxController {
  CreateTaskUsecase createTaskUsecase;
  GetAllEmployeeUsecase getAllEmployeeUsecase;
  CreatSpecialTasksUsecase creatSpecialTasksUsecase;
  EmployeeService employeeService;
  SpecialTasksService specialTasksService;
  EmployeeTaskService employeeTaskService;

  CreateTaskController({
    required this.createTaskUsecase,
    required this.getAllEmployeeUsecase,
    required this.creatSpecialTasksUsecase,
    required this.employeeService,
    required this.specialTasksService,
    required this.employeeTaskService,
  });

  final formKey = GlobalKey<FormState>();

  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController taskDescriptionController =
      TextEditingController();
  final TextEditingController taskNotesController = TextEditingController();
  final TextEditingController employeeIdConroller = TextEditingController();
  final RxString selectedEmployeeId = ''.obs;
  final RxList<String> selectedEmployeeIds = <String>[].obs;

  /// Single-select (legacy dropdown screen).
  void selectEmployee(String id) {
    selectedEmployeeIds
      ..clear()
      ..add(id);
    selectedEmployeeIds.refresh();
    selectedEmployeeId.value = id;
    employeeIdConroller.text = id;
  }

  /// Multi-select (operational avatar row).
  void toggleEmployee(String id) {
    if (selectedEmployeeIds.contains(id)) {
      selectedEmployeeIds.remove(id);
    } else {
      selectedEmployeeIds.add(id);
    }
    selectedEmployeeIds.refresh();
    if (selectedEmployeeIds.isEmpty) {
      selectedEmployeeId.value = '';
      employeeIdConroller.clear();
    } else {
      selectedEmployeeId.value = selectedEmployeeIds.first;
      employeeIdConroller.text = selectedEmployeeIds.first;
    }
  }

  bool isEmployeeSelected(String id) => selectedEmployeeIds.contains(id);

  List<String> get employeeIdsForApi => selectedEmployeeIds.isNotEmpty
      ? selectedEmployeeIds.toList()
      : (employeeIdConroller.text.isNotEmpty ? [employeeIdConroller.text] : []);
  final TextEditingController subTaskNameController = TextEditingController();
  final TextEditingController subTaskDescriptionController =
      TextEditingController();

  // عدد النقاط
  final TextEditingController pointsController = TextEditingController();

  // المهام الفرعية
  RxList subTasks = [].obs;
  final Rxn<int> editingSubTaskIndex = Rxn<int>();

  void prepareNewSubTask() {
    subTaskNameController.clear();
    subTaskDescriptionController.clear();
    subTaskFile.value = null;
    requireSubTasImage.value = false;
    subTaskProofMediaType.value = ProofMediaType.none;
    editingSubTaskIndex.value = null;
  }

  void startEditSubTask(int index) {
    final task = subTasks[index] as Map;
    subTaskNameController.text = task['subTaskName']?.toString() ?? '';
    subTaskDescriptionController.text =
        task['subTaskdescription']?.toString() ?? '';
    final img = task['subTaskImage'];
    String? localPath;
    if (img is List && img.isNotEmpty) {
      final first = img.first.toString();
      if (first.isNotEmpty && !first.startsWith('http')) {
        localPath = first;
      }
    } else if (img is String && img.isNotEmpty && !img.startsWith('http')) {
      localPath = img;
    }
    subTaskFile.value = localPath != null ? XFile(localPath) : null;
    requireSubTasImage.value = task['imageIsRequired'] == true;
    subTaskProofMediaType.value = ProofMediaType.normalize(
      task['proofMediaType']?.toString(),
      required: requireSubTasImage.value,
    );
    final bonus = task['bonusPoints'] as int? ?? 0;
    subtaskBonusEnabled.value = bonus > 0;
    subtaskBonusPoints.value = bonus;
    editingSubTaskIndex.value = index;
  }

  void reorderSubTasks(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = subTasks.removeAt(oldIndex);
    subTasks.insert(newIndex, item);
  }

  void clearSubTaskForm() {
    subTaskNameController.clear();
    subTaskDescriptionController.clear();
    subTaskFile.value = null;
    requireSubTasImage.value = false;
    subTaskProofMediaType.value = ProofMediaType.none;
    subtaskBonusEnabled.value = false;
    subtaskBonusPoints.value = 0;
    editingSubTaskIndex.value = null;
  }

  // دالة لإضافة أو تحديث مهمة فرعية
  void addSubTask() {
    if (subTaskNameController.text.isEmpty) return;

    final data = <String, dynamic>{
      'subTaskName': subTaskNameController.text,
      'subTaskdescription': subTaskDescriptionController.text,
      'imageIsRequired': subTaskProofMediaType.value != ProofMediaType.none,
      'proofMediaType': subTaskProofMediaType.value,
      'bonusPoints': subtaskBonusEnabled.value ? subtaskBonusPoints.value : 0,
    };
    if (subTaskFile.value != null) {
      data['subTaskImage'] = subTaskFile.value!.path;
    }

    final editIndex = editingSubTaskIndex.value;
    if (editIndex != null && editIndex >= 0 && editIndex < subTasks.length) {
      final existing = subTasks[editIndex] as Map;
      if (existing['subTaskId'] != null) {
        data['subTaskId'] = existing['subTaskId'];
      }
      if (!data.containsKey('subTaskImage') &&
          existing['subTaskImage'] != null) {
        data['subTaskImage'] = existing['subTaskImage'];
      }
      subTasks[editIndex] = data;
    } else {
      subTasks.add(data);
    }
    clearSubTaskForm();
  }

  // متغيرات للتواريخ والأوقات
  final startDate = DateTime.now().obs;
  final endDate = DateTime.now().obs;

  final startTime = TimeOfDay.now().obs;
  final endTime = TimeOfDay.now().obs;

  RxInt isSelected = 0.obs;

  // متغير لعرض التقويم
  final isStartDateCalendarVisible = false.obs;
  final isEndDateCalendarVisible = false.obs;

  // دالة لإظهار/إخفاء التقويم (الشاشة القديمة)
  void toggleCalendar(bool isStartDate) {
    if (isStartDate) {
      isStartDateCalendarVisible.value = !isStartDateCalendarVisible.value;
      isEndDateCalendarVisible.value = false;
    } else {
      isEndDateCalendarVisible.value = !isEndDateCalendarVisible.value;
      isStartDateCalendarVisible.value = false;
    }
  }

  void _mergeStartDateTime() {
    startDate.value = DateTime(
      startDate.value.year,
      startDate.value.month,
      startDate.value.day,
      startTime.value.hour,
      startTime.value.minute,
    );
  }

  void _mergeEndDateTime() {
    endDate.value = DateTime(
      endDate.value.year,
      endDate.value.month,
      endDate.value.day,
      endTime.value.hour,
      endTime.value.minute,
    );
  }

  String _formatTimeLabel(DateTime dt) {
    final t = TimeOfDay.fromDateTime(dt);
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final period = t.period == DayPeriod.am ? 'morning'.tr : 'evening'.tr;
    return '${hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')} $period';
  }

  /// Ensures end is strictly after start; optionally bumps end by 1 hour.
  bool _ensureEndAfterStart({bool autoFix = false}) {
    _mergeStartDateTime();
    _mergeEndDateTime();
    if (endDate.value.isAfter(startDate.value)) {
      return true;
    }
    if (autoFix) {
      endDate.value = startDate.value.add(const Duration(hours: 1));
      endTime.value = TimeOfDay.fromDateTime(endDate.value);
      Get.snackbar(
        'info'.tr,
        'endTimeAutoAdjusted'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return true;
    }
    return false;
  }

  void _initDefaultEndAfterStart() {
    _mergeStartDateTime();
    if (!endDate.value.isAfter(startDate.value)) {
      endDate.value = startDate.value.add(const Duration(hours: 1));
      endTime.value = TimeOfDay.fromDateTime(endDate.value);
    }
  }

  Future<void> pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: Get.locale,
    );
    if (picked != null) {
      startDate.value = DateTime(
        picked.year,
        picked.month,
        picked.day,
        startTime.value.hour,
        startTime.value.minute,
      );
      _mergeStartDateTime();
    }
  }

  Future<void> pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: Get.locale,
    );
    if (picked != null) {
      endDate.value = DateTime(
        picked.year,
        picked.month,
        picked.day,
        endTime.value.hour,
        endTime.value.minute,
      );
      _mergeEndDateTime();
    }
  }

  Future<void> pickStartTime(BuildContext context) async {
    final picked = await HorizontalTimePickerSheet.show(
      context,
      initial: startTime.value,
    );
    if (picked != null) {
      startTime.value = picked;
      _mergeStartDateTime();
      if (!endDate.value.isAfter(startDate.value)) {
        _ensureEndAfterStart(autoFix: true);
      }
    }
  }

  Future<void> pickEndTime(BuildContext context) async {
    final picked = await HorizontalTimePickerSheet.show(
      context,
      initial: endTime.value,
    );
    if (picked != null) {
      endTime.value = picked;
      _mergeEndDateTime();
      if (!endDate.value.isAfter(startDate.value)) {
        _ensureEndAfterStart(autoFix: true);
      }
    }
  }

  // متغيرات للخيارات
  RxBool hideTask = false.obs;
  RxBool requireAdminReview = true.obs;

  // التكرار ايام الاسبوع
  RxString selectedDays = ''.obs;

  RxString priority = 'medium'.obs;
  RxString durationType = 'forever'.obs;
  RxInt endAfterCount = 1.obs;
  final recurrenceEndDate = DateTime.now().add(const Duration(days: 30)).obs;
  RxString recurrenceSummary = ''.obs;

  // Monthly / yearly recurrence options
  RxString monthlyMode =
      'day_of_month'.obs; // day_of_month | nth_weekday | custom_dates
  RxInt monthDay = 1.obs;
  RxString weekdayOrdinal = 'second'.obs;
  RxString monthlyWeekday = 'monday'.obs;
  RxList<int> customMonthDays = <int>[].obs;
  RxInt yearlyMonth = 1.obs;
  RxInt yearlyDay = 1.obs;

  // Task reminder (stored in recurrence_config until dedicated API fields exist)
  RxString reminderWhen = 'none'.obs;
  RxString reminderChannel = 'push'.obs;

  bool get showRecurrenceDuration =>
      selectedDays.value.isNotEmpty && selectedDays.value != 'noRepeat';

  String get durationCountLabelKey {
    switch (selectedDays.value) {
      case 'daily':
        return 'endAfterDays';
      case 'weekly':
        return 'endAfterWeeks';
      case 'monthly':
        return 'endAfterMonths';
      case 'yearly':
        return 'endAfterYears';
      default:
        return 'endAfterTimes';
    }
  }

  String get durationCountUnit => RecurrenceConfigHelper.countUnitLabel(
      selectedDays.value, endAfterCount.value);

  void setRecurrenceType(String type) {
    selectedDays.value = type;
    isRecurrenceVisible.value = type != 'noRepeat';
    if (type == 'noRepeat') {
      durationType.value = 'forever';
    } else {
      endAfterCount.value = 1;
    }
    updateRecurrenceSummary();
  }

  static void _selectionHaptic() => HapticHelper.selection();

  void toggleDay(String day) {
    if (selectedDaysList.contains(day)) {
      selectedDaysList.remove(day);
    } else {
      selectedDaysList.add(day);
      _selectionHaptic();
    }
    updateRecurrenceSummary();
  }

  void addWeekdayWhileDragging(String day) {
    if (!selectedDaysList.contains(day)) {
      selectedDaysList.add(day);
      _selectionHaptic();
      updateRecurrenceSummary();
    }
  }

  void toggleMonthDay(int day) {
    if (customMonthDays.contains(day)) {
      customMonthDays.remove(day);
    } else {
      customMonthDays.add(day);
    }
    customMonthDays.refresh();
    updateRecurrenceSummary();
  }

  Map<String, dynamic> buildRecurrenceConfigMap() {
    return RecurrenceConfigHelper.build(
      recurrenceType:
          selectedDays.value.isEmpty ? 'noRepeat' : selectedDays.value,
      durationType: durationType.value,
      endAfterCount: endAfterCount.value,
      anchorStart: startDate.value,
      anchorEnd: endDate.value,
      recurrenceEndDate: recurrenceEndDate.value,
      weekdays: selectedDaysList.toList(),
      monthlyMode: monthlyMode.value,
      monthDay: monthDay.value,
      weekdayOrdinal: weekdayOrdinal.value,
      weekdayName: monthlyWeekday.value,
      monthDays: customMonthDays.toList(),
      yearlyMonth: yearlyMonth.value,
      yearlyDay: yearlyDay.value,
      reminderWhen: reminderWhen.value,
      reminderChannel: reminderChannel.value,
    );
  }

  void updateRecurrenceSummary() {
    recurrenceSummary.value = RecurrenceArabicSummary.build(
      recurrenceType:
          selectedDays.value.isEmpty ? 'noRepeat' : selectedDays.value,
      weekdays: selectedDaysList.toList(),
      durationType: durationType.value,
      endAfterCount: endAfterCount.value,
      endDate: durationType.value == 'end_date'
          ? showData(recurrenceEndDate.value)
          : null,
      monthlyMode: monthlyMode.value,
      monthDay: monthDay.value,
      weekdayOrdinal: weekdayOrdinal.value,
      weekdayName: monthlyWeekday.value,
      monthDays: customMonthDays.toList(),
      yearlyMonth: yearlyMonth.value,
      yearlyDay: yearlyDay.value,
      reminderWhen: reminderWhen.value,
      reminderChannel: reminderChannel.value,
    );
  }

  // متغير لاظهار التكرار
  RxBool isRecurrenceVisible = false.obs;

  void toggleRecurrence() {
    isRecurrenceVisible.value = !isRecurrenceVisible.value;
  }

  final weekDays = [
    'noRepeat',
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  RxList<String> selectedDaysList = <String>[].obs;

  // متغير للصورة
  final subTaskFile = Rx<XFile?>(null);

  List<File> selectedFile = [];

  final RxBool requireSubTasImage = false.obs;
  final RxString subTaskProofMediaType = ProofMediaType.none.obs;
  final RxBool subtaskBonusEnabled = false.obs;
  final RxInt subtaskBonusPoints = 0.obs;

  /// Default bonus for subtasks (from general app settings).
  int get defaultSubtaskBonusPoints {
    final fromSettings = AppSettingsService.instance.subtaskBonusDefault.value;
    if (fromSettings > 0) return fromSettings;
    return 5;
  }

  final RxBool requireImage = false.obs;
  final RxString proofMediaType = ProofMediaType.none.obs;

  void setMainProofMediaType(String value) {
    proofMediaType.value = value;
    requireImage.value = value != ProofMediaType.none;
  }

  void setSubTaskProofMediaType(String value) {
    subTaskProofMediaType.value = value;
    requireSubTasImage.value = value != ProofMediaType.none;
  }

  RxBool isLoding = false.obs;

  final RxString recordedPath = ''.obs;

  // دالة لإنشاء المهمة
  void createTask(BuildContext context, {int employeeTaskId = 0}) async {
    if (formKey.currentState!.validate()) {
      if (employeeIdsForApi.isEmpty) {
        Helpers.showCustomDialogError(
          context: context,
          title: 'error'.tr,
          message: 'selectEmployeeFirst'.tr,
        );
        return;
      }
      _mergeStartDateTime();
      _mergeEndDateTime();
      if (!_ensureEndAfterStart()) {
        final startLabel = _formatTimeLabel(startDate.value);
        final endLabel = _formatTimeLabel(endDate.value);
        Helpers.showCustomDialogError(
          context: context,
          title: 'error'.tr,
          message: 'endDateBeforeStartDateDetail'
              .tr
              .replaceAll('@start', startLabel)
              .replaceAll('@end', endLabel),
        );
        return;
      }
      isLoding(true);
      final details = isEdit ? employeeTaskService.taskDetails.value : null;
      final templateId = details?.templateId;
      final occurrenceId = details?.occurrenceId;
      final result = await createTaskUsecase.call(
        employeeTaskId: isEdit ? employeeTaskId : 0,
        templateId: templateId,
        occurrenceId: occurrenceId,
        name: taskNameController.text,
        description: taskDescriptionController.text,
        notes: taskNotesController.text,
        employeeId: employeeIdsForApi.isNotEmpty
            ? employeeIdsForApi.first
            : employeeIdConroller.text,
        employeeIds: employeeIdsForApi,
        points: pointsController.text.isEmpty ? '0' : pointsController.text,
        startTime: startDate.value,
        endTime: endDate.value,
        taskRecurrence:
            selectedDays.value.isEmpty ? 'noRepeat' : selectedDays.value,
        taskRecurrenceTime: selectedDaysList,
        subEmployeeTasks: subTasks,
        notShownForEmployee: hideTask.value ? '1' : '0',
        isForcedToUploadImg:
            proofMediaType.value != ProofMediaType.none ? '1' : '0',
        proofMediaType: proofMediaType.value,
        requiresAdminReview: requireAdminReview.value ? '1' : '0',
        adminImg: selectedFile,
        audio: hasPlayableAudio(recordedPath.value)
            ? File(recordedPath.value)
            : File(''),
        priority: priority.value,
        recurrenceConfig: buildRecurrenceConfigMap(),
      );
      result.fold(
        (failure) {
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: failure.data['message'] ?? 'Unknown error',
          );
        },
        (success) {
          Get.find<EmployeeTasksController>().getEmployeeTasks();
          if (isEdit && details != null) {
            Get.find<EmployeeTasksController>().getTaskDetails(
              taskId:
                  details.occurrenceId?.toString() ?? details.taskId.toString(),
              occurrenceId: details.occurrenceId?.toString(),
            );
          }
          Future.delayed(
            const Duration(milliseconds: 1500),
            () {
              Get.back();
              Get.back();
            },
          );
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: success,
          );
        },
      );
      isLoding(false);
    }
  }

  // دالة لإنشاء المهمة خاصة
  void createSpecialTask(BuildContext context, {int specialTaskId = 0}) async {
    if (formKey.currentState!.validate()) {
      _mergeStartDateTime();
      _mergeEndDateTime();
      if (!_ensureEndAfterStart()) {
        final startLabel = _formatTimeLabel(startDate.value);
        final endLabel = _formatTimeLabel(endDate.value);
        Helpers.showCustomDialogError(
          context: context,
          title: 'error'.tr,
          message: 'endDateBeforeStartDateDetail'
              .tr
              .replaceAll('@start', startLabel)
              .replaceAll('@end', endLabel),
        );
        return;
      }
      isLoding(true);

      final result = await creatSpecialTasksUsecase.call(
        specialTaskId: specialTaskId,
        name: taskNameController.text,
        description: taskDescriptionController.text,
        notes: taskNotesController.text,
        startDate: startDate.value,
        endDate: endDate.value,
        taskRecurrence:
            selectedDays.value.isEmpty ? 'noRepeat' : selectedDays.value,
        taskRecurrenceTime: selectedDaysList,
        subSpecialTasks: subTasks,
        notShownForEmployee: hideTask.value ? '1' : '0',
        forceEmployeeToAddImg: requireImage.value,
        adminImg: selectedFile,
        audio: hasPlayableAudio(recordedPath.value)
            ? File(recordedPath.value)
            : File(''),
      );
      result.fold(
        (failure) {
          final errors = failure.data != null ? failure.data['errors'] : null;

          if (errors is Map<String, dynamic>) {
            final messages = errors.values
                .expand((list) => list)
                .cast<String>()
                .join('')
                .replaceAll('.', '- \n');

            Helpers.showCustomDialogError(
              context: context,
              title: failure.errMessage,
              message: messages,
            );
          } else {
            Helpers.showCustomDialogError(
              context: context,
              title: failure.errMessage,
              message: "Unexpected error occurred",
            );
          }
        },
        (success) {
          Get.find<SpecialTasksController>().getSpecialTasks();
          if (isEdit) {
            Future.delayed(
              const Duration(milliseconds: 500),
              () {
                Get.find<SpecialTasksController>().getSpecialTasksDetails(
                  specialTaskId: specialTaskId.toString(),
                );
              },
            );
          }
          Future.delayed(
            const Duration(milliseconds: 1000),
            () {
              Get.back();
              Get.back();
            },
          );
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: success,
          );
        },
      );
      isLoding(false);
    } else {
      Get.snackbar(
        'info'.tr,
        'pleaseFillAllFields'.tr,
        backgroundColor: AppColors.redColor,
        colorText: AppColors.whiteColor,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  //Get Employee
  Future<void> getEmployee() async {
    try {
      final result = await getAllEmployeeUsecase.call();
      employeeService.employeeList.assignAll(result);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failedToLoadEmployees'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  final bool isEdit = Get.arguments['isEdit'];
  final String title = Get.arguments['title'];

  void updateSpecialTask() {
    final data = specialTasksService.specialTaskDetails.value!;
    taskNameController.text = data.taskName;
    taskDescriptionController.text = data.taskDescription;
    taskNotesController.text = data.notes;
    selectedDays.value = data.taskRecurrence;
    for (var element in data.taskRecurrenceTime) {
      selectedDaysList.add(element);
    }
    selectedFile = data.adminImg.map((e) => File(e)).toList();
    startDate.value = data.startTime;
    endDate.value = data.endTime;
    startTime.value = TimeOfDay.fromDateTime(data.startTime);
    endTime.value = TimeOfDay.fromDateTime(data.endTime);
    recordedPath.value = parseAudioFromApi(data.audio) ?? '';
    for (var element in data.subTasks) {
      subTasks.add({
        'subTaskId': element.subTaskId,
        'subTaskName': element.subTaskName,
        'subTaskdescription': element.subTaskDescription,
        'subTaskImage': element.adminImg,
        'imageIsRequired': element.forceEmployeeToAddImg,
        'proofMediaType': element.forceEmployeeToAddImg
            ? ProofMediaType.both
            : ProofMediaType.none,
      });
    }
  }

  int? editTemplateId;
  int? editOccurrenceId;

  void _applyReminderFromDetails(TaskDetailsEntity data) {
    final rem = RecurrenceConfigHelper.parseReminderFromApi({
      if (data.reminderWhen != null) 'reminder_when': data.reminderWhen,
      if (data.reminderChannel != null)
        'reminder_channel': data.reminderChannel,
      if (data.recurrenceConfig != null)
        'recurrence_config': data.recurrenceConfig,
    });
    reminderWhen.value = rem.when;
    reminderChannel.value = rem.channel;
    updateRecurrenceSummary();
  }

  void _applyRecurrenceConfigFromDetails(Map<String, dynamic> cfg) {
    final duration = cfg['duration_type']?.toString();
    if (duration != null && duration.isNotEmpty) {
      durationType.value = duration;
    }
    if (cfg['end_after_count'] != null) {
      endAfterCount.value = asInt(cfg['end_after_count'], 1);
    }
    if (cfg['end_date'] != null) {
      final d = DateTime.tryParse(cfg['end_date'].toString());
      if (d != null) recurrenceEndDate.value = d;
    }
    final weekdays = cfg['weekdays'];
    if (weekdays is List && weekdays.isNotEmpty) {
      selectedDaysList
        ..clear()
        ..addAll(weekdays.map((e) => e.toString().toLowerCase()));
    }
    final monthDays = cfg['month_days'];
    if (monthDays is List && monthDays.isNotEmpty) {
      customMonthDays
        ..clear()
        ..addAll(monthDays.map((e) => asInt(e)));
    }
  }

  void updateEmployeeTask() {
    final data = employeeTaskService.taskDetails.value!;
    editTemplateId = data.templateId;
    editOccurrenceId = data.occurrenceId;
    taskNameController.text = data.taskName;
    taskDescriptionController.text = data.taskDescription;
    taskNotesController.text = data.notes;
    selectedEmployeeIds
      ..clear()
      ..addAll(
        data.assigneeIds.isNotEmpty
            ? data.assigneeIds.map((e) => e.toString())
            : [data.employeeId.toString()],
      );
    selectedEmployeeId.value = selectedEmployeeIds.first;
    employeeIdConroller.text = selectedEmployeeIds.first;
    for (var element in data.subTasks) {
      subTasks.add({
        'subTaskId': element.id,
        'subTaskName': element.name,
        'subTaskdescription': element.description,
        'subTaskImage': element.adminImg,
        'imageIsRequired': element.isForcedToUploadImg,
        'proofMediaType': element.proofMediaType,
      });
    }
    pointsController.text = data.points.toString();
    startDate.value = data.startTime;
    endDate.value = data.endTime;
    startTime.value = TimeOfDay.fromDateTime(data.startTime);
    endTime.value = TimeOfDay.fromDateTime(data.endTime);
    hideTask.value = data.notShownForEmployee;
    selectedDays.value = data.taskRecurrence;
    for (var element in data.taskRecurrenceTime) {
      selectedDaysList.add(element);
    }
    recordedPath.value = parseAudioFromApi(data.audio) ?? '';
    selectedFile.addAll(data.adminImg?.map((e) => File(e)).toList() ?? []);
    requireImage.value = data.isForcedToUploadImg;
    proofMediaType.value = data.proofMediaType;
    requireAdminReview.value = data.requiresAdminReview;
    priority.value = data.priority;
    if (data.taskRecurrence.isNotEmpty) {
      selectedDays.value = data.taskRecurrence;
      isRecurrenceVisible.value = data.taskRecurrence != 'noRepeat';
    }
    if (data.recurrenceConfig != null && data.recurrenceConfig!.isNotEmpty) {
      _applyRecurrenceConfigFromDetails(data.recurrenceConfig!);
    }
    _applyReminderFromDetails(data);
  }

  void cloneEmployeeTask() {
    final data = employeeTaskService.taskDetails.value!;
    editTemplateId = null;
    editOccurrenceId = null;
    taskNameController.text = data.taskName;
    taskDescriptionController.text = data.taskDescription;
    taskNotesController.text = data.notes;
    selectedEmployeeIds.clear();
    selectedEmployeeId.value = '';
    employeeIdConroller.clear();
    subTasks.clear();
    for (var element in data.subTasks) {
      subTasks.add({
        'subTaskName': element.name,
        'subTaskdescription': element.description,
        'subTaskImage': element.adminImg,
        'imageIsRequired': element.isForcedToUploadImg,
        'proofMediaType': element.proofMediaType,
      });
    }
    pointsController.text = data.points.toString();
    startDate.value = data.startTime;
    endDate.value = data.endTime;
    startTime.value = TimeOfDay.fromDateTime(data.startTime);
    endTime.value = TimeOfDay.fromDateTime(data.endTime);
    hideTask.value = data.notShownForEmployee;
    selectedDays.value = data.taskRecurrence;
    selectedDaysList
      ..clear()
      ..addAll(data.taskRecurrenceTime);
    recordedPath.value = '';
    selectedFile.clear();
    requireImage.value = data.isForcedToUploadImg;
    proofMediaType.value = data.proofMediaType;
    requireAdminReview.value = data.requiresAdminReview;
    priority.value = data.priority;
    isRecurrenceVisible.value =
        data.taskRecurrence.isNotEmpty && data.taskRecurrence != 'noRepeat';
    if (data.recurrenceConfig != null && data.recurrenceConfig!.isNotEmpty) {
      _applyRecurrenceConfigFromDetails(data.recurrenceConfig!);
    }
    _applyReminderFromDetails(data);
  }

  @override
  void onInit() {
    super.onInit();
    AppSettingsService.instance.ensureLoaded();
    getEmployee();
    if (isEdit) {
      title == 'editSpecialTask' ? updateSpecialTask() : updateEmployeeTask();
    } else if (isCloneFromTask) {
      cloneEmployeeTask();
    } else if (title == 'createNewEmployeeTask' ||
        title == 'addNewPravateTask') {
      _initDefaultEndAfterStart();
    }
    if (title == 'createNewEmployeeTask' ||
        title == 'editEmployeeTask' ||
        title == 'addNewPravateTask' ||
        title == 'editSpecialTask') {
      updateRecurrenceSummary();
    }
  }

  @override
  void onClose() {
    taskNameController.dispose();
    taskDescriptionController.dispose();
    taskNotesController.dispose();
    subTaskNameController.dispose();
    employeeIdConroller.dispose();
    subTaskDescriptionController.dispose();
    pointsController.dispose();
    subTasks.clear();
    selectedDaysList.clear();
    super.onClose();
  }

  final bool isCloneFromTask = Get.arguments?['cloneFromTask'] == true;
}
