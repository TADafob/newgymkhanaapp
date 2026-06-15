import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nrbgymkhana/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 1️⃣ Prepare the controller
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // 2️⃣ On animation end, move to your real app
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GymkhanaApp()),
          );
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // match the native splash bg
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
          'assets/images/common/splashscreen.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward();
          },
        ),
      ),
    );
  }
}
