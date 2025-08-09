import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';

class ChecksController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final GlobalKey formKey = GlobalKey<FormState>();

  final TextEditingController checkValueController = TextEditingController();
  final TextEditingController currencyController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController checkNumberController = TextEditingController();

  final TextEditingController bankNameController = TextEditingController();

  final currentTab = 0.obs;
  final tabs = ['didNotActOnIt', 'actedOnIt', 'archive'].obs;

  // ألا حصائيات العامة
  final RxString youOwe = '19'.obs;
  final RxString forYou = '0'.obs;
  final RxString all = '19'.obs;
  final RxString employees = '40'.obs;
  final RxString totalDebts = '30'.obs;
  final RxString totalOwed = '5'.obs;
  final RxString expenses = '1200'.obs;

  // احصائيات الشيكات الصادرة
  final RxString outGoingNumberOfChecks = '20'.obs;
  final RxString outGoingTotal = '3000'.obs;
  final RxString totalFunds = '2000'.obs;
  final RxString coveragePercentage = '40'.obs;

  // احصائيات الشيكات الواردة
  final RxString inComingNumberOfChecks = '50'.obs;
  final RxString inComingTotal = '30000'.obs;

  final outGoingChecksList = <Map<String, dynamic>>[].obs;

  final inComingChecksList = <Map<String, dynamic>>[].obs;

  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
    animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    opacityAnimation = Tween<double>(begin: 0, end: 1).animate(animController);
    sizeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animController, curve: Curves.fastOutSlowIn),
    );

    ever(isAddMenuOpen, (bool open) {
      if (open) {
        animController.forward();
      } else {
        animController.reverse();
      }
    });
  }

  void changeTab(int index) {
    currentTab.value = index;
    fetchOrders();
  }

  // متغير للتحكم في قائمة الإضافة
  final RxBool isAddMenuOpen = false.obs;

  late AnimationController animController;
  late Animation<double> opacityAnimation;
  late Animation<double> sizeAnimation;

  void toggleAddMenu() {
    isAddMenuOpen.value = !isAddMenuOpen.value;
  }

  List<Map<String, String>> addList = [
    {
      'title': 'newCheck',
      'icon': AssetsManger.invoiceIcon,
      'route': AppRoutes.NEWCHECKSCREEN
    },
    {
      'title': 'newReceipt',
      'icon': AssetsManger.invoiceIcon,
      'route': AppRoutes.NEWCHECKSCREEN,
    },
  ];

  void fetchOrders() {
    // Simulate fetching orders based on the current tab
    outGoingChecksList.clear();
    inComingChecksList.clear();
    if (currentTab.value == 0) {
      inComingChecksList.addAll(
        [
          {
            'id': '1',
            'total': '35000',
            'date': '2025/07/25',
            'days': '15',
            'checkNumber': '7881',
            'month': 'يوليو 2025',
          },
          {
            'id': '2',
            'total': '25000',
            'date': '2025/08/02',
            'days': '5',
            'checkNumber': '7851',
            'month': 'اغسطس 2025',
          },
          {
            'id': '3',
            'total': '25000',
            'date': '2025/08/02',
            'days': '-10',
            'checkNumber': '7851',
            'month': 'يناير 2025',
          },
          {
            'id': '1',
            'total': '35000',
            'date': '2025/07/25',
            'days': '15',
            'checkNumber': '7881',
            'month': 'يوليو 2025',
          },
          {
            'id': '2',
            'total': '25000',
            'date': '2025/08/02',
            'days': '5',
            'checkNumber': '7851',
            'month': 'اغسطس 2025',
          },
          {
            'id': '3',
            'total': '25000',
            'date': '2025/08/02',
            'days': '-10',
            'checkNumber': '7851',
            'month': 'يناير 2025',
          },
        ],
      );
      outGoingChecksList.addAll(
        [
          {
            'id': '1',
            'total': '35000',
            'date': '2025/07/25',
            'days': '20',
            'checkNumber': '7881',
            'month': 'يوليو 2025',
          },
          {
            'id': '2',
            'total': '25000',
            'date': '2025/08/02',
            'days': '5',
            'checkNumber': '7851',
            'month': 'اغسطس 2025',
          },
          {
            'id': '3',
            'total': '25000',
            'date': '2025/08/02',
            'days': '-10',
            'checkNumber': '7851',
            'month': 'يناير 2025',
          },
        ],
      );
    } else if (currentTab.value == 1) {
      inComingChecksList.addAll(
        [
          {
            'id': '2',
            'total': '25000',
            'date': '2025/08/02',
            'days': '5',
            'checkNumber': '5621',
            'month': 'اغسطس 2025',
          },
          {
            'id': '1',
            'total': '35000',
            'date': '2025/07/25',
            'days': '10',
            'checkNumber': '7851',
            'month': 'يوليو 2025',
          },
          {
            'id': '2',
            'total': '25000',
            'date': '2025/08/02',
            'days': '-1',
            'checkNumber': '7851',
            'month': 'فبراير 2025',
          },
        ],
      );
      outGoingChecksList.addAll(
        [
          {
            'id': '2',
            'total': '25000',
            'date': '2025/08/02',
            'days': '5',
            'checkNumber': '5621',
            'month': 'اغسطس 2025',
          },
          {
            'id': '1',
            'total': '35000',
            'date': '2025/07/25',
            'days': '10',
            'checkNumber': '7851',
            'month': 'يوليو 2025',
          },
          {
            'id': '2',
            'total': '25000',
            'date': '2025/08/02',
            'days': '-1',
            'checkNumber': '7851',
            'month': 'فبراير 2025',
          },
        ],
      );
    } else if (currentTab.value == 2) {
      inComingChecksList.addAll(
        [
          {
            'id': '1',
            'total': '35000',
            'date': '2025/07/25',
            'status': 'شيك مقبول',
            'days': '10',
            'checkNumber': '7851',
            'month': 'يوليو 2025',
          },
          {
            'id': '2',
            'total': '25000',
            'date': '2025/08/02',
            'status': 'شيك مرجع',
            'days': '5',
            'checkNumber': '7851',
            'month': 'اغسطس 2025',
          },
          {
            'id': '2',
            'total': '25000',
            'date': '2025/08/02',
            'status': 'شيك معدوم',
            'days': '-1',
            'checkNumber': '7851',
            'month': 'اغسطس 2025',
          },
        ],
      );
      outGoingChecksList.addAll(
        [
          {
            'id': '1',
            'total': '35000',
            'date': '2025/07/25',
            'status': 'شيك مقبول',
            'days': '10',
            'checkNumber': '7851',
            'month': 'يوليو 2025',
          },
          {
            'id': '2',
            'total': '25000',
            'date': '2025/08/02',
            'status': 'شيك مرجع',
            'days': '5',
            'checkNumber': '7851',
            'month': 'اغسطس 2025',
          },
          {
            'id': '2',
            'total': '25000',
            'date': '2025/08/02',
            'status': 'شيك معدوم',
            'days': '-1',
            'checkNumber': '7851',
            'month': 'اغسطس 2025',
          },
        ],
      );
    }
  }

  var selectedOption = ''.obs;

  // الشيكات الصادرة
  RxList<String> outgoingChecksDidNotActOnIt =
      <String>['endorseTheCheck', 'voidTheCheck'].obs;

  RxList<String> outgoingChecksActedOnIt =
      <String>['cashTheCheck', 'returnedCheck', 'voidTheCheck'].obs;

  List<String> beneficiary = [
    'ماجد أحمد',
    'علي محمد',
    'سارة خالد',
    'أحمد علي',
  ].obs;

  String selectedBeneficiary = '';

  final RxBool amountFilter = false.obs;

  final RxBool dateFilter = false.obs;

  // الشيكات الواردة
  RxList<String> incomingChecksDidNotActOnIt =
      <String>['cashTheCheck', 'returnedCheck', 'endorseTheCheck'].obs;

  RxList<String> incomingChecksActedOnIt =
      <String>['cashTheCheck', 'returnedCheck'].obs;

  RxList<String> archive = ['voidTheCheck', 'returnedCheck'].obs;

  List<String> boxesName = [
    'ماجد أحمد',
    'علي محمد',
    'سارة خالد',
    'أحمد علي',
  ].obs;

  String selectedBox = '';

  // Add New Check
  List<String> customers = [
    'ماجد أحمد',
    'علي محمد',
    'سارة خالد',
    'أحمد علي',
  ].obs;

  // متغيرات للتقويم
  final selectedDay = DateTime.now().obs;

  // متغير لعرض التقويم
  final isCalendarVisible = false.obs;

  // دالة لإظهار/إخفاء التقويم
  void toggleCalendar() {
    isCalendarVisible.value = !isCalendarVisible.value;
  }

  // العملات
  List<String> currency = [
    'currency',
    'currency1',
    'currency2',
  ].obs;

  // صورة الشيك من الامام
  // final checkFrontImage = Rx<File?>(null);
  List<File> checkFrontImage = [];

  // صورة الشيك من الخلف
  // final checkBackImage = Rx<File?>(null);
  List<File> checkBackImage = [];

  void cashTheChecks() {
    if ((formKey.currentState as FormState).validate()) {
      Get.back();
      print('cashTheChecks');
    }
  }
}
