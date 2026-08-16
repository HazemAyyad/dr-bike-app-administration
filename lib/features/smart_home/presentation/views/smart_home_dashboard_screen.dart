import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/services/theme_service.dart';
import '../../../../core/utils/app_colors.dart';
import '../../data/smart_home_api_service.dart';
import '../../data/smart_home_native_service.dart';
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
        actions: [
          IconButton(
            tooltip: 'refresh'.tr,
            onPressed: controller.refreshData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.homes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
            children: [
              if (controller.errorMessage.value.isNotEmpty)
                _ErrorBanner(message: controller.errorMessage.value),
              if (controller.canViewSmartHomeOwners) ...[
                _OwnerFilter(controller: controller),
                SizedBox(height: 14.h),
              ],
              _HomeSummaryCard(controller: controller),
              SizedBox(height: 16.h),
              _NativeStatusCard(controller: controller),
              SizedBox(height: 16.h),
              _SectionHeader(
                title: 'rooms'.tr,
                actionLabel: 'addRoom'.tr,
                onAction: () => _notReady('addRoom'.tr),
              ),
              SizedBox(height: 8.h),
              _RoomsStrip(controller: controller),
              SizedBox(height: 18.h),
              _SectionHeader(
                title: 'devices'.tr,
                actionLabel: 'addDevice'.tr,
                onAction: controller.canViewSmartHomeOwners &&
                        controller.selectedOwnerId.value != null
                    ? () => _notReady('smartHomeAdminReadOnly'.tr)
                    : _showAddDeviceDialog,
              ),
              SizedBox(height: 8.h),
              _DevicesList(controller: controller),
            ],
          ),
        );
      }),
    );
  }

  void _notReady(String title) {
    Get.snackbar(title, 'smartHomeComingSoon'.tr);
  }

  Future<void> _showAddDeviceDialog() async {
    await Get.to<void>(() => _AddDeviceFlowScreen(controller: controller));
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

class _HomeSummaryCard extends StatelessWidget {
  const _HomeSummaryCard({required this.controller});

  final SmartHomeController controller;

  @override
  Widget build(BuildContext context) {
    final home = controller.selectedHome;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            home?.name.isNotEmpty == true
                ? home!.name
                : 'smartHomeDefaultName'.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w800,
                ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'devices'.tr,
                  value: controller.devicesCount.toString(),
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'online'.tr,
                  value: controller.onlineDevicesCount.toString(),
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'offline'.tr,
                  value: controller.offlineDevicesCount.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
              ),
        ),
        SizedBox(height: 3.h),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.white.withOpacity(.85),
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
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
    if (controller.rooms.isEmpty) {
      return _EmptyState(text: 'noRoomsYet'.tr);
    }
    return SizedBox(
      height: 46.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.rooms.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final room = controller.rooms[index];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              room.name,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          );
        },
      ),
    );
  }
}

class _DevicesList extends StatelessWidget {
  const _DevicesList({required this.controller});

  final SmartHomeController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.devices.isEmpty) {
      return _EmptyState(text: 'noDevicesYet'.tr);
    }
    return Column(
      children: controller.devices.map((device) {
        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.all(12.w),
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
                child: Icon(
                  _iconForCategory(device.category),
                  color: AppColors.primaryColor,
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
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _deviceSubtitle(device),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppColors.customGreyColor5,
                          ),
                    ),
                  ],
                ),
              ),
              _OnlinePill(online: device.online),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _deviceSubtitle(SmartDeviceModel device) {
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
