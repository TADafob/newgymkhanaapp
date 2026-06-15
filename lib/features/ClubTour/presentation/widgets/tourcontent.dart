import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/ClubTour/presentation/widgets/personsdetailspage.dart';
import 'package:nrbgymkhana/features/ClubTour/presentation/widgets/restbarsportsdetails.dart';

// Define a model for the card
class FeatureCard {
  final String title;
  final IconData icon;
  final String points;
  final String imageUrl;
  final bool isLocked;

  FeatureCard({
    required this.title,
    required this.icon,
    required this.points,
    required this.imageUrl,
    this.isLocked = false,
  });
}

// Create a provider for the cards
final featureCardsProvider = Provider<List<FeatureCard>>((ref) {
  return [
    FeatureCard(
        title: 'Restaurants',
        icon: Icons.food_bank,
        points: '2 Restaurants',
        imageUrl:
            "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/2b/c7/0f/0b/upepo-restaurant.jpg?w=600&h=-1&s=1"),
    FeatureCard(
        title: 'Bar and Drinks',
        icon: Icons.local_bar,
        points: '1 Bar',
        imageUrl:
            "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS9ctCaIqBbDpxv9ahuDhpV_jJCEQUUR-LgPw&s"),
    FeatureCard(
        title: 'Bandas',
        icon: Icons.sports_soccer,
        points: '10 Bandas',
        imageUrl:
            "https://img.freepik.com/free-photo/sports-tools_53876-138077.jpg"),
    FeatureCard(
        title: 'Club Committee',
        icon: Icons.groups,
        points: '12 Committee Members',
        imageUrl:
            "https://www.thestratalife.com.au/wp-content/uploads/2023/11/board-committee-meeting_900.gif",
        isLocked: true),
    FeatureCard(
        title: 'Managerial Team',
        icon: Icons.business_center,
        points: '9 Managerial Team',
        imageUrl:
            "https://midias.siteware.com.br/wp-content/uploads/2023/04/24163428/team-management.png",
        isLocked: true),
    FeatureCard(
        title: 'Trustees',
        icon: Icons.verified,
        points: '6 Trustee Members',
        imageUrl:
            "https://dundeecarerscentre.org.uk/cms/uploads/become-a-trustee-pic.png",
        isLocked: true),
  ];
});

// The main page
class FeaturePage extends ConsumerWidget {
  const FeaturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(featureCardsProvider);

    // Divide the cards into two categories
    final category1 = cards.take(3).toList();
    final category2 = cards.skip(3).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entertainment and Sports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: category1.length,
            itemBuilder: (context, index) {
              return FeatureCardWidget(card: category1[index]);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Managerials',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: category2.length,
            itemBuilder: (context, index) {
              return FeatureCardWidget(card: category2[index]);
            },
          ),
        ],
      ),
    );
  }
}

// Reusable card widget
class FeatureCardWidget extends StatelessWidget {
  final FeatureCard card;

