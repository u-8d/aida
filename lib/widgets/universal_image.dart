import 'dart:io';
import 'package:flutter/material.dart';

class UniversalImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget? placeholder;

  const UniversalImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget(context, 'No image', null);
    }

    // Check if it's an asset path
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder ?? _buildErrorWidget,
      );
    }

    // Check if it's a local file path
    if (imageUrl.startsWith('/') || 
        imageUrl.startsWith('file://') || 
        (!imageUrl.startsWith('http') && !imageUrl.startsWith('https'))) {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: errorBuilder ?? _buildErrorWidget,
        );
      } else {
        return _buildErrorWidget(context, 'File not found', null);
      }
    }

    // Network image (http/https)
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: placeholder != null 
          ? (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return placeholder!;
            }
          : null,
      errorBuilder: errorBuilder ?? _buildErrorWidget,
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error, StackTrace? stackTrace) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.grey[400],
          ),
          if (width == null || width! > 100)
            const SizedBox(height: 8),
          if (width == null || width! > 100)
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
