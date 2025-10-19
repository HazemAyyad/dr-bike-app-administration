import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/core/utils/app_colors.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../routes/app_routes.dart';
import '../../controllers/finacial_service.dart';
import '../../controllers/official_papers_controller.dart';
import '../../widgets/official_papers_widgets/add_files_dialog.dart';
import '../../widgets/official_papers_widgets/cancel_file_dialog.dart';
import '../../widgets/official_papers_widgets/custom_data_widget.dart';

class TreasuryScreen extends GetView<OfficialPapersController> {
  const TreasuryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'safes', action: false),
      body: CustomScrollView(
        slivers: [
          Obx(
            () {
              if (controller.isFilesLoading.value) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (FinacialService().safes.isEmpty) {
                return const SliverFillRemaining(
                  child: ShowNoData(),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    mainAxisSpacing: 10.h,
                    crossAxisSpacing: 24.w,
                    mainAxisExtent: 70.h,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final safe = FinacialService().safes[index];
                      return CustomDataWidget(
                        onLongPress: () {
                          Get.dialog(
                            CancelFileDialog(
                              treasuryId: safe.id.toString(),
                              fileName: safe.name,
                            ),
                          );
                        },
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.FILEBOXSCREEN,
                            arguments: {'safesId': safe.id.toString()},
                          );
                        },
                        title: 'safe_name',
                        value: safe.name,
                      );
                    },
                    childCount: FinacialService().safes.length,
                  ),
                ),
              );
            },
          )
        ],
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: SizedBox(
        height: 55.h,
        width: 55.w,
        child: FloatingActionButton(
          onPressed: () {
            Get.dialog(
              AddFilesDialog(
                title: 'create_safe',
                label: 'safe_name',
                hintText: 'safe_name',
                onPressed: () {
                  controller.addSafe();
                },
              ),
            );
          },
          backgroundColor: AppColors.secondaryColor,
          elevation: 2.0,
          shape: const CircleBorder(),
          child: Icon(
            Icons.add,
            color: AppColors.whiteColor,
            size: 42.sp,
          ),
        ),
      ),
    );
  }
}