  const FeatureCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (card.isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("This feature is locked.")),
          );
        } else if (card.title == 'Restaurants' ||
            card.title == 'Bar and Drinks' ||
            card.title == 'Bandas') {
          // Navigate to RestaurantDetailPage with respective data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailPage(
                imageUrl: card.imageUrl,
                name: card.title,
                location: card.title == 'Restaurants'
                    ? "Club Restaurants"
                    : card.title == 'Bar and Drinks'
                        ? "Pari Events Bar and Catering Limited"
                        : "Club Sports Complex",
                status: "Runs daily from",
                hours: card.title == 'Restaurants'
                    ? "7AM to 10PM"
                    : card.title == 'Bar and Drinks'
                        ? "11AM to 12 Midnight"
                        : "6AM to 10PM",
                cuisine: card.title == 'Restaurants'
                    ? "Dine in and Take Aways"
                    : card.title == 'Bar and Drinks'
                        ? "Cocktails, Wine & Spirits"
                        : "Multiple Indoor & Outdoor Sports",
                phone: card.title == 'Restaurants'
                    ? "See All Restaurants"
                    : card.title == 'Bar and Drinks'
                        ? "See All Bars"
                        : "See All Sports",
                galleryImages: card.title == 'Restaurants'
                    ? [
                        "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/28/99/4f/74/savor-the-flavors-of.jpg?w=600&h=-1&s=1",
                        "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1a/2a/17/35/sushi-counter-and-graffiti.jpg?w=600&h=-1&s=1",
                        "https://www.simbapos.co.ke/wp-content/uploads/2023/04/restaurant-proper-management-in-kenya-1110x550.jpg"
                      ]
                    : card.title == 'Bar and Drinks'
                        ? [
                            "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1a/2a/17/35/sushi-counter-and-graffiti.jpg?w=600&h=-1&s=1",
                            "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS9ctCaIqBbDpxv9ahuDhpV_jJCEQUUR-LgPw&s",
                            "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/28/99/4f/74/savor-the-flavors-of.jpg?w=600&h=-1&s=1"
                          ]
                        : [
                            "https://img.freepik.com/free-photo/sports-tools_53876-138077.jpg",
                            "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1a/2a/17/35/sushi-counter-and-graffiti.jpg?w=600&h=-1&s=1",
                            "https://www.simbapos.co.ke/wp-content/uploads/2023/04/restaurant-proper-management-in-kenya-1110x550.jpg"
                          ],
              ),
            ),
          );
        } else {
          List<Profile> profiles = [];
          if (card.title == 'Club Committee') {
            profiles = getCommitteeProfiles();
          } else if (card.title == 'Managerial Team') {
            profiles = getManagerialProfiles();
          } else if (card.title == 'Trustees') {
            profiles = getTrusteeProfiles();
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileListPage(profiles: profiles),
            ),
          );
        }
      },
      child: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(card.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: card.isLocked ? 0.6 : 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(card.icon, size: 32, color: Colors.white),
                const Spacer(),
                Text(
                  card.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.points,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (card.isLocked)
            const Align(
              alignment: Alignment.center,
              child: Icon(Icons.lock, color: Colors.white, size: 32),
            ),
        ],
      ),
    );
  }

  // Example method for fetching profiles
  List<Profile> getCommitteeProfiles() {
    return [
      Profile(
          name: "Barbara Jones",
          job: "Chairperson",
          imageUrl: "https://randomuser.me/api/portraits/women/44.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Kevin Reid",
          job: "Vice Chairperson",
          imageUrl: "https://randomuser.me/api/portraits/men/32.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Keanu Barnett",
          job: "Secretary",
          imageUrl: "https://randomuser.me/api/portraits/men/47.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Matthew Gilbert",
          job: "Assistant Secretary",
          imageUrl: "https://randomuser.me/api/portraits/men/52.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Treasurer",
          imageUrl: "https://randomuser.me/api/portraits/women/38.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Assistant Treasurer",
          imageUrl: "https://randomuser.me/api/portraits/men/68.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Outdoor Sports Secretary",
          imageUrl: "https://randomuser.me/api/portraits/women/33.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Indoor Sports Secretary",
          imageUrl: "https://randomuser.me/api/portraits/women/39.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Committee Member",
          imageUrl: "https://randomuser.me/api/portraits/men/31.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Committee Member",
          imageUrl: "https://randomuser.me/api/portraits/men/18.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Committee Member",
          imageUrl: "https://randomuser.me/api/portraits/men/58.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Committee Member",
          imageUrl: "https://randomuser.me/api/portraits/men/98.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Committee Member",
          imageUrl: "https://randomuser.me/api/portraits/women/48.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"), // Add committee members here
    ];
  }

  List<Profile> getManagerialProfiles() {
    return [
      Profile(
          name: "Barbara Jones",
          job: "Chairperson",
          imageUrl: "https://randomuser.me/api/portraits/women/44.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Kevin Reid",
          job: "Vice Chairperson",
          imageUrl: "https://randomuser.me/api/portraits/men/32.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Keanu Barnett",
          job: "Secretary",
          imageUrl: "https://randomuser.me/api/portraits/men/47.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Matthew Gilbert",
          job: "Assistant Secretary",
          imageUrl: "https://randomuser.me/api/portraits/men/52.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Treasurer",
          imageUrl: "https://randomuser.me/api/portraits/women/38.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Assistant Treasurer",
          imageUrl: "https://randomuser.me/api/portraits/men/68.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Outdoor Sports Secretary",
          imageUrl: "https://randomuser.me/api/portraits/women/33.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Indoor Sports Secretary",
          imageUrl: "https://randomuser.me/api/portraits/women/39.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Committee Member",
          imageUrl: "https://randomuser.me/api/portraits/men/31.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
    ];
  }

  List<Profile> getTrusteeProfiles() {
    return [
      Profile(
          name: "Barbara Jones",
          job: "Chairperson",
          imageUrl: "https://randomuser.me/api/portraits/women/44.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Kevin Reid",
          job: "Vice Chairperson",
          imageUrl: "https://randomuser.me/api/portraits/men/32.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Keanu Barnett",
          job: "Secretary",
          imageUrl: "https://randomuser.me/api/portraits/men/47.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Matthew Gilbert",
          job: "Assistant Secretary",
          imageUrl: "https://randomuser.me/api/portraits/men/52.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Treasurer",
          imageUrl: "https://randomuser.me/api/portraits/women/38.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"),
      Profile(
          name: "Marie Hughes",
          job: "Assistant Treasurer",
          imageUrl: "https://randomuser.me/api/portraits/men/68.jpg",
          jobs: '2024/2025',
          rate: "J-05-0023"), // Add trustee members here
    ];
  }
}
