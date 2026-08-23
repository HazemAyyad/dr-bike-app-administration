import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/services/theme_service.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../data/smart_home_api_service.dart';
import '../../data/smart_home_native_service.dart';
import '../../data/tuya_device_capability_resolver.dart';
import '../controllers/smart_home_controller.dart';

class SmartHomeDashboardScreen extends GetView<SmartHomeController> {
  const SmartHomeDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          'smartHome'.tr,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
      body: Obx(() {
        final showInitialSkeleton =
            controller.isLoading.value && controller.homes.isEmpty;
        final showDeviceSkeleton =
            controller.isRefreshing.value && !showInitialSkeleton;

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
            children: showInitialSkeleton
                ? const [_SmartHomeDashboardSkeleton()]
                : [
                    if (controller.errorMessage.value.isNotEmpty)
                      _ErrorBanner(message: controller.errorMessage.value),
                    if (controller.canViewSmartHomeOwners) ...[
                      _OwnerFilter(controller: controller),
                      SizedBox(height: 14.h),
                    ],
                    _SmartLocationSelector(controller: controller),
                    SizedBox(height: 10.h),
                    _NativeStatusCard(controller: controller),
                    if (!controller.isUnassignedSelected) ...[
                      SizedBox(height: 12.h),
                      _RoomsStrip(controller: controller),
                    ],
                    SizedBox(height: 14.h),
                    _SectionHeader(
                      title: 'devices'.tr,
                      actionLabel: 'addDevice'.tr,
                      onAction: _showAddDeviceDialog,
                    ),
                    SizedBox(height: 8.h),
                    if (showDeviceSkeleton)
                      const _SmartHomeDeviceListSkeleton()
                    else
                      _DevicesList(controller: controller),
                  ],
          ),
        );
      }),
    );
  }

  Future<void> _showAddDeviceDialog() async {
    await Get.to<void>(() => _AddDeviceFlowScreen(controller: controller));
  }
}

class _SmartHomeDashboardSkeleton extends StatelessWidget {
  const _SmartHomeDashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonBlock(width: double.infinity, height: 42.h, radius: 8),
        SizedBox(height: 10.h),
        SkeletonBlock(width: double.infinity, height: 86.h, radius: 8),
        SizedBox(height: 12.h),
        SizedBox(
          height: 34.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, index) => SkeletonBlock(
              width: index == 0 ? 62.w : 88.w,
              height: 34.h,
              radius: 999,
            ),
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemCount: 4,
          ),
        ),
        SizedBox(height: 18.h),
        Row(
          children: [
            SkeletonBlock(width: 88.w, height: 18.h),
            const Spacer(),
            SkeletonBlock(width: 78.w, height: 32.h, radius: 999),
          ],
        ),
        SizedBox(height: 10.h),
        const _SmartHomeDeviceListSkeleton(count: 4),
      ],
    );
  }
}

class _SmartHomeDeviceListSkeleton extends StatelessWidget {
  const _SmartHomeDeviceListSkeleton({this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => const _SmartHomeDeviceCardSkeleton(),
      ),
    );
  }
}

