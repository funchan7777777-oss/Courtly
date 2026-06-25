import 'dart:io';

import 'package:flutter/cupertino.dart';

class CourtlyProfileImage extends StatelessWidget {
  const CourtlyProfileImage({
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.fallback,
    super.key,
  });

  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final path = imagePath?.trim();
    if (path == null || path.isEmpty) {
      return _fallback();
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }

    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() {
    final child = fallback ?? const CourtlyProfileImageFallback();
    if (width == null && height == null) {
      return child;
    }

    return SizedBox(width: width, height: height, child: child);
  }
}

class CourtlyProfileImageFallback extends StatelessWidget {
  const CourtlyProfileImageFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF56308A), Color(0xFF1A004D)],
        ),
      ),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            var iconSize = 36.0;
            if (constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
              final shortest = constraints.maxWidth < constraints.maxHeight
                  ? constraints.maxWidth
                  : constraints.maxHeight;
              iconSize = shortest * 0.48;
            }

            return Icon(
              CupertinoIcons.person_fill,
              color: CupertinoColors.white,
              size: iconSize,
            );
          },
        ),
      ),
    );
  }
}
