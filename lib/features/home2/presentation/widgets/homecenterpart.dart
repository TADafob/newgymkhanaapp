import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nrbgymkhana/core/utils/appfonts.dart';
import 'package:nrbgymkhana/features/common/widgets/homecenternavs.dart';
import 'package:nrbgymkhana/features/home/presentation/widgets/newssection.dart';

class HomeCenterPart extends StatelessWidget {
  final List<Map<String, dynamic>> actions;
  final Map<String, String> actionRoutes;
  final bool? multi;
  final String title;

  const HomeCenterPart({
    super.key,
    required this.actions,
    this.multi,
    required this.title,
    required this.actionRoutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10, left: 14, right: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 3.0,
            spreadRadius: 0.0,
            offset: const Offset(0.0, 0.7),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: context.headline2),
              if (multi == true)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewsCenterPart(),
                      ),
                    );
                  },
                  child: Text(
                    'More',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 3.0,
              crossAxisSpacing: 8.0,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _ActionCard(
                action: action,
                actionRoutes: actionRoutes,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final Map<String, dynamic> action;
  final Map<String, String> actionRoutes;

  const _ActionCard({
    required this.action,
    required this.actionRoutes,
  });

  @override
  Widget build(BuildContext context) {
    return CenterHomeNavs(
      ischatpage: action['ischatpage'],
      isHomepage: true,
      title: action['title']!,
      icon: action['icon'] != null ? Icon(action['icon'] as IconData) : null,
      imageurl: action['image']!,
      onTapped: () {
        final route = actionRoutes[action['title']!];
        if (route != null) {
          action['ischatpage'] == null ? context.go(route) : context.push(route);
        }
      },
    );
  }
}
