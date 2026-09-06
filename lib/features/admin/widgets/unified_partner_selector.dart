import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/utils/app_colors.dart';

typedef PartnerSelected<T> = FutureOr<void> Function(
  T partner,
  bool isSeller,
);

/// The shared customer/supplier picker for admin workflows.
class UnifiedPartnerSelector<T> extends StatefulWidget {
  const UnifiedPartnerSelector({
    required this.customers,
    required this.sellers,
    required this.selected,
    required this.selectedIsSeller,
    required this.idOf,
    required this.nameOf,
    required this.phoneOf,
    required this.onSelected,
    required this.onCleared,
    this.onAddRequested,
    this.title = 'الزبون أو المورد',
    this.hintText = 'ابحث بالاسم أو رقم الهاتف',
    this.requiredSelection = false,
    this.enabled = true,
    this.compact = false,
    this.showTitle = true,
    this.maxInitialResults = 8,
    this.maxSearchResults = 15,
    Key? key,
  }) : super(key: key);

  final List<T> customers;
  final List<T> sellers;
  final T? selected;
  final bool selectedIsSeller;
  final int Function(T value) idOf;
  final String Function(T value) nameOf;
  final String Function(T value) phoneOf;
  final PartnerSelected<T> onSelected;
  final FutureOr<void> Function()? onCleared;
  final FutureOr<void> Function(bool isSeller)? onAddRequested;
  final String title;
  final String hintText;
  final bool requiredSelection;
  final bool enabled;
  final bool compact;
  final bool showTitle;
  final int maxInitialResults;
  final int maxSearchResults;

  @override
  State<UnifiedPartnerSelector<T>> createState() =>
      _UnifiedPartnerSelectorState<T>();
}

class _UnifiedPartnerSelectorState<T> extends State<UnifiedPartnerSelector<T>> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _syncSelectedText();
    _focusNode.addListener(() {
      if (!mounted) return;
      if (_focusNode.hasFocus) {
        setState(() => _showResults = true);
        return;
      }
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showResults = false);
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant UnifiedPartnerSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) _syncSelectedText();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncSelectedText() {
    final selected = widget.selected;
    final text = selected == null ? '' : widget.nameOf(selected);
    if (_searchController.text != text) {
      _searchController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  List<_PartnerEntry<T>> _results() {
    final rows = <_PartnerEntry<T>>[
      ...widget.customers.map((item) => _PartnerEntry(item, false)),
      ...widget.sellers.map((item) => _PartnerEntry(item, true)),
    ];
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return rows.take(widget.maxInitialResults).toList();
    return rows
        .where((entry) =>
            '${widget.nameOf(entry.value)} ${widget.phoneOf(entry.value)}'
                .toLowerCase()
                .contains(query))
        .take(widget.maxSearchResults)
        .toList();
  }

  Future<void> _select(_PartnerEntry<T> entry) async {
    await widget.onSelected(entry.value, entry.isSeller);
    if (!mounted) return;
    _searchController.text = widget.nameOf(entry.value);
    _focusNode.unfocus();
    setState(() => _showResults = false);
  }

  Future<void> _clear({bool keepFocus = false}) async {
    await widget.onCleared?.call();
    if (!mounted) return;
    _searchController.clear();
    if (keepFocus) _focusNode.requestFocus();
    setState(() => _showResults = keepFocus);
  }

  Future<void> _showAddMenu() async {
    final callback = widget.onAddRequested;
    if (callback == null) return;
    final isSeller = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('إضافة زبون'),
              onTap: () => Navigator.pop(context, false),
            ),
            ListTile(
              leading: const Icon(Icons.add_business_outlined),
              title: const Text('إضافة مورد / تاجر'),
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
    if (isSeller == null) return;
    await callback(isSeller);
    if (!mounted) return;
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final rows = _results();
    final padding = widget.compact ? 10.r : 12.r;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle)
          Row(
            children: [
              Icon(Icons.people_alt_outlined,
                  size: 19.sp, color: AppColors.primaryColor),
              SizedBox(width: 6.w),
              Text(widget.title,
                  style:
                      TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
              if (widget.requiredSelection)
                Text(' *',
                    style: TextStyle(color: Colors.red, fontSize: 13.sp)),
              const Spacer(),
              if (selected != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    widget.selectedIsSeller ? 'مورد / تاجر' : 'زبون',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        if (widget.showTitle) SizedBox(height: 8.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _searchController,
                focusNode: _focusNode,
                enabled: widget.enabled,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.customGreyColor7,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: selected == null
                      ? null
                      : IconButton(
                          tooltip: 'إلغاء الاختيار',
                          onPressed: () => _clear(keepFocus: true),
                          icon: const Icon(Icons.close_rounded),
                        ),
                  hintText: widget.hintText,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: 12.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11.r),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (_) => widget.requiredSelection && selected == null
                    ? 'اختر زبونًا أو موردًا'
                    : null,
                onChanged: (_) {
                  if (selected != null) widget.onCleared?.call();
                  setState(() => _showResults = true);
                },
                onTapOutside: (_) => _focusNode.unfocus(),
              ),
            ),
            if (widget.onAddRequested != null) ...[
              SizedBox(width: 6.w),
              IconButton(
                tooltip: 'إضافة زبون أو مورد',
                onPressed: widget.enabled ? _showAddMenu : null,
                icon: Icon(
                  Icons.add_circle_sharp,
                  color: widget.enabled
                      ? AppColors.primaryColor
                      : Colors.grey.shade400,
                  size: 30.sp,
                ),
              ),
            ],
          ],
        ),
        if (_showResults && widget.enabled)
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: 220.h),
            margin: EdgeInsets.only(top: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.operationalCardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: rows.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(14.r),
                    child: const Text('لا توجد نتائج'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final entry = rows[index];
                      final phone = widget.phoneOf(entry.value).trim();
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          entry.isSeller
                              ? Icons.storefront_outlined
                              : Icons.person_outline_rounded,
                          color: AppColors.primaryColor,
                        ),
                        title: Text(
                          widget.nameOf(entry.value),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text([
                          entry.isSeller ? 'مورد / تاجر' : 'زبون',
                          if (phone.isNotEmpty) phone,
                        ].join(' • ')),
                        onTap: () => _select(entry),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}

class _PartnerEntry<T> {
  const _PartnerEntry(this.value, this.isSeller);

  final T value;
  final bool isSeller;
}