class _SmartHomeDeviceCardSkeleton extends StatelessWidget {
  const _SmartHomeDeviceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.black.withValues(alpha: .05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SkeletonCircle(size: 42.r),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(width: double.infinity, height: 14.h),
                    SizedBox(height: 7.h),
                    SkeletonBlock(width: 120.w, height: 9.h),
                  ],
                ),
              ),
              SkeletonBlock(width: 30.w, height: 30.w, radius: 999),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: SkeletonBlock(
                  width: double.infinity,
                  height: 72.h,
                  radius: 8,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: SkeletonBlock(
                  width: double.infinity,
                  height: 72.h,
                  radius: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _AddDeviceStage { search, manualReset, wifi, connecting, failed }

class _ResetInstruction {
  const _ResetInstruction({required this.icon, required this.title});

  final IconData icon;
  final String title;
}

class _AddDeviceFlowScreen extends StatefulWidget {
  const _AddDeviceFlowScreen({required this.controller});

  final SmartHomeController controller;

  @override
  State<_AddDeviceFlowScreen> createState() => _AddDeviceFlowScreenState();
}

class _AddDeviceFlowScreenState extends State<_AddDeviceFlowScreen> {
  late final TextEditingController ssidController;
  late final TextEditingController passwordController;
  _AddDeviceStage stage = _AddDeviceStage.search;
  int resetStep = 0;
  bool loadingWifi = true;
  bool loadingCurrentWifi = false;
  bool useBluetoothPairing = false;
  SmartHomeBleScanDevice? selectedBleDevice;

  @override
  void initState() {
    super.initState();
    ssidController = TextEditingController();
    passwordController = TextEditingController();
    widget.controller.errorMessage('');
    widget.controller.bluetoothDevices.clear();
    widget.controller.selectedBluetoothDevice.value = null;
    _loadWifi();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanNearby());
  }

  Future<void> _loadWifi() async {
    final savedWifi = await widget.controller.savedWifiCredentials();
    final currentSsid =
        savedWifi.ssid.isEmpty ? await widget.controller.currentWifiSsid() : '';
    if (!mounted) return;
    ssidController.text =
        savedWifi.ssid.isNotEmpty ? savedWifi.ssid : currentSsid;
    passwordController.text = savedWifi.password;
    setState(() => loadingWifi = false);
  }

  Future<void> _fillCurrentWifi() async {
    setState(() => loadingCurrentWifi = true);
    final ssid = await widget.controller.currentWifiSsid();
    if (!mounted) return;
    if (ssid.isNotEmpty) ssidController.text = ssid;
    setState(() => loadingCurrentWifi = false);
  }

  Future<void> _scanNearby() async {
    await widget.controller.scanBluetoothDevices();
  }

  void _selectBleDevice(SmartHomeBleScanDevice device) {
    selectedBleDevice = device;
    widget.controller.selectedBluetoothDevice.value = device;
    useBluetoothPairing = true;
    _goWifi();
  }

  void _goManual() {
    widget.controller.errorMessage('');
    selectedBleDevice = null;
    widget.controller.selectedBluetoothDevice.value = null;
    useBluetoothPairing = false;
    setState(() {
      stage = _AddDeviceStage.manualReset;
      resetStep = 0;
    });
  }

  void _goWifi() {
    widget.controller.errorMessage('');
    setState(() => stage = _AddDeviceStage.wifi);
  }

  void _nextResetStep() {
    if (resetStep >= 2) {
      _goWifi();
      return;
    }
    setState(() => resetStep += 1);
  }

  Future<void> _connect() async {
    widget.controller.errorMessage('');
    setState(() => stage = _AddDeviceStage.connecting);
    final existingDeviceIds =
        widget.controller.devices.map((device) => device.id).toSet();

    final success = useBluetoothPairing && selectedBleDevice != null
        ? await widget.controller.startBluetoothDevicePairing(
            scanDevice: selectedBleDevice!,
            ssid: ssidController.text,
            password: passwordController.text,
          )
        : await widget.controller.startDevicePairing(
            ssid: ssidController.text,
            password: passwordController.text,
          );

    if (!mounted) return;
    if (success) {
      Get.back<void>();
      return;
    }

    final failedMessage = widget.controller.errorMessage.value;
    await widget.controller.refreshData();
    if (!mounted) return;
    final addedDevice = widget.controller.devices.any(
      (device) => !existingDeviceIds.contains(device.id),
    );
    if (addedDevice) {
      Get.back<void>();
      return;
    }
    if (failedMessage.isNotEmpty) {
      widget.controller.errorMessage(failedMessage);
    }
    setState(() => stage = _AddDeviceStage.failed);
  }

  void _retry() {
    widget.controller.errorMessage('');
    setState(() => stage = _AddDeviceStage.connecting);
    _connect();
  }

  @override
  void dispose() {
    ssidController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 28.h),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _buildStage(context),
          ),
        ),
      ),
    );
  }

  Widget _buildStage(BuildContext context) {
    switch (stage) {
      case _AddDeviceStage.search:
        return _buildSearch(context);
      case _AddDeviceStage.manualReset:
        return _buildManualReset(context);
      case _AddDeviceStage.wifi:
        return _buildWifi(context);
      case _AddDeviceStage.connecting:
        return _buildConnecting(context);
      case _AddDeviceStage.failed:
        return _buildFailed(context);
    }
  }

  Widget _buildHeader({String? trailing, VoidCallback? onTrailing}) {
    return Row(
      children: [
        IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.close_rounded),
        ),
        const Spacer(),
        if (trailing != null)
          TextButton(
            onPressed: onTrailing,
            style: TextButton.styleFrom(
              backgroundColor: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(trailing),
          ),
      ],
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Column(
      key: const ValueKey('search'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: 34.h),
        Center(
          child: Text(
            'smartHomeSearchingNearby'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 27.sp,
                ),
          ),
        ),
        SizedBox(height: 10.h),
        Center(
          child: Text(
            'smartHomeSearchingHint'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.customGreyColor5,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        SizedBox(height: 54.h),
        Center(child: _RadarGraphic(scanning: true)),
        SizedBox(height: 34.h),
        Obx(() {
          if (widget.controller.isScanningBluetooth.value) {
            return _PermissionNotice(
              title: 'smartHomeBluetoothScan'.tr,
              subtitle: 'smartHomeBluetoothScanning'.tr,
              icon: Icons.bluetooth_searching_rounded,
            );
          }
          if (widget.controller.bluetoothDevices.isEmpty) {
            return _PermissionNotice(
              title: 'smartHomeBluetoothNoDevicesTitle'.tr,
              subtitle: 'smartHomeBluetoothNoDevices'.tr,
              icon: Icons.bluetooth_disabled_rounded,
              actionLabel: 'retry'.tr,
              onAction: _scanNearby,
            );
          }
          return Column(
            children: widget.controller.bluetoothDevices
                .map(
                  (device) => _BleDeviceTile(
                    device: device,
                    onTap: () => _selectBleDevice(device),
                  ),
                )
                .toList(growable: false),
          );
        }),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: Text(
                'smartHomeAddManually'.tr,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            TextButton(
              onPressed: _goManual,
              child: Text('smartHomeManualWifiDevice'.tr),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManualReset(BuildContext context) {
    final steps = [
      _ResetInstruction(
        icon: Icons.power_settings_new_rounded,
        title: 'smartHomeResetStepPower'.tr,
      ),
      _ResetInstruction(
        icon: Icons.touch_app_rounded,
        title: 'smartHomeResetStepHold'.tr,
      ),
      _ResetInstruction(
        icon: Icons.wifi_tethering_rounded,
        title: 'smartHomeResetStepBlink'.tr,
      ),
    ];
    final current = steps[resetStep];

    return Column(
      key: ValueKey('manual-$resetStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
            trailing: 'smartHomeOtherModes'.tr,
            onTrailing: () {
              setState(() => stage = _AddDeviceStage.search);
            }),
        SizedBox(height: 42.h),
        Text(
          'smartHomeResetDevice'.tr,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 30.sp,
              ),
        ),
        const Spacer(),
        Center(
          child: Icon(
            current.icon,
            size: 92.r,
            color: resetStep == 2 ? AppColors.customOrange3 : Colors.grey[400],
          ),
        ),
        SizedBox(height: 28.h),
        Center(child: _StepDots(current: resetStep)),
        SizedBox(height: 46.h),
        Text(
          current.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 22.sp,
              ),
        ),
        const Spacer(flex: 2),
        Row(
          children: [
            if (resetStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => resetStep -= 1),
                  child: Text('back'.tr),
                ),
              ),
            if (resetStep > 0) SizedBox(width: 14.w),
            Expanded(
              child: ElevatedButton(
                onPressed: _nextResetStep,
                child: Text('next'.tr),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWifi(BuildContext context) {
    return Column(
      key: const ValueKey('wifi'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
            trailing: 'smartHomeOtherModes'.tr,
            onTrailing: () {
              setState(() => stage = _AddDeviceStage.search);
            }),
        SizedBox(height: 38.h),
        Text(
          useBluetoothPairing
              ? 'smartHomeBluetoothPair'.tr
              : 'smartHomeManualWifiDevice'.tr,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 28.sp,
              ),
        ),
        SizedBox(height: 10.h),
        Text(
          'smartHomeWifiConnectHint'.tr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.customGreyColor5,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 32.h),
        TextField(
          controller: ssidController,
          enabled: !loadingWifi && !loadingCurrentWifi,
          decoration: InputDecoration(
            labelText: 'smartHomeWifiName'.tr,
            suffixIcon: IconButton(
              tooltip: 'smartHomeUseCurrentWifi'.tr,
              onPressed:
                  loadingWifi || loadingCurrentWifi ? null : _fillCurrentWifi,
              icon: loadingCurrentWifi
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find_rounded),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        TextField(
          controller: passwordController,
          enabled: !loadingWifi,
          obscureText: true,
          decoration: InputDecoration(labelText: 'smartHomeWifiPassword'.tr),
        ),
        SizedBox(height: 12.h),
        Obx(() {
          if (widget.controller.errorMessage.value.isEmpty) {
            return const SizedBox.shrink();
          }
          return _ErrorBanner(message: widget.controller.errorMessage.value);
        }),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  stage = useBluetoothPairing
                      ? _AddDeviceStage.search
                      : _AddDeviceStage.manualReset;
                }),
                child: Text('back'.tr),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: ElevatedButton(
                onPressed: loadingWifi ? null : _connect,
                child: Text('next'.tr),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnecting(BuildContext context) {
    return Column(
      key: const ValueKey('connecting'),
      children: [
        _buildHeader(),
        const Spacer(),
        Text(
          'smartHomeConnectingDevice'.tr,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 28.sp,
              ),
        ),
        SizedBox(height: 72.h),
        Icon(
          useBluetoothPairing
              ? Icons.bluetooth_connected_rounded
              : Icons.devices_other_rounded,
          size: 88.r,
          color: AppColors.primaryColor.withOpacity(.35),
        ),
        SizedBox(height: 54.h),
        LinearProgressIndicator(
          minHeight: 6.h,
          borderRadius: BorderRadius.circular(999),
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildFailed(BuildContext context) {
    final message = widget.controller.errorMessage.value;
    return Column(
      key: const ValueKey('failed'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: 72.h),
        Text(
          'smartHomeFailedToAdd'.tr,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 29.sp,
              ),
        ),
        SizedBox(height: 28.h),
        Text(
          'smartHomeFailedCheck'.tr,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 25.sp,
              ),
        ),
        SizedBox(height: 28.h),
        Text(
          'smartHomeFailedHint1'.tr,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.customGreyColor5,
                fontWeight: FontWeight.w600,
                height: 1.8,
              ),
        ),
        Text(
          'smartHomeFailedHint2'.tr,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.customGreyColor5,
                fontWeight: FontWeight.w600,
                height: 1.8,
              ),
        ),
        if (message.isNotEmpty) ...[
          SizedBox(height: 18.h),
          _ErrorBanner(message: message),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _retry,
            child: Text('retry'.tr),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => setState(() => stage = _AddDeviceStage.search),
            child: Text('smartHomeTryOtherModes'.tr),
          ),
        ),
        SizedBox(height: 12.h),
        Center(
          child: TextButton(
            onPressed: () => Get.snackbar(
              'smartHomeReportIssue'.tr,
              'smartHomeIssueLogged'.tr,
            ),
            child: Text('smartHomeReportIssue'.tr),
          ),
        ),
      ],
    );
  }
}

class _RadarGraphic extends StatelessWidget {
  const _RadarGraphic({required this.scanning});

  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190.w,
      height: 190.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryColor.withOpacity(.06),
      ),
      child: Center(
        child: Container(
          width: 118.w,
          height: 118.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryColor.withOpacity(.08),
          ),
          child: Icon(
            scanning ? Icons.radar_rounded : Icons.devices_other_rounded,
            color: AppColors.primaryColor,
            size: 52.r,
          ),
        ),
      ),
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: AppColors.primaryColor.withOpacity(.12),
            child: Icon(icon, color: AppColors.primaryColor),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.customGreyColor5,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _BleDeviceTile extends StatelessWidget {
  const _BleDeviceTile({required this.device, required this.onTap});

  final SmartHomeBleScanDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        tileColor: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        leading: const Icon(Icons.bluetooth_connected_rounded),
        title: Text(device.displayName),
        subtitle: Text(
          '${device.isWifiCombo ? 'WiFi + BLE' : 'BLE'}  RSSI ${device.rssi}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final active = index == current;
        return Container(
          width: 26.w,
          height: 26.w,
          margin: EdgeInsets.symmetric(horizontal: 5.w),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.customGreyColor5 : Colors.transparent,
            border: Border.all(color: AppColors.customGreyColor5),
          ),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: active ? Colors.white : AppColors.customGreyColor5,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      }),
    );
  }
}

class _OwnerFilter extends StatelessWidget {
  const _OwnerFilter({required this.controller});

  final SmartHomeController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.owners.isEmpty) {
      return _EmptyState(text: 'smartHomeNoOwners'.tr);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.manage_accounts_rounded, color: AppColors.primaryColor),
          SizedBox(width: 10.w),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: controller.selectedOwnerId.value,
                isExpanded: true,
                hint: Text('smartHomeSelectOwner'.tr),
                items: controller.owners
                    .map(
                      (owner) => DropdownMenuItem<int>(
                        value: owner.id,
                        child: Text(
                          _ownerLabel(owner),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: controller.selectOwner,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ownerLabel(SmartHomeOwnerModel owner) {
    final name = owner.name.isNotEmpty ? owner.name : '#${owner.id}';
    return '$name  ${owner.devicesCount} ${'devices'.tr}';
  }
}

class _SmartLocationSelector extends StatelessWidget {
  const _SmartLocationSelector({required this.controller});

  final SmartHomeController controller;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = controller.isUnassignedSelected
        ? 'smartHomeUnassignedDevices'.tr
        : _locationLabel(controller.selectedHome);
    final selectedIcon = controller.isUnassignedSelected
        ? Icons.inventory_2_outlined
        : _locationIcon(controller.selectedHome?.type ?? 'home');
    return Row(
      children: [
        Expanded(
          child: PopupMenuButton<String>(
            tooltip: 'smartHomeSelectLocation'.tr,
            onSelected: (value) async {
              if (value == 'add') {
                _showLocationDialog(controller: controller);
              } else {
                await controller.selectLocationKey(value);
              }
            },
            itemBuilder: (_) => [
              ...controller.homes.map(
                (home) => PopupMenuItem<String>(
                  value: 'home:${home.id}',
                  child: _LocationMenuRow(
                    icon: _locationIcon(home.type),
                    label: _locationLabel(home),
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: smartHomeUnassignedLocationKey,
                child: _LocationMenuRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'smartHomeUnassignedDevices'.tr,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'add',
                child: _LocationMenuRow(
                  icon: Icons.add_rounded,
                  label: 'smartHomeAddLocation'.tr,
                ),
              ),
            ],
            child: Container(
              height: 42.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.whiteColor2,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(selectedIcon, size: 20.r, color: AppColors.primaryColor),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      selectedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 13.sp,
                          ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        IconButton.filledTonal(
          tooltip: 'smartHomeAddLocation'.tr,
          onPressed: () => _showLocationDialog(controller: controller),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _LocationMenuRow extends StatelessWidget {
  const _LocationMenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.r, color: AppColors.primaryColor),
        SizedBox(width: 10.w),
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

IconData _locationIcon(String type) {
  return type == 'company' ? Icons.apartment_rounded : Icons.home_outlined;
}

String _locationLabel(SmartHomeModel? home) {
  if (home == null) return 'smartHomeDefaultName'.tr;
  return home.name.isNotEmpty ? home.name : 'smartHomeDefaultName'.tr;
}

String _deviceLocationSummary(SmartDeviceModel device) {
  if (device.smartHomeId == null) return 'smartHomeUnassignedDevices'.tr;
  if (device.roomName.trim().isNotEmpty) return device.roomName;
  return 'smartHomeLocationOnly'.tr;
}

Future<void> _showLocationDialog({
  required SmartHomeController controller,
}) async {
  await Get.bottomSheet<void>(
    _LocationFormSheet(controller: controller),
    isScrollControlled: true,
  );
}

class _LocationFormSheet extends StatefulWidget {
  const _LocationFormSheet({required this.controller});

  final SmartHomeController controller;

  @override
  State<_LocationFormSheet> createState() => _LocationFormSheetState();
}

class _LocationFormSheetState extends State<_LocationFormSheet> {
  late final TextEditingController nameController;
  String type = 'home';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
  }

  Future<void> _save() async {
    if (saving) return;
    final cleanName = nameController.text.trim();
    if (cleanName.isEmpty) {
      Get.snackbar(
          'smartHomeAddLocation'.tr, 'smartHomeLocationNameRequired'.tr);
      return;
    }
    setState(() => saving = true);
    final ok = await widget.controller.createLocation(
      name: cleanName,
      type: type,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => saving = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'smartHomeAddLocation'.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  selected: type == 'home',
                  label: Text('smartHomeHomeType'.tr),
                  avatar: const Icon(Icons.home_outlined),
                  onSelected: (_) => setState(() => type = 'home'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ChoiceChip(
                  selected: type == 'company',
                  label: Text('smartHomeCompanyType'.tr),
                  avatar: const Icon(Icons.apartment_rounded),
                  onSelected: (_) => setState(() => type = 'company'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: nameController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: 'smartHomeLocationName'.tr),
            onSubmitted: (_) => _save(),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text('save'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetPanel extends StatelessWidget {
  const _BottomSheetPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          18.w,
          14.h,
          18.w,
          18.h + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
        ),
        child: child,
      ),
    );
  }
}

class _NativeStatusCard extends StatelessWidget {
  const _NativeStatusCard({required this.controller});

  final SmartHomeController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.nativeStatus.value;
    final ok = status.initialized;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.info_rounded,
            color: ok ? Colors.green : AppColors.customOrange3,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? 'tuyaSdkReady'.tr : 'tuyaSdkNeedsSetup'.tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  controller.isLinkingTuyaUser.value
                      ? 'tuyaUserLinking'.tr
                      : controller.isTuyaUserLinked
                          ? 'tuyaUserLinked'.tr
                          : 'tuyaUserNeedsLink'.tr,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: controller.isTuyaUserLinked
                            ? Colors.green
                            : AppColors.customGreyColor5,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add_rounded),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _RoomsStrip extends StatelessWidget {
  const _RoomsStrip({required this.controller});

  final SmartHomeController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.rooms.length + 2,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _RoomChip(
              label: 'smartHomeAllDevices'.tr,
              selected: controller.selectedRoomId.value == null,
              onTap: () => controller.selectRoom(null),
            );
          }
          if (index == controller.rooms.length + 1) {
            return _RoomAddChip(
              onTap: () => _showRoomDialog(controller: controller),
            );
          }
          final room = controller.rooms[index - 1];
          return _RoomChip(
            label: room.name,
            selected: controller.selectedRoomId.value == room.id,
            onTap: () => controller.selectRoom(room.id),
            onLongPress: () => _showRoomActions(
              controller: controller,
              room: room,
            ),
          );
        },
      ),
    );
  }
}

class _RoomChip extends StatelessWidget {
  const _RoomChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryColor
          : (ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor2),
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          constraints: BoxConstraints(minWidth: 58.w),
          padding: EdgeInsets.symmetric(horizontal: 13.w),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: selected ? Colors.white : null,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

class _RoomAddChip extends StatelessWidget {
  const _RoomAddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: 'addRoom'.tr,
      onPressed: onTap,
      icon: const Icon(Icons.add_rounded),
    );
  }
}

Future<void> _showRoomDialog({
  required SmartHomeController controller,
  SmartRoomModel? room,
}) async {
  await Get.dialog<void>(
    _RoomFormDialog(controller: controller, room: room),
  );
}

class _RoomFormDialog extends StatefulWidget {
  const _RoomFormDialog({required this.controller, this.room});

  final SmartHomeController controller;
  final SmartRoomModel? room;

  @override
  State<_RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<_RoomFormDialog> {
  late final TextEditingController nameController;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.room?.name ?? '');
  }

  Future<void> _save() async {
    if (saving) return;
    final cleanName = nameController.text.trim();
    if (cleanName.isEmpty) {
      Get.snackbar('addRoom'.tr, 'smartHomeRoomNameRequired'.tr);
      return;
    }
    setState(() => saving = true);
    final ok = widget.room == null
        ? await widget.controller.createRoom(cleanName)
        : await widget.controller.renameRoom(
            room: widget.room!,
            name: cleanName,
          );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => saving = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.room == null ? 'addRoom'.tr : 'smartHomeRenameRoom'.tr),
      content: TextField(
        controller: nameController,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(labelText: 'smartHomeRoomName'.tr),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Get.back<void>(),
          child: Text('cancel'.tr),
        ),
        ElevatedButton.icon(
          onPressed: saving ? null : _save,
          icon: saving
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text('save'.tr),
        ),
      ],
    );
  }
}

Future<void> _showRoomActions({
  required SmartHomeController controller,
  required SmartRoomModel room,
}) async {
  await Get.bottomSheet<void>(
    _BottomSheetPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: Text('smartHomeRenameRoom'.tr),
            onTap: () {
              Get.back<void>();
              _showRoomDialog(controller: controller, room: room);
            },
          ),
          ListTile(
            leading:
                Icon(Icons.delete_outline_rounded, color: Colors.red.shade600),
            title: Text('smartHomeDeleteRoom'.tr),
            onTap: () {
              Get.back<void>();
              _confirmDeleteRoom(controller: controller, room: room);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _confirmDeleteRoom({
  required SmartHomeController controller,
  required SmartRoomModel room,
}) async {
  final ok = await Get.dialog<bool>(
    AlertDialog(
      title: Text('smartHomeDeleteRoom'.tr),
      content: Text('smartHomeDeleteRoomConfirm'.tr),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text('cancel'.tr),
        ),
        ElevatedButton.icon(
          onPressed: () => Get.back(result: true),
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text('delete'.tr),
        ),
      ],
    ),
  );
  if (ok == true) {
    await controller.deleteRoom(room);
  }
}

class _DevicesList extends StatelessWidget {
  const _DevicesList({required this.controller});

  final SmartHomeController controller;

  @override
  Widget build(BuildContext context) {
    final visibleDevices = controller.visibleDevices;
    if (visibleDevices.isEmpty) {
      return _EmptyState(text: 'noDevicesYet'.tr);
    }
    return Column(
      children: visibleDevices
          .map(
            (device) => _SmartDeviceCard(
              controller: controller,
              device: device,
              onOpen: () => Get.to<void>(
                () => _DeviceDetailsScreen(
                  controller: controller,
                  initialDevice: device,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

Future<bool> _showRenameDeviceDialog({
  required SmartHomeController controller,
  required SmartDeviceModel device,
}) async {
  final result = await Get.dialog<bool>(
    _RenameDeviceDialog(
      controller: controller,
      device: device,
    ),
  );
  return result == true;
}

Future<bool> _showRenameFunctionDialog({
  required SmartHomeController controller,
  required SmartDeviceModel device,
  required TuyaDeviceFunction function,
}) async {
  final metadata = _functionMetadata(device, function);
  if (metadata == null) {
    Get.snackbar(
      'smartHomeEditSwitchName'.tr,
      'smartHomeSwitchMetadataMissing'.tr,
    );
    return false;
  }
  final result = await Get.dialog<bool>(
    _RenameFunctionDialog(
      controller: controller,
      device: device,
      function: function,
      metadata: metadata,
    ),
  );
  return result == true;
}

class _RenameFunctionDialog extends StatefulWidget {
  const _RenameFunctionDialog({
    required this.controller,
    required this.device,
    required this.function,
    required this.metadata,
  });

  final SmartHomeController controller;
  final SmartDeviceModel device;
  final TuyaDeviceFunction function;
  final SmartDeviceFunctionModel metadata;

  @override
  State<_RenameFunctionDialog> createState() => _RenameFunctionDialogState();
}

class _RenameFunctionDialogState extends State<_RenameFunctionDialog> {
  late final TextEditingController nameController;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.metadata.displayName.trim().isNotEmpty
          ? widget.metadata.displayName
          : _functionLabelForDevice(widget.device, widget.function),
    );
  }

  Future<void> _save() async {
    if (saving) return;
    final cleanName = nameController.text.trim();
    if (cleanName.isEmpty) {
      Get.snackbar(
        'smartHomeEditSwitchName'.tr,
        'smartHomeSwitchNameRequired'.tr,
      );
      return;
    }
    setState(() => saving = true);
    final ok = await widget.controller.renameDeviceFunction(
      device: widget.device,
      function: widget.metadata,
      displayName: cleanName,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context, rootNavigator: true).pop(true);
      return;
    }
    setState(() => saving = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('smartHomeEditSwitchName'.tr),
      content: TextField(
        controller: nameController,
        enabled: !saving,
        autofocus: true,
        maxLength: 80,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(labelText: 'smartHomeSwitchName'.tr),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Get.back(result: false),
          child: Text('cancel'.tr),
        ),
        ElevatedButton.icon(
          onPressed: saving ? null : _save,
          icon: saving
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text('save'.tr),
        ),
      ],
    );
  }
}

class _RenameDeviceDialog extends StatefulWidget {
  const _RenameDeviceDialog({
    required this.controller,
    required this.device,
  });

  final SmartHomeController controller;
  final SmartDeviceModel device;

  @override
  State<_RenameDeviceDialog> createState() => _RenameDeviceDialogState();
}

class _RenameDeviceDialogState extends State<_RenameDeviceDialog> {
  late final TextEditingController nameController;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.device.name);
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);
    final ok = await widget.controller.renameSmartDevice(
      device: widget.device,
      name: nameController.text,
    );
    if (!mounted) return;
    if (ok) {
      Get.back(result: true);
      return;
    }
    setState(() => saving = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('smartHomeRenameDevice'.tr),
      content: TextField(
        controller: nameController,
        enabled: !saving,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(labelText: 'smartHomeDeviceName'.tr),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Get.back(result: false),
          child: Text('cancel'.tr),
        ),
        ElevatedButton.icon(
          onPressed: saving ? null : _save,
          icon: saving
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text('save'.tr),
        ),
      ],
    );
  }
}

Future<bool> _showDeleteDeviceDialog({
  required SmartHomeController controller,
  required SmartDeviceModel device,
}) async {
  var deleting = false;
  final result = await Get.dialog<bool>(
    StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('smartHomeDeleteDevice'.tr),
          content: Text(
            'smartHomeDeleteDeviceConfirm'.trParams({'name': device.name}),
          ),
          actions: [
            TextButton(
              onPressed: deleting ? null : () => Get.back(result: false),
              child: Text('cancel'.tr),
            ),
            ElevatedButton.icon(
              onPressed: deleting
                  ? null
                  : () async {
                      setState(() => deleting = true);
                      final ok = await controller.deleteSmartDevice(
                        device: device,
                      );
                      if (Get.isDialogOpen == true) Get.back(result: ok);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              icon: deleting
                  ? SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_rounded),
              label: Text('delete'.tr),
            ),
          ],
        );
      },
    ),
  );
  return result == true;
}

