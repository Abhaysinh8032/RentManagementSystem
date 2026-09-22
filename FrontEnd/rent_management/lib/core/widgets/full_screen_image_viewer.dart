import 'package:flutter/material.dart';

/// Shared by the bill card (payment proofs) and could be reused anywhere else
/// a stored image needs a closer look. Pinch-to-zoom via InteractiveViewer.
void showFullScreenImage(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          InteractiveViewer(
            child: Image.network(
              imageUrl,
              errorBuilder: (context, error, stackTrace) => const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Could not load image', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        ],
      ),
    ),
  );
}
