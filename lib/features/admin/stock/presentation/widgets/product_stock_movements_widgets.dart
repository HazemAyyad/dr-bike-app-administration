import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/product_stock_movement_model.dart';
import '../../domain/stock_movements_filters.dart';
import '../utils/open_instant_sale_invoice.dart';
import '../utils/open_product_purchase.dart';
import '../utils/open_purchase_invoice_from_stock.dart';
import '../utils/stock_movements_pdf_helper.dart';

import '../../../../../core/helpers/app_failure_notice.dart';

class StockMovementSummaryBar extends StatelessWidget {
  const StockMovementSummaryBar({Key? key, required this.summary})
      : super(key: key);

  final StockMovementSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AdminUiColors.subtleOverlay(context),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 12.h,
        alignment: WrapAlignment.center,
        children: [
          _summaryBox(context, 'stockPurchased'.tr, '${summary.purchased}',
              Colors.green.shade700),
          _summaryBox(
              context, 'stockSold'.tr, '${summary.sold}', AppColors.redColor),
          _summaryBox(context, 'stockSalesReturned'.tr,
              '${summary.salesReturned}', Colors.teal.shade700),
          _summaryBox(context, 'stockPurchaseReturned'.tr,
              '${summary.purchaseReturned}', Colors.orange.shade800),
          _summaryBox(context, 'stock'.tr, '${summary.currentStock}',
              Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }

  Widget _summaryBox(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 76.w) / 3,
      child: _SummaryChip(label: label, value: value, color: color),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
        ),
      ],
    );
  }
}

class StockMovementsToolbar extends StatelessWidget {
  const StockMovementsToolbar({
    Key? key,
    required this.filters,
    required this.total,
    required this.onFilter,
    required this.onPrint,
    required this.onQuickAdjust,
  }) : super(key: key);

  final StockMovementsFilters filters;
  final int total;
  final VoidCallback onFilter;
  final VoidCallback onPrint;
  final VoidCallback onQuickAdjust;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.tonalIcon(
            onPressed: onQuickAdjust,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: Text('stockAdjustment'.tr),
          ),
          OutlinedButton.icon(
            onPressed: onFilter,
            icon: Badge(
              isLabelVisible: filters.activeCount > 0,
              label: Text('${filters.activeCount}'),
              child: const Icon(Icons.filter_list, size: 18),
            ),
            label: Text('filters'.tr),
          ),
          OutlinedButton.icon(
            onPressed: onPrint,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text('stockMovementsPdf'.tr),
          ),
          Text(
            '$total ${'stockMovementsRecords'.tr}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class StockMovementsTable extends StatelessWidget {
  const StockMovementsTable({
    Key? key,
    required this.movements,
  }) : super(key: key);

  final List<ProductStockMovementModel> movements;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 72,
          columnSpacing: 14.w,
          horizontalMargin: 12.w,
          headingTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
          columns: [
            DataColumn(label: Text('stockMoveColType'.tr)),
            DataColumn(label: Text('stockMoveColVariant'.tr)),
            DataColumn(label: Text('quantity'.tr)),
            DataColumn(label: Text('stockMoveColBefore'.tr)),
            DataColumn(label: Text('stockMoveColAfter'.tr)),
            DataColumn(label: Text('stockMoveColCost'.tr)),
            DataColumn(label: Text('stockMoveColDocument'.tr)),
            DataColumn(label: Text('notes'.tr)),
            DataColumn(label: Text('date'.tr)),
            DataColumn(label: Text('stockMoveColUser'.tr)),
          ],
          rows: movements.map((m) => _buildRow(context, m, cs)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    ProductStockMovementModel m,
    ColorScheme cs,
  ) {
    final qty = m.quantity;
    final qtyColor = qty >= 0 ? Colors.green.shade700 : AppColors.redColor;
    final qtyText = qty == 0 ? '—' : (qty > 0 ? '+$qty' : '$qty');
    final variant = [
      if (m.size != null && m.size!.isNotEmpty) m.size,
      if (m.colorAr != null && m.colorAr!.isNotEmpty) m.colorAr,
    ].whereType<String>().join(' / ');

    return DataRow(
      cells: [
        DataCell(Text(m.movementTypeLabel())),
        DataCell(Text(variant.isEmpty ? '—' : variant)),
        DataCell(
          Text(
            qtyText,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: qtyColor,
            ),
          ),
        ),
        DataCell(Text('${m.stockBefore}')),
        DataCell(Text('${m.stockAfter}')),
        DataCell(Text(stockMovementCostText(m))),
        DataCell(_movementDocumentLink(context, m, cs)),
        DataCell(
          Text(
            m.note?.trim().isNotEmpty == true ? m.note! : '—',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(Text(m.createdAt ?? '—')),
        DataCell(Text(m.createdByName?.trim().isNotEmpty == true
            ? m.createdByName!
            : '—')),
      ],
    );
  }
}

class StockMovementListTile extends StatelessWidget {
  const StockMovementListTile({Key? key, required this.movement})
      : super(key: key);

  final ProductStockMovementModel movement;

  @override
  Widget build(BuildContext context) {
    final qty = movement.quantity;
    final qtyColor = qty >= 0 ? Colors.green.shade700 : AppColors.redColor;
    final qtyText = qty == 0 ? '—' : (qty > 0 ? '+$qty' : '$qty');
    final variant = [
      if (movement.size != null && movement.size!.isNotEmpty) movement.size,
      if (movement.colorAr != null && movement.colorAr!.isNotEmpty)
        movement.colorAr,
    ].whereType<String>().join(' / ');
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.movementTypeLabel(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (variant.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      variant,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                if (movement.document != null || movement.hasInvoiceLink)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: _movementDocumentLink(context, movement, cs),
                  ),
                if (stockMovementCostText(movement) != '—')
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      stockMovementCostText(movement),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                if (movement.note != null && movement.note!.trim().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      movement.note!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ),
                if (movement.createdAt != null)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      movement.createdAt!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            qtyText,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: qtyColor,
                ),
          ),
        ],
      ),
    );
  }
}

