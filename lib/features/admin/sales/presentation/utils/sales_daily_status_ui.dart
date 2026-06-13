import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';

class SalesDailyStatusUi {
  static Color colorFor(String status) {
    switch (status) {
      case 'closing_requested':
        return Colors.orange.shade800;
      case 'closed':
        return Colors.grey.shade700;
      default:
        return AppColors.primaryColor;
    }
  }

  static IconData iconFor(String status) {
    switch (status) {
      case 'closing_requested':
        return Icons.hourglass_top_rounded;
      case 'closed':
        return Icons.lock_outline;
      default:
        return Icons.lock_open_rounded;
    }
  }

  static String labelFor(String status) {
    switch (status) {
      case 'closing_requested':
        return 'salesDailyClosingPending'.tr;
      case 'closed':
        return 'salesDailyDayClosed'.tr;
      default:
        return 'salesDailyDayOpen'.tr;
    }
  }

  static String shortLabelFor(String status) {
    switch (status) {
      case 'closing_requested':
        return 'salesDailyStatusPending'.tr;
      case 'closed':
        return 'salesDailyStatusClosed'.tr;
      default:
        return 'salesDailyStatusOpen'.tr;
    }
  }
}
