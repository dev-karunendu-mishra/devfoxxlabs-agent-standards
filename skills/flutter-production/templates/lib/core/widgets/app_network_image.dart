import 'package:auto_skeleton/auto_skeleton.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// The only way to show a network image.
/// - Disk + memory cache via `cached_network_image`.
/// - RAM downscaling via [memCacheWidth] / [memCacheHeight] — size them to the
///   display (avatar 150, card 350, banner 400×300).
/// - Skeleton placeholder, themed fallback on null URL or load error.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth = 400,
    this.memCacheHeight = 300,
    this.borderRadius,
    this.fallbackAsset,
    this.errorIcon = Icons.image_not_supported_outlined,
    this.cacheKey,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;

  /// Bundled asset shown when there is no URL or it fails to load.
  final String? fallbackAsset;
  final IconData errorIcon;

  /// Stable key for URLs that change on every fetch (signed links).
  final String? cacheKey;

  /// Resolves protocol-relative (`//cdn…`) and root-relative (`/storage/…`)
  /// paths the server sends against the public site.
  static String? resolve(String? url) {
    final u = url?.trim();
    if (u == null || u.isEmpty) return null;
    if (u.startsWith('//')) return 'https:$u';
    if (u.startsWith('/')) return '${AppConfig.webBaseUrl}$u';
    return u;
  }

  /// Widget tests never hit the network.
  static bool get _isTesting =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = resolve(imageUrl);

    final Widget image = (url == null || _isTesting)
        ? _fallback(colorScheme)
        : CachedNetworkImage(
            imageUrl: url,
            cacheKey: cacheKey,
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            placeholder: (context, _) => AutoSkeleton(
              enabled: true,
              skeletonItem: Container(
                width: width ?? double.infinity,
                height: height ?? double.infinity,
                color: colorScheme.surfaceContainerHigh,
              ),
              child: const SizedBox.shrink(),
            ),
            errorWidget: (context, _, _) => _fallback(colorScheme),
          );

    final radius = borderRadius;
    return radius == null
        ? image
        : ClipRRect(borderRadius: radius, child: image);
  }

  Widget _fallback(ColorScheme colorScheme) {
    final asset = fallbackAsset;
    if (asset != null) {
      return Image.asset(
        asset,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: memCacheWidth,
        errorBuilder: (context, _, _) => _iconBox(colorScheme),
      );
    }
    return _iconBox(colorScheme);
  }

  Widget _iconBox(ColorScheme colorScheme) {
    final h = height;
    return Container(
      width: width,
      height: height,
      color: colorScheme.surfaceContainerLow,
      alignment: Alignment.center,
      child: Icon(
        errorIcon,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        size: (h != null && h < 40) ? 18 : 24,
      ),
    );
  }
}
