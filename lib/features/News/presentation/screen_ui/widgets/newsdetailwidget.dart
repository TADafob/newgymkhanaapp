import 'package:flutter/material.dart';

class NewsDetailsPage extends StatelessWidget {
  final String title;
  final String author;
  final String date;
  final String image;
  final String content;
  final List<String>? additionalImages; // List for extra images

  const NewsDetailsPage({
    super.key,
    required this.title,
    required this.author,
    required this.date,
    required this.image,
    required this.content,
    this.additionalImages, // Optional additional images
  });

  @override
  Widget build(BuildContext context) {
    // Split content into paragraphs
    List<String> paragraphs = content.split("\n\n");

    return Scaffold(
      //appBar: TopAppBar(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: Colors.blueGrey),
                      onPressed: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Main Image at the Top
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30), top: Radius.circular(30)),
                    child: Image.network(
                      image,
                      width: double.infinity,
                      height: 230,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // News Content
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 10),

                      // Author & Date Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.blue,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 15),
                              Text(author, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                            ],
                          ),
                          Text(date, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Content with additional images inserted
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildContentWithImages(paragraphs),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Function to insert images between content
  List<Widget> _buildContentWithImages(List<String> paragraphs) {
    List<Widget> contentWidgets = [];

    for (int i = 0; i < paragraphs.length; i++) {
      contentWidgets.add(
        Text(
          paragraphs[i],
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      );

      // Insert additional images in between paragraphs
      if (additionalImages != null && i < additionalImages!.length) {
        contentWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                additionalImages![i],
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }

      contentWidgets.add(const SizedBox(height: 10));
    }

    return contentWidgets;
  }
}
