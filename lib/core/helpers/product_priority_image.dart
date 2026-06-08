import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../utils/assets_manger.dart';
import 'product_image_utils.dart';
import 'show_net_image.dart';

/// Tries product images in priority order: view → normal → 3d → fallback.
/// If thumbnail/full URL fails to load, moves to the next candidate.
class ProductPriorityImage extends StatefulWidget {
  const ProductPriorityImage({
    Key? key,
    required this.imageUrls,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.useThumbnail = true,
    this.placeholder,
    this.missingPlaceholder,
  }) : super(key: key);

  final List<String> imageUrls;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool useThumbnail;
  final Widget? placeholder;
  final Widget? missingPlaceholder;

  @override
  State<ProductPriorityImage> createState() => _ProductPriorityImageState();
}

class _ProductPriorityImageState extends State<ProductPriorityImage> {
  int _candidateIndex = 0;
  bool _useOriginal = false;

  List<String> get _resolvedUrls {
    final urls = <String>[];
    for (final raw in widget.imageUrls) {
      if (!ProductImageUtils.isValidUrl(raw)) continue;
      final trimmed = raw.trim();
      if (!urls.contains(trimmed)) {
        urls.add(trimmed);
      }
    }
    return urls;
  }

  void _advance() {
    if (!mounted) return;

    if (!_useOriginal && widget.useThumbnail) {
      setState(() => _useOriginal = true);
      return;
    }

    if (_candidateIndex + 1 < _resolvedUrls.length) {
      setState(() {
        _candidateIndex += 1;
        _useOriginal = false;
      });
      return;
    }

    setState(() => _candidateIndex = _resolvedUrls.length);
  }

  @override
  Widget build(BuildContext context) {
    final urls = _resolvedUrls;
    if (urls.isEmpty || _candidateIndex >= urls.length) {
      return _wrap(widget.missingPlaceholder ?? _defaultMissing());
    }

    final raw = urls[_candidateIndex];
    final resolved = _useOriginal || !widget.useThumbnail
        ? ShowNetImage.getPhoto(raw)
        : ShowNetImage.getThumbnailPhoto(raw);

    if (resolved == AssetsManager.noImageNet) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _advance());
      return _wrap(widget.missingPlaceholder ?? _defaultMissing());
    }

    final placeholder = widget.placeholder ??
        SizedBox(
          width: widget.width,
          height: widget.height,
        );

    return _wrap(
      CachedNetworkImage(
        key: ValueKey('${raw}_${_candidateIndex}_$_useOriginal'),
        cacheManager: CacheManager(
          Config(
            'imagesCache',
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 100,
          ),
        ),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        imageUrl: resolved,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _advance());
          return placeholder;
        },
      ),
    );
  }

  Widget _wrap(Widget child) {
    if (widget.borderRadius == null) return child;
    return ClipRRect(
      borderRadius: widget.borderRadius!,
      child: child,
    );
  }

  Widget _defaultMissing() {
    return Image.asset(
      AssetsManager.stockImage,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.contain,
    );
  }
}
