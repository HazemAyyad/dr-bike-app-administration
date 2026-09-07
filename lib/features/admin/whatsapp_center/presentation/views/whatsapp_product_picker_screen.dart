import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_net_image.dart';
import '../../data/whatsapp_models.dart';
import '../controllers/whatsapp_conversation_controller.dart';

class WhatsAppProductPickerScreen extends StatefulWidget {
  const WhatsAppProductPickerScreen({Key? key}) : super(key: key);

  @override
  State<WhatsAppProductPickerScreen> createState() =>
      _WhatsAppProductPickerScreenState();
}

class _WhatsAppProductPickerScreenState
    extends State<WhatsAppProductPickerScreen> {
  final WhatsAppConversationController controller =
      Get.find<WhatsAppConversationController>();
  final TextEditingController search = TextEditingController();
  final Map<String, WhatsAppProduct> selected = <String, WhatsAppProduct>{};
  final Map<String, int> quantities = <String, int>{};
  List<WhatsAppProduct> products = const [];
  bool loading = true;
  Object? error;
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await controller.api.getProducts(search: search.text);
      final block = result['products'];
      final data = block is Map && block['data'] is List
          ? block['data'] as List
          : const [];
      products = data
          .whereType<Map>()
          .map((item) =>
              WhatsAppProduct.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      error = e;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('مشاركة منتجات'),
            actions: [
              if (selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(child: Text('${selected.length}/30')),
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: search,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onChanged: (_) {
                    debounce?.cancel();
                    debounce = Timer(const Duration(milliseconds: 450), _load);
                  },
                ),
              ),
              Expanded(child: _content()),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 9, 14, 11),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: controller.channel == 'whatsapp'
                              ? const Color(0x1A075E54)
                              : const Color(0x141877F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          controller.channel == 'whatsapp'
                              ? Icons.picture_as_pdf
                              : Icons.link,
                          color: controller.channel == 'instagram'
                              ? const Color(0xFFE1306C)
                              : controller.channel == 'facebook'
                                  ? const Color(0xFF1877F2)
                                  : const Color(0xFF075E54),
                        ),
                      ),
                      if (selected.isNotEmpty)
                        Positioned(
                          left: -5,
                          top: -5,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Text('${selected.length}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المنتجات المختارة (${selected.length})',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          controller.channel == 'whatsapp'
                              ? 'سيتم إرسال ملف PDF بالصور والتفاصيل'
                              : 'سيتم إرسال أسماء المنتجات وروابطها',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF667781)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: controller.channel == 'instagram'
                              ? const Color(0xFFE1306C)
                              : controller.channel == 'facebook'
                                  ? const Color(0xFF1877F2)
                                  : const Color(0xFF00A884),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(112, 48),
                        ),
                        onPressed: selected.isEmpty || controller.sending.value
                            ? null
                            : _sendPdf,
                        icon: controller.sending.value
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
                        label: const Text('إرسال'),
                      )),
                ],
              ),
            ),
          ),
        ),
      );

  Future<void> _sendPdf() async {
    Map<String, int>? confirmedQuantities;
    if (controller.channel == 'whatsapp') {
      confirmedQuantities = await _confirmQuantities();
      if (confirmedQuantities == null) return;
      quantities
        ..clear()
        ..addAll(confirmedQuantities);
    }
    final sent = await controller.sendSelectedProducts(
      selected.keys.toList(),
      quantities: controller.channel == 'whatsapp' ? quantities : null,
    );
    if (!sent || !mounted) return;
    Navigator.of(context).pop();
    Future<void>.delayed(Duration.zero, () {
      Get.snackbar(
        'تم',
        controller.channel == 'whatsapp'
            ? 'تم إرسال ملف المنتجات PDF في المحادثة'
            : 'تم إرسال روابط المنتجات في المحادثة',
      );
    });
  }

  Future<Map<String, int>?> _confirmQuantities() {
    final draft = <String, int>{
      for (final product in selected.values)
        product.id: quantities[product.id] ?? 1,
    };

    return showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Directionality(
          textDirection: TextDirection.rtl,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .78,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, color: Color(0xFF6B65BD)),
                      SizedBox(width: 8),
                      Text('تأكيد كميات عرض المنتجات',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: selected.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final product = selected.values.elementAt(index);
                      final quantity = draft[product.id] ?? 1;
                      final maxQuantity = product.stock > 999
                          ? 999
                          : product.stock > 0
                              ? product.stock
                              : 1;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        title: Text(product.name,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          'السعر: ${product.price ?? 0} ₪  •  المتوفر: ${product.stock}',
                        ),
                        trailing: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F1FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: quantity >= maxQuantity
                                    ? null
                                    : () => setSheetState(
                                        () => draft[product.id] = quantity + 1),
                                icon: const Icon(Icons.add, size: 19),
                              ),
                              Text('$quantity',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: quantity <= 1
                                    ? null
                                    : () => setSheetState(
                                        () => draft[product.id] = quantity - 1),
                                icon: const Icon(Icons.remove, size: 19),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7DF),
                    border: Border.all(color: const Color(0xFFEFC75E)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'ملاحظة: قد توجد أخطاء في الأسعار أو الكميات لأن العرض مُعد بمساعدة الذكاء الاصطناعي. يرجى مراجعته قبل الاعتماد.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF77550A)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6B65BD),
                      ),
                      onPressed: () => Navigator.of(sheetContext).pop(draft),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('إنشاء وإرسال PDF'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label:
              Text('تعذر تحميل المنتجات\n$error', textAlign: TextAlign.center),
        ),
      );
    }
    if (products.isEmpty) {
      return const Center(
        child: Text('لا توجد منتجات'),
      );
    }
    return LayoutBuilder(builder: (context, constraints) {
      const columns = 4;
      const horizontalGap = 6.0;
      const verticalGap = 6.0;
      const horizontalPadding = 10.0;
      final rows =
          ((constraints.maxHeight + verticalGap) / 112).floor().clamp(2, 4);
      final cellWidth = (constraints.maxWidth -
              horizontalPadding * 2 -
              horizontalGap * (columns - 1)) /
          columns;
      final cellHeight =
          (constraints.maxHeight - verticalGap * (rows - 1)) / rows;

      return GridView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: rows,
          mainAxisSpacing: horizontalGap,
          crossAxisSpacing: verticalGap,
          childAspectRatio: cellHeight / cellWidth,
        ),
        itemCount: products.length,
        itemBuilder: (_, index) => _productCard(products[index]),
      );
    });
  }

  Widget _productCard(WhatsAppProduct product) {
    final isSelected = selected.containsKey(product.id);
    final image = ShowNetImage.getThumbnailPhoto(product.image ?? '');
    return InkWell(
      onTap: () => setState(() {
        if (isSelected) {
          selected.remove(product.id);
          quantities.remove(product.id);
        } else if (selected.length < 30) {
          selected[product.id] = product;
          quantities[product.id] = 1;
        }
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF00A884) : const Color(0xFFD5E4E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(9)),
                    child: image.isEmpty
                        ? const ColoredBox(
                            color: Color(0xFFF0F4F3),
                            child: Icon(Icons.inventory_2_outlined),
                          )
                        : CachedNetworkImage(
                            imageUrl: image, fit: BoxFit.cover),
                  ),
                  if (isSelected)
                    const Positioned(
                      top: 4,
                      left: 4,
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: Color(0xFF00A884),
                        child: Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                    ),
                  Positioned(
                    bottom: 3,
                    right: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('المتوفر ${product.stock}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 8)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 76,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(product.name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 10)),
                        if (product.price != null)
                          Text('${product.price} ₪',
                              style: const TextStyle(
                                  color: Color(0xFF075E54),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        if (product.code?.isNotEmpty == true)
                          Text(product.code!,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Color(0xFF667781), fontSize: 8)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
