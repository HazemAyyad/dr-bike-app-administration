import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_phone_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/general_data_list_controller.dart';
import 'person_product_settings_screen.dart';

class AddNewCustomerScreen extends StatefulWidget {
  const AddNewCustomerScreen({Key? key}) : super(key: key);

  @override
  State<AddNewCustomerScreen> createState() => _AddNewCustomerScreenState();
}

class _AddNewCustomerScreenState extends State<AddNewCustomerScreen> {
  final formKey = GlobalKey<FormState>();
  final GeneralDataListController controller =
      Get.find<GeneralDataListController>();

  @override
  Widget build(BuildContext context) {
    final sellerId = Get.arguments['sellerId'];
    final employeeId = Get.arguments['employeeId'];
    final employeeType = Get.arguments['employeeType'];

    return Scaffold(
      appBar: CustomAppBar(
        title: controller.isEdit.value ? 'editCustomer' : 'addNewCustomer',
        action: false,
      ),
      body: Form(
        key: formKey,
        child: GetBuilder<GeneralDataListController>(
          builder: (controller) {
            if (controller.isEditLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 16.h),
              children: [
                _CustomerActionsBar(
                  controller: controller,
                  sellerId: sellerId,
                  employeeId: employeeId,
                  employeeType: employeeType,
                ),
                SizedBox(height: 8.h),
                _CustomerFormSection(
                  icon: Icons.person_outline,
                  title: 'البيانات الأساسية',
                  children: [
                    _AdaptiveFields(
                      children: [
                        _AdaptiveField(
                          width: .58,
                          child: CustomTextField(
                            isRequired: true,
                            label: 'customerName',
                            hintText: 'customerNameExample',
                            controller: controller.customerNameController,
                          ),
                        ),
                        _AdaptiveField(
                          width: .42,
                          child: CustomDropdownField(
                            isRequired: true,
                            label: 'customerTypeTitle',
                            hint: 'customerNameExample',
                            value: controller.selectedCustomerType.text.isEmpty
                                ? null
                                : controller.selectedCustomerType.text,
                            items: controller.customerTypeList,
                            onChanged: (value) {
                              controller.selectedCustomerType.text = value!;
                            },
                            border:
                                Border.all(color: AppColors.customGreyColor3),
                          ),
                        ),
                        _AdaptiveField(
                          width: .50,
                          child: CustomPhoneField(
                            label: 'customerPhoneNumber',
                            hintText: 'phoneNumberExample',
                            controller: controller.phoneNumberController,
                          ),
                        ),
                        _AdaptiveField(
                          width: .50,
                          child: CustomPhoneField(
                            label: 'alternatePhone',
                            hintText: 'phoneNumberExample',
                            controller: controller.subPhoneNumberController,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                _CustomerFormSection(
                  icon: Icons.alternate_email_outlined,
                  title: 'التواصل والسوشال',
                  collapsible: true,
                  initiallyExpanded: false,
                  children: [
                    _AdaptiveFields(
                      children: [
                        _AdaptiveField(
                          width: .50,
                          child: CustomTextField(
                            label: 'facebookName',
                            hintText: 'facebookNameExample',
                            controller: controller.facebookNameController,
                            validator: (p0) => null,
                          ),
                        ),
                        _AdaptiveField(
                          width: .50,
                          child: CustomTextField(
                            label: 'facebookLink',
                            hintText: 'facebookLinkExample',
                            controller: controller.facebookLinkController,
                            validator: (p0) => null,
                          ),
                        ),
                        _AdaptiveField(
                          width: .50,
                          child: CustomTextField(
                            label: 'instagramName',
                            hintText: 'instagramNameExample',
                            controller: controller.instagramNameController,
                            validator: (p0) => null,
                          ),
                        ),
                        _AdaptiveField(
                          width: .50,
                          child: CustomTextField(
                            label: 'instagramLink',
                            hintText: 'instagramLinkExample',
                            controller: controller.instagramLinkController,
                            validator: (p0) => null,
                          ),
                        ),
                        _AdaptiveField(
                          width: 1,
                          child: CustomDropdownFieldWithSearch(
                            tital: 'closeContacts',
                            hint: controller.closePeopleController.text.isEmpty
                                ? 'customerNameExample'
                                : controller.closePeopleController.text,
                            labelStyle:
                                controller.closePeopleController.text.isEmpty
                                    ? null
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: AppColors.blackColor,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                            items: controller.closePeopleList,
                            onChanged: (value) {
                              controller.closePeopleController.text =
                                  value!.name;
                            },
                            itemAsString: (item) => item.name,
                            compareFn: (item, value) => item.id == value.id,
                            validator: (p0) => null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                _CustomerFormSection(
                  icon: Icons.category_outlined,
                  title: 'تصنيفات العملاء والموردين',
                  collapsible: true,
                  initiallyExpanded: false,
                  trailing: TextButton.icon(
                    onPressed: () => Get.toNamed(
                      AppRoutes.CONTACTCATEGORIESSETTINGSSCREEN,
                    )?.then((_) => controller.getContactCategories()),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      minimumSize: Size(0, 34.h),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('إدارة'),
                  ),
                  children: [
                    Text(
                      'يمكن اختيار أكثر من تصنيف لنفس العميل أو المورد',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.customGreyColor2,
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    controller.contactCategories.isEmpty
                        ? Text(
                            'لا توجد تصنيفات',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: AppColors.customGreyColor2,
                              fontSize: 13.sp,
                            ),
                          )
                        : Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: controller.contactCategories.map(
                              (category) {
                                final selected = controller
                                    .selectedContactCategoryIds
                                    .contains(category.id);
                                return FilterChip(
                                  label: Text(category.name),
                                  selected: selected,
                                  selectedColor: AppColors.primaryColor
                                      .withValues(alpha: .16),
                                  checkmarkColor: AppColors.primaryColor,
                                  avatar: CircleAvatar(
                                    radius: 5.r,
                                    backgroundColor: _contactCategoryColor(
                                      category.color,
                                    ),
                                  ),
                                  onSelected: (_) => controller
                                      .toggleContactCategory(category.id),
                                );
                              },
                            ).toList(),
                          ),
                  ],
                ),
                SizedBox(height: 8.h),
                _CustomerFormSection(
                  icon: Icons.photo_library_outlined,
                  title: 'الصور والوثائق',
                  collapsible: true,
                  initiallyExpanded: false,
                  children: [
                    MediaUploadButton(
                      allowedType: MediaType.image,
                      title: 'personalIdImage',
                      initialFiles: controller.personalIdImage,
                      onFilesChanged: (files) {
                        controller.personalIdImage = List.of(files);
                        controller.update();
                      },
                    ),
                    SizedBox(height: 8.h),
                    MediaUploadButton(
                      allowedType: MediaType.image,
                      title: 'carLicenseImage',
                      initialFiles: controller.licenseImage,
                      onFilesChanged: (files) {
                        controller.licenseImage = List.of(files);
                        controller.update();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                _CustomerFormSection(
                  icon: Icons.home_work_outlined,
                  title: 'السكن والعمل والقريب',
                  collapsible: true,
                  initiallyExpanded: false,
                  children: [
                    _AdaptiveFields(
                      children: [
                        _AdaptiveField(
                          width: .50,
                          child: CustomTextField(
                            label: 'residenceLocation',
                            hintText: 'residenceLocationExample',
                            controller: controller.residenceLocationController,
                            validator: (p0) => null,
                          ),
                        ),
                        _AdaptiveField(
                          width: .50,
                          child: CustomTextField(
                            label: 'work',
                            hintText: 'workExample',
                            controller: controller.workController,
                            validator: (p0) => null,
                          ),
                        ),
                        _AdaptiveField(
                          width: .50,
                          child: CustomTextField(
                            label: 'closestPersonWork',
                            hintText: 'workTitleExample',
                            controller: controller.closestPersonWorkController,
                            validator: (p0) => null,
                          ),
                        ),
                        _AdaptiveField(
                          width: .50,
                          child: CustomTextField(
                            label: 'workLocation',
                            hintText: 'residenceLocationExample',
                            controller: controller.workLocationController,
                            validator: (p0) => null,
                          ),
                        ),
                        _AdaptiveField(
                          width: .50,
                          child: CustomPhoneField(
                            label: 'closestPersonNumber',
                            hintText: 'phoneNumberExample',
                            controller:
                                controller.closestPersonNumberController,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                AppButton(
                  isLoading: controller.isLoading,
                  text:
                      controller.isEdit.value ? 'editCustomer' : 'addCustomer',
                  textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                  height: 48.h,
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    if (controller.isEdit.value) {
                      controller.addPerson(
                        context: context,
                        validateForm: false,
                        customerId: controller.currentTab.value == 1
                            ? employeeId
                            : employeeType == 'customer'
                                ? employeeId
                                : '',
                        sellerId: controller.currentTab.value == 0
                            ? sellerId
                            : employeeType == 'seller'
                                ? sellerId
                                : '',
                      );
                    } else {
                      controller.addPerson(
                        context: context,
                        validateForm: false,
                      );
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CustomerActionsBar extends StatelessWidget {
  const _CustomerActionsBar({
    required this.controller,
    required this.sellerId,
    required this.employeeId,
    required this.employeeType,
  });

  final GeneralDataListController controller;
  final dynamic sellerId;
  final dynamic employeeId;
  final dynamic employeeType;

  @override
  Widget build(BuildContext context) {
    if (!controller.isEdit.value) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          onPressed: () => controller.importFromContacts(context),
          icon: Icon(Icons.contacts_outlined, size: 19.sp),
          label: Text('importContacts'.tr),
        ),
      );
    }

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        onPressed: () {
          final isSeller =
              controller.currentTab.value == 0 || employeeType == 'seller';
          Get.to(
            () => PersonProductSettingsScreen(
              personName: controller.customerNameController.text,
              customerId: isSeller ? null : employeeId.toString(),
              sellerId: isSeller ? sellerId.toString() : null,
            ),
          );
        },
        icon: const Icon(Icons.price_change_outlined),
        label: const Text('تعديل أسعار وإظهار المنتجات'),
      ),
    );
  }
}

class _CustomerFormSection extends StatefulWidget {
  const _CustomerFormSection({
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final bool collapsible;
  final bool initiallyExpanded;

  @override
  State<_CustomerFormSection> createState() => _CustomerFormSectionState();
}

class _CustomerFormSectionState extends State<_CustomerFormSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final showBody = !widget.collapsible || _expanded;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkColor : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.collapsible
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: BorderRadius.circular(8.r),
            child: Row(
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Icon(
                    widget.icon,
                    color: AppColors.primaryColor,
                    size: 17.sp,
                  ),
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                        ),
                  ),
                ),
                if (widget.trailing != null && showBody) widget.trailing!,
                if (widget.collapsible)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primaryColor,
                  ),
              ],
            ),
          ),
          if (showBody) ...[
            SizedBox(height: 9.h),
            ...widget.children,
          ],
        ],
      ),
    );
  }
}

class _AdaptiveField {
  const _AdaptiveField({required this.child, this.width = .5});

  final Widget child;
  final double width;
}

class _AdaptiveFields extends StatelessWidget {
  const _AdaptiveFields({required this.children});

  final List<_AdaptiveField> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        final gap = 10.w;
        if (!wide) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i].child,
                if (i != children.length - 1) SizedBox(height: 8.h),
              ],
            ],
          );
        }
        return Wrap(
          spacing: gap,
          runSpacing: 12.h,
          children: children.map((field) {
            final width = (constraints.maxWidth * field.width) - gap;
            return SizedBox(
              width: width.clamp(180.0, constraints.maxWidth),
              child: field.child,
            );
          }).toList(),
        );
      },
    );
  }
}

Color _contactCategoryColor(String value) {
  final hex = value.replaceAll('#', '').trim();
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
    return AppColors.primaryColor;
  }
  return Color(int.parse('ff$hex', radix: 16));
}
