import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/checks_controller.dart';

class CurrencyExchangeCard extends GetView<ChecksController> {
  const CurrencyExchangeCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fromCurrency = controller
          .exchangeCurrencyByCode(controller.exchangeFromCurrency.value);
      final toCurrency = controller
          .exchangeCurrencyByCode(controller.exchangeToCurrency.value);
      final isDark = ThemeService.isDark.value;

      return Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: isDark ? AppColors.customGreyColor : AppColors.whiteColor2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'currencyExchange'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color:
                              isDark ? Colors.white : AppColors.secondaryColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'refreshExchangeRate'.tr,
                  onPressed: controller.isExchangeLoading.value
                      ? null
                      : controller.fetchExchangeRate,
                  icon: controller.isExchangeLoading.value
                      ? SizedBox(
                          width: 18.r,
                          height: 18.r,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: controller.exchangeAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: controller.onExchangeAmountChanged,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
              decoration: InputDecoration(
                labelText: 'exchangeAmount'.tr,
                prefixText: '${fromCurrency.symbol} ',
                filled: true,
                fillColor:
                    isDark ? AppColors.customGreyColor4 : AppColors.whiteColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _CurrencyDropdown(
                    label: 'from'.tr,
                    value: controller.exchangeFromCurrency.value,
                    onChanged: controller.changeExchangeFrom,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: IconButton(
                    tooltip: 'swapCurrencies'.tr,
                    onPressed: controller.swapExchangeCurrencies,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.whiteColor,
                      fixedSize: Size(42.r, 42.r),
                    ),
                    icon: const Icon(Icons.swap_horiz),
                  ),
                ),
                Expanded(
                  child: _CurrencyDropdown(
                    label: 'to'.tr,
                    value: controller.exchangeToCurrency.value,
                    onChanged: controller.changeExchangeTo,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.customGreyColor4 : AppColors.whiteColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'convertedAmount'.tr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.customGreyColor3
                              : AppColors.greyColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${controller.formatExchangeNumber(controller.convertedExchangeAmount.value)} ${toCurrency.symbol}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color:
                              isDark ? Colors.white : AppColors.secondaryColor,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  SizedBox(height: 6.h),
                  Directionality(
                    textDirection: controller.exchangeError.value.isNotEmpty
                        ? Directionality.of(context)
                        : TextDirection.ltr,
                    child: Text(
                      controller.exchangeError.value.isNotEmpty
                          ? controller.exchangeError.value
                          : 'exchangeRateValue'.trParams({
                              'rate': controller.formatExchangeNumber(
                                controller.exchangeRate.value,
                              ),
                              'from': fromCurrency.code,
                              'to': toCurrency.code,
                              'date': controller.exchangeRateDate.value.isEmpty
                                  ? 'now'.tr
                                  : controller.exchangeRateDate.value,
                            }),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: controller.exchangeError.value.isNotEmpty
                          ? TextAlign.start
                          : TextAlign.left,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: controller.exchangeError.value.isNotEmpty
                                ? AppColors.redColor
                                : AppColors.customGreyColor5,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _CurrencyDropdown extends GetView<ChecksController> {
  const _CurrencyDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark ? AppColors.customGreyColor4 : AppColors.whiteColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      ),
      items: controller.exchangeCurrencies.map((currency) {
        return DropdownMenuItem<String>(
          value: currency.code,
          child: Text(
            '${currency.symbol} ${currency.translationKey.tr}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
