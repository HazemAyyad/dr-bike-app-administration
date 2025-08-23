import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildSubTaskImage(dynamic subTaskImage) {
  if (subTaskImage == null) return const SizedBox.shrink();

  // لو List
  if (subTaskImage is List && subTaskImage.isNotEmpty) {
    final firstImage = subTaskImage.first;

    if (firstImage.toString().contains('http')) {
      return CachedNetworkImage(
        imageUrl: firstImage,
        height: 50.h,
        width: 50.w,
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else {
      return Image.file(
        File(firstImage),
        height: 50.h,
        width: 50.w,
      );
    }
  }

  // لو String
  if (subTaskImage is String && subTaskImage.isNotEmpty) {
    if (subTaskImage.contains('http')) {
      return CachedNetworkImage(
        imageUrl: subTaskImage,
        height: 40.h,
        width: 40.w,
      );
    } else {
      return Image.file(
        File(subTaskImage),
        height: 40.h,
        width: 40.w,
      );
    }
  }

  // لو مفيش صور
  return const SizedBox.shrink();
}
