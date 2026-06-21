import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.iconSize = 24.0,
  });

  final String imagePath;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: fit,
        placeholder: (context, url) => _FallbackImage(iconSize: iconSize),
        errorWidget: (context, url, error) => _FallbackImage(iconSize: iconSize),
      );
    }

    // Inline base64 data URI (e.g. images picked in demo mode where there is no
    // Supabase storage to upload to). Decode and render the bytes directly.
    if (imagePath.startsWith('data:')) {
      final bytes = _decodeDataUri(imagePath);
      if (bytes == null) return _FallbackImage(iconSize: iconSize);
      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _FallbackImage(iconSize: iconSize),
      );
    }

    return Image.asset(
      imagePath,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _FallbackImage(iconSize: iconSize),
    );
  }

  Uint8List? _decodeDataUri(String uri) {
    final commaIndex = uri.indexOf(',');
    if (commaIndex == -1) return null;
    final meta = uri.substring(0, commaIndex);
    final data = uri.substring(commaIndex + 1);
    try {
      if (meta.contains('base64')) {
        return base64Decode(data);
      }
      return Uint8List.fromList(utf8.encode(Uri.decodeFull(data)));
    } catch (_) {
      return null;
    }
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C4A3A),
            Color(0xFF267D65),
            Color(0xFF3EA47E),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.spa_outlined,
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
