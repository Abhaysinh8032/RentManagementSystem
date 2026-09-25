import 'package:flutter/material.dart';

import '../../../core/widgets/full_screen_image_viewer.dart';

/// Detail-screen banner - replaces the single static PropertyImage there.
/// Swipeable when there's more than one image, with dot indicators and a
/// tap-to-zoom into the full gallery viewer. Falls back to a single
/// placeholder icon when there are no images at all.
class PropertyImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final BorderRadius borderRadius;

  const PropertyImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 200,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<PropertyImageGallery> createState() => _PropertyImageGalleryState();
}

class _PropertyImageGalleryState extends State<PropertyImageGallery> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: Container(
          height: widget.height,
          color: Colors.indigo.shade50,
          child: const Center(child: Icon(Icons.chair_alt_rounded, size: 72, color: Colors.indigo)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => showFullScreenImageGallery(context, widget.imageUrls, initialIndex: index),
                child: Container(
                  color: Colors.indigo.shade50,
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.chair_alt_rounded, size: 72, color: Colors.indigo)),
                  ),
                ),
              ),
            ),
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.imageUrls.length,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _currentIndex ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
