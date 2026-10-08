import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../core/helpers/show_net_image.dart';
import '../utils/online_store_admin_ui.dart';

bool isOnlineStoreSvgPath(String path) {
  final uri = Uri.tryParse(path.trim());
  final source = uri?.path ?? path;
  return source.toLowerCase().endsWith('.svg');
}

class OnlineStoreNetworkImage extends StatelessWidget {
  const OnlineStoreNetworkImage({
    Key? key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
  }) : super(key: key);

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final url = ShowNetImage.getPhoto(path);
    final fallback = errorWidget ??
        const ColoredBox(
          color: OnlineStoreAdminUi.surfaceMuted,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: OnlineStoreAdminUi.textSecondary,
            ),
          ),
        );
    if (isOnlineStoreSvgPath(path)) {
      return SvgPicture.network(
        url,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (_) => const ColoredBox(
          color: OnlineStoreAdminUi.surfaceMuted,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
