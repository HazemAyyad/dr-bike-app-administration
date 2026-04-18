import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';

import '../utils/app_colors.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    Key? key,
    required this.label,
    required this.hintText,
    this.controller,
    this.suffixIcon,
    this.enabled = true,
    this.fillColor,
    this.labelColor,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.hintColor,
    this.obscureText = false,
    this.isRequired = false,
    this.suffix,
    this.labelTextstyle,
    this.suffixIconColor,
    this.border,
    this.decoration,
    this.hintStyle,
    this.minLines,
    this.maxLines,
    this.sizedBox,
    this.onChanged,
  }) : super(key: key);

  final String label;
  final String hintText;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final bool enabled;
  final Color? fillColor;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Color? labelColor;
  final String? Function(String?)? validator;
  final Color? hintColor;
  final bool obscureText;
  final bool isRequired;
  final Widget? suffix;
  final TextStyle? labelTextstyle;
  final Color? suffixIconColor;
  final InputBorder? border;
  final Decoration? decoration;
  final TextStyle? hintStyle;
  final int? minLines;
  final int? maxLines;
  final bool? sizedBox;
  final Function(String)? onChanged;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with WidgetsBindingObserver {
  late FocusNode _focusNode;
  bool _wasFocused = false;
  bool _shouldKeepKeyboard = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addObserver(this);

    _focusNode.addListener(() {
      _shouldKeepKeyboard = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _wasFocused = _focusNode.hasFocus;
    } else if (state == AppLifecycleState.resumed) {
      if (_wasFocused || _shouldKeepKeyboard) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _focusNode.canRequestFocus) {
            _focusNode.requestFocus();
            SystemChannels.textInput.invokeMethod('TextInput.show');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelGap = math.max(8.0, 10.h);

    final Color defaultLabelColor = widget.labelColor ??
        (isDark
            ? scheme.onSurface
            : AppColors.customGreyColor);

    final Color defaultFillColor = widget.fillColor ??
        (Theme.of(context).inputDecorationTheme.fillColor ??
            Theme.of(context).colorScheme.surface);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.label == ''
            ? const SizedBox.shrink()
            : Text.rich(
                TextSpan(
                  text: widget.label.tr,
                  style: widget.labelTextstyle ??
                      Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: defaultLabelColor,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                          ),
                  children: widget.isRequired
                      ? [
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ]
                      : [],
                ),
              ),
        widget.sizedBox == false || widget.label == ''
            ? const SizedBox.shrink()
            : SizedBox(height: labelGap),
        Container(
          decoration: widget.decoration,
          child: TextFormField(
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            minLines: widget.minLines ?? 1,
            maxLines: widget.maxLines ?? 1,
            obscureText: widget.obscureText,
            controller: widget.controller,
            enabled: widget.enabled,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 15.sp,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
            onTap: () {
              _shouldKeepKeyboard = true;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: defaultFillColor,
              hintText: widget.hintText.tr,
              hintStyle: widget.hintStyle ??
                  TextStyle(
                    color: widget.hintColor ?? Theme.of(context).hintColor,
                  ),
              suffix: widget.suffix,
              suffixIcon: widget.suffixIcon,
              suffixIconColor: widget.suffixIconColor,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 13.h, horizontal: 10.w),
              border: widget.border ??
                  OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11.r),
                    gapPadding: 1.w,
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
              enabledBorder: widget.border ??
                  OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11.r),
                    gapPadding: 1.w,
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11.r),
                borderSide:
                    const BorderSide(color: Colors.transparent, width: 0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11.r),
                gapPadding: 1.w,
                borderSide: const BorderSide(
                  color: AppColors.secondaryColor,
                  width: 2,
                ),
              ),
            ),
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction ?? TextInputAction.next,
            validator: widget.validator ??
                (value) {
                  if (value == null || value.isEmpty) {
                    return widget.label.tr;
                  }
                  return null;
                },
          ),
        ),
      ],
    );
  }
}
