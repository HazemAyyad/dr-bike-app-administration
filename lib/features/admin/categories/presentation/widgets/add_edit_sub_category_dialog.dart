import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/sub_category_model.dart';
import '../controllers/category_management_controller.dart';
import 'add_edit_category_dialog.dart' show CategoryImagePickerArea;

class AddEditSubCategoryDialog extends StatefulWidget {
  const AddEditSubCategoryDialog({
    Key? key,
    required this.controller,
    required this.mainCategoryId,
    required this.mainCategoryName,
    this.subCategory,
  }) : super(key: key);

  final CategoryManagementController controller;
  final int mainCategoryId;
  final String mainCategoryName;
  final SubCategoryModel? subCategory;

  @override
  State<AddEditSubCategoryDialog> createState() =>
      _AddEditSubCategoryDialogState();
}

class _AddEditSubCategoryDialogState extends State<AddEditSubCategoryDialog> {
  late final TextEditingController _nameArCtrl;
  late final TextEditingController _nameEngCtrl;
  late final TextEditingController _nameAbreeCtrl;
  XFile? _selectedImage;

  bool get isEdit => widget.subCategory != null;

  @override
  void initState() {
    super.initState();
    _nameArCtrl =
        TextEditingController(text: widget.subCategory?.nameAr ?? '');
    _nameEngCtrl =
        TextEditingController(text: widget.subCategory?.nameEng ?? '');
    _nameAbreeCtrl =
        TextEditingController(text: widget.subCategory?.nameAbree ?? '');
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEngCtrl.dispose();
    _nameAbreeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _selectedImage = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Dialog(
      backgroundColor: isDark ? AppColors.darkColor : AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                isEdit ? 'editSubCategory'.tr : 'addSubCategory'.tr,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                      color: isDark
                          ? AppColors.whiteColor
                          : AppColors.secondaryColor,
                    ),
              ),
              // Parent label (when adding)
              if (!isEdit && widget.mainCategoryName.isNotEmpty) ...[
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.folder,
                        size: 14.sp, color: AppColors.primaryColor),
                    SizedBox(width: 4.w),
                    Text(
                      widget.mainCategoryName,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            fontSize: 11.sp,
                            color: AppColors.primaryColor,
                          ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 16.h),
              // Image picker
              CategoryImagePickerArea(
                selectedImage: _selectedImage,
                existingImageUrl: widget.subCategory?.imageUrl,
                onTap: _pickImage,
                isDark: isDark,
              ),
              SizedBox(height: 16.h),
              // nameAr
              _buildField(
                context: context,
                ctrl: _nameArCtrl,
                label: 'nameAr'.tr,
                isDark: isDark,
                isRequired: true,
              ),
              SizedBox(height: 12.h),
              // nameEng
              _buildField(
                context: context,
                ctrl: _nameEngCtrl,
                label: 'nameEng'.tr,
                isDark: isDark,
              ),
              SizedBox(height: 12.h),
              // nameAbree
              _buildField(
                context: context,
                ctrl: _nameAbreeCtrl,
                label: 'nameAbree'.tr,
                isDark: isDark,
              ),
              SizedBox(height: 20.h),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Obx(
                      () {
                        final saving = widget.controller.isSaving.value;
                        return AppButton(
                          isSafeArea: false,
                          isLoading: widget.controller.isSaving,
                          text: isEdit ? 'save'.tr : 'add'.tr,
                          onPressed: saving
                              ? null
                              : () => widget.controller.saveSubCategory(
                                    subCategoryId: widget.subCategory?.id,
                                    nameAr: _nameArCtrl.text,
                                    nameEng: _nameEngCtrl.text,
                                    nameAbree: _nameAbreeCtrl.text,
                                    mainCategoryId: widget.mainCategoryId,
                                    image: _selectedImage,
                                  ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required TextEditingController ctrl,
    required String label,
    required bool isDark,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.customGreyColor6
                      : AppColors.secondaryColor,
                ),
            children: isRequired
                ? [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontSize: 12.sp),
                    )
                  ]
                : [],
          ),
        ),
        SizedBox(height: 4.h),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? AppColors.customGreyColor
                : AppColors.customGreyColor7,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            isDense: true,
          ),
          style:
              Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 13.sp),
        ),
      ],
    );
  }
}
