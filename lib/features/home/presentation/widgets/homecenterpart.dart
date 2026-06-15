import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/appfonts.dart';
import 'package:nrbgymkhana/features/common/widgets/homecenternavs.dart';
import 'package:nrbgymkhana/features/home/presentation/widgets/newssection.dart';

class HomeCenterPart extends StatelessWidget {
  final List<Map<String, dynamic>> actions;
  final Map<String, String> actionRoutes;
  final Map<String, VoidCallback>? actionCallbacks;
  final bool? multi;
  final String title;
  final String? subtitle;
  final Color accentColor;

  const HomeCenterPart({
    super.key,
    required this.actions,
    this.multi,
    required this.title,
    this.subtitle,
    required this.actionRoutes,
    this.actionCallbacks,
    this.accentColor = AppKolors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.headline2.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppKolors.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
                if (multi == true)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewsCenterPart()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: accentColor.withOpacity(0.25)),
                      ),
                      child: Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1D1E33) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : accentColor.withOpacity(0.10),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.0,
                  children: actions.map((action) {
                    return CenterHomeNavs(
                      ischatpage: action['ischatpage'],
                      isHomepage: true,
                      title: action['title']!,
                      icon: action['icon'] != null
                          ? Icon(action['icon'] as IconData)
                          : null,
                      imageurl: action['image']!,
                      accentColor: accentColor,
                      onTapped: () {
                        final title = action['title'] as String;
                        final callback = actionCallbacks?[title];
                        if (callback != null) {
                          callback();
                          return;
                        }
                        final route = actionRoutes[title];
                        if (route != null) {
                          action['ischatpage'] == null
                              ? context.go(route)
                              : context.push(route);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
