import 'package:flutter/material.dart';
import 'package:nrbgymkhana/core/utils/appfonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/common/widgets/nodatawidget.dart';
import 'package:nrbgymkhana/features/home/presentation/providers/homeproviders.dart';

class NewsCenterPart extends ConsumerWidget {
  const NewsCenterPart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsyncValue = ref.watch(newsStreamProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Announcements', style: context.headline2),
              TextButton(
                onPressed: () {},
                child:
                    Text('More', style: TextStyle(color: Colors.grey.shade600)),
              ),
            ],
          ),
          newsAsyncValue.when(
            data: (querySnapshot) {
              if (querySnapshot.docs.isEmpty) {
                return nodatawidget(title: 'No news available at the moment');
              }

              final latestNews = querySnapshot.docs.reversed
                  .take(3)
                  .toList(); // Get last 3 news items

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: latestNews.length,
                itemBuilder: (context, int index) {
                  final doc = latestNews[index];
                  final title = doc['title'];
                  final content = doc['content'];
                  final date = (doc['posted_At'] as Timestamp).toDate();
                  final imageUrl = doc['image_Url'] ??
                      'https://res.cloudinary.com/dbeofdu5x/image/upload/v1744020084/NAIROBI_GYMKHANA_LOGO_BANNER_kiaxwy.png';

                  // Validate image URL
                  String finalImageUrl = (Uri.tryParse(imageUrl)
                              ?.hasAbsolutePath ??
                          false)
                      ? imageUrl
                      : 'https://res.cloudinary.com/dbeofdu5x/image/upload/v1744020084/NAIROBI_GYMKHANA_LOGO_BANNER_kiaxwy.png';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    // // decoration: BoxDecoration(
                    // //   color: Colors.white,
                    // //   border: Border.all(color: AppKolors.primary),
                    // //   borderRadius: BorderRadius.circular(10),
                    // //   boxShadow: [
                    // //     BoxShadow(
                    // //       color: Colors.grey.withValues(alpha: 0.5),
                    // //       spreadRadius: 2,
                    // //       blurRadius: 3,
                    // //       offset: Offset(0, 1),
                    // //     ),
                    //   ],
                    // ),
                    child: ListTile(
                      leading: Image.network(finalImageUrl),
                      title: Text(title,
                          maxLines: 1, style: context.newstitleHeadline),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(content,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.newstitlebody1),
                          Text(
                              'Date: ${date.toLocal().toString().split(' ')[0]}',
                              style: AppFonts.newstitlebody2),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('Error: $error')),
          ),
        ],
      ),
    );
  }
}