Widget _movementDocumentLink(
  BuildContext context,
  ProductStockMovementModel movement,
  ColorScheme colors,
) {
  final document = movement.document;
  final number = document?.number.trim().isNotEmpty == true
      ? document!.number
      : movement.displayInvoiceNumber;
  if (number.isEmpty) return const Text('—');
  return InkWell(
    onTap: () {
      if (movement.hasInvoiceLink) {
        openInstantSaleInvoiceFromStock(
          context: context,
          saleId: movement.referenceId!,
        );
        return;
      }
      if (document?.type == 'purchase' && canPurchaseProductFromStock) {
        openPurchaseInvoiceFromStock(
          context: context,
          billId: document!.id,
        );
        return;
      }
      if (document != null) {
        showStockMovementDocumentDetails(context, document);
      }
    },
    child: Text(
      document?.sourceNumber?.trim().isNotEmpty == true
          ? '$number\n${document!.sourceNumber}'
          : number,
      style: TextStyle(
        color: colors.primary,
        fontWeight: FontWeight.w800,
        decoration: TextDecoration.underline,
      ),
    ),
  );
}

Future<void> showStockMovementDocumentDetails(
  BuildContext context,
  StockMovementDocument document,
) {
  final rows = <MapEntry<String, String>>[
    MapEntry('stockMoveColDocument'.tr, document.number),
    if (document.sourceNumber?.trim().isNotEmpty == true)
      MapEntry('stockDocumentSource'.tr, document.sourceNumber!),
    if (document.partyName?.trim().isNotEmpty == true)
      MapEntry('stockDocumentParty'.tr, document.partyName!),
    if (document.status?.trim().isNotEmpty == true)
      MapEntry('stockDocumentStatus'.tr, document.status!),
    if (document.unitPrice != null)
      MapEntry('price'.tr, _stockMovementMoney(document.unitPrice!)),
    if (document.total != null)
      MapEntry('total'.tr, _stockMovementMoney(document.total!)),
    if (document.paid != null)
      MapEntry('stockDocumentPaid'.tr, _stockMovementMoney(document.paid!)),
    if (document.remaining != null)
      MapEntry('stockDocumentRemaining'.tr,
          _stockMovementMoney(document.remaining!)),
    if (document.boxName?.trim().isNotEmpty == true)
      MapEntry('stockDocumentBox'.tr, document.boxName!),
    if (document.reason?.trim().isNotEmpty == true)
      MapEntry('stockDocumentReason'.tr, document.reason!),
    if (document.note?.trim().isNotEmpty == true)
      MapEntry('notes'.tr, document.note!),
  ];
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'stockDocumentDetails'.tr,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 12.h),
            for (final row in rows)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110.w,
                      child: Text(
                        row.key,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(child: Text(row.value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

String stockMovementCostText(ProductStockMovementModel m) {
  if (m.unitCost == null && m.totalCost == null) return '—';
  final parts = <String>[];
  if (m.unitCost != null) {
    parts.add('${'stockMoveUnitCost'.tr}: ${_stockMovementMoney(m.unitCost!)}');
  }
  if (m.totalCost != null) {
    parts.add(
        '${'stockMoveTotalCost'.tr}: ${_stockMovementMoney(m.totalCost!)}');
  }
  return parts.join(' | ');
}

String _stockMovementMoney(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}

Future<void> exportStockMovementsPdf({
  required BuildContext context,
  required String productName,
  required StockMovementSummary summary,
  required List<ProductStockMovementModel> movements,
  StockMovementsFilters? filters,
}) async {
  if (movements.isEmpty) {
    Get.snackbar('info'.tr, 'noData'.tr);
    return;
  }

  try {
    Get.snackbar(
      'info'.tr,
      'reportExportPreparing'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
    final bytes = await StockMovementsPdfHelper.buildPdfBytes(
      productName: productName,
      summary: summary,
      movements: movements,
      filters: filters,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: StockMovementsPdfHelper.fileBaseName(productName),
    );
  } catch (e) {
    AppFailureNotice.show(
      title: 'error'.tr,
      message: '${'reportExportFailed'.tr}: $e',
    );
  }
}
