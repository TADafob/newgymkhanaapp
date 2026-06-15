import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class NoticeImageViewerScreen extends StatefulWidget {
  /// If you have multiple images, pass them here.
  final List<String>? imageUrls;

  /// If you have exactly one image, you can pass it here.
  final String? imageUrl;

  /// Which index to open first (only applies when imageUrls is non-null).
  final int initialIndex;

  NoticeImageViewerScreen({
    this.imageUrls,
    this.imageUrl,
    this.initialIndex = 0,
    super.key,
  }) : assert(
          (imageUrls != null && imageUrls.isNotEmpty) || imageUrl != null,
          'Either provide imageUrls (non-empty) or imageUrl',
        );

  @override
  _NoticeImageViewerScreenState createState() =>
      _NoticeImageViewerScreenState();
}

class _NoticeImageViewerScreenState extends State<NoticeImageViewerScreen> {
  late final PageController _pageController;
  late final List<String> _urls;
  int _current = 0;

  /// Tracks which URLs have finished decoding.
  final Map<String, bool> _decoded = {};

  @override
  void initState() {
    super.initState();

    // Normalize into a single list
    _urls = widget.imageUrl != null ? [widget.imageUrl!] : widget.imageUrls!;

    // Clamp initial index
    _current = widget.initialIndex.clamp(0, _urls.length - 1);

    _pageController = PageController(initialPage: _current);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Pre-resolve & listen for full decode on each URL
    for (final url in _urls) {
      final provider = CachedNetworkImageProvider(url);
      final stream = provider.resolve(const ImageConfiguration());
      stream.addListener(
        ImageStreamListener((_, __) {
          if (mounted) {
            setState(() => _decoded[url] = true);
          }
        }),
      );
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    if (sdkInt >= 33) {
      final img = await Permission.photos.request();
      final vid = await Permission.videos.request();
      return img.isGranted && vid.isGranted;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  Future<void> _saveImage() async {
    // 1️⃣ ask runtime permission
    final granted = await _requestStoragePermission();
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
      return;
    }

    // 2️⃣ existing PhotoManager permission & save logic
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied to save image')),
      );
      return;
    }

    try {
      final url = _urls[_current];
      final data = await NetworkAssetBundle(Uri.parse(url)).load("");
      final bytes = data.buffer.asUint8List();
      final result = await PhotoManager.editor.saveImage(
        bytes,
        title: "notice_image_$_current.jpg",
        filename: '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: result != null
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.5),
          content: Text(
            result != null ? 'Saved to gallery' : 'Failed to save image',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.withValues(alpha: 0.5),
          content: Text('Error saving image: $e',
              style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        elevation: 0,
        title: Text(
          // If single image, skip the count
          widget.imageUrl != null
              ? 'Photo'
              : 'Photo ${_current + 1}/${_urls.length}',
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _saveImage,
            icon: const Icon(Icons.file_download_rounded),
            tooltip: 'Save image',
            color: Colors.white,
          ),
        ],
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: _urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        builder: (ctx, idx) {
          final url = _urls[idx];
          // No loadingBuilder here; move it to PhotoViewGallery below
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(url),
            heroAttributes: PhotoViewHeroAttributes(tag: 'photo_$idx'),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            filterQuality: FilterQuality.high,
          );
        },
        loadingBuilder: (context, event) {
          final idx = _pageController.hasClients
              ? _pageController.page?.round() ?? 0
              : 0;
          final url = _urls[idx];
          final isReady = _decoded[url] == true;
          // Block render until fully decoded
          if (!isReady) {
            return const Center(child: CircularProgressIndicator());
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
