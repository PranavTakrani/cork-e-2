import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/image_filters.dart';
import '../utils/theme.dart';

class PolaroidWidget extends StatelessWidget {
  final String imageUrl;
  final String? caption;
  final String? filterType;
  final double width;
  final double height;
  final bool showPin;
  final VoidCallback? onRotate;

  const PolaroidWidget({
    super.key,
    required this.imageUrl,
    this.caption,
    this.filterType,
    this.width = 200,
    this.height = 250,
    this.showPin = true,
    this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height + 20, // give space for pin
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Polaroid frame
          Positioned(
            top: 20,
            left: 0,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Image area
                  Container(
                    width: width - 16,
                    height: height - 60,
                    margin: const EdgeInsets.all(8),
                    color: Colors.black,
                    child: ColorFiltered(
                      colorFilter: RetroFilters.getFilter(filterType) ??
                          const ColorFilter.mode(
                              Colors.transparent, BlendMode.multiply),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ),

                  // Caption area
                  Expanded(
                    child: Container(
                      width: width,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: Text(
                          caption ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontFamily: 'Kalam',
                                fontSize: 14,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pin above frame
          if (showPin)
            Positioned(
              top: 0,
              left: width / 2 - 15,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: RetroTheme.redPin,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 3,
                      offset: const Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ),

          // Rotation button - now at the same Stack level as the frame
          if (onRotate != null)
            Positioned(
              top: 25, // 20 (frame top) + 5 (offset from frame top)
              left: width - 15, // 15px overlap from right edge
              child: GestureDetector(
                onTap: onRotate,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.rotate_right,
                    size: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}