import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/expentions.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/stock_images_export_model.dart';
import '../controllers/stock_controller.dart';

class StockImagesExportsScreen extends StatefulWidget {
  const StockImagesExportsScreen({Key? key}) : super(key: key);

  @override
  State<StockImagesExportsScreen> createState() =>
      _StockImagesExportsScreenState();
}

class _StockImagesExportsScreenState extends State<StockImagesExportsScreen> {
  final StockController controller = Get.find<StockController>();
  final RxList<StockImagesExportModel> exports = <StockImagesExportModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxSet<String> deletingIds = <String>{}.obs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadExports();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (exports.any((e) => e.isRunning)) {
        _loadExports(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadExports({bool silent = false}) async {
    if (isLoading.value && !silent) return;
    try {
      if (!silent) isLoading(true);
      final rows =
          await controller.stockDatasource.listProductsImagesZipExports(
        perPage: 50,
      );
      exports.assignAll(rows);
    } on ServerException catch (e) {
      _showError(e.errorModel.errorMessage);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (!silent) isLoading(false);
    }
  }

  Future<void> _startExport() async {
    await controller.startNewProductsImagesZipExport();
    await _loadExports();
  }

  Future<void> _deleteExport(StockImagesExportModel export) async {
    if (export.isRunning ||
        export.isDeleted ||
        deletingIds.contains(export.id)) {
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('deleteStockImagesExportTitle'.tr),
        content: Text('deleteStockImagesExportMessage'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('deleteZipFile'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      deletingIds.add(export.id);
      await controller.stockDatasource.deleteProductsImagesZipExport(
        exportId: export.id,
      );
      Get.snackbar(
        'success'.tr,
        'stockImagesExportDeleted'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await _loadExports(silent: true);
    } on ServerException catch (e) {
      _showError(e.errorModel.errorMessage);
    } catch (e) {
      _showError(e.toString());
    } finally {
      deletingIds.remove(export.id);
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'stockImagesExports'.tr,
        actions: [
          Obx(() {
            return IconButton(
              tooltip: 'refresh'.tr,
              onPressed: isLoading.value ? null : () => _loadExports(),
              icon: isLoading.value
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            );
          }),
          Obx(() {
            final busy = controller.isProductsCsvBusy.value;
            return IconButton(
              tooltip: 'startNewExport'.tr,
              onPressed: busy ? null : _startExport,
              icon: busy
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (isLoading.value && exports.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (exports.isEmpty) {
          return Center(
            child: FilledButton.icon(
              onPressed: _startExport,
              icon: const Icon(Icons.folder_zip_outlined),
              label: Text('startNewExport'.tr),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _loadExports,
          child: ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemBuilder: (context, index) {
              return _ExportTile(
                export: exports[index],
                downloading: controller.isProductsCsvBusy,
                deletingIds: deletingIds,
                onDownload: () async {
                  await controller.downloadProductsImagesZipExport(
                    exports[index].id,
                  );
                  await _loadExports(silent: true);
                },
                onDelete: () => _deleteExport(exports[index]),
              );
            },
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemCount: exports.length,
          ),
        );
      }),
    );
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.export,
    required this.downloading,
    required this.deletingIds,
    required this.onDownload,
    required this.onDelete,
  });

  final StockImagesExportModel export;
  final RxBool downloading;
  final RxSet<String> deletingIds;
  final Future<void> Function() onDownload;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final color = export.isCompleted
        ? Colors.green
        : export.isFailed
            ? Colors.red
            : AppColors.secondaryColor;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_statusIcon(export), color: color),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    '${'operation'.tr} #${export.id}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusChip(status: export.status, color: color),
              ],
            ),
            SizedBox(height: 10.h),
            LinearProgressIndicator(
              value: export.isRunning || export.isCompleted
                  ? export.progress
                  : null,
              minHeight: 6.h,
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 6.h,
              children: [
                _Metric(label: 'products'.tr, value: _progressText(export)),
                _Metric(
                  label: 'imagesAdded'.tr,
                  value: export.imagesAdded.toString(),
                ),
                if (export.fileSizeHuman.isNotEmpty)
                  _Metric(label: 'fileSize'.tr, value: export.fileSizeHuman),
                if (export.createdAt.isNotEmpty)
                  _Metric(label: 'createdAt'.tr, value: export.createdAt),
                if (export.completedAt.isNotEmpty)
                  _Metric(label: 'completedAt'.tr, value: export.completedAt),
              ],
            ),
            if (export.errorMessage.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Text(
                export.errorMessage,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ],
            SizedBox(height: 12.h),
            _SourceSummary(summary: export.sourceSummary),
            if (export.isCompleted ||
                (!export.isRunning && !export.isDeleted)) ...[
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!export.isRunning && !export.isDeleted)
                    Obx(() {
                      final deleting = deletingIds.contains(export.id);
                      return TextButton.icon(
                        onPressed: deleting ? null : onDelete,
                        icon: deleting
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                        label: Text('deleteZipFile'.tr),
                      );
                    }),
                  if (export.isCompleted) ...[
                    SizedBox(width: 8.w),
                    Obx(() {
                      return FilledButton.icon(
                        onPressed: downloading.value ? null : onDownload,
                        icon: downloading.value
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.file_download_outlined),
                        label: Text('download'.tr),
                      );
                    }),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(StockImagesExportModel export) {
    if (export.isCompleted) return Icons.check_circle_outline;
    if (export.isDeleted) return Icons.delete_outline;
    if (export.isFailed) return Icons.error_outline;
    return Icons.hourglass_top_outlined;
  }

  String _progressText(StockImagesExportModel export) {
    if (export.totalProducts <= 0) {
      return export.processedProducts.toString();
    }
    return '${export.processedProducts}/${export.totalProducts}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'stockExportStatus_$status'.tr,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12.sp,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 12.sp),
      ),
    );
  }
}

class _SourceSummary extends StatelessWidget {
  const _SourceSummary({required this.summary});

  final StockImagesExportSourceSummary summary;

  @override
  Widget build(BuildContext context) {
    final hasAny = summary.sources.isNotEmpty || summary.tables.isNotEmpty;
    if (!hasAny) {
      return Text(
        'stockImagesSourcesPending'.tr,
        style: TextStyle(color: Colors.grey.shade700),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'stockImagesSources'.tr,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 6.h),
        ...summary.sources.map(
          (source) => Text(
            '${source.label} (${source.imagesAdded})',
            style: TextStyle(fontSize: 12.sp),
          ),
        ),
        if (summary.tables.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Text(
            'stockImagesTables'.tr,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6.h),
          ...summary.tables
              .where((table) =>
                  table.linksSeen > 0 ||
                  table.imagesAdded > 0 ||
                  table.missingImages > 0)
              .map(
                (table) => Text(
                  '${table.label}: ${table.imagesAdded}/${table.linksSeen}'
                  '${table.missingImages > 0 ? ' - ${'missingImages'.tr}: ${table.missingImages}' : ''}',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
        ],
      ],
    );
  }
}
