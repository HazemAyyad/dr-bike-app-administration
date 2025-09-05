import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_text_field.dart';
import '../../controllers/sales_controller.dart';

class BuildItem extends GetView<SalesController> {
  const BuildItem({
    Key? key,
    required this.item,
    required this.index,
    required this.animation,
  }) : super(key: key);

  final ItemModel item;
  final int index;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: Row(
        children: [
          Expanded(
            child: CustomTextField(
              isRequired: true,
              label: 'quantity',
              hintText: 'discountExample',
              controller: item.quantityController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                controller.calculateGrandTotal();
              },
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: CustomTextField(
                isRequired: true,
                label: 'price',
                hintText: 'totalExample',
                controller: item.priceController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  controller.calculateGrandTotal();
                }),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Obx(
              () => CustomTextField(
                enabled: false,
                label: 'total',
                hintText: item.total.value.toString(),
                validator: (p0) => null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
