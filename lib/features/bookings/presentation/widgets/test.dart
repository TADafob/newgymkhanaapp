import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> images;         
  final String fallbackImageUrl;      
  final String facilityName;          

  const ImageCarousel({
    required this.images,
    required this.fallbackImageUrl,
    required this.facilityName,
    super.key,
  });

  @override
  _ImageCarouselState createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    print ('facility name: ${widget.facilityName}');
    // If no images, show fallback
    if (widget.images.isEmpty) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12.r),
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Image.network(
            widget.fallbackImageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                widget.facilityName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            CarouselSlider(
              items: widget.images.map((url) {
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                );
              }).toList(),
              options: CarouselOptions(
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                viewportFraction: 1.0,
                height: double.infinity,
                enableInfiniteScroll: widget.images.length > 1,
                onPageChanged: (index, reason) {
                  setState(() {
                    _current = index;
                  });
                },
              ),
            ),

            // facility name overlay
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                    widget.facilityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ),
            ),

            // dots indicator
            if (widget.images.length > 1)
              Positioned(
                bottom: 8,
                right: 8,
                child: Row(
                  children: List.generate(
                    widget.images.length,
                    (i) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      width: _current == i ? 10.r : 6.r,
                      height: _current == i ? 10.r : 6.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _current == i
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white60,
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
