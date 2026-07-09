import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../maintenance/data/repositories/maintenance_implement.dart';
import '../../../maintenance/domain/usecases/get_maintenance_invoice_usecase.dart';
import '../../../maintenance/presentation/widgets/maintenance_invoice_sheet.dart';
import '../../data/models/instant_sales_model.dart';
import '../../data/models/invoice_model.dart';
import '../controllers/sales_controller.dart';
import '../utils/instant_sale_display.dart';
import '../utils/product_image_viewer.dart';
import '../utils/sales_amount_format.dart';
import 'instant_sale_audit_info.dart';
import 'instant_sale_payment_totals_footer.dart';

void showInstantSaleLinesModal(BuildContext context, InstantSalesModel sale) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _InstantSaleLinesSheet(sale: sale),
  );
}

class _InstantSaleLinesSheet extends StatefulWidget {
  final InstantSalesModel sale;

  const _InstantSaleLinesSheet({required this.sale});

  @override
  State<_InstantSaleLinesSheet> createState() => _InstantSaleLinesSheetState();
}

class _InstantSaleLinesSheetState extends State<_InstantSaleLinesSheet> {
  InvoiceModel? _invoice;
  var _loading = true;
  String? _error;
  var _usingSaleFallback = false;
  var _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    final token = ++_loadToken;
    setState(() {
      _loading = true;
      _error = null;
      _usingSaleFallback = false;
    });
    try {
      final controller = Get.find<SalesController>();
      final invoice = await controller.invoiceModelUsecase.call(
        invoiceId: widget.sale.id.toString(),
      );
      if (!mounted || token != _loadToken) return;
      setState(() {
        _invoice = invoice;
        _loading = false;
        _usingSaleFallback = false;
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      final message = e is ServerFailure
          ? e.errMessage
          : e is NoConnectionFailure
              ? e.errMessage
              : 'failed'.tr;
      final canFallback = widget.sale.lineItems.isNotEmpty;
      setState(() {
        _invoice = null;
        _loading = false;
        _error = message;
        _usingSaleFallback = canFallback;
      });
    }
  }

  Future<void> _openMaintenanceInvoice() async {
    final maintenanceId = _invoice?.maintenanceId;
    if (maintenanceId == null) return;

    AppDependencyRegistry.ensureMaintenance();
    final result = await GetMaintenanceInvoiceUsecase(
      maintenanceRepository: Get.find<MaintenanceImplement>(),
    ).call(maintenanceId: maintenanceId.toString());

    result.fold(
      (failure) => Get.snackbar(
        'error'.tr,
        failure.errMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      ),
      (invoice) => showMaintenanceInvoiceSheet(context, invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final sale = widget.sale;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.85.sh),
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.customGreyColor4 : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'instantSaleInvoice'.tr} ${sale.invoiceNumber}',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${sale.partnerTypeDisplay} · ${sale.partnerName}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_invoice?.maintenanceId != null)
                    IconButton(
                      tooltip: 'maintenanceInvoice'.tr,
                      onPressed: _openMaintenanceInvoice,
                      icon: const Icon(Icons.build_circle_outlined),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade300),
            InstantSaleAuditInfo(sale: sale),
            if (_loading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (_usingSaleFallback)
              Flexible(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          'instantSaleInvoicePartialLoad'.tr,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: _buildSaleFallbackList(sale)),
                  ],
                ),
              )
            else if (_error != null)
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _loadInvoice,
                      child: Text('tryAgain'.tr),
                    ),
                  ],
                ),
              )
            else if (_invoice != null)
              Flexible(child: _buildLinesList(_invoice!, sale))
            else
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Text('noData'.tr, textAlign: TextAlign.center),
              ),
            InstantSalePaymentTotalsFooter(
              total: _invoice != null
                  ? SalesAmountFormat.parse(_invoice!.totalCost)
                  : SalesAmountFormat.parse(sale.totalCost),
              paid: _invoice != null
                  ? SalesAmountFormat.parse(_invoice!.paidAmount)
                  : sale.paidAmountValue,
              remaining: _invoice != null
                  ? SalesAmountFormat.parse(_invoice!.remainingAmount)
                  : sale.remainingAmountValue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinesList(InvoiceModel invoice, InstantSalesModel sale) {
    final rows = <Widget>[];

    if (invoice.isPackageSale) {
      rows.add(_ModalPackageExpandable(invoice: invoice));
      var extras = invoice.additionalProductLines;
      if (extras.isEmpty && sale.additionalProductLines.isNotEmpty) {
        extras = sale.additionalProductLines
            .map(
              (s) => SubProductModel(
                id: s.id,
                productName: s.productName,
                productImage: 'no image',
                cost: s.cost,
                quantity: s.quantity,
                subtotal: ((double.tryParse(s.cost) ?? 0) *
                        (double.tryParse(s.quantity) ?? 0))
                    .toStringAsFixed(2),
                isPackageComponent: false,
                isAdditionalProduct: true,
                sizeLabel: s.sizeLabel,
                colorLabel: s.colorLabel,
                variantLabel: s.variantLabel,
              ),
            )
            .toList();
      }
      if (extras.isNotEmpty) {
        rows.add(SizedBox(height: 12.h));
        rows.add(
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(
              'instantSaleAdditionalProducts'.tr,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        );
        for (final sub in extras) {
          rows.add(Divider(height: 1, color: Colors.grey.shade200));
          rows.add(_LineRow(
            context: context,
            imageUrl: sub.productImage,
            name: sub.displayProductName,
            productNameOnly: sub.productName,
            sizeLabel: sub.sizeLabel,
            colorLabel: sub.colorLabel,
            quantity: sub.quantity,
            unitPrice: sub.cost,
          ));
        }
      }
    } else {
      rows.add(_LineRow(
        context: context,
        imageUrl: invoice.productImage,
        name: invoice.displayProductTitle,
        productNameOnly: invoice.displayProductNameOnly,
        sizeLabel: invoice.sizeLabel,
        colorLabel: invoice.colorLabel,
        quantity: invoice.quantity,
        unitPrice: invoice.cost,
      ));

      for (final sub in invoice.subProducts) {
        rows.add(Divider(height: 1, color: Colors.grey.shade200));
        rows.add(_LineRow(
          context: context,
          imageUrl: sub.productImage,
          name: sub.displayProductName,
          productNameOnly: sub.productName,
          sizeLabel: sub.sizeLabel,
          colorLabel: sub.colorLabel,
          quantity: sub.quantity,
          unitPrice: sub.cost,
        ));
      }
    }

    if (rows.isEmpty) {
      for (final line in sale.lineItems) {
        rows.add(_LineRow(
          context: context,
          imageUrl: '',
          name: line.name,
          productNameOnly: line.name,
          sizeLabel: line.sizeLabel,
          colorLabel: line.colorLabel,
          quantity: line.quantity,
          unitPrice: line.unitCost,
          badge: line.isPackageHeader
              ? 'instantSalePackageBadge'.tr
              : line.isAdditionalProduct
                  ? 'instantSaleAdditionalProducts'.tr
                  : null,
        ));
      }
    }

    if (invoice.additionalNotes.isNotEmpty) {
      rows.add(SizedBox(height: 12.h));
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: 6.h),
          child: Text(
            'additionalNotes'.tr,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      );
      for (final note in invoice.additionalNotes) {
        rows.add(
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    note.text.trim().isEmpty ? '-' : note.text,
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
                Text(
                  '${note.amount} ${'currency'.tr}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: rows,
    );
  }

  Widget _buildSaleFallbackList(InstantSalesModel sale) {
    final rows = <Widget>[];
    for (final line in sale.lineItems) {
      rows.add(_LineRow(
        context: context,
        imageUrl: '',
        name: line.name,
        productNameOnly: line.name,
        sizeLabel: line.sizeLabel,
        colorLabel: line.colorLabel,
        quantity: line.quantity,
        unitPrice: line.unitCost,
        badge: line.isPackageHeader
            ? 'instantSalePackageBadge'.tr
            : line.isAdditionalProduct
                ? 'instantSaleAdditionalProducts'.tr
                : null,
      ));
    }
    if (rows.isEmpty) {
      return Center(child: Text('noData'.tr));
    }
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: rows,
    );
  }
}

class _ModalPackageExpandable extends StatefulWidget {
  const _ModalPackageExpandable({required this.invoice});

  final InvoiceModel invoice;

  @override
  State<_ModalPackageExpandable> createState() =>
      _ModalPackageExpandableState();
}

class _ModalPackageExpandableState extends State<_ModalPackageExpandable> {
  bool _expanded = false;

  static const Color _accent = Color(0xFFE65100);
  static const Color _bg = Color(0xFFFFF3E0);

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final components = invoice.packageComponentLines;
    final qty = SalesAmountFormat.parse(invoice.quantity);
    final unit = SalesAmountFormat.parse(invoice.cost);
    final lineTotal = qty * unit;
    final url = ShowNetImage.getThumbnailPhoto(invoice.productImage);
    final hasImage = url.isNotEmpty && invoice.productImage.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: SizedBox(
                        width: 48.w,
                        height: 48.w,
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.card_giftcard_rounded,
                      color: _accent,
                      size: 40.sp,
                    ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'instantSalePackageBadge'.tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          invoice.displayProductTitle,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${'quantity'.tr}: ${SalesAmountFormat.display(qty)} · '
                          '${'price'.tr}: ${SalesAmountFormat.display(unit)} · '
                          '${'total'.tr}: ${SalesAmountFormat.display(lineTotal)}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (!_expanded && components.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              'packageContentsCount'.trParams({
                                'count': '${components.length}',
                              }),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: _accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _accent,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && components.isNotEmpty) ...[
            Divider(height: 1, color: Colors.orange.shade200),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
              child: Text(
                'packageContents'.tr,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                ),
              ),
            ),
            ...components.map(
              (sub) => Padding(
                padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 8.h),
                child: _LineRow(
                  context: context,
                  imageUrl: sub.productImage,
                  name: sub.displayProductName,
                  productNameOnly: sub.productName,
                  sizeLabel: sub.sizeLabel,
                  colorLabel: sub.colorLabel,
                  quantity: sub.quantity,
                  unitPrice: sub.cost,
                  indent: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final BuildContext context;
  final String imageUrl;
  final String name;
  final String? productNameOnly;
  final String? sizeLabel;
  final String? colorLabel;
  final String quantity;
  final String unitPrice;
  final String? badge;
  final bool indent;

  const _LineRow({
    required this.context,
    required this.imageUrl,
    required this.name,
    this.productNameOnly,
    this.sizeLabel,
    this.colorLabel,
    required this.quantity,
    required this.unitPrice,
    this.badge,
    this.indent = false,
  });

  @override
  Widget build(BuildContext context) {
    final qty = SalesAmountFormat.parse(quantity);
    final unit = SalesAmountFormat.parse(unitPrice);
    final showVariant = hasProductVariant(
      sizeLabel: sizeLabel,
      colorLabel: colorLabel,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: indent ? 12.w : 0,
        top: 10.h,
        bottom: 10.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductImageThumb(context: context, imageUrl: imageUrl),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ),
                Text(
                  productNameOnly?.trim().isNotEmpty == true
                      ? productNameOnly!.trim()
                      : name,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                if (showVariant) ...[
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: [
                      _VariantChip(
                        label: 'size'.tr,
                        value: variantDashOrValue(sizeLabel),
                      ),
                      _VariantChip(
                        label: 'color'.tr,
                        value: variantDashOrValue(colorLabel),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 6.h),
                Text(
                  '${'quantity'.tr}: ${SalesAmountFormat.display(qty)} · '
                  '${'price'.tr}: ${SalesAmountFormat.display(unit)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade700,
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

class _VariantChip extends StatelessWidget {
  const _VariantChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}

class _ProductImageThumb extends StatelessWidget {
  final BuildContext context;
  final String imageUrl;

  const _ProductImageThumb({
    required this.context,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = ShowNetImage.getThumbnailPhoto(imageUrl);
    final original = ShowNetImage.getPhoto(imageUrl);
    final hasImage = resolved.isNotEmpty &&
        imageUrl.trim().isNotEmpty &&
        imageUrl != 'no image';

    return GestureDetector(
      onTap: hasImage ? () => openProductImageViewer(context, imageUrl) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: 64.w,
          height: 64.w,
          color: Colors.grey.shade200,
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: resolved,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, __, ___) {
                        if (original != resolved && original.isNotEmpty) {
                          return CachedNetworkImage(
                            imageUrl: original,
                            fit: BoxFit.cover,
                          );
                        }
                        return Icon(
                          Icons.inventory_2_outlined,
                          size: 28.sp,
                          color: Colors.grey,
                        );
                      },
                    ),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.zoom_in,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : Icon(
                  Icons.inventory_2_outlined,
                  size: 28.sp,
                  color: Colors.grey,
                ),
        ),
      ),
    );
  }
}
