import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:flutter/services.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/app_settings_service.dart';
import '../../../../../core/services/attendance_settings_service.dart';
import '../../../../../core/services/biometric_auth_service.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/user_data.dart';
import '../../../../../routes/app_routes.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({Key? key}) : super(key: key);

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  bool _biometricEnabled = false;
  bool _biometricBusy = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
    AppSettingsService.instance.ensureLoaded();
    AttendanceSettingsService.instance.ensureLoaded();
  }

  Future<void> _editSalesDailySettings() async {
    await AppSettingsService.instance.ensureLoaded(force: true);
    final service = AppSettingsService.instance;
    final varianceCtrl = TextEditingController(
      text: service.salesDailyVarianceAlertThreshold.value.toStringAsFixed(0),
    );
    final shekelCtrl = TextEditingController(
      text:
          '${service.salesDailyMaxFloat['شيكل']?.toStringAsFixed(0) ?? '500'}',
    );
    final dollarCtrl = TextEditingController(
      text:
          '${service.salesDailyMaxFloat['دولار']?.toStringAsFixed(0) ?? '200'}',
    );
    final dinarCtrl = TextEditingController(
      text:
          '${service.salesDailyMaxFloat['دينار']?.toStringAsFixed(0) ?? '200'}',
    );

    const dialogBg = Color(0xFFF3F4F6);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);
    const actionBg = Color(0xFFE5E7EB);

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'salesDailySettingsTitle'.tr,
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: varianceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'salesDailyVarianceAlertSetting'.tr,
                  labelStyle: const TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: shekelCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'salesDailyMaxFloatShekel'.tr,
                  labelStyle: const TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dollarCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'salesDailyMaxFloatDollar'.tr,
                  labelStyle: const TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dinarCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'salesDailyMaxFloatDinar'.tr,
                  labelStyle: const TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: textSecondary),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: actionBg,
              foregroundColor: textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('save'.tr),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) {
      varianceCtrl.dispose();
      shekelCtrl.dispose();
      dollarCtrl.dispose();
      dinarCtrl.dispose();
      return;
    }

    final variance = double.tryParse(varianceCtrl.text.trim()) ??
        service.salesDailyVarianceAlertThreshold.value;
    final maxFloat = <String, double>{
      'شيكل': double.tryParse(shekelCtrl.text.trim()) ??
          service.salesDailyMaxFloat['شيكل'] ??
          500,
      'دولار': double.tryParse(dollarCtrl.text.trim()) ??
          service.salesDailyMaxFloat['دولار'] ??
          200,
      'دينار': double.tryParse(dinarCtrl.text.trim()) ??
          service.salesDailyMaxFloat['دينار'] ??
          200,
    };
    varianceCtrl.dispose();
    shekelCtrl.dispose();
    dollarCtrl.dispose();
    dinarCtrl.dispose();

    final ok = await service.updateSalesDailySettings(
      varianceAlertThreshold: variance < 0 ? 0 : variance,
      maxFloat: maxFloat,
    );
    if (!mounted) return;
    if (ok) {
      Helpers.showCustomDialogSuccess(
        context: context,
        title: 'success'.tr,
        message: 'settingsUpdated'.tr,
      );
    } else {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'settingsUpdateFailed'.tr,
      );
    }
  }

  Future<void> _editShiplySettings() async {
    await AppSettingsService.instance.ensureLoaded(force: true);
    final service = AppSettingsService.instance;
    var enabled = service.shiplyEnabled.value;
    var testMode = service.shiplyIsTestMode.value;

    const dialogBg = Color(0xFFF3F4F6);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'shiplySettingsTitle'.tr,
            style: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: enabled,
                activeColor: const Color(0xFF059669),
                title: Text(
                  'shiplyIntegrationEnabled'.tr,
                  style: const TextStyle(color: textPrimary),
                ),
                onChanged: (v) => setDialogState(() => enabled = v),
              ),
              SwitchListTile(
                value: testMode,
                activeColor: const Color(0xFF2563EB),
                title: Text(
                  'shiplySandboxMode'.tr,
                  style: const TextStyle(color: textPrimary),
                ),
                subtitle: Text(
                  'shiplySandboxModeDesc'.tr,
                  style: const TextStyle(color: textSecondary, fontSize: 12),
                ),
                onChanged:
                    enabled ? (v) => setDialogState(() => testMode = v) : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr,
                  style: const TextStyle(color: textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text('save'.tr, style: const TextStyle(color: textPrimary)),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final ok = await service.updateShiplySettings(
      enabled: enabled,
      testMode: testMode,
    );
    if (!mounted) return;
    if (ok) {
      Helpers.showCustomDialogSuccess(
        context: context,
        title: 'success'.tr,
        message: 'settingsUpdated'.tr,
      );
    } else {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'settingsUpdateFailed'.tr,
      );
    }
  }

  Future<void> _editPasswordResetOtpDeliveryMethod() async {
    await AppSettingsService.instance.ensureLoaded(force: true);
    final service = AppSettingsService.instance;
    var selected = service.passwordResetOtpDeliveryMethod.value;

    const dialogBg = Color(0xFFF3F4F6);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'passwordResetOtpDeliverySetting'.tr,
            style: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selected,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'passwordResetOtpDeliverySetting'.tr,
                    labelStyle: const TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'email',
                      child: Text('passwordResetOtpDeliveryEmail'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('passwordResetOtpDeliveryAdmin'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'sms',
                      child: Text('passwordResetOtpDeliverySms'.tr),
                    ),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selected = v ?? 'email'),
                ),
                const SizedBox(height: 10),
                Text(
                  _passwordResetDeliveryDescription(selected),
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr,
                  style: const TextStyle(color: textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text('save'.tr, style: const TextStyle(color: textPrimary)),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final ok = await service.updatePasswordResetOtpDeliveryMethod(selected);
    if (!mounted) return;
    if (ok) {
      Helpers.showCustomDialogSuccess(
        context: context,
        title: 'success'.tr,
        message: 'settingsUpdated'.tr,
      );
    } else {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'settingsUpdateFailed'.tr,
      );
    }
  }

  Future<void> _editAppUpdateSettings() async {
    await AppSettingsService.instance.ensureLoaded(force: true);
    final service = AppSettingsService.instance;
    var android = service.appUpdateSettings['android'] ??
        AppUpdatePlatformSettings.defaults('android');
    var ios = service.appUpdateSettings['ios'] ??
        AppUpdatePlatformSettings.defaults('ios');
    var windows = service.appUpdateSettings['windows'] ??
        AppUpdatePlatformSettings.defaults('windows');

    final androidVersionCtrl =
        TextEditingController(text: android.latestVersion);
    final androidLatestBuildCtrl =
        TextEditingController(text: '${android.latestBuild}');
    final androidMinimumBuildCtrl =
        TextEditingController(text: '${android.minimumBuild}');
    final androidUrlCtrl = TextEditingController(text: android.url);
    final androidTitleCtrl = TextEditingController(text: android.title);
    final androidMessageCtrl = TextEditingController(text: android.message);

    final iosVersionCtrl = TextEditingController(text: ios.latestVersion);
    final iosLatestBuildCtrl =
        TextEditingController(text: '${ios.latestBuild}');
    final iosMinimumBuildCtrl =
        TextEditingController(text: '${ios.minimumBuild}');
    final iosUrlCtrl = TextEditingController(text: ios.url);
    final iosTitleCtrl = TextEditingController(text: ios.title);
    final iosMessageCtrl = TextEditingController(text: ios.message);

    final windowsVersionCtrl =
        TextEditingController(text: windows.latestVersion);
    final windowsLatestBuildCtrl =
        TextEditingController(text: '${windows.latestBuild}');
    final windowsMinimumBuildCtrl =
        TextEditingController(text: '${windows.minimumBuild}');
    final windowsUrlCtrl = TextEditingController(text: windows.url);
    final windowsTitleCtrl = TextEditingController(text: windows.title);
    final windowsMessageCtrl = TextEditingController(text: windows.message);

    const dialogBg = Color(0xFFF3F4F6);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'appUpdateSettingsTitle'.tr,
            style: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AppUpdatePlatformEditor(
                    title: 'Android',
                    settings: android,
                    versionCtrl: androidVersionCtrl,
                    latestBuildCtrl: androidLatestBuildCtrl,
                    minimumBuildCtrl: androidMinimumBuildCtrl,
                    urlCtrl: androidUrlCtrl,
                    titleCtrl: androidTitleCtrl,
                    messageCtrl: androidMessageCtrl,
                    onActiveChanged: (v) => setDialogState(
                        () => android = android.copyWith(isActive: v)),
                    onForceChanged: (v) => setDialogState(
                      () => android = android.copyWith(forceUpdate: v),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _AppUpdatePlatformEditor(
                    title: 'iOS',
                    settings: ios,
                    versionCtrl: iosVersionCtrl,
                    latestBuildCtrl: iosLatestBuildCtrl,
                    minimumBuildCtrl: iosMinimumBuildCtrl,
                    urlCtrl: iosUrlCtrl,
                    titleCtrl: iosTitleCtrl,
                    messageCtrl: iosMessageCtrl,
                    onActiveChanged: (v) =>
                        setDialogState(() => ios = ios.copyWith(isActive: v)),
                    onForceChanged: (v) => setDialogState(
                        () => ios = ios.copyWith(forceUpdate: v)),
                  ),
                  SizedBox(height: 12.h),
                  _AppUpdatePlatformEditor(
                    title: 'Windows',
                    settings: windows,
                    versionCtrl: windowsVersionCtrl,
                    latestBuildCtrl: windowsLatestBuildCtrl,
                    minimumBuildCtrl: windowsMinimumBuildCtrl,
                    urlCtrl: windowsUrlCtrl,
                    titleCtrl: windowsTitleCtrl,
                    messageCtrl: windowsMessageCtrl,
                    onActiveChanged: (v) => setDialogState(
                        () => windows = windows.copyWith(isActive: v)),
                    onForceChanged: (v) => setDialogState(
                        () => windows = windows.copyWith(forceUpdate: v)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr,
                  style: const TextStyle(color: textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text('save'.tr, style: const TextStyle(color: textPrimary)),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) {
      _disposeAppUpdateControllers([
        androidVersionCtrl,
        androidLatestBuildCtrl,
        androidMinimumBuildCtrl,
        androidUrlCtrl,
        androidTitleCtrl,
        androidMessageCtrl,
        iosVersionCtrl,
        iosLatestBuildCtrl,
        iosMinimumBuildCtrl,
        iosUrlCtrl,
        iosTitleCtrl,
        iosMessageCtrl,
        windowsVersionCtrl,
        windowsLatestBuildCtrl,
        windowsMinimumBuildCtrl,
        windowsUrlCtrl,
        windowsTitleCtrl,
        windowsMessageCtrl,
      ]);
      return;
    }

    android = android.copyWith(
      latestVersion: androidVersionCtrl.text.trim(),
      latestBuild: int.tryParse(androidLatestBuildCtrl.text.trim()) ?? 0,
      minimumBuild: int.tryParse(androidMinimumBuildCtrl.text.trim()) ?? 0,
      url: androidUrlCtrl.text.trim(),
      title: androidTitleCtrl.text.trim().isEmpty
          ? 'تحديث جديد متاح'
          : androidTitleCtrl.text.trim(),
      message: androidMessageCtrl.text.trim().isEmpty
          ? 'يرجى تحديث التطبيق للحصول على آخر التحسينات.'
          : androidMessageCtrl.text.trim(),
    );
    ios = ios.copyWith(
      latestVersion: iosVersionCtrl.text.trim(),
      latestBuild: int.tryParse(iosLatestBuildCtrl.text.trim()) ?? 0,
      minimumBuild: int.tryParse(iosMinimumBuildCtrl.text.trim()) ?? 0,
      url: iosUrlCtrl.text.trim(),
      title: iosTitleCtrl.text.trim().isEmpty
          ? 'تحديث جديد متاح'
          : iosTitleCtrl.text.trim(),
      message: iosMessageCtrl.text.trim().isEmpty
          ? 'يرجى تحديث التطبيق للحصول على آخر التحسينات.'
          : iosMessageCtrl.text.trim(),
    );
    windows = windows.copyWith(
      latestVersion: windowsVersionCtrl.text.trim(),
      latestBuild: int.tryParse(windowsLatestBuildCtrl.text.trim()) ?? 0,
      minimumBuild: int.tryParse(windowsMinimumBuildCtrl.text.trim()) ?? 0,
      url: windowsUrlCtrl.text.trim(),
      title: windowsTitleCtrl.text.trim().isEmpty
          ? 'تحديث جديد متاح'
          : windowsTitleCtrl.text.trim(),
      message: windowsMessageCtrl.text.trim().isEmpty
          ? 'يرجى تحديث التطبيق للحصول على آخر التحسينات.'
          : windowsMessageCtrl.text.trim(),
    );
    _disposeAppUpdateControllers([
      androidVersionCtrl,
      androidLatestBuildCtrl,
      androidMinimumBuildCtrl,
      androidUrlCtrl,
      androidTitleCtrl,
      androidMessageCtrl,
      iosVersionCtrl,
      iosLatestBuildCtrl,
      iosMinimumBuildCtrl,
      iosUrlCtrl,
      iosTitleCtrl,
      iosMessageCtrl,
      windowsVersionCtrl,
      windowsLatestBuildCtrl,
      windowsMinimumBuildCtrl,
      windowsUrlCtrl,
      windowsTitleCtrl,
      windowsMessageCtrl,
    ]);

    final ok = await service.updateAppUpdateSettings(
      android: android,
      ios: ios,
      windows: windows,
    );
    if (!mounted) return;
    if (ok) {
      Helpers.showCustomDialogSuccess(
        context: context,
        title: 'success'.tr,
        message: 'settingsUpdated'.tr,
      );
    } else {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'settingsUpdateFailed'.tr,
      );
    }
  }

  void _disposeAppUpdateControllers(List<TextEditingController> controllers) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        for (final controller in controllers) {
          controller.dispose();
        }
      });
    });
  }

  Future<void> _showPasswordResetCodeReport() async {
    const dialogBg = Color(0xFFF3F4F6);
    const textPrimary = Color(0xFF111827);
    const textSecondary = Color(0xFF6B7280);
    var status = 'all';
    var future = AppSettingsService.instance.fetchPasswordResetCodeReport();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void setStatus(String next) {
            setDialogState(() {
              status = next;
              future = AppSettingsService.instance
                  .fetchPasswordResetCodeReport(status: status);
            });
          }

          return AlertDialog(
            backgroundColor: dialogBg,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'passwordResetCodesReportTitle'.tr,
              style: const TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(ctx).size.height * .68,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _PasswordResetStatusChip(
                          label: 'passwordResetStatus_all'.tr,
                          selected: status == 'all',
                          onSelected: () => setStatus('all'),
                        ),
                        _PasswordResetStatusChip(
                          label: 'passwordResetStatus_active'.tr,
                          selected: status == 'active',
                          onSelected: () => setStatus('active'),
                        ),
                        _PasswordResetStatusChip(
                          label: 'passwordResetStatus_used'.tr,
                          selected: status == 'used',
                          onSelected: () => setStatus('used'),
                        ),
                        _PasswordResetStatusChip(
                          label: 'passwordResetStatus_expired'.tr,
                          selected: status == 'expired',
                          onSelected: () => setStatus('expired'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Expanded(
                    child: FutureBuilder<List<PasswordResetCodeReportRow>>(
                      future: future,
                      builder: (ctx, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final rows = snapshot.data ??
                            const <PasswordResetCodeReportRow>[];
                        if (rows.isEmpty) {
                          return Center(
                            child: Text(
                              'passwordResetCodesReportEmpty'.tr,
                              style: const TextStyle(color: textSecondary),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => SizedBox(height: 8.h),
                          itemBuilder: (_, index) =>
                              _PasswordResetCodeReportCard(row: rows[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => setStatus(status),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('refresh'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'close'.tr,
                  style: const TextStyle(color: textPrimary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editAdminFabOptions() async {
    await AppSettingsService.instance.ensureLoaded(force: true);
    final service = AppSettingsService.instance;
    final options = <String, String>{
      'newInvoice': 'newInvoice',
      'newEmployee': 'newEmployee',
      'newExpense': 'newExpense',
      'newCustomer': 'newCustomer',
      'createNewEmployeeTask': 'newTask',
      'addNewPrivateTask': 'newPrivateTask',
      'newSalesInvoice': 'salesInvoiceShortcut',
      'newCashProfit': 'newCashProfit',
      'newMaintenance': 'newMaintenance',
      'newFollowUp': 'createFollowUp',
      'newProduct': 'addProduct',
    };
    final selected = service.adminFabOptions.toSet();
    const dialogBg = Color(0xFFF3F4F6);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);
    const actionBg = Color(0xFFE5E7EB);

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'adminFabOptionsSetting'.tr,
            style: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: (options.length * 56.0)
                .clamp(
                  0,
                  MediaQuery.of(ctx).size.height * .62,
                )
                .toDouble(),
            child: ListView(
              children: options.entries
                  .map(
                    (entry) => CheckboxListTile(
                      value: selected.contains(entry.key),
                      activeColor: const Color(0xFF059669),
                      checkColor: Colors.white,
                      title: Text(
                        entry.value.tr,
                        style: const TextStyle(color: textPrimary),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            selected.add(entry.key);
                          } else {
                            selected.remove(entry.key);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'cancel'.tr,
                style: const TextStyle(color: textSecondary),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: actionBg,
                foregroundColor: textPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('save'.tr),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    final ok = await service.updateAdminFabOptions(selected);
    if (!mounted) return;
    if (ok) {
      Helpers.showCustomDialogSuccess(
        context: context,
        title: 'success'.tr,
        message: 'settingsUpdated'.tr,
      );
    } else {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'settingsUpdateFailed'.tr,
      );
    }
  }

  Future<void> _editEmployeeAllowedWifiSsids() async {
    await AppSettingsService.instance.ensureLoaded(force: true);
    final service = AppSettingsService.instance;
    final controller = TextEditingController(
      text: service.employeeAllowedWifiSsids.value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .join('\n'),
    );

    const dialogBg = Color(0xFFF3F4F6);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'employeeAllowedWifiSsidsSetting'.tr,
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            minLines: 4,
            maxLines: 8,
            style: const TextStyle(color: textPrimary),
            decoration: InputDecoration(
              labelText: 'employeeAllowedWifiSsidsHint'.tr,
              helperText: 'employeeAllowedWifiSsidsDesc'.tr,
              helperMaxLines: 3,
              labelStyle: const TextStyle(color: textSecondary),
              helperStyle: const TextStyle(color: textSecondary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'save'.tr,
              style: const TextStyle(color: textPrimary),
            ),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) {
      controller.dispose();
      return;
    }

    final ok = await service.updateEmployeeAllowedWifiSsids(controller.text);
    controller.dispose();
    if (!mounted) return;
    if (ok) {
      Helpers.showCustomDialogSuccess(
        context: context,
        title: 'success'.tr,
        message: 'settingsUpdated'.tr,
      );
    } else {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'settingsUpdateFailed'.tr,
      );
    }
  }

  Future<void> _loadBiometricState() async {
    final enabled =
        await BiometricAuthService.instance.isBiometricLoginEnabled();
    if (mounted) {
      setState(() => _biometricEnabled = enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = const Color(0xFFF5F5F5);

    final stockInventoryItem = _SettingsItem(
      icon: Icons.inventory_2_outlined,
      iconColor: const Color(0xFF0369A1),
      titleKey: 'stockInventorySettings',
      descriptionKey: 'stockInventorySettingsDesc',
      onTap: () => Get.toNamed(AppRoutes.STOCKINVENTORYSETTINGSSCREEN),
    );
    final items = userType == 'admin'
        ? <_SettingsItem>[
            _SettingsItem(
              icon: Icons.how_to_reg_outlined,
              iconColor: const Color(0xFFDC2626),
              titleKey: 'attendanceSettings',
              descriptionKey: 'attendanceSettingsDesc',
              onTap: () => Get.toNamed(AppRoutes.ATTENDANCESETTINGSSCREEN),
            ),
            _SettingsItem(
              icon: Icons.wifi_rounded,
              iconColor: const Color(0xFF16A34A),
              titleKey: 'employeeAllowedWifiSsidsSetting',
              descriptionKey: 'employeeAllowedWifiSsidsSettingDesc',
              onTap: _editEmployeeAllowedWifiSsids,
            ),
            _SettingsItem(
              icon: Icons.people_outline,
              iconColor: const Color(0xFF059669),
              titleKey: 'manageCustomers',
              descriptionKey: 'manageCustomersDesc',
              onTap: () => Get.toNamed(
                AppRoutes.GENERALDATALISTSCREEN,
                arguments: {'initialTab': 1},
              ),
            ),
            _SettingsItem(
              icon: Icons.storefront_outlined,
              iconColor: const Color(0xFF7C3AED),
              titleKey: 'manageMerchants',
              descriptionKey: 'manageMerchantsDesc',
              onTap: () => Get.toNamed(
                AppRoutes.GENERALDATALISTSCREEN,
                arguments: {'initialTab': 0},
              ),
            ),
            _SettingsItem(
              icon: Icons.category_outlined,
              iconColor: const Color(0xFF6B65BD),
              titleKey: 'contactCategoriesSettings',
              descriptionKey: 'contactCategoriesSettingsDesc',
              onTap: () =>
                  Get.toNamed(AppRoutes.CONTACTCATEGORIESSETTINGSSCREEN),
            ),
            _SettingsItem(
              icon: Icons.account_balance_outlined,
              iconColor: const Color(0xFF0D9488),
              titleKey: 'banksManagement',
              descriptionKey: 'banksManagementDesc',
              onTap: () => Get.toNamed(AppRoutes.BANKSSETTINGSSCREEN),
            ),
            _SettingsItem(
              icon: Icons.stars_rounded,
              iconColor: const Color(0xFF7C3AED),
              titleKey: 'إعدادات النقاط',
              descriptionKey: 'قواعد النقاط والتصنيفات والمكافآت',
              onTap: () => Get.toNamed(AppRoutes.EMPLOYEEPOINTSSETTINGSSCREEN),
            ),
            _SettingsItem(
              icon: Icons.lock_reset_outlined,
              iconColor: const Color(0xFF2563EB),
              titleKey: 'passwordResetOtpDeliverySetting',
              descriptionKey: 'passwordResetOtpDeliverySettingDesc',
              onTap: _editPasswordResetOtpDeliveryMethod,
            ),
            _SettingsItem(
              icon: Icons.manage_search_outlined,
              iconColor: const Color(0xFF0F766E),
              titleKey: 'passwordResetCodesReportTitle',
              descriptionKey: 'passwordResetCodesReportDesc',
              onTap: _showPasswordResetCodeReport,
            ),
            _SettingsItem(
              icon: Icons.local_shipping_outlined,
              iconColor: const Color(0xFF7C3AED),
              titleKey: 'shiplySettingsTitle',
              descriptionKey: 'shiplySettingsDesc',
              onTap: _editShiplySettings,
            ),
            _SettingsItem(
              icon: Icons.system_update_alt_outlined,
              iconColor: const Color(0xFF0F766E),
              titleKey: 'appUpdateSettingsTitle',
              descriptionKey: 'appUpdateSettingsDesc',
              onTap: _editAppUpdateSettings,
            ),
            _SettingsItem(
              icon: Icons.query_stats_outlined,
              iconColor: const Color(0xFF2563EB),
              titleKey: 'appVersionReportTitle',
              descriptionKey: 'appVersionReportDesc',
              onTap: () => Get.toNamed(AppRoutes.APPVERSIONREPORTSCREEN),
            ),
            _SettingsItem(
              icon: Icons.backup_outlined,
              iconColor: const Color(0xFF0F766E),
              titleKey: 'databaseBackups',
              descriptionKey: 'databaseBackupsDesc',
              onTap: () => Get.toNamed(AppRoutes.DATABASEBACKUPSSCREEN),
            ),
            _SettingsItem(
              icon: Icons.point_of_sale_outlined,
              iconColor: const Color(0xFFBE123C),
              titleKey: 'salesDailySettingsTitle',
              descriptionKey: 'salesDailySettingsDesc',
              onTap: _editSalesDailySettings,
            ),
            _SettingsItem(
              icon: Icons.add_circle_outline,
              iconColor: const Color(0xFF0F766E),
              titleKey: 'adminFabOptionsSetting',
              descriptionKey: 'adminFabOptionsSettingDesc',
              onTap: _editAdminFabOptions,
            ),
            stockInventoryItem,
          ]
        : <_SettingsItem>[
            if (canManageStockInventorySettings) stockInventoryItem,
          ];
    final showBiometricSettings = userType == 'admin';

    return Scaffold(
      backgroundColor: pageBg,
      appBar: CustomAppBar(
        title: 'generalSettings',
        action: false,
        backgroundColor: pageBg,
      ),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        itemBuilder: (_, i) {
          if (showBiometricSettings && i == 0) {
            return _BiometricSettingsCard(
              enabled: _biometricEnabled,
              busy: _biometricBusy,
              onChanged: _toggleBiometricLogin,
            );
          }
          final itemIndex = showBiometricSettings ? i - 1 : i;
          return _SettingsCard(item: items[itemIndex]);
        },
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemCount: items.length + (showBiometricSettings ? 1 : 0),
      ),
    );
  }

  Future<void> _toggleBiometricLogin(bool value) async {
    if (_biometricBusy) return;

    setState(() => _biometricBusy = true);
    try {
      final service = BiometricAuthService.instance;

      if (!value) {
        await service.setBiometricLoginEnabled(false);
        await service.clearLoginData();
        if (mounted) setState(() => _biometricEnabled = false);
        _showMessage('تم تعطيل الدخول بالبصمة بنجاح');
        return;
      }

      final token = await UserData.getUserToken();
      final userDataJson = await service.readCurrentUserData();
      if (token.isEmpty || userDataJson == null || userDataJson.isEmpty) {
        if (mounted) setState(() => _biometricEnabled = false);
        _showMessage(
          'يرجى تسجيل الدخول مرة أخرى لتفعيل الدخول بالبصمة',
          isError: true,
        );
        return;
      }

      final readiness = await service.checkReadiness(
        requireCurrentSession: true,
      );
      if (!readiness.ready) {
        if (mounted) setState(() => _biometricEnabled = false);
        _showMessage(
          readiness.message ?? 'تم إلغاء عملية التحقق',
          isError: true,
        );
        return;
      }

      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      final authResult = await service.authenticate(
        checkReadinessFirst: false,
        context: context,
        source: 'general_settings_toggle',
      );
      if (!authResult.success) {
        if (mounted) setState(() => _biometricEnabled = false);
        _showMessage(
          authResult.message ?? 'تم إلغاء المصادقة بالبصمة',
          isError: true,
        );
        return;
      }

      await service.saveLoginData(
        token: token,
        userDataJson: userDataJson,
      );
      await service.setBiometricLoginEnabled(true);
      if (mounted) setState(() => _biometricEnabled = true);
      _showMessage('تم تفعيل الدخول بالبصمة بنجاح');
    } catch (e) {
      debugPrint('Biometric settings toggle error: $e');
      if (mounted) setState(() => _biometricEnabled = false);
      _showMessage(
        'تعذر تفعيل الدخول بالبصمة، حاول مرة أخرى',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'تنبيه' : 'تم',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      colorText: Colors.white,
    );
  }

  String _passwordResetDeliveryDescription(String method) {
    switch (method) {
      case 'admin':
        return 'passwordResetOtpDeliveryAdminDesc'.tr;
      case 'sms':
        return 'passwordResetOtpDeliverySmsDesc'.tr;
      default:
        return 'passwordResetOtpDeliveryEmailDesc'.tr;
    }
  }
}

class _PasswordResetStatusChip extends StatelessWidget {
  const _PasswordResetStatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 8.w),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        selectedColor: const Color(0xFF2563EB),
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF374151),
          fontWeight: FontWeight.w700,
        ),
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _PasswordResetCodeReportCard extends StatelessWidget {
  const _PasswordResetCodeReportCard({required this.row});

  final PasswordResetCodeReportRow row;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(row.status);
    final name = row.userName.isNotEmpty ? row.userName : row.email;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(row.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            row.email,
            style: TextStyle(color: const Color(0xFF6B7280), fontSize: 12.sp),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: SelectableText(
                  row.token,
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'copy'.tr,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: row.token));
                  Get.snackbar(
                    'copied'.tr,
                    row.token,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                icon: const Icon(Icons.copy_outlined),
              ),
              const Spacer(),
              Text(
                _deliveryMethodLabel(row.deliveryMethod),
                style: TextStyle(
                  color: const Color(0xFF374151),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 4.h,
            children: [
              _MetaText(
                label: 'passwordResetRequestedAt'.tr,
                value: _shortDate(row.createdAt),
              ),
              if (row.expiresAt.isNotEmpty)
                _MetaText(
                  label: 'passwordResetExpiresAt'.tr,
                  value: _shortDate(row.expiresAt),
                ),
              if (row.usedAt.isNotEmpty)
                _MetaText(
                  label: 'passwordResetUsedAt'.tr,
                  value: _shortDate(row.usedAt),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'used':
        return const Color(0xFF2563EB);
      case 'expired':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF059669);
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'used':
        return 'passwordResetStatus_used'.tr;
      case 'expired':
        return 'passwordResetStatus_expired'.tr;
      default:
        return 'passwordResetStatus_active'.tr;
    }
  }

  static String _deliveryMethodLabel(String method) {
    switch (method) {
      case 'admin':
        return 'passwordResetOtpDeliveryAdmin'.tr;
      case 'sms':
        return 'passwordResetOtpDeliverySms'.tr;
      default:
        return 'passwordResetOtpDeliveryEmail'.tr;
    }
  }

  static String _shortDate(String value) {
    if (value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: TextStyle(
        color: const Color(0xFF6B7280),
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _BiometricSettingsCard extends StatelessWidget {
  const _BiometricSettingsCard({
    required this.enabled,
    required this.busy,
    required this.onChanged,
  });

  final bool enabled;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    const cardColor = Colors.white;
    const borderColor = Color(0xFFE5E7EB);
    const titleColor = Color(0xFF111827);
    const descColor = Color(0xFF6B7280);
    final disabled = kIsWeb || busy;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.fingerprint,
                  color: const Color(0xFF059669),
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفعيل الدخول بالبصمة',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      kIsWeb
                          ? 'الدخول بالبصمة غير متاح على الويب'
                          : 'استخدم بصمة الإصبع أو الوجه لتسجيل الدخول على هذا الجهاز',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: descColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              busy
                  ? SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: enabled && !kIsWeb,
                      onChanged: disabled ? null : onChanged,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppUpdatePlatformEditor extends StatelessWidget {
  const _AppUpdatePlatformEditor({
    required this.title,
    required this.settings,
    required this.versionCtrl,
    required this.latestBuildCtrl,
    required this.minimumBuildCtrl,
    required this.urlCtrl,
    required this.titleCtrl,
    required this.messageCtrl,
    required this.onActiveChanged,
    required this.onForceChanged,
  });

  final String title;
  final AppUpdatePlatformSettings settings;
  final TextEditingController versionCtrl;
  final TextEditingController latestBuildCtrl;
  final TextEditingController minimumBuildCtrl;
  final TextEditingController urlCtrl;
  final TextEditingController titleCtrl;
  final TextEditingController messageCtrl;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<bool> onForceChanged;

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SwitchListTile(
            value: settings.isActive,
            activeThumbColor: const Color(0xFF059669),
            contentPadding: EdgeInsets.zero,
            title: Text(
              'appUpdateActive'.tr,
              style: const TextStyle(color: textPrimary),
            ),
            onChanged: onActiveChanged,
          ),
          SwitchListTile(
            value: settings.forceUpdate,
            activeThumbColor: const Color(0xFFDC2626),
            contentPadding: EdgeInsets.zero,
            title: Text(
              'appUpdateForce'.tr,
              style: const TextStyle(color: textPrimary),
            ),
            onChanged: onForceChanged,
          ),
          _AppUpdateTextField(
            controller: versionCtrl,
            label: 'appUpdateLatestVersion'.tr,
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _AppUpdateTextField(
                  controller: latestBuildCtrl,
                  label: 'appUpdateLatestBuild'.tr,
                  number: true,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _AppUpdateTextField(
                  controller: minimumBuildCtrl,
                  label: 'appUpdateMinimumBuild'.tr,
                  number: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _AppUpdateTextField(
            controller: urlCtrl,
            label: 'appUpdateUrl'.tr,
          ),
          SizedBox(height: 10.h),
          _AppUpdateTextField(
            controller: titleCtrl,
            label: 'appUpdateDialogTitle'.tr,
          ),
          SizedBox(height: 10.h),
          _AppUpdateTextField(
            controller: messageCtrl,
            label: 'appUpdateDialogMessage'.tr,
            maxLines: 3,
          ),
          SizedBox(height: 6.h),
          Text(
            'appUpdateBuildHint'.tr,
            style: TextStyle(color: textSecondary, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}

class _AppUpdateTextField extends StatelessWidget {
  const _AppUpdateTextField({
    required this.controller,
    required this.label,
    this.number = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final bool number;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: const TextStyle(color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.titleKey,
    required this.descriptionKey,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String titleKey;
  final String descriptionKey;
  final VoidCallback onTap;
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.item});

  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    const cardColor = Colors.white;
    const borderColor = Color(0xFFE5E7EB);
    const titleColor = Color(0xFF111827);
    const descColor = Color(0xFF6B7280);
    const chevronColor = Color(0xFF9CA3AF);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: item.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titleKey.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      item.descriptionKey.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: descColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Get.locale?.languageCode == 'ar'
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: chevronColor,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
