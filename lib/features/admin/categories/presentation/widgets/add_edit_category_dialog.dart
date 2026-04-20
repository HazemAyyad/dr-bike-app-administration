import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/category_model.dart';
import '../controllers/category_management_controller.dart';

class AddEditCategoryDialog extends StatefulWidget {
  const AddEditCategoryDialog({
    Key? key,
    required this.controller,
    this.category,
  }) : super(key: key);

  final CategoryManagementController controller;
  final CategoryModel? category;

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  late final TextEditingController _nameArCtrl;
  late final TextEditingController _nameEngCtrl;
  late final TextEditingController _nameAbreeCtrl;
  XFile? _selectedImage;

  bool get isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameArCtrl = TextEditingController(text: widget.category?.nameAr ?? '');
    _nameEngCtrl = TextEditingController(text: widget.category?.nameEng ?? '');
    _nameAbreeCtrl = TextEditingController(text: widget.category?.nameAbree ?? '');
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
                isEdit ? 'editCategory'.tr : 'addCategory'.tr,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                      color: isDark ? AppColors.whiteColor : AppColors.secondaryColor,
                    ),
              ),
              SizedBox(height: 16.h),
              // Image picker
              CategoryImagePickerArea(
                selectedImage: _selectedImage,
                existingImageUrl: widget.category?.imageUrl,
                onTap: _pickImage,
                isDark: isDark,
              ),
              SizedBox(height: 16.h),
              // nameAr
              _buildField(
                context: context,
                controller: _nameArCtrl,
                label: 'nameAr'.tr,
                isDark: isDark,
                isRequired: true,
              ),
              SizedBox(height: 12.h),
              // nameEng
              _buildField(
                context: context,
                controller: _nameEngCtrl,
                label: 'nameEng'.tr,
                isDark: isDark,
              ),
              SizedBox(height: 12.h),
              // nameAbree
              _buildField(
                context: context,
                controller: _nameAbreeCtrl,
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
                              : () => widget.controller.saveCategory(
                                    context: context,
                                    categoryId: widget.category?.id,
                                    nameAr: _nameArCtrl.text,
                                    nameEng: _nameEngCtrl.text,
                                    nameAbree: _nameAbreeCtrl.text,
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
    required TextEditingController controller,
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
                  color: isDark ? AppColors.customGreyColor6 : AppColors.secondaryColor,
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
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.customGreyColor : AppColors.customGreyColor7,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 13.sp),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared image picker area widget (reused in sub-category dialog too)
// ─────────────────────────────────────────────────────────────────────────────

class CategoryImagePickerArea extends StatelessWidget {
  const CategoryImagePickerArea({
    required this.selectedImage,
    required this.existingImageUrl,
    required this.onTap,
    required this.isDark,
  });

  final XFile? selectedImage;
  final String? existingImageUrl;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasExisting = existingImageUrl != null && existingImageUrl!.isNotEmpty;

    Widget imageContent;
    if (selectedImage != null) {
      imageContent = ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: Image.file(
          File(selectedImage!.path),
          width: double.infinity,
          height: 130.h,
          fit: BoxFit.cover,
        ),
      );
    } else if (hasExisting) {
      imageContent = ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: CachedNetworkImage(
          imageUrl: ShowNetImage.getPhoto(existingImageUrl),
          width: double.infinity,
          height: 130.h,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _placeholder(context),
        ),
      );
    } else {
      imageContent = _placeholder(context);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 130.h,
        decoration: BoxDecoration(
          color: isDark ? AppColors.customGreyColor : AppColors.customGreyColor7,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppColors.primaryColor.withAlpha(120),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            imageContent,
            Positioned(
              bottom: 6.h,
              right: 6.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 12.sp),
                    SizedBox(width: 4.w),
                    Text(
                      'changeImage'.tr,
                      style: TextStyle(color: Colors.white, fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 36.sp, color: AppColors.primaryColor),
          SizedBox(height: 6.h),
          Text(
            'selectImage'.tr,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
