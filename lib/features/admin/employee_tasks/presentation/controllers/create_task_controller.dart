import 'dart:io';
import 'package:doctorbike/core/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../employee_section/domain/usecases/get_all_employee.dart';
import '../../../employee_section/presentation/controllers/employee_service.dart';
import '../../domain/usecases/create_task_usecase.dart';
import 'employee_tasks_controller.dart';

class CreateTaskController extends GetxController {
  CreateTaskUsecase createTaskUsecase;
  GetAllEmployeeUsecase getAllEmployeeUsecase;
  EmployeeService employeeService;

  CreateTaskController({
    required this.createTaskUsecase,
    required this.getAllEmployeeUsecase,
    required this.employeeService,
  });

  final formKey = GlobalKey<FormState>();

  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController taskDescriptionController =
      TextEditingController();
  final TextEditingController taskNotesController = TextEditingController();
  final TextEditingController employeeIdConroller = TextEditingController();
  final TextEditingController subTaskNameController = TextEditingController();
  final TextEditingController subTaskDescriptionController =
      TextEditingController();

  // عدد النقاط
  final TextEditingController pointsController = TextEditingController();

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
    'noRepeat',
    'daily',
    'weekly',
    'monthly',
  ];

  RxList<String> selectedDaysList = <String>[].obs;

  // متغير للصورة
  final subTaskFile = Rx<XFile?>(null);

  final selectedFile = Rx<XFile?>(null);

  final RxBool requireSubTasImage = false.obs;

  final RxBool requireImage = false.obs;

  RxBool isLoding = false.obs;

  final RxString recordedPath = ''.obs;

  // دالة لإنشاء المهمة
  void createTask(BuildContext context) async {
    if (formKey.currentState!.validate() &&
        selectedDays.value.isNotEmpty &&
        selectedDaysList.isNotEmpty) {
      // isLoding(true);

      final result = await createTaskUsecase.call(
        name: taskNameController.text,
        description: taskDescriptionController.text,
        notes: taskNotesController.text,
        employeeId: employeeIdConroller.text,
        points: pointsController.text,
        startTime: startDate.value,
        endTime: endDate.value,
        taskRecurrence: selectedDays.value,
        taskRecurrenceTime: selectedDaysList,
        subEmployeeTasks: subTasks,
        notShownForEmployee: hideTask.value ? '1' : '0',
        isForcedToUploadImg: requireImage.value ? '1' : '0',
        adminImg: selectedFile.value,
        audio: File(recordedPath.value),
      );
      result.fold(
        (failure) {
          final errors = failure.data['errors'] as Map<String, dynamic>;
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
        },
        (success) {
          Get.find<EmployeeTasksController>().getEmployeeTasks();
          Future.delayed(
            const Duration(seconds: 2),
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

    // resetData();
  }

  //Get Employee
  void getEmployee() async {
    final result = await getAllEmployeeUsecase.call();
    employeeService.employeeList.assignAll(result);
    update();
  }

  @override
  void onInit() {
    super.onInit();
    getEmployee();
  }

  @override
  void dispose() {
    taskNameController.dispose();
    taskDescriptionController.dispose();
    taskNotesController.dispose();
    subTaskNameController.dispose();
    employeeIdConroller.dispose();
    subTaskDescriptionController.dispose();
    pointsController.dispose();
    subTasks.clear();
    selectedDaysList.clear();
    super.dispose();
  }
}
