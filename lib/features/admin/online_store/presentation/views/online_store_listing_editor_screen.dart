import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../../../routes/app_routes.dart';
import '../../data/online_store_models.dart';
import '../controllers/online_store_listings_controller.dart';
import '../controllers/online_store_media_controller.dart';
import '../utils/online_store_feedback.dart';
import '../utils/online_store_permissions.dart';
import '../widgets/online_store_network_image.dart';

class OnlineStoreListingEditorScreen extends StatefulWidget {
  const OnlineStoreListingEditorScreen({Key? key}) : super(key: key);

  @override
  State<OnlineStoreListingEditorScreen> createState() =>
      _OnlineStoreListingEditorScreenState();
}

class _OnlineStoreListingEditorScreenState
    extends State<OnlineStoreListingEditorScreen> {
  final controller = Get.find<OnlineStoreListingsController>();
  final mediaController = Get.find<OnlineStoreMediaController>();
  late OnlineStoreListing listing;
  late final TextEditingController nameAr;
  late final TextEditingController descriptionAr;
  late final TextEditingController stockLimit;
  late final TextEditingController brandAr;
  late final TextEditingController shippingWarrantyAr;
  late final TextEditingController returnPolicyAr;
  late final List<TextEditingController> specLabels;
  late final List<TextEditingController> specValues;
  late List<String> specIcons;
  late bool customName;
  late bool customDescription;
  late bool useFullInventory;
  late bool isFeatured;
  late bool isNew;
  late bool showOnHome;
  List<OnlineStoreEntity> categories = const [];
  Set<int> selectedCategoryIds = <int>{};
  bool loadingCategories = false;
  bool submitting = false;

  static const purple = Color(0xFF6D28D9);
  static const border = Color(0xFFE4E7EC);
  static const muted = Color(0xFFF6F7F9);

  @override
  void initState() {
    super.initState();
    listing = Get.arguments as OnlineStoreListing;
    customName = '${listing.titleTranslations['ar'] ?? ''}'.trim().isNotEmpty;
    customDescription =
        '${listing.descriptionTranslations['ar'] ?? ''}'.trim().isNotEmpty;
    nameAr = TextEditingController(
        text:
            customName ? '${listing.titleTranslations['ar']}' : _originalName);
    descriptionAr = TextEditingController(
        text: customDescription
            ? '${listing.descriptionTranslations['ar']}'
            : _originalDescription);
    useFullInventory = listing.onlineStockLimit == null;
    stockLimit = TextEditingController(
        text: '${listing.onlineStockLimit ?? _inventoryAvailable}');
    final presentation = listing.detailPresentation;
    brandAr = TextEditingController(
        text:
            '${onlineStoreMap(presentation['brand_translations'])['ar'] ?? ''}');
    shippingWarrantyAr = TextEditingController(
        text:
            '${onlineStoreMap(presentation['shipping_warranty_translations'])['ar'] ?? ''}');
    returnPolicyAr = TextEditingController(
        text:
            '${onlineStoreMap(presentation['return_policy_translations'])['ar'] ?? ''}');
    final quickSpecs = onlineStoreRows(presentation['quick_specs']);
    specLabels = List.generate(
        3,
        (index) => TextEditingController(
            text: index < quickSpecs.length
                ? '${onlineStoreMap(quickSpecs[index]['label_translations'])['ar'] ?? ''}'
                : ''));
    specValues = List.generate(
        3,
        (index) => TextEditingController(
            text: index < quickSpecs.length
                ? '${onlineStoreMap(quickSpecs[index]['value_translations'])['ar'] ?? ''}'
                : ''));
    specIcons = List.generate(
        3,
        (index) => index < quickSpecs.length
            ? '${quickSpecs[index]['icon'] ?? 'custom'}'
            : const ['speed', 'battery', 'motor'][index]);
    isFeatured = listing.isFeatured;
    isNew = listing.isNew;
    showOnHome = listing.showOnHome;
    mediaController.load(listing.id);
    if (OnlineStorePermissions.canManageCategories) _loadCategories();
  }

  String get _originalName =>
      '${listing.originalNameTranslations['ar'] ?? listing.productName}';
  String get _originalDescription =>
      '${listing.originalDescriptionTranslations['ar'] ?? ''}';
  int get _physicalStock =>
      int.tryParse('${listing.availability['physical_stock'] ?? 0}') ?? 0;
  int get _reserved =>
      int.tryParse('${listing.availability['reserved_qty'] ?? 0}') ?? 0;
  int get _inventoryAvailable =>
      int.tryParse(
          '${listing.availability['inventory_available_qty'] ?? listing.availability['available_qty'] ?? 0}') ??
      0;
  int get _onlineAvailable => useFullInventory
      ? _inventoryAvailable
      : (int.tryParse(stockLimit.text) ?? 0).clamp(0, _inventoryAvailable);

  Future<void> _loadCategories() async {
    setState(() => loadingCategories = true);
    try {
      final snapshot = await controller.listingCategories(listing.id);
      if (!mounted) return;
      setState(() {
        categories = snapshot.categories
            .where((category) =>
                category.values['is_active'] == true ||
                category.values['is_active'] == 1)
            .toList(growable: false);
        selectedCategoryIds = snapshot.selectedIds;
      });
    } finally {
      if (mounted) setState(() => loadingCategories = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF4F5F7),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF151A2D),
          title: const Text('تجهيز المنتج للمتجر',
              style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            Center(child: _statusChip()),
            const SizedBox(width: 12),
          ],
        ),
        bottomNavigationBar: _bottomActions(),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              _productSummary(),
              _section(
                title: 'معلومات العرض',
                icon: Icons.description_outlined,
                child: Column(children: [
                  _sourceValue('الاسم الأصلي', _originalName),
                  _switchRow('استخدام اسم مختلف في المتجر', customName,
                      (value) {
                    setState(() {
                      customName = value;
                      if (!value) nameAr.text = _originalName;
                    });
                  }),
                  _input(nameAr, 'اسم المنتج في المتجر', enabled: customName),
                  const Divider(height: 28),
                  _sourceValue('الوصف الأصلي', _originalDescription,
                      maxLines: 3),
                  _switchRow('استخدام وصف مختلف في المتجر', customDescription,
                      (value) {
                    setState(() {
                      customDescription = value;
                      if (!value) descriptionAr.text = _originalDescription;
                    });
                  }),
                  _input(descriptionAr, 'الوصف في المتجر',
                      enabled: customDescription, lines: 3),
                ]),
              ),
              _productPresentationSection(),
              _section(
                title: 'كمية المتجر',
                icon: Icons.inventory_2_outlined,
                child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: _metric('المتوفر فعلياً', '$_physicalStock',
                            const Color(0xFFEAF8EF), const Color(0xFF15803D))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _metric('المحجوز', '$_reserved',
                            const Color(0xFFFFF7E8), const Color(0xFFF59E0B))),
                  ]),
                  _stockMode('إتاحة كامل المخزون', true),
                  _stockMode('تحديد حد للبيع عبر المتجر', false),
                  _input(stockLimit, 'الكمية المتاحة للمتجر',
                      enabled: !useFullInventory,
                      numeric: true,
                      suffix: 'قطع',
                      onChanged: (_) => setState(() {})),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E9FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                        'المتاح للبيع إلكترونياً: $_onlineAvailable قطع',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: purple, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'هذا الحد لا يغيّر مخزون المنتج الأساسي، ويعرض الأقل بينه وبين المتوفر الفعلي.',
                    style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                  ),
                ]),
              ),
              _mediaSection(),
              _section(
                title: 'التصنيف والظهور',
                icon: Icons.sell_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (loadingCategories)
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: muted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                      )
                    else if (categories.isEmpty)
                      const Text('لا توجد تصنيفات متجر فعالة.')
                    else
                      DropdownButtonFormField<int>(
                        initialValue: selectedCategoryIds.isEmpty
                            ? null
                            : selectedCategoryIds.first,
                        decoration:
                            const InputDecoration(labelText: 'التصنيف الرئيسي'),
                        items: categories
                            .map((category) => DropdownMenuItem(
                                value: category.id,
                                child: Text(category.label)))
                            .toList(),
                        onChanged: (id) => setState(
                            () => selectedCategoryIds = id == null ? {} : {id}),
                      ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _optionChip('مميز', isFeatured,
                          (value) => setState(() => isFeatured = value)),
                      _optionChip('جديد', isNew,
                          (value) => setState(() => isNew = value)),
                      _optionChip('الرئيسية', showOnHome,
                          (value) => setState(() => showOnHome = value)),
                    ]),
                    const SizedBox(height: 14),
                    _readinessPanel(),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.PRODUCTDETAILSSCREEN,
                    arguments: listing.productId),
                icon: const Icon(Icons.open_in_new),
                label: const Text('فتح المنتج الأصلي في المخزون'),
              ),
            ],
          ),
        ),
      );

  Widget _productSummary() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: _box(),
        child: Row(children: [
          Obx(() {
            final main = mediaController.items
                .firstWhereOrNull((item) => item.isMain && item.isVisible);
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: muted,
                width: 74,
                height: 74,
                child: main == null || main.url.isEmpty
                    ? const Icon(Icons.inventory_2_outlined, size: 34)
                    : OnlineStoreNetworkImage(path: main.url),
              ),
            );
          }),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(customName ? nameAr.text : _originalName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(
                  'رمز المنتج: ${listing.productCode.isEmpty ? listing.productId : listing.productCode}',
                  style: const TextStyle(color: Color(0xFF667085))),
              const SizedBox(height: 4),
              Text('المتوفر في المخزون: $_physicalStock قطعة',
                  style: const TextStyle(
                      color: Color(0xFF15803D), fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      );

  Widget _mediaSection() => _section(
        title: 'وسائط صفحة المنتج',
        icon: Icons.image_outlined,
        child: Obx(() {
          if (mediaController.loading.value) {
            return SizedBox(
              height: 142,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tileWidth = ((constraints.maxWidth - 16) / 3)
                      .clamp(72.0, 112.0)
                      .toDouble();
                  return Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        3,
                        (index) => Padding(
                          padding: EdgeInsetsDirectional.only(
                              end: index == 2 ? 0 : 8),
                          child: Container(
                            width: tileWidth,
                            decoration: BoxDecoration(
                              color: muted,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: border),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return SizedBox(
            height: 142,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _importProductMediaTile(),
                _addImageTile(),
                _addVideoTile(),
                ...mediaController.items.map(_mediaTile),
              ],
            ),
          );
        }),
      );

  Widget _importProductMediaTile() => InkWell(
        onTap: mediaController.saving.value
            ? null
            : mediaController.importMissingProductMedia,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 118,
          margin: const EdgeInsetsDirectional.only(end: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F0FF),
            border: Border.all(color: const Color(0xFF7C3AED)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sync_rounded, size: 32, color: Color(0xFF7C3AED)),
              SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('استيراد وسائط المنتج',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );

  Widget _addVideoTile() => InkWell(
        onTap: () async {
          final picked = await FilePicker.platform.pickFiles(
            type: FileType.video,
            allowMultiple: false,
          );
          final path = picked?.files.single.path;
          if (path != null) {
            await mediaController.addStoreVideo(XFile(path));
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 108,
          margin: const EdgeInsetsDirectional.only(end: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF98A2B3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined, size: 34),
              SizedBox(height: 6),
              Text('إضافة فيديو'),
            ],
          ),
        ),
      );

  Widget _addImageTile() => InkWell(
        onTap: () async {
          final file =
              await ImagePicker().pickImage(source: ImageSource.gallery);
          if (file != null) await mediaController.addStoreImage(file);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 108,
          margin: const EdgeInsetsDirectional.only(end: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF98A2B3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 34),
                SizedBox(height: 6),
                Text('إضافة صورة'),
              ]),
        ),
      );

  Widget _mediaTile(OnlineStoreMedia media) => Container(
        width: 128,
        margin: const EdgeInsetsDirectional.only(end: 10),
        decoration: BoxDecoration(
          border: Border.all(color: media.isMain ? purple : border, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned.fill(
              child: media.mediaType == 'video'
                  ? const ColoredBox(
                      color: Color(0xFF101218),
                      child: Center(
                          child: Icon(Icons.play_circle_outline,
                              color: Colors.white, size: 42)),
                    )
                  : media.url.isEmpty
                      ? const ColoredBox(color: muted, child: Icon(Icons.image))
                      : OnlineStoreNetworkImage(path: media.url)),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(
                media.sourceType == 'store_specific'
                    ? 'خاص بالمتجر'
                    : 'من المخزون',
                style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF151A2D).withValues(alpha: .86),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _mediaRoleLabel(media),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            left: 4,
            right: 4,
            bottom: 4,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _mediaAction(media.isMain ? Icons.star : Icons.star_border,
                      () => mediaController.selectMain(media.sourceMediaId),
                      selected: media.isMain),
                  _mediaAction(
                      media.isVisible ? Icons.visibility : Icons.visibility_off,
                      () => mediaController.toggleVisible(media.sourceMediaId)),
                  PopupMenuButton<String>(
                    tooltip: 'نوع الصورة',
                    onSelected: (value) =>
                        mediaController.setRole(media.sourceMediaId, value),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'additional', child: Text('صورة إضافية')),
                      PopupMenuItem(value: 'folded', child: Text('صورة مطوية')),
                      PopupMenuItem(
                          value: 'detail', child: Text('صورة تفصيلية')),
                      PopupMenuItem(value: 'video', child: Text('فيديو')),
                    ],
                    child: const Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(7)),
                      child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.label_outline, size: 20)),
                    ),
                  ),
                ]),
          ),
        ]),
      );

  String _mediaRoleLabel(OnlineStoreMedia media) {
    if (media.isMain) return 'صورة رئيسية';
    if (media.mediaType == 'video' || media.role == 'video') return 'فيديو';
    if (media.sourceType == 'image3d' || media.role == 'model_3d') {
      return 'عرض 3D';
    }
    return const {
          'folded': 'صورة مطوية',
          'detail': 'صورة تفصيلية',
          'additional': 'صورة إضافية',
        }[media.role] ??
        'صورة إضافية';
  }

  Widget _productPresentationSection() => _section(
        title: 'تفاصيل صفحة المنتج في المتجر',
        icon: Icons.storefront_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _input(brandAr, 'العلامة/المتجر (اختياري)'),
            const SizedBox(height: 12),
            const Text('المواصفات السريعة (حتى 3)',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (var index = 0; index < 3; index++) ...[
              LayoutBuilder(builder: (context, constraints) {
                final iconPicker = DropdownButtonFormField<String>(
                  initialValue: specIcons[index],
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'الأيقونة'),
                  items: const {
                    'speed': 'السرعة',
                    'battery': 'البطارية',
                    'motor': 'المحرك',
                    'range': 'المدى',
                    'weight': 'الوزن',
                    'warranty': 'الضمان',
                    'custom': 'أخرى',
                  }
                      .entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => specIcons[index] = value ?? 'custom'),
                );
                final textFields = Row(children: [
                  Expanded(child: _input(specLabels[index], 'العنوان')),
                  const SizedBox(width: 8),
                  Expanded(child: _input(specValues[index], 'القيمة')),
                ]);
                if (constraints.maxWidth < 480) {
                  return Column(children: [
                    iconPicker,
                    const SizedBox(height: 8),
                    textFields,
                  ]);
                }
                return Row(children: [
                  SizedBox(width: 118, child: iconPicker),
                  const SizedBox(width: 8),
                  Expanded(child: textFields),
                ]);
              }),
              const SizedBox(height: 10),
            ],
            _input(shippingWarrantyAr, 'الشحن والضمان', lines: 3),
            const SizedBox(height: 10),
            _input(returnPolicyAr, 'سياسة الإرجاع', lines: 3),
            const SizedBox(height: 8),
            const Text(
              'هذه الحقول تخص عرض المتجر الإلكتروني فقط ولا تعدّل بيانات المنتج الأصلي.',
              style: TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ],
        ),
      );

  Widget _mediaAction(IconData icon, VoidCallback onTap,
          {bool selected = false}) =>
      Material(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(icon,
                  size: 20, color: selected ? purple : Colors.black87)),
        ),
      );

  Widget _section(
          {required String title,
          required IconData icon,
          required Widget child}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: _box(),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(icon, color: const Color(0xFF344054)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ]),
      );

  BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A101828), blurRadius: 8, offset: Offset(0, 2))
        ],
      );

  Widget _sourceValue(String label, String value, {int maxLines = 1}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: muted, borderRadius: BorderRadius.circular(9)),
          child: Text(value.trim().isEmpty ? 'لا توجد قيمة أصلية' : value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF475467))),
        ),
      ]);

  Widget _switchRow(String title, bool value, ValueChanged<bool> changed) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        value: value,
        activeThumbColor: purple,
        onChanged: changed,
      );

  Widget _input(TextEditingController controller, String label,
          {bool enabled = true,
          bool numeric = false,
          int lines = 1,
          String? suffix,
          ValueChanged<String>? onChanged}) =>
      TextField(
        controller: controller,
        enabled: enabled,
        maxLines: lines,
        keyboardType: numeric ? TextInputType.number : null,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, suffixText: suffix),
      );

  Widget _metric(String label, String value, Color background, Color color) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        ]),
      );

  Widget _stockMode(String label, bool value) => InkWell(
        onTap: () => setState(() => useFullInventory = value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Icon(
              useFullInventory == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color:
                  useFullInventory == value ? purple : const Color(0xFF98A2B3),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
          ]),
        ),
      );

  Widget _optionChip(String label, bool value, ValueChanged<bool> changed) =>
      FilterChip(
        label: Text(label),
        selected: value,
        selectedColor: const Color(0xFFF0E9FF),
        checkmarkColor: purple,
        onSelected: changed,
      );

  Widget _readinessPanel() {
    final ready = listing.readinessIssues.isEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ready ? const Color(0xFFEAF8EF) : const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(children: [
        Icon(ready ? Icons.check_circle : Icons.info_outline,
            color: ready ? const Color(0xFF15803D) : const Color(0xFFD97706)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            ready
                ? 'جميع متطلبات النشر مكتملة'
                : listing.readinessIssues
                    .map(OnlineStoreFeedback.readinessLabel)
                    .join(' • '),
            style: TextStyle(
                color:
                    ready ? const Color(0xFF15803D) : const Color(0xFF9A3412),
                fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }

  Widget _statusChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: muted, borderRadius: BorderRadius.circular(16)),
        child: Text(const {
              'draft': 'مسودة',
              'ready': 'جاهز',
              'published': 'منشور',
              'hidden': 'مخفي',
            }[listing.status] ??
            listing.status),
      );

  Widget _bottomActions() => SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Obx(() => Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.saving.value || submitting
                        ? null
                        : () => _save(false),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: purple,
                        side: const BorderSide(color: purple),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('حفظ كمسودة',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: controller.saving.value || submitting
                        ? null
                        : () => _save(true),
                    style: FilledButton.styleFrom(
                        backgroundColor: purple,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('حفظ ونشر في المتجر',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ])),
        ),
      );

  Future<void> _refresh() async {
    final refreshed = await controller.repository.listing(listing.id);
    if (!mounted) return;
    setState(() => listing = refreshed);
    await mediaController.load(listing.id);
    if (OnlineStorePermissions.canManageCategories) await _loadCategories();
  }

  Future<void> _save(bool publish) async {
    if (!useFullInventory) {
      final value = int.tryParse(stockLimit.text);
      if (value == null || value < 0 || value > _inventoryAvailable) {
        OnlineStoreFeedback.error(
            Exception('أدخل كمية صحيحة لا تتجاوز المتوفر فعلياً.'),
            context: context);
        return;
      }
    }
    setState(() => submitting = true);
    try {
      var updated = await controller.updateListing(listing, {
        'name_translations': {
          ...listing.titleTranslations,
          'ar': customName ? nameAr.text.trim() : null,
        },
        'description_translations': {
          ...listing.descriptionTranslations,
          'ar': customDescription ? descriptionAr.text.trim() : null,
        },
        'detail_presentation': {
          ...listing.detailPresentation,
          'brand_translations': {
            ...onlineStoreMap(listing.detailPresentation['brand_translations']),
            'ar': brandAr.text.trim().isEmpty ? null : brandAr.text.trim(),
          },
          'shipping_warranty_translations': {
            ...onlineStoreMap(
                listing.detailPresentation['shipping_warranty_translations']),
            'ar': shippingWarrantyAr.text.trim().isEmpty
                ? null
                : shippingWarrantyAr.text.trim(),
          },
          'return_policy_translations': {
            ...onlineStoreMap(
                listing.detailPresentation['return_policy_translations']),
            'ar': returnPolicyAr.text.trim().isEmpty
                ? null
                : returnPolicyAr.text.trim(),
          },
          'quick_specs': [
            for (var index = 0; index < 3; index++)
              if (specLabels[index].text.trim().isNotEmpty &&
                  specValues[index].text.trim().isNotEmpty)
                {
                  'icon': specIcons[index],
                  'label_translations': {'ar': specLabels[index].text.trim()},
                  'value_translations': {'ar': specValues[index].text.trim()},
                },
          ],
        },
        'is_featured': isFeatured,
        'is_new': isNew,
        'show_on_home': showOnHome,
        'online_stock_limit':
            useFullInventory ? null : int.parse(stockLimit.text),
        if (listing.updatedAt != null) 'updated_at': listing.updatedAt,
      });
      if (updated == null || !mounted) return;
      await mediaController.save();
      if (OnlineStorePermissions.canManageCategories) {
        await controller.saveListingCategories(updated.id, selectedCategoryIds);
      }
      updated = await controller.repository.listing(updated.id);
      if (!mounted) return;
      if (publish) {
        if (updated.readinessIssues.isNotEmpty) {
          setState(() => listing = updated!);
          OnlineStoreFeedback.error(
            Exception(updated.readinessIssues
                .map(OnlineStoreFeedback.readinessLabel)
                .join('\n')),
            title: 'أكمل متطلبات النشر أولاً',
            context: context,
          );
          return;
        }
        updated = await _publish(updated);
        if (updated == null || !mounted) return;
      }
      setState(() => listing = updated!);
      OnlineStoreFeedback.success(
          publish
              ? 'تم نشر المنتج، وسيظهر الآن في المتجر.'
              : 'تم حفظ تخصيصات المتجر.',
          context: context);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<OnlineStoreListing?> _publish(OnlineStoreListing current) async {
    var updated = current;
    for (var step = 0; step < 3 && updated.status != 'published'; step++) {
      final target = const <String, String>{
        'hidden': 'draft',
        'draft': 'ready',
        'ready': 'published',
      }[updated.status];
      if (target == null) {
        if (!mounted) return null;
        OnlineStoreFeedback.error(
          Exception('لا يمكن نشر المنتج من حالته الحالية.'),
          context: context,
        );
        return null;
      }
      final transitioned = await controller.transition(updated, target);
      if (transitioned == null) return null;
      updated = transitioned;
    }
    return updated.status == 'published' ? updated : null;
  }

  @override
  void dispose() {
    nameAr.dispose();
    descriptionAr.dispose();
    stockLimit.dispose();
    brandAr.dispose();
    shippingWarrantyAr.dispose();
    returnPolicyAr.dispose();
    for (final controller in [...specLabels, ...specValues]) {
      controller.dispose();
    }
    super.dispose();
  }
}
