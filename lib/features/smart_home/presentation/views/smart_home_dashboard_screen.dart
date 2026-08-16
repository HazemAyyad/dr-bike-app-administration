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
      children: controller.devices
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
  final nameController = TextEditingController(text: device.name);
  var saving = false;
  final result = await Get.dialog<bool>(
    StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('smartHomeRenameDevice'.tr),
          content: TextField(
            controller: nameController,
            enabled: !saving,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: 'smartHomeDeviceName'.tr),
            onSubmitted: (_) async {
              if (saving) return;
              setState(() => saving = true);
              final ok = await controller.renameSmartDevice(
                device: device,
                name: nameController.text,
              );
              if (Get.isDialogOpen == true) Get.back(result: ok);
            },
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Get.back(result: false),
              child: Text('cancel'.tr),
            ),
            ElevatedButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      final ok = await controller.renameSmartDevice(
                        device: device,
                        name: nameController.text,
                      );
                      if (Get.isDialogOpen == true) Get.back(result: ok);
                    },
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
      },
    ),
  );
  nameController.dispose();
  return result == true;
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
    final dps = _visibleDps(device).take(4).toList(growable: false);
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
                    SizedBox(width: 8.w),
                    _RenameDeviceButton(
                      enabled: !busy,
                      onPressed: () => _showRenameDeviceDialog(
                        controller: controller,
                        device: device,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _RoundPowerButton(
                      enabled: device.canTogglePower && !busy,
                      busy: busy,
                      active: device.powerOn == true,
                      onPressed: () => controller.setDevicePower(
                        device: device,
                        powerOn: device.powerOn != true,
                      ),
                    ),
                  ],
                ),
                if (dps.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Row(
                    children: dps
                        .map(
                          (entry) => Expanded(
                            child: _DpsShortcut(
                              label: _dpsLabel(device, entry.key),
                              value: entry.value,
                              busy: busy,
                              onTap: entry.value is bool
                                  ? () => controller.setDeviceDps(
                                        device: device,
                                        commandCode: entry.key,
                                        value: !(entry.value as bool),
                                      )
                                  : null,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<MapEntry<String, dynamic>> _visibleDps(SmartDeviceModel device) {
    final entries = device.lastStatus.entries
        .where((entry) => entry.value is bool || entry.value is num)
        .toList(growable: false);
    entries.sort((a, b) {
      final ap = a.key == device.primaryPowerDp ? 0 : 1;
      final bp = b.key == device.primaryPowerDp ? 0 : 1;
      return ap == bp ? a.key.compareTo(b.key) : ap.compareTo(bp);
    });
    return entries;
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

List<MapEntry<String, dynamic>> _boolDps(Map<String, dynamic> status) {
  final entries = status.entries
      .where((entry) => entry.value is bool)
      .toList(growable: false);
  entries.sort((a, b) => a.key.compareTo(b.key));
  return entries;
}

String _dpsLabel(SmartDeviceModel device, String key) {
  final fromSchema = _schemaName(device, key);
  if (fromSchema.isNotEmpty) return fromSchema;
  return _friendlyDpsName(key);
}

String _schemaName(SmartDeviceModel device, String key) {
  final schemaMap = device.rawMetadata['schema_map'];
  if (schemaMap is! Map) return '';

  final direct = schemaMap[key];
  if (direct is Map) {
    final name = direct['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
  }

  for (final raw in schemaMap.values) {
    if (raw is! Map) continue;
    final code = raw['code']?.toString();
    if (code != key) continue;
    final name = raw['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
  }
  return '';
}

String _friendlyDpsName(String key) {
  final clean = key
      .replaceAll('_', ' ')
      .replaceAll('switch led', 'switch')
      .replaceAll('switch', 'Switch')
      .trim();
  if (clean.isEmpty) return 'DPS';
  return clean.length > 16 ? '${clean.substring(0, 14)}...' : clean;
}

class _RenameDeviceButton extends StatelessWidget {
  const _RenameDeviceButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: 'smartHomeRenameDevice'.tr,
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.edit_rounded),
    );
  }
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
    required this.busy,
    required this.onTap,
  });

  final String label;
  final dynamic value;
  final bool busy;
  final VoidCallback? onTap;

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
                Text(
                  value == true
                      ? 'ON'
                      : value == false
                          ? 'OFF'
                          : '$value',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            active ? activeColor : AppColors.customGreyColor5,
                        fontWeight: FontWeight.w900,
                        fontSize: 10.sp,
                      ),
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
    final ok = await widget.controller.setDevicePower(
      device: device,
      powerOn: value,
    );
    if (!mounted || !ok) return;
    _syncDeviceFromController();
  }

  Future<void> _sendDps(String code, dynamic value) async {
    final ok = await widget.controller.setDeviceDps(
      device: device,
      commandCode: code,
      value: value,
    );
    if (!mounted || !ok) return;
    _syncDeviceFromController();
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
            tooltip: 'refresh'.tr,
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Obx(() {
        final busy = widget.controller.deviceDetailsBusyIds.contains(device.id);
        final controlling =
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
            _DpsCard(status: device.lastStatus),
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
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: Colors.white.withOpacity(.16),
            child: Icon(Icons.devices_other_rounded,
                color: Colors.white, size: 30.r),
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
                  device.tuyaDeviceId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(.8),
                        fontWeight: FontWeight.w600,
                      ),
                ),
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
  });

  final SmartDeviceModel device;
  final bool busy;
  final bool readOnly;
  final ValueChanged<bool> onPowerChanged;
  final void Function(String code, dynamic value) onDps;

  @override
  Widget build(BuildContext context) {
    final curtainDp = _curtainCommandDp(device.lastStatus);
    final boolDps = _boolDps(device.lastStatus);
    if (_looksLikeCurtain(device) || curtainDp.isNotEmpty) {
      return _CurtainCommandSurface(
        device: device,
        busy: busy,
        readOnly: readOnly,
        commandDp: curtainDp,
        percentDp: _curtainPercentDp(device.lastStatus),
        onDps: onDps,
      );
    }

    if (boolDps.length >= 2) {
      return _MultiSwitchCommandSurface(
        device: device,
        entries: boolDps,
        busy: busy,
        readOnly: readOnly,
        onDps: onDps,
      );
    }

    return _PowerCommandSurface(
      device: device,
      busy: busy,
      readOnly: readOnly,
      onPowerChanged: onPowerChanged,
    );
  }

  bool _looksLikeCurtain(SmartDeviceModel device) {
    final text =
        '${device.category} ${device.productName} ${device.name}'.toLowerCase();
    return text.contains('curtain') ||
        text.contains('blind') ||
        text.contains('ستار') ||
        text.contains('بوابة');
  }

  String _curtainCommandDp(Map<String, dynamic> status) {
    for (final key in const [
      'control',
      'control_1',
      'curtain_control',
      'mach_operate',
      'open_close',
    ]) {
      if (status.containsKey(key)) return key;
    }
    return '';
  }

  String _curtainPercentDp(Map<String, dynamic> status) {
    for (final key in const [
      'percent_control',
      'percent_control_1',
      'percent_state',
      'position',
    ]) {
      if (status[key] is num) return key;
    }
    return '';
  }
}

class _MultiSwitchCommandSurface extends StatelessWidget {
  const _MultiSwitchCommandSurface({
    required this.device,
    required this.entries,
    required this.busy,
    required this.readOnly,
    required this.onDps,
  });

  final SmartDeviceModel device;
  final List<MapEntry<String, dynamic>> entries;
  final bool busy;
  final bool readOnly;
  final void Function(String code, dynamic value) onDps;

  @override
  Widget build(BuildContext context) {
    final enabled = !busy && !readOnly;
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
            final entry = entries[index];
            return _SwitchChannelButton(
              label: _dpsLabel(device, entry.key),
              active: entry.value == true,
              busy: busy,
              enabled: enabled,
              onTap: () => onDps(entry.key, entry.value != true),
            );
          },
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: _AllSwitchesButton(
                label: 'OFF',
                enabled: enabled,
                onTap: () {
                  for (final entry in entries) {
                    if (entry.value == true) onDps(entry.key, false);
                  }
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _AllSwitchesButton(
                label: 'ON',
                enabled: enabled,
                active: true,
                onTap: () {
                  for (final entry in entries) {
                    if (entry.value != true) onDps(entry.key, true);
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

class _SwitchChannelButton extends StatelessWidget {
  const _SwitchChannelButton({
    required this.label,
    required this.active,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool busy;
  final bool enabled;
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
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58.r,
                height: 58.r,
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
                          size: 30.r,
                        ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: active ? activeColor : AppColors.customGreyColor5,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              SizedBox(height: 4.h),
              Text(
                active ? 'ON' : 'OFF',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: active ? activeColor : AppColors.customGreyColor5,
                      fontWeight: FontWeight.w900,
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
  });

  final String label;
  final bool enabled;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? const Color(0xFF28C79A) : Colors.white,
        foregroundColor: active ? Colors.white : AppColors.customGreyColor5,
        minimumSize: Size.fromHeight(54.h),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        elevation: 0,
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
    final active = device.powerOn == true;
    final canToggle = device.canTogglePower && !readOnly && !busy;
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
              active ? 'ON' : 'OFF',
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
              device.primaryPowerDp.isEmpty
                  ? 'No DPS'
                  : '${'smartHomeDpsCode'.tr}: ${device.primaryPowerDp}',
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
    required this.commandDp,
    required this.percentDp,
    required this.onDps,
  });

  final SmartDeviceModel device;
  final bool busy;
  final bool readOnly;
  final String commandDp;
  final String percentDp;
  final void Function(String code, dynamic value) onDps;

  @override
  Widget build(BuildContext context) {
    final disabled = busy || readOnly || commandDp.isEmpty;
    final percent = percentDp.isEmpty
        ? 0.0
        : ((device.lastStatus[percentDp] as num?)?.toDouble() ?? 0)
            .clamp(0, 100)
            .toDouble();
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
                  label: 'open',
                  onTap: disabled ? null : () => onDps(commandDp, 'open'),
                ),
              ),
              Positioned(
                bottom: 40.h,
                child: _CurtainActionButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  label: 'close',
                  onTap: disabled ? null : () => onDps(commandDp, 'close'),
                ),
              ),
              InkResponse(
                onTap: disabled ? null : () => onDps(commandDp, 'stop'),
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
            ],
          ),
        ),
        if (percentDp.isNotEmpty)
          _CurtainPercentSlider(
            label: device.name,
            value: percent,
            enabled: !busy && !readOnly,
            onChanged: (value) => onDps(percentDp, value.round()),
          ),
      ],
    );
  }
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
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final double value;
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
    value = widget.value;
  }

  @override
  void didUpdateWidget(covariant _CurtainPercentSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) value = widget.value;
  }

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
              value: value.clamp(0, 100),
              min: 0,
              max: 100,
              onChanged: widget.enabled
                  ? (next) => setState(() => value = next)
                  : null,
              onChangeEnd: widget.enabled ? widget.onChanged : null,
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
  const _DpsCard({required this.status});

  final Map<String, dynamic> status;

  @override
  Widget build(BuildContext context) {
    final rows = status.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
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
            ...rows.map(
              (row) => _SpecRow(
                label: row.key,
                value: row.value?.toString() ?? '',
              ),
            ),
        ],
      ),
    );
  }
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
