import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nrbgymkhana/features/News/presentation/screen_ui/widgets/newsdetailwidget.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

class NewsScreen extends ConsumerWidget {
  NewsScreen({super.key});

  final List<String> categories = ["All", "International", "Media", "Magazine", "Business"];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    return Expanded(
      child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Recent News",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildBreakingNewsCard(context),
                const SizedBox(height: 10),
                _buildCategoryTabs(ref, selectedCategory),
                const SizedBox(height: 10),
                _buildNewsList(context),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildBreakingNewsCard(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewsDetailsPage(
            title: "Contact Lost With Sriwijaya Air Boeing 737-500 After Take Off",
            author: "John Smith",
            date: "10 Jan, 2020",
            image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR9YYh5Fk1u9VsWWr1MhkyQeOzeNbtnnMO96g&s",
            content: "An Indonesian passenger plane carrying 62 people lost contact with air traffic controllers shortly after takeoff from the nation's capital of Jakarta on Saturday, according to state transportation officials.\n\nThe Ministry of Transportation confirmed that airport authorities lost contact with the plane, Sriwijaya Air Flight 182, at approximately 2:40 p.m. local time...",
            additionalImages: [
              "https://cdn.pixabay.com/photo/2015/04/23/22/00/new-year-background-736885_1280.jpg",
              "https://cdn.pixabay.com/photo/2015/04/23/22/00/new-year-background-736885_1280.jpg"
            ], // Add extra images here
          ),
        ),
      );
    },
    child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15), bottom: Radius.circular(15)),
            child: CachedNetworkImage(
              imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR9YYh5Fk1u9VsWWr1MhkyQeOzeNbtnnMO96g&s',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              memCacheWidth: 600,
              memCacheHeight: 400,
              maxHeightDiskCache: 400,
              maxWidthDiskCache: 600,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              "Contact Lost With Sriwijaya Air Boeing 737-500 After Take Off",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white, size: 15),
                    ),
                    const SizedBox(width: 5),
                    Text("John Smith", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
                Text("10 Jan, 2020", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildCategoryTabs(WidgetRef ref, String selectedCategory) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          bool isSelected = category == selectedCategory;
          return GestureDetector(
            onTap: () => ref.read(selectedCategoryProvider.notifier).state = category,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.black54,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNewsList(BuildContext context) {
  final List<Map<String, dynamic>> newsArticles = [
  {
    'title': 'An Illinois town fights to save its power plant',
    'date': 'Jan 10, 2021',
    'image': 'https://cdn.pixabay.com/photo/2015/04/23/22/00/new-year-background-736885_1280.jpg', // Main image
    'author': 'Jane Doe',
    'content': 'An Illinois town is struggling to keep its power plant operational amidst regulatory challenges...\n\nThe plant has been a key employer for decades...',
    'additionalImages': [
      'https://cdn.pixabay.com/photo/2015/04/23/22/00/new-year-background-736885_1280.jpg',
      'https://cdn.pixabay.com/photo/2015/04/23/22/00/new-year-background-736885_1280.jpg'
    ], // Extra images
  },
  {
    'title': '14 Passengers Banned By Nona Airlines After Bad Behavior',
    'date': 'Jan 09, 2021',
    'image': 'https://cdn.pixabay.com/photo/2015/04/23/22/00/new-year-background-736885_1280.jpg', // Main image
    'author': 'Michael Lee',
    'content': 'Nona Airlines has banned 14 passengers due to repeated misconduct during flights...\n\nAuthorities say stricter measures will be implemented...',
    'additionalImages': [
      'https://cdn.pixabay.com/photo/2015/04/23/22/00/new-year-background-736885_1280.jpg'
    ], // Extra images
  },
];

  
  return ListView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    itemCount: newsArticles.length,
    itemBuilder: (context, index) {
      final news = newsArticles[index];
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailsPage(
                title: newsArticles[index]['title']!,
              author: newsArticles[index]['author']!,
              date: newsArticles[index]['date']!,
              image: newsArticles[index]['image']!,
              content: newsArticles[index]['content']!,
              additionalImages: newsArticles[index]['additionalImages'] as List<String>?,        
              ),
            ),
          );
        },
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: news['image']!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                memCacheWidth: 160,
                memCacheHeight: 160,
                maxHeightDiskCache: 160,
                maxWidthDiskCache: 160,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1.5))),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported, size: 20),
                ),
              ),
            ),
            title: Text(
              news['title']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 5),
                    Text(news['date']!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.timelapse, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 5),
                    Text("10 min read", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
}