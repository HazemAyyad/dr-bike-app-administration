import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/helpers/show_net_image.dart';

class EmployeePointEvidencePreview extends StatelessWidget {
  const EmployeePointEvidencePreview({
    Key? key,
    required this.url,
    required this.mediaType,
    this.height = 100,
  }) : super(key: key);

  final String url;
  final String mediaType;
  final double height;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ShowNetImage.getPhoto(url);
    if (mediaType == 'video') {
      return InkWell(
        onTap: () => launchUrl(
          Uri.parse(resolvedUrl),
          mode: LaunchMode.externalApplication,
        ),
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          height: height.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill_rounded,
                  size: 42.sp, color: Colors.white),
              SizedBox(height: 4.h),
              Text(
                'فتح الفيديو',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Image.network(
        resolvedUrl,
        height: height.h,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : SizedBox(
                height: height.h,
                child: const Center(child: CircularProgressIndicator()),
              ),
      ),
    );
  }
}
