import 'dart:io';
import 'package:doctorbike/core/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../employee_section/domain/usecases/get_all_employee.dart';
import '../../../employee_section/presentation/controllers/employee_service.dart';
import '../../../employee_tasks/presentation/controllers/employee_task_service.dart';
import '../../../special_tasks/presentation/controllers/special_tasks_controller.dart';
import '../../../special_tasks/presentation/controllers/special_tasks_service.dart';
import '../../domain/usecases/creat_special_tasks_usecase.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../../employee_tasks/presentation/controllers/employee_tasks_controller.dart';

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
  RxString selectedDays = ''.obs;

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

  List<File> selectedFile = [];

  final RxBool requireSubTasImage = false.obs;

  final RxBool requireImage = false.obs;

  RxBool isLoding = false.obs;

  final RxString recordedPath = ''.obs;

  // دالة لإنشاء المهمة
  void createTask(BuildContext context, {int employeeTaskId = 0}) async {
    if (formKey.currentState!.validate() && selectedDays.value.isNotEmpty) {
      isLoding(true);

      final result = await createTaskUsecase.call(
        employeeTaskId: employeeTaskId,
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
        adminImg: selectedFile,
        audio: File(recordedPath.value),
      );
      result.fold(
        (failure) {
          print(failure);
          // final errors = failure.data['errors'] as Map<String, dynamic>;
          // final messages = errors.values
          //     .expand((list) => list)
          //     .cast<String>()
          //     .join('')
          //     .replaceAll('.', '- \n');
          // Helpers.showCustomDialogError(
          //   context: context,
          //   title: failure.errMessage,
          //   message: messages,
          // );
        },
        (success) {
          Get.find<EmployeeTasksController>().getEmployeeTasks();
          Get.find<EmployeeTasksController>()
              .getTaskDetails(taskId: employeeTaskId.toString());

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
    }
  }

  // دالة لإنشاء المهمة خاصة
  void createSpecialTask(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      isLoding(true);

      final result = await creatSpecialTasksUsecase.call(
        name: taskNameController.text,
        description: taskDescriptionController.text,
        notes: taskNotesController.text,
        startDate: startDate.value,
        endDate: endDate.value,
        taskRecurrence: selectedDays.value,
        taskRecurrenceTime: selectedDaysList,
        subSpecialTasks: subTasks,
        notShownForEmployee: hideTask.value ? '1' : '0',
        forceEmployeeToAddImg: requireImage.value,
        adminImg: selectedFile,
        audio: File(recordedPath.value),
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
  }

  //Get Employee
  void getEmployee() async {
    final result = await getAllEmployeeUsecase.call();
    employeeService.employeeList.value = result;
    update();
  }

  final bool isEdit = Get.arguments['isEdit'];
  final String title = Get.arguments['title'];

  final RxBool deleteImage = false.obs;
  void updatePrivateTask() {
    taskNameController.text =
        specialTasksService.specialTaskDetails.value!.taskName;
    taskDescriptionController.text =
        specialTasksService.specialTaskDetails.value!.taskDescription;
    //  taskNotesController.text = specialTasksService.specialTaskDetails.value!.;
    selectedDays.value =
        specialTasksService.specialTaskDetails.value!.taskRecurrence;
    for (var element
        in specialTasksService.specialTaskDetails.value!.taskRecurrenceTime) {
      selectedDaysList.add(element);
    }
    selectedFile = specialTasksService.specialTaskDetails.value!.adminImg
        .map((e) => File(e))
        .toList();
    for (var element
        in specialTasksService.specialTaskDetails.value!.subTasks) {
      subTasks.add({
        'subTaskName': element.subTaskName,
        'subTaskdescription': element.subTaskDescription,
        'subTaskImage': element.adminImg,
        'imageIsRequired': element.forceEmployeeToAddImg,
      });
    }
  }

  void updateEmployeeTask() {
    final data = employeeTaskService.taskDetails.value!;
    taskNameController.text = data.taskName;
    taskDescriptionController.text = data.taskDescription;
    taskNotesController.text = data.notes;
    employeeIdConroller.text = data.employeeId.toString();
    for (var element in data.subTasks) {
      subTasks.add({
        'subTaskName': element.name,
        'subTaskdescription': element.description,
        'subTaskImage': element.adminImg,
        'imageIsRequired': element.isForcedToUploadImg ? '1' : '0',
      });
    }
    pointsController.text = data.points.toString();
    startDate.value = data.startTime;
    endDate.value = data.endTime;
    hideTask.value = data.notShownForEmployee;
    selectedDays.value = data.taskRecurrence;
    for (var element in data.taskRecurrenceTime) {
      selectedDaysList.add(element);
    }
    recordedPath.value = File(data.audio!).path;
    selectedFile = data.adminImg?.map((e) => File(e)).toList() ?? [];
    selectedDays.value = data.taskRecurrence;
  }

  @override
  void onInit() {
    super.onInit();
    getEmployee();
    if (isEdit) {
      // title == 'editPrivateTask' ? updatePrivateTask() :
      updateEmployeeTask();
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
}
