import 'package:flutter/material.dart';
import 'package:nrbgymkhana/features/testfeature/colors.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.home, color: primaryColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.calendar_today, color: textColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble, color: textColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.person, color: textColor),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}