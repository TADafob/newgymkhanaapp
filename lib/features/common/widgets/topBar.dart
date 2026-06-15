import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/appfonts.dart';
import 'package:nrbgymkhana/core/utils/constants.dart';
import 'package:nrbgymkhana/features/common/sharedpreff/localstorage.dart';
import 'package:cached_network_image/cached_network_image.dart';

final _userProfileProvider = FutureProvider((ref) async {
  final uid = await LocalStorage.getUserId();
  final snapshot = await FirebaseFirestore.instance
      .collection('users_members')
      .doc(uid)
      .get();
  return snapshot.exists ? snapshot.data() : null;
});

class TopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const TopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(_userProfileProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppKolors.primary, AppKolors.darkCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x440693e3),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Logo with subtle glow ring
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppKolors.accent.withOpacity(0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white10,
                  backgroundImage:
                      AssetImage('assets/images/common/logo2.png'),
                ),
              ),
              const SizedBox(width: 12),

              // App name centered
              Expanded(
                child: Center(
                  child: Text(
                    AppConstants.appName,
                    style: context.appbartitleHeadline.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 1.8,
                      shadows: [
                        const Shadow(
                          color: Color(0x6607d8c3),
                          blurRadius: 8,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Accent divider line
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppKolors.accent.withOpacity(0.7),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Avatar with accent border
              userProfile.when(
                data: (data) {
                  final url = data?['avatar_Url'] ?? '';
                  final imageProvider = url.isNotEmpty
                      ? CachedNetworkImageProvider(url)
                      : const CachedNetworkImageProvider(
                          'https://res.cloudinary.com/dbeofdu5x/image/upload/v1744020084/NAIROBI_GYMKHANA_LOGO_BANNER_kiaxwy.png');
                  return _AvatarRing(imageProvider: imageProvider);
                },
                loading: () => const _AvatarRing(
                    imageProvider: AssetImage('assets/images/common/logo2.png')),
                error: (_, __) => const _AvatarRing(
                    imageProvider: AssetImage('assets/images/common/logo2.png')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  final ImageProvider imageProvider;
  const _AvatarRing({required this.imageProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppKolors.accent, AppKolors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppKolors.accent.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppKolors.dark,
        backgroundImage: imageProvider,
      ),
    );
  }
}
