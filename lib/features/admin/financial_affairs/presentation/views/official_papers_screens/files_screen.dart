import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/core/utils/app_colors.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../controllers/finacial_service.dart';
import '../../controllers/official_papers_controller.dart';
import '../../widgets/official_papers_widgets/add_files_dialog.dart';
import '../../widgets/official_papers_widgets/cancel_file_dialog.dart';
import '../../widgets/official_papers_widgets/custom_data_widget.dart';
import '../../widgets/official_papers_widgets/show_files_data.dart';

class FilesScreen extends GetView<OfficialPapersController> {
  const FilesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String fileBoxId = Get.arguments['fileBoxId'];
    final String safesId = Get.arguments['safesId'];

    return Scaffold(
      appBar: CustomAppBar(
        title: FinacialService()
            .safes
            .where((element) => element.id.toString() == safesId)
            .first
            .fileBoxes
            .where((element) => element.id.toString() == fileBoxId)
            .first
            .name,
        action: false,
      ),
      body: CustomScrollView(
        slivers: [
          Obx(
            () {
              final files = FinacialService()
                  .safes
                  .where((element) => element.id.toString() == safesId)
                  .first
                  .fileBoxes
                  .where((element) => element.id.toString() == fileBoxId)
                  .first;
              if (controller.isFilesLoading.value) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (files.files.isEmpty) {
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
                      final data = files.files[index];
                      return CustomDataWidget(
                        onLongPress: () {
                          Get.dialog(
                            CancelFileDialog(
                              fileId: data.id.toString(),
                              fileName: data.name,
                            ),
                          );
                        },
                        onTap: () {
                          controller.getFileData(fileId: data.id.toString());
                          Get.dialog(ShowFilesData(data: data));
                        },
                        title: "",
                        value: data.name,
                      );
                    },
                    childCount: files.files.length,
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
                title: 'create_file',
                label: 'file_name',
                hintText: 'file_name',
                onPressed: () {
                  controller.addSafe(
                    fileBoxId: fileBoxId,
                  );
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
