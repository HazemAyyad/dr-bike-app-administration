import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class RowText extends StatelessWidget {
  const RowText({Key? key, required this.title, style}) : super(key: key);

  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(
      title.tr,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12.sp,
          ),
    );
  }
}
