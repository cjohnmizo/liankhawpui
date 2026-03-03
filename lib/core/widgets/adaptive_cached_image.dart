import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/core/providers/app_preferences_provider.dart';

class AdaptiveCachedImage extends ConsumerWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget Function(BuildContext context)? placeholderBuilder;
  final Widget Function(BuildContext context)? errorBuilder;
  final int lowDataCacheWidth;
  final int lowDataCacheHeight;

  const AdaptiveCachedImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholderBuilder,
    this.errorBuilder,
    this.lowDataCacheWidth = 720,
    this.lowDataCacheHeight = 720,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowDataMode = ref.watch(lowDataModeEnabledProvider);

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      filterQuality: lowDataMode ? FilterQuality.low : FilterQuality.medium,
      fadeInDuration: lowDataMode
          ? Duration.zero
          : const Duration(milliseconds: 180),
      memCacheWidth: lowDataMode ? lowDataCacheWidth : null,
      memCacheHeight: lowDataMode ? lowDataCacheHeight : null,
      maxWidthDiskCache: lowDataMode ? lowDataCacheWidth : null,
      maxHeightDiskCache: lowDataMode ? lowDataCacheHeight : null,
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
