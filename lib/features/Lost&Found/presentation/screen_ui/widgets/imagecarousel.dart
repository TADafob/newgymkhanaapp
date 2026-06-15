import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  const ImageCarousel(this.imageUrls, {super.key});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.imageUrls.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 60),
              SizedBox(height: 8),
              Text("No image available"),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          items: widget.imageUrls.map((url) {
            return SizedBox(
              width: double.infinity,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.image_not_supported, size: 80)),
              ),
            );
          }).toList(),
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1.0,
            enableInfiniteScroll: widget.imageUrls.length > 1,
            autoPlay: widget.imageUrls.length > 1,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (i, _) => setState(() => _current = i),
          ),
        ),
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.imageUrls.asMap().entries.map((e) {
                return GestureDetector(
                  onTap: () => setState(() => _current = e.key),
                  child: Container(
                    width: _current == e.key ? 16.0 : 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color: theme.colorScheme.primary
                          .withValues(alpha: _current == e.key ? 0.9 : 0.4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
