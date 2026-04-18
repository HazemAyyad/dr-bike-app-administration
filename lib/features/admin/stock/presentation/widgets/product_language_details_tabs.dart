import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/product_details_model.dart';
import 'custom_text_and_dis.dart';

/// Read-only Arabic / English / Hebrew tabs for name + description on product details.
class ProductLanguageDetailsTabs extends StatelessWidget {
  const ProductLanguageDetailsTabs({Key? key, required this.product})
      : super(key: key);

  final ProductDetailsModel product;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            labelColor: cs.primary,
            unselectedLabelColor: Theme.of(context).hintColor,
            indicatorColor: cs.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'langArabic'.tr),
              Tab(text: 'langEnglish'.tr),
              Tab(text: 'langHebrew'.tr),
            ],
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 200.h,
            child: TabBarView(
              children: [
                _langPane(
                  name: product.nameAr,
                  description: product.descriptionAr ?? '',
                ),
                _langPane(
                  name: product.nameEng,
                  description: product.descriptionEng ?? '',
                ),
                _langPane(
                  name: product.nameAbree ?? '',
                  description: product.descriptionAbree ?? '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _langPane({required String name, required String description}) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextAndDis(
            title: 'productName',
            discription: name.isEmpty ? '—' : name,
          ),
          CustomTextAndDis(
            title: 'productDetails',
            discription: description.isEmpty ? '—' : description,
          ),
        ],
      ),
    );
  }
}
