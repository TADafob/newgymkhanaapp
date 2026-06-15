import 'package:flutter/material.dart';

class RestaurantDetailPage extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String location;
  final String status;
  final String hours;
  final String cuisine;
  final String phone;
  final List<String> galleryImages;

  const RestaurantDetailPage({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.location,
    required this.status,
    required this.hours,
    required this.cuisine,
    required this.phone,
    required this.galleryImages,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: TopAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 40,
                    left: 16,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 16,
                    child: Icon(Icons.favorite_border, color: Colors.white),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    SizedBox(height: 4),
                    Text(
                      location,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      status,
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      hours,
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Casual Dining - $cuisine",
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(120, 35),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.blueAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text("Menu", style: TextStyle(color: Colors.blueAccent)),
                        ),
                        SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(120, 35),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.blueAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(phone, style: TextStyle(color: Colors.blueAccent)),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Gallery",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: galleryImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                galleryImages[index],
                                width: 150,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Ratings!",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(5, (index) {
                        return ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(30, 35),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.blueAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text("${index + 1}★", style: TextStyle(color: Colors.blueAccent)),
                        );
                      }),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "We would love to hear more about your experience!",
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        "Add Your Review",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
