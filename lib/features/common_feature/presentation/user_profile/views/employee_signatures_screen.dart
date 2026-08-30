import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/widgets/skeleton_loading.dart';
import '../controllers/employee_signatures_controller.dart';
import '../widgets/signature_capture_flow.dart';

class EmployeeSignaturesScreen extends GetView<EmployeeSignaturesController> {
  const EmployeeSignaturesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: CustomAppBar(
          title: 'توقيعاتي',
          action: false,
          actions: [
            IconButton(
              tooltip: 'إضافة توقيع',
              onPressed: () => _add(context),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.signatures.isEmpty) {
            return ListView.separated(
              padding: EdgeInsets.all(14.r),
              itemCount: 4,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (_, index) => SkeletonBlock(
                width: double.infinity,
                height: index == 0 ? 145.h : 125.h,
                radius: 16,
              ),
            );
          }
          final defaultSignature = controller.defaultSignature;
          final others = controller.signatures
              .where((signature) => !signature.isDefault)
              .toList();
          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 90.h),
              children: [
                _Hero(count: controller.signatures.length),
                SizedBox(height: 12.h),
                if (defaultSignature == null && others.isEmpty)
                  _Empty(onAdd: () => _add(context))
                else ...[
                  if (defaultSignature != null) ...[
                    const _SectionTitle(
                      title: 'التوقيع الافتراضي',
                      subtitle: 'يظهر أولًا عند تأكيد استلام الراتب',
                    ),
                    SizedBox(height: 7.h),
                    _SignatureCard(
                      signature: defaultSignature,
                      controller: controller,
                      onRename: () => _rename(context, defaultSignature),
                      onDelete: () => _delete(context, defaultSignature),
                    ),
                    SizedBox(height: 14.h),
                  ],
                  if (others.isNotEmpty) ...[
                    _SectionTitle(
                      title: 'توقيعات أخرى',
                      subtitle: '${others.length} توقيع محفوظ',
                    ),
                    SizedBox(height: 7.h),
                    ...others.map((signature) => Padding(
                          padding: EdgeInsets.only(bottom: 9.h),
                          child: _SignatureCard(
                            signature: signature,
                            controller: controller,
                            onRename: () => _rename(context, signature),
                            onDelete: () => _delete(context, signature),
                          ),
                        )),
                  ],
                ],
              ],
            ),
          );
        }),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _add(context),
          backgroundColor: AppColors.operationalPurple,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.draw_rounded),
          label: const Text('إضافة توقيع'),
        ),
      );

  Future<void> _add(BuildContext context) async {
    final capture = await showEmployeeSignatureCapture(context);
    if (capture == null || !context.mounted) return;
    final name = TextEditingController(
      text: controller.signatures.isEmpty
          ? 'التوقيع الرسمي'
          : 'توقيع ${controller.signatures.length + 1}',
    );
    final makeDefault = controller.signatures.isEmpty.obs;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حفظ التوقيع'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            height: 115.h,
            width: double.infinity,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13.r),
              border: Border.all(color: AppColors.operationalCardBorder),
            ),
            child: Image.memory(capture.processedBytes, fit: BoxFit.contain),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'اسم التوقيع',
              hintText: 'مثال: التوقيع الرسمي',
              border: OutlineInputBorder(),
            ),
          ),
          Obx(() => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: makeDefault.value,
                onChanged: (value) => makeDefault.value = value ?? false,
                title: const Text('تعيينه كتوقيع افتراضي'),
                subtitle: const Text('يمكن تغييره لاحقًا من قائمة التوقيعات'),
              )),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          Obx(() => FilledButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () => Navigator.pop(context, true),
                child: const Text('حفظ واعتماد'),
              )),
        ],
      ),
    );
    if (accepted == true) {
      await controller.create(
        name: name.text,
        source: capture.source,
        originalBytes: capture.originalBytes,
        isDefault: makeDefault.value,
      );
    }
    name.dispose();
  }

  Future<void> _rename(
    BuildContext context,
    EmployeeSignatureModel signature,
  ) async {
    final name = TextEditingController(text: signature.name);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل اسم التوقيع'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (accepted == true) await controller.rename(signature, name.text);
    name.dispose();
  }

  Future<void> _delete(
    BuildContext context,
    EmployeeSignatureModel signature,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded,
            color: Colors.red, size: 40),
        title: const Text('حذف التوقيع؟'),
        content: Text(
          signature.isDefault && controller.signatures.length > 1
              ? 'سيتم حذف ${signature.name} واختيار أحدث توقيع آخر كافتراضي. سندات الرواتب السابقة لن تتأثر.'
              : 'سيتم حذف ${signature.name} من ملفك. سندات الرواتب السابقة لن تتأثر.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (accepted == true) await controller.deleteSignature(signature);
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.operationalNavy, AppColors.operationalPurple],
          ),
          borderRadius: BorderRadius.circular(19.r),
        ),
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: Colors.white, size: 30),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('توقيعاتك المعتمدة',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900)),
                Text(
                  'احفظ أكثر من توقيع واختر واحدًا افتراضيًا • $count محفوظ',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .75),
                      fontSize: 11.sp),
                ),
              ],
            ),
          ),
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ]);
}

class _SignatureCard extends StatelessWidget {
  const _SignatureCard({
    required this.signature,
    required this.controller,
    required this.onRename,
    required this.onDelete,
  });
  final EmployeeSignatureModel signature;
  final EmployeeSignaturesController controller;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: signature.isDefault
              ? AppColors.customGreen1.withValues(alpha: .055)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: signature.isDefault
                ? AppColors.customGreen1
                : AppColors.operationalCardBorder,
            width: signature.isDefault ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 112.w,
            height: 78.h,
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: CachedNetworkImage(
              imageUrl: signature.imageUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(signature.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  if (signature.isDefault)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppColors.customGreen1,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: const Text('افتراضي',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900)),
                    ),
                ]),
                SizedBox(height: 4.h),
                Text(_sourceLabel(signature.source),
                    style: Theme.of(context).textTheme.bodySmall),
                if (!signature.isDefault)
                  TextButton.icon(
                    onPressed: () => controller.makeDefault(signature),
                    icon: const Icon(Icons.star_outline_rounded, size: 18),
                    label: const Text('تعيين كافتراضي'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rename') onRename();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('تعديل الاسم')),
              PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف', style: TextStyle(color: Colors.red))),
            ],
          ),
        ]),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: AppColors.operationalSurface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.operationalCardBorder),
        ),
        child: Column(children: [
          Icon(Icons.draw_outlined,
              size: 52.sp, color: AppColors.operationalPurple),
          SizedBox(height: 9.h),
          const Text('لا يوجد توقيع محفوظ',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const Text(
            'أضف توقيعك يدويًا أو صوّره أو ارفعه من الجهاز.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 13.h),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة أول توقيع'),
          ),
        ]),
      );
}

String _sourceLabel(String source) {
  if (source == 'manual') return 'توقيع يدوي داخل التطبيق';
  if (source == 'camera') return 'تم تصويره بالكاميرا';
  if (source == 'upload') return 'تم رفعه من الجهاز';
  return 'توقيع محفوظ';
}
