import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import 'assets_screens/assets_screen.dart';
import 'expenses_screens/expenses_screen.dart';
import 'official_papers_screens/official_papers_screen.dart';

class FinancialAffairsScreen extends StatelessWidget {
  const FinancialAffairsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'financialMatters',
          action: false,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(52.h),
            child: Container(
              margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 7.h),
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.operationalSurface,
                borderRadius: BorderRadius.circular(13.r),
                border: Border.all(color: AppColors.operationalCardBorder),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.operationalPurple,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: ThemeService.isDark.value
                    ? Colors.white70
                    : AppColors.operationalNavy,
                labelStyle:
                    TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800),
                unselectedLabelStyle:
                    TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.receipt_long_outlined),
                    SizedBox(width: 4),
                    Text('المصاريف')
                  ])),
                  Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.inventory_2_outlined),
                    SizedBox(width: 4),
                    Text('الأصول')
                  ])),
                  Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.folder_copy_outlined),
                    SizedBox(width: 4),
                    Text('الأوراق')
                  ])),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            ExpensesScreen(embedded: true),
            AssetsScreen(embedded: true),
            OfficialPapersScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}