Future<void> _showMoveDeviceSheet({
  required SmartHomeController controller,
  required SmartDeviceModel device,
}) async {
  await Get.bottomSheet<void>(
    _MoveDeviceSheet(controller: controller, device: device),
    isScrollControlled: true,
  );
}

class _MoveDeviceSheet extends StatefulWidget {
  const _MoveDeviceSheet({
    required this.controller,
    required this.device,
  });

  final SmartHomeController controller;
  final SmartDeviceModel device;

  @override
  State<_MoveDeviceSheet> createState() => _MoveDeviceSheetState();
}

class _MoveDeviceSheetState extends State<_MoveDeviceSheet> {
  late final Future<Map<int, List<SmartRoomModel>>> roomsFuture;
  String? movingTargetKey;

  @override
  void initState() {
    super.initState();
    roomsFuture = _loadRoomsByHome();
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetPanel(
      child: FutureBuilder<Map<int, List<SmartRoomModel>>>(
        future: roomsFuture,
        builder: (context, snapshot) {
          final roomsByHome =
              snapshot.data ?? const <int, List<SmartRoomModel>>{};
          final moving = movingTargetKey != null;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'smartHomeMoveDevice'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              SizedBox(height: 8.h),
              _MoveTargetTile(
                icon: Icons.inventory_2_outlined,
                label: 'smartHomeUnassignedDevices'.tr,
                selected: widget.device.smartHomeId == null,
                busy: movingTargetKey == _moveTargetKey(null, null),
                onTap: moving ? null : () => _move(null, null),
              ),
              ...widget.controller.homes.expand((home) {
                final rooms = roomsByHome[home.id] ?? const <SmartRoomModel>[];
                return [
                  _MoveTargetTile(
                    icon: _locationIcon(home.type),
                    label: _locationLabel(home),
                    selected: widget.device.smartHomeId == home.id &&
                        widget.device.smartRoomId == null,
                    busy: movingTargetKey == _moveTargetKey(home.id, null),
                    onTap: moving ? null : () => _move(home.id, null),
                  ),
                  ...rooms.map(
                    (room) => _MoveTargetTile(
                      icon: Icons.meeting_room_outlined,
                      label: room.name,
                      indent: true,
                      selected: widget.device.smartRoomId == room.id,
                      busy: movingTargetKey == _moveTargetKey(home.id, room.id),
                      onTap: moving ? null : () => _move(home.id, room.id),
                    ),
                  ),
                ];
              }),
              if (snapshot.connectionState == ConnectionState.waiting)
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<int, List<SmartRoomModel>>> _loadRoomsByHome() async {
    final result = <int, List<SmartRoomModel>>{};
    for (final home in widget.controller.homes) {
      result[home.id] = await widget.controller.apiService.getRooms(
        home.id,
        userId: widget.controller.selectedOwnerId.value,
      );
    }
    return result;
  }

  Future<void> _move(int? homeId, int? roomId) async {
    final targetKey = _moveTargetKey(homeId, roomId);
    setState(() => movingTargetKey = targetKey);
    final ok = await widget.controller.moveSmartDevice(
      device: widget.device,
      smartHomeId: homeId,
      smartRoomId: roomId,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => movingTargetKey = null);
  }

  String _moveTargetKey(int? homeId, int? roomId) =>
      '${homeId ?? 'unassigned'}:${roomId ?? 'none'}';
}

class _MoveTargetTile extends StatelessWidget {
  const _MoveTargetTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.busy = false,
    this.indent = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool busy;
  final bool indent;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsetsDirectional.only(start: indent ? 28.w : 0),
      leading: Icon(icon, color: selected ? AppColors.primaryColor : null),
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: busy
          ? SizedBox(
              width: 18.r,
              height: 18.r,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : selected
              ? const Icon(Icons.check_rounded)
              : null,
      onTap: onTap,
    );
  }
}

Future<void> _showManageChannelsSheet({
  required SmartHomeController controller,
  required SmartDeviceModel device,
}) async {
  await Get.bottomSheet<void>(
    _ManageChannelsSheet(controller: controller, device: device),
    isScrollControlled: true,
  );
}

class _ManageChannelsSheet extends StatelessWidget {
  const _ManageChannelsSheet({
    required this.controller,
    required this.device,
  });

  final SmartHomeController controller;
  final SmartDeviceModel device;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetPanel(
      child: Obx(() {
        final current = controller.devices.firstWhereOrNull(
              (item) => item.id == device.id,
            ) ??
            device;
        final functions = _primarySwitchesForManagement(current);
        final metadata = functions
            .map((function) =>
                MapEntry(function, _functionMetadata(current, function)))
            .where((entry) => entry.value != null)
            .toList(growable: false);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'smartHomeManageChannels'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            SizedBox(height: 8.h),
            if (metadata.isEmpty)
              Text('smartHomeSwitchMetadataMissing'.tr)
            else
              ...metadata.asMap().entries.map((indexed) {
                final index = indexed.key;
                final entry = indexed.value;
                final function = entry.key;
                final item = entry.value!;
                return ListTile(
                  dense: true,
                  leading: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkResponse(
                        onTap: index == 0
                            ? null
                            : () => controller.updateDeviceFunctionSettings(
                                  device: current,
                                  function: item,
                                  sortOrder: item.sortOrder - 1,
                                ),
                        child:
                            Icon(Icons.keyboard_arrow_up_rounded, size: 18.r),
                      ),
                      InkResponse(
                        onTap: index == metadata.length - 1
                            ? null
                            : () => controller.updateDeviceFunctionSettings(
                                  device: current,
                                  function: item,
                                  sortOrder: item.sortOrder + 1,
                                ),
                        child:
                            Icon(Icons.keyboard_arrow_down_rounded, size: 18.r),
                      ),
                    ],
                  ),
                  title: Text(
                    _functionLabelForDevice(current, function),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Wrap(
                    spacing: 2.w,
                    children: [
                      IconButton(
                        tooltip: 'smartHomeEditSwitchName'.tr,
                        onPressed: () => _showRenameFunctionDialog(
                          controller: controller,
                          device: current,
                          function: function,
                        ),
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      IconButton(
                        tooltip: item.isVisible
                            ? 'smartHomeHideChannel'.tr
                            : 'smartHomeShowChannel'.tr,
                        onPressed: () =>
                            controller.updateDeviceFunctionSettings(
                          device: current,
                          function: item,
                          isVisible: !item.isVisible,
                        ),
                        icon: Icon(item.isVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded),
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      }),
    );
  }
}

class _SmartDeviceCard extends StatelessWidget {
  const _SmartDeviceCard({
    required this.controller,
    required this.device,
    required this.onOpen,
  });

  final SmartHomeController controller;
  final SmartDeviceModel device;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final busy = controller.deviceControlBusyIds.contains(device.id);
    final functions = _visiblePrimarySwitches(device);
    final curtainCommand = _dashboardCurtainCommand(device);
    final hasSchema = DeviceCapabilityResolver.functions(device).isNotEmpty;
    final powerFunction = DeviceCapabilityResolver.resolvePower(device);
    final showHeaderPowerButton = functions.isEmpty &&
        curtainCommand == null &&
        (powerFunction != null || !hasSchema);
    final powerActive = powerFunction == null
        ? device.powerOn == true
        : DeviceCapabilityResolver.statusValue(device, powerFunction) == true;
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 16.h),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 58.h,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(.08),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        _iconForCategory(device.category),
                        color: AppColors.primaryColor,
                        size: 26.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15.sp,
                                ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _deviceSubtitle(device),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.customGreyColor5,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    _OnlineDot(online: device.online),
                    PopupMenuButton<String>(
                      enabled: !busy,
                      tooltip: 'settings'.tr,
                      onSelected: (value) {
                        if (value == 'rename') {
                          _showRenameDeviceDialog(
                            controller: controller,
                            device: device,
                          );
                        } else if (value == 'move') {
                          _showMoveDeviceSheet(
                            controller: controller,
                            device: device,
                          );
                        } else if (value == 'channels') {
                          _showManageChannelsSheet(
                            controller: controller,
                            device: device,
                          );
                        } else if (value == 'delete') {
                          _showDeleteDeviceDialog(
                            controller: controller,
                            device: device,
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text('smartHomeRenameDevice'.tr),
                        ),
                        PopupMenuItem(
                          value: 'move',
                          child: Text('smartHomeMoveDevice'.tr),
                        ),
                        PopupMenuItem(
                          value: 'channels',
                          child: Text('smartHomeManageChannels'.tr),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('smartHomeDeleteDevice'.tr),
                        ),
                      ],
                      icon: const Icon(Icons.more_vert_rounded),
                    ),
                    if (showHeaderPowerButton)
                      _RoundPowerButton(
                        enabled: !busy,
                        busy: busy,
                        active: powerActive,
                        onPressed: () => controller.setDevicePower(
                          device: device,
                          powerOn: !powerActive,
                        ),
                      ),
                  ],
                ),
                if (curtainCommand != null) ...[
                  SizedBox(height: 12.h),
                  _CurtainMiniControls(
                    enabled: !busy,
                    onCommand: (value) => controller.setDeviceDps(
                      device: device,
                      commandCode: curtainCommand.code,
                      value: value,
                    ),
                  ),
                ] else if (functions.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: functions.map((function) {
                        final value = DeviceCapabilityResolver.statusValue(
                          device,
                          function,
                        );
                        return SizedBox(
                          width: 92.w,
                          child: _DpsShortcut(
                            label: _functionLabelForDevice(device, function),
                            value: value,
                            statusLabel: _functionStatusLabel(
                              function,
                              value,
                            ),
                            busy: busy,
                            onLongPress: () => _showRenameFunctionDialog(
                              controller: controller,
                              device: device,
                              function: function,
                            ),
                            onEdit: () => _showRenameFunctionDialog(
                              controller: controller,
                              device: device,
                              function: function,
                            ),
                            onTap: function.isBool
                                ? () => controller.setDeviceDps(
                                      device: device,
                                      commandCode: function.code,
                                      value: value != true,
                                    )
                                : null,
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _deviceSubtitle(SmartDeviceModel device) {
    if (device.roomName.trim().isNotEmpty) return device.roomName;
    if (device.smartHomeId == null) return 'smartHomeUnassignedDevices'.tr;
    if (device.category.isNotEmpty) return device.category;
    if (device.protocol.isNotEmpty) return device.protocol.toUpperCase();
    if (device.productName.isNotEmpty &&
        !_looksLikeTuyaIdentifier(device.productName)) {
      return device.productName;
    }
    return 'smartDevice'.tr;
  }

  bool _looksLikeTuyaIdentifier(String value) {
    final clean = value.trim();
    if (clean.length < 10) return false;
    return RegExp(r'^[a-z0-9_-]+$').hasMatch(clean);
  }

  IconData _iconForCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('light') || value.contains('switch')) {
      return Icons.lightbulb_outline_rounded;
    }
    if (value.contains('curtain') || value.contains('blind')) {
      return Icons.curtains_rounded;
    }
    if (value.contains('lock')) return Icons.lock_outline_rounded;
    if (value.contains('sensor')) return Icons.sensors_rounded;
    return Icons.devices_other_rounded;
  }
}

bool _looksLikeCurtainDevice(SmartDeviceModel device) {
  final text =
      '${device.category} ${device.productName} ${device.name}'.toLowerCase();
  return text.contains('curtain') ||
      text.contains('blind') ||
      text.contains('ستار') ||
      text.contains('بوابة');
}

TuyaDeviceFunction? _dashboardCurtainCommand(SmartDeviceModel device) {
  if (!_looksLikeCurtainDevice(device)) return null;
  for (final function in DeviceCapabilityResolver.writableFunctions(device)) {
    final code = function.code.toLowerCase();
    if (function.isEnum &&
        (code == 'control' ||
            code.contains('curtain') ||
            code.contains('mach_operate') ||
            code.contains('open_close'))) {
      return function;
    }
  }
  return null;
}

class _CurtainMiniControls extends StatelessWidget {
  const _CurtainMiniControls({
    required this.enabled,
    required this.onCommand,
  });

  final bool enabled;
  final ValueChanged<String> onCommand;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniCommandButton(
          icon: Icons.keyboard_arrow_up_rounded,
          label: _friendlyEnumValue('open'),
          enabled: enabled,
          onTap: () => onCommand('open'),
        ),
        SizedBox(width: 8.w),
        _MiniCommandButton(
          icon: Icons.pause_rounded,
          label: _friendlyEnumValue('stop'),
          enabled: enabled,
          onTap: () => onCommand('stop'),
        ),
        SizedBox(width: 8.w),
        _MiniCommandButton(
          icon: Icons.keyboard_arrow_down_rounded,
          label: _friendlyEnumValue('close'),
          enabled: enabled,
          onTap: () => onCommand('close'),
        ),
      ],
    );
  }
}

class _MiniCommandButton extends StatelessWidget {
  const _MiniCommandButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 18.r),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
      ),
    );
  }
}

String _deviceMainStatusLabel(SmartDeviceModel device) {
  final ar = Get.locale?.languageCode == 'ar';
  if (_looksLikeCurtainDevice(device)) {
    final functions = DeviceCapabilityResolver.writableFunctions(device);
    final command = _functionByCode(functions, 'control');
    final percent = _functionByCode(functions, 'percent_control');
    final commandValue = command == null
        ? null
        : DeviceCapabilityResolver.statusValue(device, command);
    final percentValue = percent == null
        ? null
        : DeviceCapabilityResolver.statusValue(device, percent);
    if (commandValue != null && percentValue != null) {
      return ar
          ? 'الحالة: ${_friendlyEnumValue(commandValue.toString())} - $percentValue%'
          : 'Status: ${_friendlyEnumValue(commandValue.toString())} - $percentValue%';
    }
    if (commandValue != null) {
      return ar
          ? 'الحالة: ${_friendlyEnumValue(commandValue.toString())}'
          : 'Status: ${_friendlyEnumValue(commandValue.toString())}';
    }
    if (percentValue != null) {
      return ar ? 'نسبة الفتح: $percentValue%' : 'Open percent: $percentValue%';
    }
    return '';
  }

  final power = DeviceCapabilityResolver.resolvePower(device);
  if (power == null) return '';
  final value = DeviceCapabilityResolver.statusValue(device, power);
  if (value is! bool) return '';
  return '${_functionLabelForDevice(device, power)}: ${_onOffLabel(value)}';
}

TuyaDeviceFunction? _functionByCode(
  List<TuyaDeviceFunction> functions,
  String code,
) {
  final clean = code.toLowerCase();
  for (final function in functions) {
    if (function.code.toLowerCase() == clean) return function;
  }
  return null;
}

String _functionLabel(TuyaDeviceFunction function) {
  final name = function.name.trim();
  if (name.isNotEmpty && !_containsCjk(name)) return name;
  return _friendlyDpsName(function.code);
}

String _functionLabelForDevice(
  SmartDeviceModel device,
  TuyaDeviceFunction function,
) {
  final metadata = _functionMetadata(device, function);
  final displayName = metadata?.displayName.trim() ?? '';
  if (displayName.isNotEmpty) return displayName;
  if (_isPrimarySwitchCode(function.code)) {
    return _defaultSwitchLabel(function.code);
  }
  return _functionLabel(function);
}

SmartDeviceFunctionModel? _functionMetadata(
  SmartDeviceModel device,
  TuyaDeviceFunction function,
) {
  return device.functions.firstWhereOrNull((item) =>
      item.code == function.code ||
      (item.dpId.isNotEmpty && item.dpId == function.dpId));
}

List<TuyaDeviceFunction> _visiblePrimarySwitches(SmartDeviceModel device) {
  final metadataByCode = {
    for (final item in device.functions)
      if (item.code.isNotEmpty) item.code: item,
  };
  final entries = DeviceCapabilityResolver.boolSwitches(device).where((item) {
    final metadata = metadataByCode[item.code];
    return metadata == null || metadata.isVisible;
  }).toList(growable: false);
  entries.sort((a, b) {
    final am = metadataByCode[a.code];
    final bm = metadataByCode[b.code];
    final order = (am?.sortOrder ?? 9999).compareTo(bm?.sortOrder ?? 9999);
    if (order != 0) return order;
    final ai = int.tryParse(a.dpId);
    final bi = int.tryParse(b.dpId);
    if (ai != null && bi != null) return ai.compareTo(bi);
    return a.dpId.compareTo(b.dpId);
  });
  return entries;
}

List<TuyaDeviceFunction> _primarySwitchesForManagement(
  SmartDeviceModel device,
) {
  final metadataByCode = {
    for (final item in device.functions)
      if (item.code.isNotEmpty) item.code: item,
  };
  final entries =
      DeviceCapabilityResolver.boolSwitches(device).toList(growable: false);
  entries.sort((a, b) {
    final am = metadataByCode[a.code];
    final bm = metadataByCode[b.code];
    final order = (am?.sortOrder ?? 9999).compareTo(bm?.sortOrder ?? 9999);
    if (order != 0) return order;
    final ai = int.tryParse(a.dpId);
    final bi = int.tryParse(b.dpId);
    if (ai != null && bi != null) return ai.compareTo(bi);
    return a.dpId.compareTo(b.dpId);
  });
  return entries;
}

bool _isPrimarySwitchCode(String code) {
  final clean = code.toLowerCase();
  return clean == 'switch' ||
      clean == 'switch_led' ||
      RegExp(r'^switch_\d+$').hasMatch(clean);
}

String _defaultSwitchLabel(String code) {
  final ar = Get.locale?.languageCode == 'ar';
  final match = RegExp(r'^switch_(\d+)$').firstMatch(code.toLowerCase());
  if (match != null) {
    return ar ? 'المفتاح ${match.group(1)}' : 'Switch ${match.group(1)}';
  }
  if (code.toLowerCase() == 'switch_led') return ar ? 'الإضاءة' : 'Light';
  return ar ? 'المفتاح' : 'Switch';
}

String _friendlyDpsName(String key) {
  final ar = Get.locale?.languageCode == 'ar';
  final code = key.trim().toLowerCase();
  final mapped = ar
      ? {
          'switch': 'تشغيل',
          'switch_1': 'المفتاح 1',
          'switch_2': 'المفتاح 2',
          'switch_3': 'المفتاح 3',
          'switch_4': 'المفتاح 4',
          'switch_led': 'الإضاءة',
          'switch_backlight': 'إضاءة زر الجهاز',
          'control': 'حركة الستارة',
          'percent_control': 'نسبة الفتح',
          'relay_status': 'حالة الريليه',
          'countdown_1': 'مؤقت المفتاح 1',
          'countdown_2': 'مؤقت المفتاح 2',
          'cur_calibration': 'معايرة الستارة',
          'control_back': 'اتجاه المحرك',
          'tr_timecon': 'وقت المعايرة',
          'bfbkqgb': 'فتح/إغلاق النسبة',
        }[code]
      : {
          'switch': 'Power',
          'switch_1': 'Switch 1',
          'switch_2': 'Switch 2',
          'switch_3': 'Switch 3',
          'switch_4': 'Switch 4',
          'switch_led': 'Light',
          'switch_backlight': 'Backlight',
          'control': 'Curtain',
          'percent_control': 'Open percent',
          'relay_status': 'Relay status',
          'countdown_1': 'Switch 1 timer',
          'countdown_2': 'Switch 2 timer',
          'cur_calibration': 'Calibration',
          'control_back': 'Motor direction',
          'tr_timecon': 'Calibration time',
          'bfbkqgb': 'Percent open/close',
        }[code];
  if (mapped != null) return mapped;
  final clean = key.replaceAll('_', ' ').trim();
  if (clean.isEmpty) return 'DPS';
  return clean.length > 16 ? '${clean.substring(0, 14)}...' : clean;
}

String _functionStatusLabel(TuyaDeviceFunction function, dynamic value) {
  final ar = Get.locale?.languageCode == 'ar';
  if (value == null) return ar ? 'غير معروف' : 'Unknown';
  if (function.isBool || value is bool) {
    return _onOffLabel(value == true);
  }
  if (function.isValue || value is num) {
    final unit = function.values['unit']?.toString() ?? '';
    return '$value$unit';
  }
  return _friendlyEnumValue(value.toString());
}

String _onOffLabel(bool active) {
  final ar = Get.locale?.languageCode == 'ar';
  return active ? (ar ? 'شغال' : 'On') : (ar ? 'مطفي' : 'Off');
}

String _friendlyEnumValue(String value) {
  final ar = Get.locale?.languageCode == 'ar';
  final key = value.toLowerCase();
  final mapped = ar
      ? {
          'open': 'فتح',
          'close': 'إغلاق',
          'stop': 'إيقاف',
          'continue': 'استمرار',
          'on': 'تشغيل',
          'off': 'إطفاء',
          'memory': 'آخر حالة',
          'forward': 'أمام',
          'back': 'عكس',
          'start': 'بدء',
          'end': 'إنهاء',
        }[key]
      : {
          'open': 'Open',
          'close': 'Close',
          'stop': 'Stop',
          'continue': 'Continue',
          'on': 'On',
          'off': 'Off',
          'memory': 'Memory',
          'forward': 'Forward',
          'back': 'Reverse',
          'start': 'Start',
          'end': 'End',
        }[key];
  return mapped ?? value;
}

bool _containsCjk(String value) {
  return value.runes.any((code) =>
      (code >= 0x3400 && code <= 0x9FFF) || (code >= 0xF900 && code <= 0xFAFF));
}

double _snapValue(
  double raw, {
  required double min,
  required double max,
  required double step,
}) {
  final safeStep = step <= 0 ? 1 : step;
  final clamped = raw.clamp(min, max).toDouble();
  final offset = ((clamped - min) / safeStep).round();
  return (min + (offset * safeStep)).clamp(min, max).toDouble();
}

int? _sliderDivisions({
  required double min,
  required double max,
  required double step,
}) {
  if (step <= 0 || max <= min) return null;
  final divisions = ((max - min) / step).round();
  return divisions > 0 ? divisions : null;
}

class _RoundPowerButton extends StatelessWidget {
  const _RoundPowerButton({
    required this.enabled,
    required this.busy,
    required this.active,
    required this.onPressed,
  });

  final bool enabled;
  final bool busy;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: enabled ? onPressed : null,
      radius: 28.r,
      child: Container(
        width: 54.w,
        height: 54.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? const Color(0xFF28C79A) : Colors.grey.shade300,
          boxShadow: [
            BoxShadow(
              color: (active ? const Color(0xFF28C79A) : Colors.black)
                  .withOpacity(active ? .18 : .06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: busy
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  Icons.power_settings_new_rounded,
                  color: Colors.white,
                  size: 28.r,
                ),
        ),
      ),
    );
  }
}

class _DpsShortcut extends StatelessWidget {
  const _DpsShortcut({
    required this.label,
    required this.value,
    required this.statusLabel,
    required this.busy,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
  });

