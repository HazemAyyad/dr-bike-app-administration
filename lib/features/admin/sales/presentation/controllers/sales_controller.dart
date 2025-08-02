import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import 'sales_service.dart';

class SalesController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final SalesService salesService;
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  SalesController({required this.salesService});
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController totalCostController = TextEditingController();

  // filters
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController employeeNameController = TextEditingController();

  final currentTab = 0.obs;
  List<String> tabs = ['spotSale', 'cashProfit'];

  final targets = <Map<String, dynamic>>[].obs;

  final RxInt selectedTypeIndex = 0.obs;

  final isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
    fetchOrders();
  }

  void fetchOrders() {
    // Simulate fetching orders based on the current tab
    targets.clear();
    if (currentTab.value == 0) {
      targets.addAll(
        [
          {
            'id': '1',
            'image':
                'https://marketplace.canva.com/EAE0GDU32B8/1/0/1131w/canva-%D9%81%D8%A7%D8%AA%D9%88%D8%B1%D8%A9-%D8%A3%D8%B2%D8%B1%D9%82-%D9%88%D8%A3%D8%B5%D9%81%D8%B1-%D8%B9%D9%85%D9%84-%D8%AA%D8%AC%D8%A7%D8%B1%D9%8A-K5dvNWT48wY.jpg',
            'total': '3000',
            'items': {
              'موتور بنزين': '2000',
              'زمور': '30',
            },
            'day': 'الاحد',
          },
          {
            'id': '2',
            'image':
                'https://marketplace.canva.com/EAE0GDU32B8/1/0/1131w/canva-%D9%81%D8%A7%D8%AA%D9%88%D8%B1%D8%A9-%D8%A3%D8%B2%D8%B1%D9%82-%D9%88%D8%A3%D8%B5%D9%81%D8%B1-%D8%B9%D9%85%D9%84-%D8%AA%D8%AC%D8%A7%D8%B1%D9%8A-K5dvNWT48wY.jpg',
            'total': '2000',
            'items': {
              'موتور بنزين': '2000',
            },
            'day': 'الاثنين',
          },
        ],
      );
    } else if (currentTab.value == 1) {
      targets.addAll(
        [
          {
            'id': '2',
            'image':
                'https://marketplace.canva.com/EAE0GDU32B8/1/0/1131w/canva-%D9%81%D8%A7%D8%AA%D9%88%D8%B1%D8%A9-%D8%A3%D8%B2%D8%B1%D9%82-%D9%88%D8%A3%D8%B5%D9%81%D8%B1-%D8%B9%D9%85%D9%84-%D8%AA%D8%AC%D8%A7%D8%B1%D9%8A-K5dvNWT48wY.jpg',
            'total': '2000',
            'items': {
              'بيع لوحة الكترونية مستعملة موجودة بالمخزن الاول': '',
            },
            'day': 'الاثنين',
          },
          {
            'id': '1',
            'image':
                'https://marketplace.canva.com/EAE0GDU32B8/1/0/1131w/canva-%D9%81%D8%A7%D8%AA%D9%88%D8%B1%D8%A9-%D8%A3%D8%B2%D8%B1%D9%82-%D9%88%D8%A3%D8%B5%D9%81%D8%B1-%D8%B9%D9%85%D9%84-%D8%AA%D8%AC%D8%A7%D8%B1%D9%8A-K5dvNWT48wY.jpg',
            'total': '3000',
            'items': {
              'بيع لوحة الكترونية مستعملة موجودة بالمخزن الاول': '',
            },
            'day': 'الاحد',
          },
        ],
      );
    }
  }

  List<String> itemsName = [
    'موتور بنزين',
    'زمور',
    'بيع لوحة الكترونية مستعملة موجودة بالمخزن الاول',
  ];
  final items = <ItemModel>[ItemModel()].obs;

  void addItem() {
    items.add(ItemModel());
    listKey.currentState?.insertItem(
      items.length - 1,
      duration: const Duration(milliseconds: 300),
    );
  }

  void removeItem(int index) {
    if (items.length > 1) {
      items.removeAt(index);
    }
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
      'title': 'newInstantSale',
      'icon': AssetsManger.invoiceIcon,
      'route': AppRoutes.NEWINSTANTSALESCREEN
    },
    {
      'title': 'newCashProfit',
      'icon': AssetsManger.moneyIcon,
      'route': AppRoutes.NEWCASHPROFITSCREEN,
    },
    {
      'title': 'receiveMaintenance',
      'icon': AssetsManger.userIcon,
      'route': AppRoutes.NEWCASHPROFITSCREEN,
    },
  ];

  @override
  void onClose() {
    animController.dispose();
    quantityController.dispose();
    priceController.dispose();
    discountController.dispose();
    totalController.dispose();
    noteController.dispose();
    totalCostController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    employeeNameController.dispose();
    for (var item in items) {
      item.quantityController.dispose();
      item.priceController.dispose();
    }
    super.onClose();
  }

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
}

class ItemModel {
  RxString selectedItem = ''.obs;
  TextEditingController quantityController = TextEditingController();
  TextEditingController priceController = TextEditingController();
}
