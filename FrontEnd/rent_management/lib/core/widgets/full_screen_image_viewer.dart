import 'package:flutter/material.dart';

/// Single-image case, kept for call sites that only ever have one image.
void showFullScreenImage(BuildContext context, String imageUrl) {
  showFullScreenImageGallery(context, [imageUrl]);
}

/// Shared by property photos and payment proofs - any place that stores more
/// than one image now needs a way to page through all of them, not just view
/// one at a time. Pinch-to-zoom per image via InteractiveViewer, swipe
/// between images via PageView, dots indicate position when there's more than one.
void showFullScreenImageGallery(BuildContext context, List<String> imageUrls, {int initialIndex = 0}) {
  if (imageUrls.isEmpty) return;

  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (dialogContext) => _GalleryDialog(imageUrls: imageUrls, initialIndex: initialIndex),
  );
}

class _GalleryDialog extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  const _GalleryDialog({required this.imageUrls, required this.initialIndex});

  @override
  State<_GalleryDialog> createState() => _GalleryDialogState();
}

class _GalleryDialogState extends State<_GalleryDialog> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) => InteractiveViewer(
              child: Image.network(
                widget.imageUrls[index],
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Could not load image', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 12,
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
                      color: i == _currentIndex ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