  final String label;
  final dynamic value;
  final String statusLabel;
  final bool busy;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final active = value == true || (value is num && value != 0);
    final enabled = onTap != null && !busy;
    final activeColor = const Color(0xFF28C79A);
    return Opacity(
      opacity: active || enabled ? 1 : .42,
      child: Material(
        color: active ? activeColor.withOpacity(.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy && onTap != null)
                  SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    value is bool
                        ? Icons.power_settings_new_rounded
                        : Icons.tune_rounded,
                    color: active ? activeColor : AppColors.customGreyColor5,
                    size: 22.r,
                  ),
                SizedBox(height: 5.h),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            active ? activeColor : AppColors.customGreyColor5,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.sp,
                      ),
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: active
                                  ? activeColor
                                  : AppColors.customGreyColor5,
                              fontWeight: FontWeight.w900,
                              fontSize: 10.sp,
                            ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    InkResponse(
                      onTap: onEdit,
                      radius: 12.r,
                      child: Icon(
                        Icons.edit_rounded,
                        size: 12.r,
                        color: AppColors.customGreyColor5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: (online ? Colors.green : AppColors.customGreyColor5)
            .withOpacity(.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        online ? 'online'.tr : 'offline'.tr,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: online ? Colors.green : AppColors.customGreyColor5,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: online ? 'online'.tr : 'offline'.tr,
      child: Container(
        width: 9.r,
        height: 9.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: online ? Colors.green : AppColors.customGreyColor5,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppColors.customGreyColor5,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.redColor.withOpacity(.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: AppColors.redColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DeviceDetailsScreen extends StatefulWidget {
  const _DeviceDetailsScreen({
    required this.controller,
    required this.initialDevice,
  });

  final SmartHomeController controller;
  final SmartDeviceModel initialDevice;

  @override
  State<_DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<_DeviceDetailsScreen> {
  late SmartDeviceModel device;
  late final TextEditingController nameController;
  bool localControlBusy = false;

  @override
  void initState() {
    super.initState();
    device = widget.initialDevice;
    nameController = TextEditingController(text: device.name);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final loaded = await widget.controller.loadDeviceDetails(device);
    if (!mounted) return;
    setState(() {
      device = loaded;
      nameController.text = loaded.name;
    });
  }

  Future<void> _rename() async {
    final ok = await widget.controller.renameSmartDevice(
      device: device,
      name: nameController.text,
    );
    if (!mounted || !ok) return;
    final updated = widget.controller.devices.firstWhereOrNull(
      (item) => item.id == device.id,
    );
    if (updated != null) setState(() => device = updated);
  }

  Future<void> _togglePower(bool value) async {
    if (localControlBusy) return;
    setState(() => localControlBusy = true);
    try {
      final ok = await widget.controller.setDevicePower(
        device: device,
        powerOn: value,
      );
      if (!mounted || !ok) return;
      _syncDeviceFromController();
    } finally {
      if (mounted) setState(() => localControlBusy = false);
    }
  }

  Future<void> _sendDps(String code, dynamic value) async {
    if (localControlBusy) return;
    setState(() => localControlBusy = true);
    try {
      final ok = await widget.controller.setDeviceDps(
        device: device,
        commandCode: code,
        value: value,
      );
      if (!mounted || !ok) return;
      _syncDeviceFromController();
    } finally {
      if (mounted) setState(() => localControlBusy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await _showDeleteDeviceDialog(
      controller: widget.controller,
      device: device,
    );
    if (!mounted || !ok) return;
    Get.back<void>();
  }

  Future<void> _move() async {
    await _showMoveDeviceSheet(
      controller: widget.controller,
      device: device,
    );
    if (!mounted) return;
    await _load();
  }

  void _syncDeviceFromController() {
    final updated = widget.controller.devices.firstWhereOrNull(
      (item) => item.id == device.id,
    );
    if (updated != null) setState(() => device = updated);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text('smartHomeDeviceDetails'.tr),
        actions: [
          IconButton(
            tooltip: 'smartHomeMoveDevice'.tr,
            onPressed: _move,
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
          IconButton(
            tooltip: 'smartHomeDeleteDevice'.tr,
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          IconButton(
            tooltip: 'refresh'.tr,
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Obx(() {
        final busy = widget.controller.deviceDetailsBusyIds.contains(device.id);
        final controlling = localControlBusy ||
            widget.controller.deviceControlBusyIds.contains(device.id);
        const readOnly = false;
        return ListView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
          children: [
            if (widget.controller.errorMessage.value.isNotEmpty)
              _ErrorBanner(message: widget.controller.errorMessage.value),
            _DeviceHero(device: device, busy: busy),
            SizedBox(height: 18.h),
            _DeviceCommandSurface(
              device: device,
              busy: controlling,
              readOnly: readOnly,
              onPowerChanged: _togglePower,
              onDps: _sendDps,
              onRenameFunction: (function) => _showRenameFunctionDialog(
                controller: widget.controller,
                device: device,
                function: function,
              ).then((_) => _syncDeviceFromController()),
            ),
            SizedBox(height: 14.h),
            _DeviceRenameCard(
              controller: nameController,
              enabled: !controlling && !readOnly,
              onSave: _rename,
            ),
            SizedBox(height: 14.h),
            _DeviceSpecsCard(device: device),
            SizedBox(height: 14.h),
            _DpsCard(device: device),
          ],
        );
      }),
    );
  }
}

class _DeviceHero extends StatelessWidget {
  const _DeviceHero({required this.device, required this.busy});

  final SmartDeviceModel device;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final iconUrl = device.icon.trim();
    final statusText = _deviceMainStatusLabel(device);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Container(
            width: 62.r,
            height: 62.r,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(8.r),
            ),
            clipBehavior: Clip.antiAlias,
            child: iconUrl.isEmpty
                ? Icon(
                    Icons.devices_other_rounded,
                    color: Colors.white,
                    size: 32.r,
                  )
                : Image.network(
                    iconUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.devices_other_rounded,
                      color: Colors.white,
                      size: 32.r,
                    ),
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                SizedBox(height: 6.h),
                Text(
                  _deviceLocationSummary(device),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(.8),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (statusText.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (busy)
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          else
            _OnlinePill(online: device.online),
        ],
      ),
    );
  }
}

class _DeviceCommandSurface extends StatelessWidget {
  const _DeviceCommandSurface({
    required this.device,
    required this.busy,
    required this.readOnly,
    required this.onPowerChanged,
    required this.onDps,
    required this.onRenameFunction,
  });

  final SmartDeviceModel device;
  final bool busy;
  final bool readOnly;
  final ValueChanged<bool> onPowerChanged;
  final void Function(String code, dynamic value) onDps;
  final ValueChanged<TuyaDeviceFunction> onRenameFunction;

  @override
  Widget build(BuildContext context) {
    final curtainCommand = _curtainCommandFunction(device);
    final auxiliary = _auxiliaryFunctions(device);
    if (_looksLikeCurtainDevice(device) || curtainCommand != null) {
      return Column(
        children: [
          _CurtainCommandSurface(
            device: device,
            busy: busy,
            readOnly: readOnly,
            commandFunction: curtainCommand,
            percentFunction: _curtainPercentFunction(device),
            onDps: onDps,
          ),
          _AuxiliaryControlsSurface(
            device: device,
            entries: auxiliary,
            title: 'smartHomeAdvancedControls'.tr,
            busy: busy,
            readOnly: readOnly,
            onDps: onDps,
          ),
        ],
      );
    }

    final boolFunctions = _visiblePrimarySwitches(device);
    if (boolFunctions.length >= 2) {
      return Column(
        children: [
          _MultiSwitchCommandSurface(
            device: device,
            entries: boolFunctions,
            busy: busy,
            readOnly: readOnly,
            onDps: onDps,
            onRenameFunction: onRenameFunction,
          ),
          _AuxiliaryControlsSurface(
            device: device,
            entries: auxiliary,
            title: 'smartHomeAdvancedControls'.tr,
            busy: busy,
            readOnly: readOnly,
            onDps: onDps,
          ),
        ],
      );
    }

    return Column(
      children: [
        _PowerCommandSurface(
          device: device,
          busy: busy,
          readOnly: readOnly,
          onPowerChanged: onPowerChanged,
        ),
        _AuxiliaryControlsSurface(
          device: device,
          entries: auxiliary,
          title: 'smartHomeAdvancedControls'.tr,
          busy: busy,
          readOnly: readOnly,
          onDps: onDps,
        ),
      ],
    );
  }

  TuyaDeviceFunction? _curtainCommandFunction(SmartDeviceModel device) {
    for (final function in DeviceCapabilityResolver.writableFunctions(device)) {
      final code = function.code.toLowerCase();
      if (function.isEnum &&
          (code.contains('control') ||
              code.contains('curtain') ||
              code.contains('mach_operate') ||
              code.contains('open_close'))) {
        return function;
      }
    }
    return null;
  }

  TuyaDeviceFunction? _curtainPercentFunction(SmartDeviceModel device) {
    for (final function in DeviceCapabilityResolver.writableFunctions(device)) {
      final code = function.code.toLowerCase();
      if (function.isValue &&
          (code.contains('percent') || code.contains('position'))) {
        return function;
      }
    }
    return null;
  }

  List<TuyaDeviceFunction> _auxiliaryFunctions(SmartDeviceModel device) {
    final primaryDpIds = <String>{
      ...DeviceCapabilityResolver.boolSwitches(device).map((item) => item.dpId),
      for (final code in const ['control', 'percent_control'])
        ...DeviceCapabilityResolver.writableFunctions(device)
            .where((item) => item.code.toLowerCase() == code)
            .map((item) => item.dpId),
    };
    return DeviceCapabilityResolver.writableFunctions(device)
        .where((item) => !primaryDpIds.contains(item.dpId))
        .toList(growable: false);
  }
}

class _MultiSwitchCommandSurface extends StatelessWidget {
  const _MultiSwitchCommandSurface({
    required this.device,
    required this.entries,
    required this.busy,
    required this.readOnly,
    required this.onDps,
    required this.onRenameFunction,
  });

  final SmartDeviceModel device;
  final List<TuyaDeviceFunction> entries;
  final bool busy;
  final bool readOnly;
  final void Function(String code, dynamic value) onDps;
  final ValueChanged<TuyaDeviceFunction> onRenameFunction;

  @override
  Widget build(BuildContext context) {
    final enabled = !busy && !readOnly;
    bool isOn(TuyaDeviceFunction function) =>
        DeviceCapabilityResolver.statusValue(device, function) == true;
    final allOn = entries.isNotEmpty && entries.every(isOn);
    final allOff = entries.isNotEmpty && entries.every((item) => !isOn(item));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: entries.length == 1 ? 1 : 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.18,
          ),
          itemBuilder: (context, index) {
            final function = entries[index];
            final value =
                DeviceCapabilityResolver.statusValue(device, function);
            return _SwitchChannelButton(
              label: _functionLabelForDevice(device, function),
              active: value == true,
              busy: busy,
              enabled: enabled,
              onLongPress: () => onRenameFunction(function),
              onEdit: () => onRenameFunction(function),
              onTap: () => onDps(function.code, value != true),
            );
          },
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: _AllSwitchesButton(
                label: 'smartHomeAllOff'.tr,
                enabled: enabled,
                active: allOff,
                activeColor: const Color(0xFFE05252),
                onTap: () {
                  for (final function in entries) {
                    final value = DeviceCapabilityResolver.statusValue(
                      device,
                      function,
                    );
                    if (value == true) onDps(function.code, false);
                  }
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _AllSwitchesButton(
                label: 'smartHomeAllOn'.tr,
                enabled: enabled,
                active: allOn,
                activeColor: const Color(0xFF28C79A),
                onTap: () {
                  for (final function in entries) {
                    final value = DeviceCapabilityResolver.statusValue(
                      device,
                      function,
                    );
                    if (value != true) onDps(function.code, true);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuxiliaryControlsSurface extends StatelessWidget {
  const _AuxiliaryControlsSurface({
    required this.device,
    required this.entries,
    required this.title,
    required this.busy,
    required this.readOnly,
    required this.onDps,
  });

  final SmartDeviceModel device;
  final List<TuyaDeviceFunction> entries;
  final String title;
  final bool busy;
  final bool readOnly;
  final void Function(String code, dynamic value) onDps;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final enabled = !busy && !readOnly;
    final grouped = <String, List<TuyaDeviceFunction>>{};
    for (final function in entries) {
      grouped
          .putIfAbsent(_secondarySectionTitle(function), () => [])
          .add(function);
    }
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: grouped.entries.expand((section) {
          return [
            Padding(
              padding: EdgeInsets.only(bottom: 7.h, top: 4.h),
              child: Text(
                section.key,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            ...section.value.map((function) {
              final value =
                  DeviceCapabilityResolver.statusValue(device, function);
              final active = value == true;
              final statusColor =
                  active ? const Color(0xFF28C79A) : AppColors.customGreyColor5;
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.black.withOpacity(.05)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _functionIcon(function),
                      color: statusColor,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _secondaryFunctionLabel(device, function),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _functionStatusLabel(function, value),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    _AuxiliaryControlAction(
                      function: function,
                      value: value,
                      enabled: enabled,
                      onDps: onDps,
                    ),
                  ],
                ),
              );
            }),
          ];
        }).toList(growable: false),
      ),
    );
  }
}

String _secondarySectionTitle(TuyaDeviceFunction function) {
  final code = function.code.toLowerCase();
  if (code.contains('countdown') || code.contains('timer')) {
    return 'smartHomeTimers'.tr;
  }
  if (code.contains('backlight') ||
      code.contains('relay') ||
      code.contains('inching') ||
      code.contains('calibration') ||
      code.contains('control_back') ||
      code.contains('direction')) {
    return 'smartHomeDeviceSettings'.tr;
  }
  return 'smartHomeAdvancedControls'.tr;
}

String _secondaryFunctionLabel(
  SmartDeviceModel device,
  TuyaDeviceFunction function,
) {
  final code = function.code.toLowerCase();
  final ar = Get.locale?.languageCode == 'ar';
  final countdown = RegExp(r'countdown_(\d+)').firstMatch(code);
  if (countdown != null) {
    final switchCode = 'switch_${countdown.group(1)}';
    final related = device.functions.firstWhereOrNull(
      (item) => item.code.toLowerCase() == switchCode,
    );
    final relatedName = related?.displayName.trim().isNotEmpty == true
        ? related!.displayName.trim()
        : _defaultSwitchLabel(switchCode);
    return ar ? 'مؤقت $relatedName' : '$relatedName timer';
  }
  final mapped = ar
      ? {
          'switch_backlight': 'إضاءة المؤشر',
          'relay_status': 'حالة التشغيل بعد عودة الكهرباء',
          'switch_inching': 'نبضة تشغيل',
          'cur_calibration': 'معايرة الستارة',
          'control_back': 'اتجاه المحرك',
          'tr_timecon': 'وقت المعايرة',
        }[code]
      : {
          'switch_backlight': 'Indicator light',
          'relay_status': 'Power-on state after outage',
          'switch_inching': 'Inching pulse',
          'cur_calibration': 'Curtain calibration',
          'control_back': 'Motor direction',
          'tr_timecon': 'Calibration time',
        }[code];
  if (mapped != null) return mapped;
  return _functionLabelForDevice(device, function);
}

class _AuxiliaryControlAction extends StatelessWidget {
  const _AuxiliaryControlAction({
    required this.function,
    required this.value,
    required this.enabled,
    required this.onDps,
  });

  final TuyaDeviceFunction function;
  final dynamic value;
  final bool enabled;
  final void Function(String code, dynamic value) onDps;

  @override
  Widget build(BuildContext context) {
    if (function.isBool) {
      return Switch.adaptive(
        value: value == true,
        onChanged: enabled ? (next) => onDps(function.code, next) : null,
      );
    }
    if (function.isEnum) {
      final range = function.values['range'];
      final options = range is List
          ? range.map((item) => item.toString()).toList(growable: false)
          : const <String>[];
      if (options.isEmpty) return const SizedBox.shrink();
      return PopupMenuButton<String>(
        enabled: enabled,
        tooltip: _functionLabel(function),
        onSelected: (next) => onDps(function.code, next),
        itemBuilder: (_) => options
            .map(
              (option) => PopupMenuItem<String>(
                value: option,
                child: Text(_friendlyEnumValue(option)),
              ),
            )
            .toList(growable: false),
        child: Icon(
          Icons.more_horiz_rounded,
          color: enabled ? AppColors.primaryColor : AppColors.customGreyColor5,
        ),
      );
    }
    if (function.isValue) {
      return IconButton(
        tooltip: 'smartHomeEditValue'.tr,
        onPressed: enabled
            ? () => _showValueControlDialog(
                  function: function,
                  value: value,
                  onDps: onDps,
                )
            : null,
        icon: const Icon(Icons.tune_rounded),
      );
    }
    if (function.isString && function.writable) {
      return IconButton(
        tooltip: 'smartHomeEditValue'.tr,
        onPressed: enabled
            ? () => _showTextControlDialog(
                  function: function,
                  value: value?.toString() ?? '',
                  onDps: onDps,
                )
            : null,
        icon: const Icon(Icons.edit_note_rounded),
      );
    }
    return const SizedBox(width: 8);
  }
}

Future<void> _showValueControlDialog({
  required TuyaDeviceFunction function,
  required dynamic value,
  required void Function(String code, dynamic value) onDps,
}) async {
  final min = _doubleValue(function.values['min']) ?? 0;
  final max = _doubleValue(function.values['max']) ?? 86400;
  final step = _doubleValue(function.values['step']) ?? 1;
  final current = (_doubleValue(value) ?? min).clamp(min, max).toDouble();
  var next = _snapValue(current, min: min, max: max, step: step);
  final result = await Get.dialog<num>(
    StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('smartHomeEditValue'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: next.clamp(min, max),
                min: min,
                max: max,
                divisions: _sliderDivisions(min: min, max: max, step: step),
                onChanged: (value) => setState(
                  () =>
                      next = _snapValue(value, min: min, max: max, step: step),
                ),
              ),
              Text(next.round().toString()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back<num>(),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () => Get.back<num>(result: next.round()),
              child: Text('save'.tr),
            ),
          ],
        );
      },
    ),
  );
  if (result != null) onDps(function.code, result);
}

Future<void> _showTextControlDialog({
  required TuyaDeviceFunction function,
  required String value,
  required void Function(String code, dynamic value) onDps,
}) async {
  final controller = TextEditingController(text: value);
  final result = await Get.dialog<String>(
    AlertDialog(
      title: Text('smartHomeEditValue'.tr),
      content: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Get.back<String>(result: value),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<String>(),
          child: Text('cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () => Get.back<String>(result: controller.text),
          child: Text('save'.tr),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result != null) onDps(function.code, result);
}

IconData _functionIcon(TuyaDeviceFunction function) {
  final code = function.code.toLowerCase();
  if (code.contains('backlight')) return Icons.light_mode_outlined;
  if (code.contains('countdown') || code.contains('time')) {
    return Icons.timer_outlined;
  }
  if (code.contains('calibration')) return Icons.tune_rounded;
  if (code.contains('relay')) return Icons.restart_alt_rounded;
  if (code.contains('control_back')) return Icons.compare_arrows_rounded;
  if (function.isEnum) return Icons.list_alt_rounded;
  if (function.isValue) return Icons.pin_rounded;
  if (function.isString) return Icons.notes_rounded;
  return Icons.settings_outlined;
}

class _SwitchChannelButton extends StatelessWidget {
  const _SwitchChannelButton({
    required this.label,
    required this.active,
    required this.busy,
    required this.enabled,
    required this.onLongPress,
    required this.onEdit,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool busy;
  final bool enabled;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF28C79A);
    return Material(
      color:
          ThemeService.isDark.value ? AppColors.customGreyColor : Colors.white,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: active ? activeColor : Colors.black.withOpacity(.05),
              width: active ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (active ? activeColor : Colors.black)
                    .withOpacity(active ? .14 : .045),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50.r,
                      height: 50.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? activeColor : Colors.grey.shade300,
                      ),
                      child: Center(
                        child: busy
                            ? SizedBox(
                                width: 18.r,
                                height: 18.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.power_settings_new_rounded,
                                color: Colors.white,
                                size: 26.r,
                              ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: active
                                ? activeColor
                                : AppColors.customGreyColor5,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                top: 0,
                end: 0,
                child: IconButton(
                  tooltip: 'smartHomeEditSwitchName'.tr,
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                  constraints: BoxConstraints.tight(Size(32.r, 32.r)),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.edit_rounded,
                    size: 15.r,
                    color: AppColors.customGreyColor5,
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

class _AllSwitchesButton extends StatelessWidget {
  const _AllSwitchesButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.active = false,
    this.activeColor = const Color(0xFF28C79A),
  });

  final String label;
  final bool enabled;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? activeColor : Colors.white,
        foregroundColor: active ? Colors.white : AppColors.customGreyColor5,
        minimumSize: Size.fromHeight(54.h),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        elevation: active ? 6 : 0,
        shadowColor:
            active ? activeColor.withValues(alpha: .36) : Colors.transparent,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _PowerCommandSurface extends StatelessWidget {
  const _PowerCommandSurface({
    required this.device,
    required this.busy,
    required this.readOnly,
    required this.onPowerChanged,
  });

  final SmartDeviceModel device;
  final bool busy;
  final bool readOnly;
  final ValueChanged<bool> onPowerChanged;

  @override
  Widget build(BuildContext context) {
    final powerFunction = DeviceCapabilityResolver.resolvePower(device);
    final hasSchema = DeviceCapabilityResolver.functions(device).isNotEmpty;
    final active = powerFunction == null
        ? device.powerOn == true
        : DeviceCapabilityResolver.statusValue(device, powerFunction) == true;
    final canToggle =
        (powerFunction != null || !hasSchema) && !readOnly && !busy;
    return SizedBox(
      height: 330.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 270.w,
            height: 270.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : Colors.white,
              border: Border.all(color: Colors.white.withOpacity(.8), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.055),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
          ),
          InkResponse(
            onTap: canToggle ? () => onPowerChanged(!active) : null,
            radius: 82.r,
            child: Container(
              width: 118.w,
              height: 118.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? const Color(0xFF28C79A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.12),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: busy
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Icon(
                        Icons.power_settings_new_rounded,
                        color:
                            active ? Colors.white : AppColors.customGreyColor5,
                        size: 54.r,
                      ),
              ),
            ),
          ),
          Positioned(
            top: 62.h,
            child: Text(
              _onOffLabel(active),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: active
                        ? const Color(0xFF28C79A)
                        : AppColors.customGreyColor5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
            ),
          ),
          Positioned(
            bottom: 42.h,
            child: Text(
              powerFunction == null
                  ? hasSchema
                      ? 'smartHomeNoPowerDps'.tr
                      : (Get.locale?.languageCode == 'ar'
                          ? 'تحميل أمر التشغيل'
                          : 'Loading power function')
                  : _functionLabelForDevice(device, powerFunction),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.customGreyColor5,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurtainCommandSurface extends StatelessWidget {
  const _CurtainCommandSurface({
    required this.device,
    required this.busy,
    required this.readOnly,
    required this.commandFunction,
    required this.percentFunction,
    required this.onDps,
  });

  final SmartDeviceModel device;
  final bool busy;
  final bool readOnly;
  final TuyaDeviceFunction? commandFunction;
  final TuyaDeviceFunction? percentFunction;
  final void Function(String code, dynamic value) onDps;

  @override
  Widget build(BuildContext context) {
    final disabled = busy || readOnly || commandFunction == null;
    final currentCommand = commandFunction == null
        ? null
        : DeviceCapabilityResolver.statusValue(device, commandFunction!);
    final rawPercent = percentFunction == null
        ? null
        : DeviceCapabilityResolver.statusValue(device, percentFunction!);
    final min = _valueSetting(percentFunction, 'min') ?? 0;
    final max = _valueSetting(percentFunction, 'max') ?? 100;
    final step = _valueSetting(percentFunction, 'step') ?? 1;
    final percent = _snapValue(
      (_doubleValue(rawPercent) ?? min).clamp(min, max).toDouble(),
      min: min,
      max: max,
      step: step,
    );
    final statusLabel = currentCommand == null
        ? (rawPercent == null
            ? (Get.locale?.languageCode == 'ar'
                ? 'الحالة غير معروفة'
                : 'Unknown status')
            : '${_functionLabel(percentFunction!)}: ${percent.round()}%')
        : _friendlyEnumValue(currentCommand.toString());
    return Column(
      children: [
        SizedBox(
          height: 360.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 292.w,
                height: 292.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : Colors.white,
                  border: Border.all(
                      color: Colors.white.withOpacity(.85), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.055),
                      blurRadius: 36,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 44.h,
                child: _CurtainActionButton(
                  icon: Icons.keyboard_arrow_up_rounded,
                  label: _friendlyEnumValue('open'),
                  onTap: disabled
                      ? null
                      : () => onDps(commandFunction!.code, 'open'),
                ),
              ),
              Positioned(
                bottom: 40.h,
                child: _CurtainActionButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  label: _friendlyEnumValue('close'),
                  onTap: disabled
                      ? null
                      : () => onDps(commandFunction!.code, 'close'),
                ),
              ),
              InkResponse(
                onTap: disabled
                    ? null
                    : () => onDps(commandFunction!.code, 'stop'),
                radius: 64.r,
                child: Container(
                  width: 108.w,
                  height: 108.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.12),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: busy
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : Icon(
                            Icons.pause_rounded,
                            color: AppColors.customGreyColor5,
                            size: 56.r,
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 132.h,
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.customGreyColor5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
              ),
            ],
          ),
        ),
        if (percentFunction != null)
          _CurtainPercentSlider(
            label: _functionLabel(percentFunction!),
            value: percent,
            min: min,
            max: max,
            step: step,
            enabled: !busy && !readOnly,
            onChanged: (value) => onDps(percentFunction!.code, value.round()),
          ),
      ],
    );
  }

  double? _valueSetting(TuyaDeviceFunction? function, String key) {
    final raw = function?.values[key];
    return _doubleValue(raw);
  }
}

double? _doubleValue(dynamic raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '');
}

class _CurtainActionButton extends StatelessWidget {
  const _CurtainActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(42.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42.r, color: AppColors.customGreyColor5),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.customGreyColor5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurtainPercentSlider extends StatefulWidget {
  const _CurtainPercentSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  State<_CurtainPercentSlider> createState() => _CurtainPercentSliderState();
}

class _CurtainPercentSliderState extends State<_CurtainPercentSlider> {
  late double value;

  @override
  void initState() {
    super.initState();
    value = _snapped(widget.value);
  }

  @override
  void didUpdateWidget(covariant _CurtainPercentSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.min != widget.min ||
        oldWidget.max != widget.max ||
        oldWidget.step != widget.step) {
      value = _snapped(widget.value);
    }
  }

  double _snapped(double raw) => _snapValue(
        raw,
        min: widget.min,
        max: widget.max,
        step: widget.step,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        children: [
          SizedBox(
            width: 82.w,
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.customGreyColor5,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(widget.min, widget.max),
              min: widget.min,
              max: widget.max,
              divisions: _sliderDivisions(
                min: widget.min,
                max: widget.max,
                step: widget.step,
              ),
              onChanged: widget.enabled
                  ? (next) => setState(() => value = _snapped(next))
                  : null,
              onChangeEnd: widget.enabled
                  ? (next) => widget.onChanged(_snapped(next))
                  : null,
            ),
          ),
          SizedBox(
            width: 52.w,
            child: Text(
              '${value.round()}%',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceRenameCard extends StatelessWidget {
  const _DeviceRenameCard({
    required this.controller,
    required this.enabled,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              decoration: InputDecoration(labelText: 'smartHomeDeviceName'.tr),
            ),
          ),
          SizedBox(width: 10.w),
          IconButton.filled(
            tooltip: 'save'.tr,
            onPressed: enabled ? onSave : null,
            icon: const Icon(Icons.save_rounded),
          ),
        ],
      ),
    );
  }
}

class _DeviceSpecsCard extends StatelessWidget {
  const _DeviceSpecsCard({required this.device});

  final SmartDeviceModel device;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('smartHomeCategory'.tr, device.category),
      MapEntry('smartHomeProductName'.tr, device.productName),
      MapEntry('smartHomeProtocol'.tr, device.protocol.toUpperCase()),
      MapEntry('smartHomeModel'.tr, device.model),
      MapEntry('smartHomeManufacturer'.tr, device.manufacturer),
      MapEntry('smartHomeProductId'.tr, device.tuyaProductId),
      MapEntry('smartHomeUuid'.tr, device.tuyaUuid),
    ].where((row) => row.value.trim().isNotEmpty).toList(growable: false);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'smartHomeDeviceSpecs'.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          SizedBox(height: 10.h),
          if (rows.isEmpty)
            Text('smartHomeNoSpecs'.tr)
          else
            ...rows.map((row) => _SpecRow(label: row.key, value: row.value)),
        ],
      ),
    );
  }
}

class _DpsCard extends StatelessWidget {
  const _DpsCard({required this.device});

  final SmartDeviceModel device;

  @override
  Widget build(BuildContext context) {
    final rows = _dpsStatusRows(device);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'smartHomeDpsStatus'.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          SizedBox(height: 10.h),
          if (rows.isEmpty)
            Text('smartHomeNoDps'.tr)
          else
            ...rows.map((row) => _SpecRow(label: row.key, value: row.value)),
        ],
      ),
    );
  }
}

List<MapEntry<String, String>> _dpsStatusRows(SmartDeviceModel device) {
  final status = DeviceCapabilityResolver.statusMap(device);
  final functions = DeviceCapabilityResolver.functions(device);
  final byDpId = {
    for (final function in functions) function.dpId: function,
  };
  final entries = status.entries.toList(growable: false)
    ..sort((a, b) {
      final aKey = a.key.toString();
      final bKey = b.key.toString();
      final aNumber = int.tryParse(aKey);
      final bNumber = int.tryParse(bKey);
      if (aNumber != null && bNumber != null) {
        return aNumber.compareTo(bNumber);
      }
      return aKey.compareTo(bKey);
    });

  return entries.map((entry) {
    final dpId = entry.key.toString();
    final function = byDpId[dpId];
    final label = function == null
        ? dpId
        : '$dpId - ${_functionLabelForDevice(device, function)}';
    final value = function == null
        ? _rawStatusLabel(entry.value)
        : _functionStatusLabel(function, entry.value);
    return MapEntry(label, value);
  }).toList(growable: false);
}

String _rawStatusLabel(dynamic value) {
  final ar = Get.locale?.languageCode == 'ar';
  if (value == null) return ar ? 'غير معروف' : 'Unknown';
  if (value is bool) return _onOffLabel(value);
  if (value is String) return _friendlyEnumValue(value);
  return value.toString();
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.customGreyColor5,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: child,
    );
  }
}
