import 'package:flutter/material.dart';

class thankYouWidget extends StatelessWidget {
  const thankYouWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      child: Image.asset('assets/images/common/logo.png'));
  }
}