import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../services/banks_service.dart';
import 'custom_text_field.dart';

class BankNameField extends StatefulWidget {
  const BankNameField({
    Key? key,
    required this.controller,
    required this.focusNode,
    this.onSubmitted,
    this.isRequired = true,
  }) : super(key: key);

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onSubmitted;
  final bool isRequired;

  @override
  State<BankNameField> createState() => _BankNameFieldState();
}

class _BankNameFieldState extends State<BankNameField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
    _ensureBanksLoaded();
  }

  Future<void> _ensureBanksLoaded() async {
    if (!Get.isRegistered<BanksService>()) {
      Get.put(BanksService());
    }
    final svc = Get.find<BanksService>();
    if (svc.banks.isEmpty) {
      await svc.loadBanks();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!widget.focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onTextChanged() {
    if (!Get.isRegistered<BanksService>()) return;
    final matches = Get.find<BanksService>().matchNames(widget.controller.text);
    if (matches.isEmpty) {
      _removeOverlay();
      return;
    }
    setState(() => _suggestions = matches.take(8).toList());
    _showOverlay();
  }

  void _showOverlay() {
    _removeOverlay();
    final fieldBox = context.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (fieldBox == null ||
        overlayBox == null ||
        !fieldBox.hasSize ||
        !overlayBox.hasSize) {
      return;
    }

    final fieldOffset =
        fieldBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final fieldSize = fieldBox.size;
    final overlaySize = overlayBox.size;
    final screenMargin = 12.w;
    final availableWidth = math.max(0.0, overlaySize.width - (screenMargin * 2));
    final menuWidth = math.min(fieldSize.width, availableWidth);
    final maxLeft =
        math.max(screenMargin, overlaySize.width - menuWidth - screenMargin);
    final left = fieldOffset.dx.clamp(screenMargin, maxLeft).toDouble();
    final top = fieldOffset.dy + fieldSize.height + 4.h;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: menuWidth,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8.r),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 240.h),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final name = _suggestions[index];
                    return ListTile(
                      dense: true,
                      title: Text(name),
                      onTap: () => _applySuggestion(name),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _applySuggestion(String fullName) {
    widget.controller.text = fullName;
    widget.controller.selection =
        TextSelection.collapsed(offset: fullName.length);
    _removeOverlay();
    widget.onSubmitted?.call();
  }

  void _handleSubmit(String _) {
    final q = widget.controller.text.trim();
    if (q.isNotEmpty && Get.isRegistered<BanksService>()) {
      final matches = Get.find<BanksService>().matchNames(q);
      if (matches.isNotEmpty) {
        widget.controller.text = matches.first;
      }
    }
    _removeOverlay();
    widget.onSubmitted?.call();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: CustomTextField(
        label: 'bankName',
        hintText: 'bankNameExample',
        controller: widget.controller,
        focusNode: widget.focusNode,
        textInputAction: TextInputAction.next,
        isRequired: widget.isRequired,
        onFieldSubmitted: _handleSubmit,
      ),
    );
  }
}
