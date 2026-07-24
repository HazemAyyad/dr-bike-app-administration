import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/custom_app_bar.dart';

class DatabaseBackupsScreen extends StatefulWidget {
  const DatabaseBackupsScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseBackupsScreen> createState() => _DatabaseBackupsScreenState();
}

class _DatabaseBackupsScreenState extends State<DatabaseBackupsScreen> {
  final _backups = <DatabaseBackupFile>[].obs;
  final _loading = true.obs;
  final _downloading = <String>{}.obs;
  String _scheduleHuman = 'كل ساعة';
  int _keepDays = 4;

  DioConsumer get _api => Get.find<DioConsumer>();

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    _loading.value = true;
    try {
      final response = await _api.get(EndPoints.databaseBackups);
      final data = response.data;
      if (data is Map && data['status']?.toString() == 'success') {
        _scheduleHuman = data['schedule_human']?.toString() ?? _scheduleHuman;
        _keepDays =
            int.tryParse(data['keep_days']?.toString() ?? '') ?? _keepDays;
        final rows = data['backups'];
        _backups.assignAll(
          rows is List
              ? rows
                  .whereType<Map>()
                  .map((row) => DatabaseBackupFile.fromJson(row))
                  .toList()
              : <DatabaseBackupFile>[],
        );
      } else {
        _showMessage(data is Map ? data['message']?.toString() : null,
            isError: true);
      }
    } catch (_) {
      _showMessage('تعذر تحميل قائمة النسخ الاحتياطية', isError: true);
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _downloadBackup(DatabaseBackupFile backup) async {
    if (!backup.canDownload || _downloading.contains(backup.filename)) return;

    _downloading.add(backup.filename);
    try {
      final response = await _api.get(
        EndPoints.databaseBackupDownload(backup.filename),
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = _bytesFromResponse(response.data);
      if (bytes.isEmpty) {
        _showMessage('ملف النسخة فارغ أو غير قابل للتحميل', isError: true);
        return;
      }

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ النسخة الاحتياطية',
        fileName: backup.filename,
        bytes: bytes,
      );

      _showMessage(
        savedPath == null ? 'تم إلغاء التحميل' : 'تم حفظ النسخة بنجاح',
        isError: savedPath == null,
      );
    } catch (_) {
      _showMessage('فشل تحميل النسخة الاحتياطية', isError: true);
    } finally {
      _downloading.remove(backup.filename);
    }
  }

  Uint8List _bytesFromResponse(dynamic data) {
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    return Uint8List(0);
  }

  void _showMessage(String? message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'تنبيه' : 'تم',
      message?.trim().isNotEmpty == true ? message! : 'حدث خطأ غير معروف',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: const CustomAppBar(
        title: 'databaseBackups',
        action: false,
        backgroundColor: pageBg,
      ),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: _loadBackups,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            children: [
              _BackupSummaryCard(
                loading: _loading.value,
                total: _backups.length,
                complete: _backups.where((e) => e.status == 'complete').length,
                failed: _backups.where((e) => e.status == 'failed').length,
                inProgress:
                    _backups.where((e) => e.status == 'in_progress').length,
                scheduleHuman: _scheduleHuman,
                keepDays: _keepDays,
                onRefresh: _loadBackups,
              ),
              SizedBox(height: 12.h),
              if (_loading.value)
                const Center(child: CircularProgressIndicator())
              else if (_backups.isEmpty)
                const _EmptyBackupsCard()
              else
                ..._backups.map(
                  (backup) => Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: _BackupFileCard(
                      backup: backup,
                      downloading: _downloading.contains(backup.filename),
                      onDownload: () => _downloadBackup(backup),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DatabaseBackupFile {
  const DatabaseBackupFile({
    required this.filename,
    required this.status,
    required this.statusLabel,
    required this.sizeHuman,
    required this.createdAt,
    required this.canDownload,
  });

  final String filename;
  final String status;
  final String statusLabel;
  final String sizeHuman;
  final String createdAt;
  final bool canDownload;

  factory DatabaseBackupFile.fromJson(Map<dynamic, dynamic> json) {
    return DatabaseBackupFile(
      filename: json['filename']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      statusLabel: json['status_label']?.toString() ?? 'غير محددة',
      sizeHuman: json['size_human']?.toString() ?? '-',
      createdAt: json['created_at']?.toString() ?? '-',
      canDownload: json['can_download'] == true,
    );
  }

  bool get isSql => filename.toLowerCase().endsWith('.sql');
}

class _BackupSummaryCard extends StatelessWidget {
  const _BackupSummaryCard({
    required this.loading,
    required this.total,
    required this.complete,
    required this.failed,
    required this.inProgress,
    required this.scheduleHuman,
    required this.keepDays,
    required this.onRefresh,
  });

  final bool loading;
  final int total;
  final int complete;
  final int failed;
  final int inProgress;
  final String scheduleHuman;
  final int keepDays;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.backup_outlined,
                  color: const Color(0xFF2563EB),
                  size: 23.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نسخ قاعدة البيانات',
                      style: TextStyle(
                        color: const Color(0xFF111827),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$scheduleHuman - احتفاظ $keepDays أيام',
                      style: TextStyle(
                        color: const Color(0xFF6B7280),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: loading ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(child: _StatPill(label: 'الكل', value: total)),
              SizedBox(width: 8.w),
              Expanded(
                child: _StatPill(
                  label: 'ناجحة',
                  value: complete,
                  color: const Color(0xFF059669),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _StatPill(
                  label: 'فشل',
                  value: failed,
                  color: const Color(0xFFDC2626),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _StatPill(
                  label: 'قيد العمل',
                  value: inProgress,
                  color: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    this.color = const Color(0xFF374151),
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }
}

class _BackupFileCard extends StatelessWidget {
  const _BackupFileCard({
    required this.backup,
    required this.downloading,
    required this.onDownload,
  });

  final DatabaseBackupFile backup;
  final bool downloading;
  final VoidCallback onDownload;

  Color get _statusColor {
    switch (backup.status) {
      case 'complete':
        return const Color(0xFF059669);
      case 'failed':
        return const Color(0xFFDC2626);
      case 'in_progress':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData get _statusIcon {
    switch (backup.status) {
      case 'complete':
        return Icons.check_circle_outline;
      case 'failed':
        return Icons.error_outline;
      case 'in_progress':
        return Icons.hourglass_top_rounded;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(_statusIcon, color: color, size: 22.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backup.filename,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: [
                    _MetaChip(label: backup.statusLabel, color: color),
                    _MetaChip(label: backup.sizeHuman),
                    _MetaChip(label: backup.createdAt),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            tooltip: backup.isSql ? 'تحميل النسخة' : 'تحميل تفاصيل الفشل',
            onPressed: backup.canDownload && !downloading ? onDownload : null,
            icon: downloading
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    this.color = const Color(0xFF6B7280),
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyBackupsCard extends StatelessWidget {
  const _EmptyBackupsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_off_outlined,
            color: const Color(0xFF9CA3AF),
            size: 36.sp,
          ),
          SizedBox(height: 10.h),
          Text(
            'لا توجد نسخ احتياطية حالياً',
            style: TextStyle(
              color: const Color(0xFF374151),
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
