import 'package:flutter/material.dart';
import 'package:nrbgymkhana/features/testfeature/facilitysection.dart';
import 'package:nrbgymkhana/features/testfeature/header.dart';

class SportsFacilitiesScreen extends StatelessWidget {
  const SportsFacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Header(),
              const FacilitiesSection(),
            ],
          ),
        ),
      ),
    );
  }
}