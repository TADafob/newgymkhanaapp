import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/responsiveness.dart';
import 'package:nrbgymkhana/features/Profile/presentation/screens_ui/mainprofilepage.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFF0F4F8),
      body: responsiveLayout(
        smallScreen: const ProfilePage(),
        mediumScreen: const Center(
          child: SizedBox(width: 420, child: ProfilePage()),
        ),
      ),
    );
  }
}
