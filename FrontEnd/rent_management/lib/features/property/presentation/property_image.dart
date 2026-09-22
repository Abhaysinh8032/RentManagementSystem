import 'package:flutter/material.dart';

/// Shared by the list card and the detail screen. Neither was actually
/// rendering `property.imageUrl` before this fix - both always showed a
/// static icon regardless of whether an image existed, for every role. That
/// was never a login/permissions issue; the real image was just never wired
/// in. `errorBuilder` falls back to the same icon if a URL is broken/unreachable.
class PropertyImage extends StatelessWidget {
  final String? imageUrl;
  final double size; // width AND height, for the square list thumbnail
  final double? height; // used instead of size for a full-width banner
  final BorderRadius borderRadius;
  final double iconSize;

  const PropertyImage({
    super.key,
    required this.imageUrl,
    this.size = 64,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: height == null ? size : double.infinity,
        height: height ?? size,
        color: Colors.indigo.shade50,
        child: hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.chair_alt_rounded, color: Colors.indigo, size: iconSize),
              )
            : Icon(Icons.chair_alt_rounded, color: Colors.indigo, size: iconSize),
      ),
    );
  }
}
