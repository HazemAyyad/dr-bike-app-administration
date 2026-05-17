import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../helpers/person_avatar_helper.dart';
import '../utils/app_colors.dart';

/// صورة زبون/تاجر — شبكة أو شعار دكتور بايك كبديل.
class PersonAvatarImage extends StatelessWidget {
  const PersonAvatarImage({
    Key? key,
    required this.imageUrl,
    required this.height,
    required this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.circular = false,
  }) : super(key: key);

  final String? imageUrl;
  final double height;
  final double width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool circular;

  String get _resolved =>
      PersonAvatarHelper.resolve(imageUrl ?? PersonAvatarHelper.placeholder);

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ??
        (circular
            ? BorderRadius.circular(width / 2)
            : BorderRadius.zero);

    Widget image;
    if (PersonAvatarHelper.isAssetPath(_resolved)) {
      image = Image.asset(
        _resolved,
        height: height,
        width: width,
        fit: fit,
        filterQuality: FilterQuality.medium,
      );
    } else {
      image = CachedNetworkImage(
        cacheManager: CacheManager(
          Config(
            'imagesCache',
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 100,
          ),
        ),
        height: height,
        width: width,
        fit: fit,
        imageUrl: _resolved,
        filterQuality: FilterQuality.medium,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => SizedBox(
          height: height,
          width: width,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Image.asset(
          PersonAvatarHelper.placeholder,
          height: height,
          width: width,
          fit: fit,
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: image,
    );
  }
}
