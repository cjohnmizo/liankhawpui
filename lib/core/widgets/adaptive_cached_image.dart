import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/core/providers/app_preferences_provider.dart';

class AdaptiveCachedImage extends ConsumerWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget Function(BuildContext context)? placeholderBuilder;
  final Widget Function(BuildContext context)? errorBuilder;
  final int? cacheWidth;
  final int? cacheHeight;
  final int lowDataCacheWidth;
  final int lowDataCacheHeight;

  const AdaptiveCachedImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholderBuilder,
    this.errorBuilder,
    this.cacheWidth,
    this.cacheHeight,
    this.lowDataCacheWidth = 720,
    this.lowDataCacheHeight = 720,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowDataMode = ref.watch(lowDataModeEnabledProvider);
    final effectiveCacheWidth =
        cacheWidth ?? (lowDataMode ? lowDataCacheWidth : null);
    final effectiveCacheHeight =
        cacheHeight ?? (lowDataMode ? lowDataCacheHeight : null);

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      filterQuality: lowDataMode ? FilterQuality.low : FilterQuality.medium,
      fadeInDuration: lowDataMode
          ? Duration.zero
          : const Duration(milliseconds: 180),
      memCacheWidth: effectiveCacheWidth,
      memCacheHeight: effectiveCacheHeight,
      maxWidthDiskCache: effectiveCacheWidth,
      maxHeightDiskCache: effectiveCacheHeight,
      placeholder: (_, __) {
        return placeholderBuilder?.call(context) ??
            const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorWidget: (_, __, ___) {
        return errorBuilder?.call(context) ??
            const Icon(Icons.broken_image_rounded);
      },
    );
  }
}
