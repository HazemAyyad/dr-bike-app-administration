import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/helpers/video_view.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../whatsapp_center/presentation/views/whatsapp_camera_screen.dart';
import '../../data/models/maintenance_service_model.dart';
import '../../data/repositories/maintenance_implement.dart';

class MaintenanceServicesSettingsScreen extends StatefulWidget {
  const MaintenanceServicesSettingsScreen({Key? key}) : super(key: key);

  @override
  State<MaintenanceServicesSettingsScreen> createState() =>
      _MaintenanceServicesSettingsScreenState();
}

class _MaintenanceServicesSettingsScreenState
    extends State<MaintenanceServicesSettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RxBool _loading = false.obs;
  final RxList<MaintenanceServiceModel> _services =
      <MaintenanceServiceModel>[].obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    _loading(true);
    try {
      final datasource = Get.find<MaintenanceImplement>().maintenanceDatasource;
      final rows = await datasource.getMaintenanceServices(search: search);
      _services.assignAll(rows);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _loading(false);
    }
  }

  Future<void> _openEditor([MaintenanceServiceModel? service]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => _MaintenanceServiceEditor(service: service),
    );
    if (saved == true) {
      await _load(search: _searchController.text);
    }
  }

  Future<void> _delete(MaintenanceServiceModel service) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('حذف خدمة'),
        content: Text('هل تريد حذف "${service.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final datasource = Get.find<MaintenanceImplement>().maintenanceDatasource;
      final response = await datasource.deleteMaintenanceService(service.id);
      if (response['status'] == 'success') {
        await _load(search: _searchController.text);
      } else {
        Get.snackbar('error'.tr, response['message']?.toString() ?? '');
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CustomAppBar(
        title: 'خدمات الصيانة',
        action: false,
        backgroundColor: Color(0xFFF5F5F5),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن خدمة',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => _load(search: value),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: Obx(() {
                if (_loading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_services.isEmpty) {
                  return Center(child: Text('noData'.tr));
                }
                return ListView.separated(
                  itemCount: _services.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (_, index) {
                    final service = _services[index];
                    return _ServiceCard(
                      service: service,
                      onEdit: () => _openEditor(service),
                      onDelete: () => _delete(service),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  final MaintenanceServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.home_repair_service_outlined,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${service.price.toStringAsFixed(2)} شيكل',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          if (service.media.isNotEmpty) ...[
            SizedBox(height: 10.h),
            SizedBox(
              height: 76.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: service.media.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (_, index) {
                  final media = service.media[index];
                  final url = ShowNetImage.getPhoto(media.url);
                  return GestureDetector(
                    onTap: () => showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'Dismiss',
                      barrierColor: Colors.black.withAlpha(128),
                      transitionDuration: Duration.zero,
                      pageBuilder: (_, __, ___) => media.isVideo
                          ? VideoView(videoPath: url)
                          : FullScreenZoomImage(imageUrl: url),
                    ),
                    child: SizedBox(
                      width: 76.w,
                      height: 76.h,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            media.isVideo
                                ? ColoredBox(
                                    color: AppColors.primaryColor
                                        .withValues(alpha: 0.12),
                                    child: Icon(
                                      Icons.videocam_outlined,
                                      color: AppColors.primaryColor,
                                      size: 28.sp,
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        const Icon(Icons.broken_image_outlined),
                                  ),
                            if (media.isVideo)
                              const Align(
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'edit'.tr,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'delete'.tr,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaintenanceServiceEditor extends StatefulWidget {
  const _MaintenanceServiceEditor({this.service});

  final MaintenanceServiceModel? service;

  @override
  State<_MaintenanceServiceEditor> createState() =>
      _MaintenanceServiceEditorState();
}

class _MaintenanceServiceEditorState extends State<_MaintenanceServiceEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  final List<File> _newMedia = [];
  final ImagePicker _picker = ImagePicker();
  late final Set<int> _keepMediaIds;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _nameController = TextEditingController(text: service?.name ?? '');
    _priceController = TextEditingController(
      text: service == null ? '' : service.price.toStringAsFixed(2),
    );
    _isActive = service?.isActive ?? true;
    _keepMediaIds = service?.media.map((item) => item.id).toSet() ?? <int>{};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('تصوير صورة أو فيديو'),
                onTap: () {
                  Navigator.pop(context);
                  _captureMedia();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('اختيار صور من الاستديو'),
                onTap: () {
                  Navigator.pop(context);
                  _pickGalleryImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('اختيار فيديو من الاستديو'),
                onTap: () {
                  Navigator.pop(context);
                  _pickGalleryVideo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureMedia() async {
    final result = await Get.to<WhatsAppCapture>(
      () => const WhatsAppCameraScreen(),
    );
    if (result == null || result.path.isEmpty) return;
    final file = File(result.path);
    if (!await file.exists()) return;
    setState(() {
      if (!_newMedia.any((item) => item.path == file.path)) {
        _newMedia.add(file);
      }
    });
  }

  Future<void> _pickGalleryImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;
    setState(() {
      for (final image in images) {
        final file = File(image.path);
        if (!_newMedia.any((item) => item.path == file.path)) {
          _newMedia.add(file);
        }
      }
    });
  }

  Future<void> _pickGalleryVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    final file = File(video.path);
    setState(() {
      if (!_newMedia.any((item) => item.path == file.path)) {
        _newMedia.add(file);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final datasource = Get.find<MaintenanceImplement>().maintenanceDatasource;
      final response = await datasource.saveMaintenanceService(
        serviceId: widget.service?.id,
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        isActive: _isActive,
        media: _newMedia,
        keepMediaIds: _keepMediaIds.toList(),
      );
      if (response['status'] == 'success') {
        Get.back(result: true);
      } else {
        Get.snackbar('error'.tr, response['message']?.toString() ?? '');
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.service?.media
            .where((item) => _keepMediaIds.contains(item.id))
            .toList() ??
        const <MaintenanceServiceMediaModel>[];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 16.h,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16.h,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.service == null ? 'خدمة جديدة' : 'تعديل خدمة',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 14.h),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الخدمة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'مطلوب' : null,
                ),
                SizedBox(height: 10.h),
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'قيمة العمل بالشيكل',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      double.tryParse(value?.trim() ?? '') == null
                          ? 'أدخل رقم صحيح'
                          : null,
                ),
                SwitchListTile(
                  value: _isActive,
                  title: const Text('فعالة'),
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                OutlinedButton.icon(
                  onPressed: _pickMedia,
                  icon: const Icon(Icons.perm_media_outlined),
                  label: const Text('إضافة فيديو أو صور'),
                ),
                if (existing.isNotEmpty || _newMedia.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      ...existing.map(
                        (media) => _MediaChip(
                          label: media.isVideo ? 'فيديو محفوظ' : 'صورة محفوظة',
                          onRemove: () =>
                              setState(() => _keepMediaIds.remove(media.id)),
                        ),
                      ),
                      ..._newMedia.map(
                        (file) => _MediaChip(
                          label: file.path.split(Platform.pathSeparator).last,
                          onRemove: () =>
                              setState(() => _newMedia.remove(file)),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('save'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaChip extends StatelessWidget {
  const _MediaChip({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: SizedBox(
        width: 140.w,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemove,
    );
  }
}
