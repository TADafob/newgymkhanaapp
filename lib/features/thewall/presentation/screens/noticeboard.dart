import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/widgets/shimmer_widgets.dart';
import 'package:nrbgymkhana/features/thewall/presentation/providers/noticesprovider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:nrbgymkhana/features/thewall/presentation/screens/notice_image_viewer.dart';

class NoticeListScreen extends ConsumerWidget {
  const NoticeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final currentKey = '${_monthName(now.month)} ${now.year}';
    final noticesAsync = ref.watch(noticeListProvider);
    final month = ref.watch(selectedMonthProvider);
    final year = ref.watch(selectedYearProvider);

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF0F4F8);

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(noticeListProvider),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120.h,
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF121212) : bgColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                title: Text(
                  'Club Notices',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 20.sp,
                  ),
                ),
                background: Container(
                    color: isDark ? const Color(0xFF121212) : bgColor),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _FilterButton(
                        label: month != null ? _monthName(month) : 'Month',
                        icon: Icons.calendar_month,
                        onTap: () => _showMonthPicker(context, ref),
                        isActive: month != null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterButton(
                        label: year?.toString() ?? 'Year',
                        icon: Icons.history,
                        onTap: () => _showYearPicker(context, ref),
                        isActive: year != null,
                      ),
                    ),
                    if (month != null || year != null) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          ref.read(selectedMonthProvider.notifier).state = null;
                          ref.read(selectedYearProvider.notifier).state = null;
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.red, size: 20),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            noticesAsync.when(
              loading: () =>
                  const SliverToBoxAdapter(child: PageShimmer(itemCount: 5)),
              error: (e, st) => SliverToBoxAdapter(
                child: Center(
                    child: Text('Error: $e',
                        style: const TextStyle(color: Colors.red))),
              ),
              data: (notices) {
                if (notices.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.newspaper,
                              size: 64.sp, color: Colors.grey.withOpacity(0.5)),
                          SizedBox(height: 16.h),
                          const Text('No notices available',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                final grouped = groupByMonth(notices);
                final sortedKeys = grouped.keys.toList()
                  ..sort((a, b) {
                    DateTime parseKey(String k) {
                      final parts = k.split(' ');
                      final m = _monthIndex(parts[0]);
                      final y = int.parse(parts[1]);
                      return DateTime(y, m);
                    }

                    return parseKey(b).compareTo(parseKey(a));
                  });

                final flatList = <Widget>[];
                for (var key in sortedKeys) {
                  flatList.add(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4.w,
                            height: 18.h,
                            decoration: BoxDecoration(
                              color: AppKolors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            key == currentKey ? '$key (Recent)' : key,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.black54,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  for (var notice in grouped[key]!) {
                    flatList.add(Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: NoticeCard(notice: notice),
                    ));
                  }
                }
                flatList.add(SizedBox(height: 80.h));

                return SliverList(delegate: SliverChildListDelegate(flatList));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ListView.builder(
        shrinkWrap: true,
        itemCount: 12,
        itemBuilder: (c, i) => ListTile(
          title: Text(_monthName(i + 1)),
          onTap: () {
            ref.read(selectedMonthProvider.notifier).state = i + 1;
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  void _showYearPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ListView.builder(
        shrinkWrap: true,
        itemCount: 5,
        itemBuilder: (c, i) {
          final y = DateTime.now().year - i;
          return ListTile(
            title: Text(y.toString()),
            onTap: () {
              ref.read(selectedYearProvider.notifier).state = y;
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _FilterButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive
              ? AppKolors.primary
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (!isActive)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18.sp,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54)),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoticeCard extends StatelessWidget {
  final Notice notice;
  const NoticeCard({required this.notice, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              NoticeDetailScreen(notice: notice, currentUserId: currentUserId),
        ),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notice.title,
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              if ((notice.imageUrls ?? []).isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 80.h,
                    width: double.infinity,
                    child: CarouselSlider.builder(
                      itemCount: notice.imageUrls!.length,
                      itemBuilder: (_, idx, __) => Image.network(
                        notice.imageUrls![idx],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                      options: CarouselOptions(
                        viewportFraction: 1.0,
                        enableInfiniteScroll: false,
                        scrollPhysics: const BouncingScrollPhysics(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                notice.details,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.person, size: 16.sp, color: AppKolors.textPrimary),
                SizedBox(width: 16.w),
                Text(notice.author,
                    style: TextStyle(color: AppKolors.textPrimary)),
                SizedBox(width: 16.w),
              ]),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.w,
                children: notice.tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _tagColor(tag).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(tag,
                              style: TextStyle(
                                  color: _tagColor(tag), fontSize: 12.sp)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${notice.date.day.toString().padLeft(2, '0')} ${_monthName(notice.date.month)}, ${notice.date.year}',
                    style: TextStyle(color: AppKolors.textPrimary),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 16.sp, color: AppKolors.textPrimary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoticeDetailScreen extends ConsumerWidget {
  final Notice notice;
  final String currentUserId;
  const NoticeDetailScreen(
      {required this.notice, required this.currentUserId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metaAsync = ref.watch(noticeMetaProvider(notice.id));
    final userAsync = ref.watch(userReactionProvider(notice.id));
    final reactsAsync = ref.watch(noticeReactionsProvider(notice.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final hasImages = (notice.imageUrls ?? []).isNotEmpty;

    return Scaffold(
      backgroundColor: bgColor,
      body: metaAsync.when(
        loading: () => const PageShimmer(itemCount: 3),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (meta) {
          final likeCount = meta['likeCount']!;
          final dislikeCount = meta['dislikeCount']!;
          final userReact =
              userAsync.maybeWhen(data: (v) => v, orElse: () => null);
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: hasImages ? 300.h : null,
                pinned: true,
                backgroundColor: bgColor,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasImages
                        ? Colors.black.withOpacity(0.3)
                        : (isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05)),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: hasImages
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: hasImages
                    ? FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(notice.imageUrls!.first,
                                fit: BoxFit.cover),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.3),
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7)
                                  ],
                                  stops: const [0.0, 0.4, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notice.title,
                          style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${notice.date.day} ${_monthName(notice.date.month)}, ${notice.date.year}',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark ? Colors.white54 : Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        if (notice.tags.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: notice.tags
                                .map((tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                          color:
                                              _tagColor(tag).withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(tag,
                                          style: TextStyle(
                                              color: _tagColor(tag),
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600)),
                                    ))
                                .toList(),
                          ),
                        if (notice.tags.isNotEmpty) const SizedBox(height: 24),
                        Text(
                          notice.details,
                          style: TextStyle(
                              fontSize: 16.sp,
                              height: 1.6,
                              color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        const SizedBox(height: 24),
                        if (hasImages) ...[
                          SizedBox(
                            height: 100.h,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: notice.imageUrls!.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) => GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NoticeImageViewerScreen(
                                      imageUrls: notice.imageUrls!,
                                      initialIndex: index,
                                    ),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(notice.imageUrls![index],
                                      width: 100.w,
                                      height: 100.h,
                                      fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Divider(
                            color:
                                isDark ? Colors.white12 : Colors.grey.shade200),
                        const SizedBox(height: 16),
                        Text('What do you think?',
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ModernReactionButton(
                              icon: Icons.thumb_up_rounded,
                              count: likeCount,
                              isActive: userReact == 'like',
                              activeColor: Colors.blue,
                              onTap: () => ref
                                  .read(reactionServiceProvider)
                                  .toggleReaction(
                                      notice.id, currentUserId, 'like'),
                            ),
                            const SizedBox(width: 16),
                            ModernReactionButton(
                              icon: Icons.thumb_down_rounded,
                              count: dislikeCount,
                              isActive: userReact == 'dislike',
                              activeColor: Colors.red,
                              onTap: () => ref
                                  .read(reactionServiceProvider)
                                  .toggleReaction(
                                      notice.id, currentUserId, 'dislike'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: reactsAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            ),
                            error: (e, _) =>
                                Text('Couldn’t load reactions: $e'),
                            data: (map) => RecentReactions(reactions: map),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ModernReactionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const ModernReactionButton({
    required this.icon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
              color: isActive ? activeColor : Colors.grey.shade300, width: 1.5),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: activeColor.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isActive ? activeColor : Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$count',
              style: TextStyle(
                  color: isActive ? activeColor : Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class RecentReactions extends StatelessWidget {
  final Map<String, String> reactions;
  const RecentReactions({required this.reactions, super.key});

  @override
  Widget build(BuildContext context) {
    final reactors = reactions.keys.toList();
    const maxVisible = 4;
    const avatarSize = 36.0;
    const overlapOffset = 20.0;

    if (reactors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('No reactions yet', style: TextStyle(color: Colors.grey)),
      );
    }

    final lastIndex =
        reactors.length < maxVisible ? reactors.length - 1 : maxVisible - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Reactions',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          SizedBox(height: 12.h),
          SizedBox(
            height: avatarSize.h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < reactors.length && i < maxVisible; i++)
                  Positioned(
                    left: i * overlapOffset.w,
                    child: _UserAvatar(
                      uid: reactors[i],
                      reactionType: reactions[reactors[i]]!,
                      showBadge: i == lastIndex,
                      size: avatarSize.toInt(),
                    ),
                  ),
                if (reactors.length > maxVisible)
                  Positioned(
                    left: maxVisible * overlapOffset.w,
                    child: _buildMoreAvatar(reactors.length - maxVisible),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreAvatar(int remaining) {
    return Container(
      width: 36.w,
      height: 36.h,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade300,
          border: Border.all(color: Colors.grey.shade400)),
      child: Center(
          child: Text('+$remaining',
              style: const TextStyle(fontSize: 12, color: Colors.black54))),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String uid;
  final String reactionType;
  final bool showBadge;
  final int size;
  const _UserAvatar(
      {required this.uid,
      required this.reactionType,
      required this.showBadge,
      required this.size});

  @override
  Widget build(BuildContext context) {
    final isLike = reactionType == 'like';
    final borderColor =
        isLike ? Colors.blue.withOpacity(0.6) : Colors.red.withOpacity(0.6);

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users_members')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get(),
      builder: (context, snap) {
        String? avatarUrl;
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          avatarUrl = snap.data!.docs.first.get('avatar_Url') as String?;
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size.toDouble().w,
              height: size.toDouble().h,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2)),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(uid[0].toUpperCase(),
                        style: const TextStyle(color: Colors.grey))
                    : null,
              ),
            ),
            if (showBadge)
              Positioned(
                bottom: -2.h,
                right: -2.w,
                child: Container(
                  width: 16.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLike ? Colors.blue : Colors.red,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: Icon(
                      isLike ? Icons.thumb_up_alt : Icons.thumb_down_alt,
                      size: 10.sp,
                      color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }
}

Color _tagColor(String tag) {
  switch (tag.toLowerCase()) {
    case 'important':
      return Colors.red;
    case 'gym':
      return Colors.purple;
    case 'payments':
      return Colors.orange;
    case 'events':
      return Colors.blue;
    case 'updates':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

String _monthName(int month) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  return names[month - 1];
}

int _monthIndex(String name) {
  const names = {
    'January': 1,
    'February': 2,
    'March': 3,
    'April': 4,
    'May': 5,
    'June': 6,
    'July': 7,
    'August': 8,
    'September': 9,
    'October': 10,
    'November': 11,
    'December': 12,
  };
  return names[name] ?? 1;
}
