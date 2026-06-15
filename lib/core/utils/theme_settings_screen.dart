import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/common/widgets/commontopcontainer.dart';
import 'package:nrbgymkhana/features/home/presentation/widgets/theme_provider.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      body: Column(
        children: [
          const CommonTopContainer(
            title: 'APP THEME',
            Image_url: 'assets/images/common/calendar.png',
            titleposition: 130,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildThemeOption(
                  context,
                  ref,
                  title: 'System Default',
                  mode: ThemeMode.system,
                  currentMode: themeMode,
                  icon: Icons.brightness_auto,
                ),
                _buildThemeOption(
                  context,
                  ref,
                  title: 'Light Mode',
                  mode: ThemeMode.light,
                  currentMode: themeMode,
                  icon: Icons.light_mode,
                ),
                _buildThemeOption(
                  context,
                  ref,
                  title: 'Dark Mode',
                  mode: ThemeMode.dark,
                  currentMode: themeMode,
                  icon: Icons.dark_mode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required IconData icon,
  }) {
    final isSelected = mode == currentMode;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      color: isSelected ? primaryColor.withValues(alpha: 0.1) : null,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isSelected ? BorderSide(color: primaryColor) : BorderSide.none,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? primaryColor : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primaryColor : null,
          ),
        ),
        trailing:
            isSelected ? Icon(Icons.check_circle, color: primaryColor) : null,
        onTap: () {
          ref.read(themeProvider.notifier).setTheme(mode);
        },
      ),
    );
  }
}
