import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../--/presentation/dashbord/widgets/stat_card.dart';
import '../controllers/checks_controller.dart';

class ChecksInformaiton extends StatelessWidget {
  const ChecksInformaiton({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final ChecksController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9.r),
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
      ),
      child: Column(
        children: [
          // الصف الأول: ديون لنا وديون علينا
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'youOwe',
                  imageicon: AssetsManger.cashIcon,
                  value: controller.youOwe.value,
                  subtitle: '',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: StatCard(
                  title: 'forYou',
                  imageicon: AssetsManger.cashIcon,
                  value: controller.forYou.value,
                  subtitle: '',
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'all',
                  imageicon: AssetsManger.productIcon,
                  value: controller.all.value,
                  subtitle: '',
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'totalDebts',
                  imageicon: AssetsManger.moneyIcon,
                  value: controller.totalDebts.value,
                  subtitle: '',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: StatCard(
                  title: 'totalOwed',
                  imageicon: AssetsManger.moneyIcon,
                  value: controller.totalOwed.value,
                  subtitle: '',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
