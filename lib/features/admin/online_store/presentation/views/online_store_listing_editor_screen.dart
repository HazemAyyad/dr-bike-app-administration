import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../routes/app_routes.dart';
import '../../data/online_store_models.dart';
import '../controllers/online_store_listings_controller.dart';
import '../utils/online_store_permissions.dart';
import '../widgets/online_store_listing_readiness.dart';

class OnlineStoreListingEditorScreen extends StatefulWidget {
  const OnlineStoreListingEditorScreen({Key? key}) : super(key: key);

  @override
  State<OnlineStoreListingEditorScreen> createState() =>
      _OnlineStoreListingEditorScreenState();
}

class _OnlineStoreListingEditorScreenState
    extends State<OnlineStoreListingEditorScreen> {
  final controller = Get.find<OnlineStoreListingsController>();
  late OnlineStoreListing listing;
  late final TextEditingController nameAr;
  late final TextEditingController nameEn;
  late final TextEditingController descriptionAr;
  late final TextEditingController descriptionEn;
  late final TextEditingController badgeAr;
  late final TextEditingController sortOrder;
  late bool isFeatured;
  late bool isNew;
  late bool showOnHome;
  late bool showAsOffer;

  @override
  void initState() {
    super.initState();
    listing = Get.arguments as OnlineStoreListing;
    nameAr =
        TextEditingController(text: '${listing.titleTranslations['ar'] ?? ''}');
    nameEn =
        TextEditingController(text: '${listing.titleTranslations['en'] ?? ''}');
    descriptionAr = TextEditingController(
        text: '${listing.descriptionTranslations['ar'] ?? ''}');
    descriptionEn = TextEditingController(
        text: '${listing.descriptionTranslations['en'] ?? ''}');
    badgeAr =
        TextEditingController(text: '${listing.badgeTranslations['ar'] ?? ''}');
    sortOrder = TextEditingController(text: '${listing.sortOrder}');
    isFeatured = listing.isFeatured;
    isNew = listing.isNew;
    showOnHome = listing.showOnHome;
    showAsOffer = listing.showAsOffer;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(listing.productName.isEmpty
              ? 'قائمة المنتج'
              : listing.productName),
          actions: [
            if (OnlineStorePermissions.canManageProducts)
              IconButton(
                tooltip: 'حفظ بيانات العرض',
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
              ),
          ],
        ),
        body: ListView(padding: const EdgeInsets.all(14), children: [
          OnlineStoreListingReadiness(
            state: listing.readinessState,
            issues: listing.readinessIssues,
          ),
          const SizedBox(height: 12),
          if (OnlineStorePermissions.canManageProducts) ...[
            _field(nameAr, 'اسم العرض بالعربية'),
            _field(nameEn, 'اسم العرض بالإنجليزية'),
            _field(descriptionAr, 'الوصف بالعربية', lines: 3),
            _field(descriptionEn, 'الوصف بالإنجليزية', lines: 3),
            _field(badgeAr, 'شارة العرض'),
            _field(sortOrder, 'الترتيب', numeric: true),
            SwitchListTile(
                value: isFeatured,
                onChanged: (v) => setState(() => isFeatured = v),
                title: const Text('مميز')),
            SwitchListTile(
                value: isNew,
                onChanged: (v) => setState(() => isNew = v),
                title: const Text('جديد')),
            SwitchListTile(
                value: showOnHome,
                onChanged: (v) => setState(() => showOnHome = v),
                title: const Text('إظهار في الرئيسية')),
            SwitchListTile(
                value: showAsOffer,
                onChanged: (v) => setState(() => showAsOffer = v),
                title: const Text('إظهار كعرض')),
          ],
          _ReadOnlyCard(
            title: 'السعر الأساسي (للقراءة فقط)',
            value: listing.basePrices.isEmpty
                ? 'غير متاح'
                : listing.basePrices.toString(),
            icon: Icons.payments_outlined,
          ),
          _ReadOnlyCard(
            title: 'المخزون والتوفر (للقراءة فقط)',
            value: listing.availability.isEmpty
                ? 'غير متاح'
                : listing.availability.toString(),
            icon: Icons.inventory_2_outlined,
          ),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.PRODUCTDETAILSSCREEN,
                arguments: listing.productId),
            icon: const Icon(Icons.open_in_new),
            label: const Text('فتح المنتج الأصلي في المخزون'),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                Get.toNamed(AppRoutes.ONLINESTOREMEDIA, arguments: listing.id),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('ترتيب وسائط المتجر'),
          ),
          if (OnlineStorePermissions.canManageProducts)
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final state in const [
                'draft',
                'ready',
                'published',
                'hidden'
              ])
                FilledButton.tonal(
                  onPressed: state == 'published' && !listing.canPublish
                      ? null
                      : () => _transition(state),
                  child: Text(_label(state)),
                ),
            ]),
        ]),
      );

  Widget _field(TextEditingController value, String label,
          {int lines = 1, bool numeric = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: value,
          maxLines: lines,
          keyboardType: numeric ? TextInputType.number : null,
          decoration: InputDecoration(labelText: label),
        ),
      );

  Future<void> _save() async {
    final updated = await controller.updateListing(listing, {
      'name_translations': {'ar': nameAr.text.trim(), 'en': nameEn.text.trim()},
      'description_translations': {
        'ar': descriptionAr.text.trim(),
        'en': descriptionEn.text.trim(),
      },
      'badge_translations': {'ar': badgeAr.text.trim()},
      'is_featured': isFeatured,
      'is_new': isNew,
      'show_on_home': showOnHome,
      'show_as_offer': showAsOffer,
      'sort_order': int.tryParse(sortOrder.text) ?? 0,
      if (listing.updatedAt != null) 'updated_at': listing.updatedAt,
    });
    if (updated != null && mounted) {
      setState(() => listing = updated);
    }
  }

  Future<void> _transition(String state) async {
    final updated = await controller.transition(listing, state);
    if (updated != null && mounted) {
      setState(() => listing = updated);
    }
  }

  String _label(String value) => const {
        'draft': 'إرجاع لمسودة',
        'ready': 'تحديد كجاهز',
        'published': 'نشر',
        'hidden': 'إخفاء',
      }[value]!;

  @override
  void dispose() {
    nameAr.dispose();
    nameEn.dispose();
    descriptionAr.dispose();
    descriptionEn.dispose();
    badgeAr.dispose();
    sortOrder.dispose();
    super.dispose();
  }
}

class _ReadOnlyCard extends StatelessWidget {
  const _ReadOnlyCard(
      {required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFFF2F2F5),
        child: ListTile(
          leading: Icon(icon),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(value),
        ),
      );
}
