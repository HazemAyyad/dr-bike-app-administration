import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/proof_media_type.dart';
import '../../../../../core/utils/app_colors.dart';

class ProofMediaTypeSelector extends StatelessWidget {
  const ProofMediaTypeSelector({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <_ProofOption>[
      const _ProofOption(ProofMediaType.none, Icons.block, 'proofMediaNone'),
      const _ProofOption(
          ProofMediaType.image, Icons.photo_camera_outlined, 'proofMediaImage'),
      const _ProofOption(
          ProofMediaType.video, Icons.videocam_outlined, 'proofMediaVideo'),
      const _ProofOption(
          ProofMediaType.both, Icons.perm_media_outlined, 'proofMediaEither'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'proofMediaType'.tr,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.operationalNavy,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: options.map((option) {
            final selected = value == option.value;
            return ChoiceChip(
              selected: selected,
              avatar: Icon(
                option.icon,
                size: 16.sp,
                color: selected ? Colors.white : AppColors.operationalPurple,
              ),
              label: Text(option.label.tr),
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.operationalNavy,
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
              ),
              selectedColor: AppColors.operationalPurple,
              backgroundColor: AppColors.operationalSurface,
              side: BorderSide(
                color: selected
                    ? AppColors.operationalPurple
                    : AppColors.operationalCardBorder,
              ),
              onSelected: (_) => onChanged(option.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ProofOption {
  const _ProofOption(this.value, this.icon, this.label);

  final String value;
  final IconData icon;
  final String label;
}
