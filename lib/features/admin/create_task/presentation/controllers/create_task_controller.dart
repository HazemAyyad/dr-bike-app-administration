import 'package:doctorbike/core/helpers/helpers.dart';
import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../--/domain/usecases/special_tasks_usecase.dart';

class CreateTaskController extends GetxController {
  CreatSpecialTasksUsecase creatSpecialTasksUsecase;
  CreateTaskController({required this.creatSpecialTasksUsecase});

  final formKey = GlobalKey<FormState>();

  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController taskDescriptionController =
      TextEditingController();
  final TextEditingController taskNotesController = TextEditingController();
  String selectedEmployees = '';

  final TextEditingController subTaskNameController = TextEditingController();
  final TextEditingController subTaskDescriptionController =
      TextEditingController();

  // عدد النقاط
  final TextEditingController pointsController = TextEditingController();

  // قائمة الموظفين المتاحين
  final availableEmployees = [
    'أحمد علي',
    'محمد خالد',
    'سارة أحمد',
    'فاطمة محمد',
    'خالد عمر',
    'زينب سعيد',
    'عمر حسن',
    'ليلى كريم'
  ];

  // المهام الفرعية
  RxList subTasks = [].obs;
  final isSubtasksListVisible = false.obs;

  // دالة لإضافة مهمة فرعية
  void addSubTask() {
    if (subTaskNameController.text.isNotEmpty) {
      subTasks.addAll([
        {
          'subTaskName': subTaskNameController.text,
          'subTaskdescription': subTaskDescriptionController.text,
          'subTaskImage': subTaskFile.value?.path,
          'imageIsRequired': requireSubTasImage.value,
        }
      ]);
      subTaskNameController.clear();
      subTaskDescriptionController.clear();
      subTaskFile.value = null;
      requireSubTasImage.value = false;
      isSubtasksListVisible.value = false;
      cancelButtonColor.value =
          Get.isDarkMode ? AppColors.darckColor : AppColors.whiteColor;
    }
  }

  Rx<Color> cancelButtonColor =
      Get.isDarkMode ? AppColors.darckColor.obs : AppColors.whiteColor.obs;

  // دالة لإظهار/إخفاء قائمة المهام الفرعية
  void toggleSubtasksList() {
    isSubtasksListVisible.value = !isSubtasksListVisible.value;
    if (!isSubtasksListVisible.value) {
      cancelButtonColor.value =
          Get.isDarkMode ? AppColors.darckColor : AppColors.whiteColor;
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        cancelButtonColor.value = AppColors.primaryColor;
      });
    }
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

  // دالة لإظهار/إخفاء التقويم
  void toggleCalendar(bool isStartDate) {
    if (isStartDate) {
      isStartDateCalendarVisible.value = !isStartDateCalendarVisible.value;
      isEndDateCalendarVisible.value = false; // إخفاء تقويم نهاية التاريخ
    } else {
      isEndDateCalendarVisible.value = !isEndDateCalendarVisible.value;
      isStartDateCalendarVisible.value = false; // إخفاء تقويم بداية التاريخ
    }
  }

  // متغيرات للخيارات
  RxBool hideTask = false.obs;

  // التكرار ايام الاسبوع
  final selectedDays = ''.obs;

  // متغير لاظهار التكرار
  RxBool isRecurrenceVisible = false.obs;
  void toggleRecurrence() {
    isRecurrenceVisible.value = !isRecurrenceVisible.value;
  }

  final weekDays = [
    'taskRepeatDaily'.tr,
    'taskRepeatWeekly'.tr,
    'taskRepeatMonthly'.tr,
    'taskRepeatYearly'.tr,
  ];

  RxList<String> selectedDaysList = <String>[].obs;

  // متغير للصورة
  final subTaskFile = Rx<XFile?>(null);

  final selectedFile = Rx<XFile?>(null);

  final RxBool requireSubTasImage = false.obs;

  final RxBool requireImage = false.obs;

  RxBool isLoding = false.obs;

  // دالة لإنشاء المهمة
  void createTask(BuildContext context) async {
    if (formKey.currentState!.validate() &&
        selectedDays.value.isNotEmpty &&
        selectedDaysList.isNotEmpty) {
      // isLoding(true);
      final token = await UserData.getUserToken();

      final result = await creatSpecialTasksUsecase.call(
        token: token,
        name: taskNameController.text,
        description: taskDescriptionController.text,
        notes: taskNotesController.text,
        points: pointsController.text,
        startDate: startDate.value.toString(),
        endDate: '2025-06-21 15:30:00',
        notShownForEmployee: hideTask.value ? '1' : '0',
        taskRecurrence: selectedDays.value,
        taskRecurrenceTime: selectedDaysList.join(','),
        subSpecialTaskName:
            subTasks.isNotEmpty ? subTasks[0]['subTaskName'] : 'N/A',
        subSpecialTaskDescription:
            subTasks.isNotEmpty ? subTasks[0]['description'] : 'N/A',
      );
      result.fold((failure) {
        final errors = failure.data['errors'] as Map<String, dynamic>;
        final messages = errors.values
            .expand((list) => list) // يجمع كل القوائم
            .cast<String>() // يحولها لـ List<String>
            .join('\n'); // يفصل كل رسالة بسطر جديد

        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: messages,
        );
      }, (success) {
        resetData();
        Get.back();
        Helpers.showCustomDialogSuccess(
          context: context,
          title: 'success'.tr,
          message: 'taskCreatedSuccessfully'.tr,
        );
        Future.delayed(const Duration(seconds: 2), () {
          Get.back();
        });
      });
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
    // هنا يمكن إضافة منطق حفظ المهمة إلى قاعدة البيانات

    // إعادة تعيين البيانات
    // resetData();
  }

  final RxString recordedPath = ''.obs;

  // دالة لإعادة تعيين البيانات
  void resetData() {
    taskNameController.clear();
    taskDescriptionController.clear();
    taskNotesController.clear();
    selectedEmployees = '';
    subTasks.clear();
    subTaskNameController.clear();
    subTaskDescriptionController.clear();
    pointsController.clear();
    selectedEmployees = '';
    selectedDays.value = '';
    isSelected.value = 0;
    hideTask.value = false;
    selectedDays.value = '';
    // selectedFile.value = null;
    isStartDateCalendarVisible.value = false;
    isSubtasksListVisible.value = false;
    isRecurrenceVisible.value = false;
    requireImage.value = false;
    selectedDaysList.clear();
  }

  @override
  void dispose() {
    taskNameController.dispose();
    taskDescriptionController.dispose();
    taskNotesController.dispose();
    subTaskNameController.dispose();
    subTaskDescriptionController.dispose();
    pointsController.dispose();
    selectedEmployees = '';
    subTasks.clear();
    selectedDays.value = '';
    isSelected.value = 0;
    hideTask.value = false;
    selectedDays.value = '';
    selectedFile.value = null;
    selectedDaysList.clear();
    super.dispose();
  }
}
