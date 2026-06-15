// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:nrbgymkhana/core/utils/appcolors.dart';
// import 'package:nrbgymkhana/core/utils/appfonts.dart';
// import 'package:nrbgymkhana/features/common/widgets/homecenternavs.dart';
// import 'package:nrbgymkhana/tests/hidetest.dart'; // Assuming ChatScreen is defined here.

// class HomeCenterPart extends StatelessWidget {
//   final List<Map<String, dynamic>> actions;
//   final Map<String, String> actionRoutes;
//   final bool? multi;
//   final String title;

//   const HomeCenterPart({
//     super.key,
//     required this.actions,
//     this.multi = false,
//     required this.title,
//     required this.actionRoutes,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
    
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(
//           color: theme.colorScheme.outline.withValues(alpha: 0.1),
//         ),
//       ),
//       margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header with title and action
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   title,
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: theme.colorScheme.tertiaryContainer,
//                   ),
//                 ),
//                 if (multi == true)
//                   TextButton.icon(
//                     onPressed: () {
//                       context.push('/chat');
//                     },
//                     icon: Icon(
//                       Icons.arrow_forward_ios_rounded,
//                       size: 14,
//                       color: theme.colorScheme.secondary,
//                     ),
//                     label: Text(
//                       'More',
//                       style: TextStyle(
//                         color: theme.colorScheme.secondary,
//                         fontSize: 14,
//                       ),
//                     ),
//                     style: TextButton.styleFrom(
//                       padding: EdgeInsets.zero,
//                       minimumSize: Size.zero,
//                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                     ),
//                   ),
//               ],
//             ),
            
//             const SizedBox(height: 12),
            
//             // Grid of actions
//             GridView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
//                 maxCrossAxisExtent: 120,
//                 mainAxisSpacing: 12,
//                 crossAxisSpacing: 12,
//                 childAspectRatio: 1.1,
//               ),
//               itemCount: actions.length,
//               itemBuilder: (context, index) {
//                 final action = actions[index];
//                 return ActionGridItem(
//                   title: action['title']!,
//                   icon: action['icon'] as IconData?,
//                   imageUrl: action['image'] ?? '',
//                   onTap: () {
//                     final route = actionRoutes[action['title']!];
//                     if (route != null) {
//                       if (action['ischatpage'] == null) {
//                         context.go(route);
//                       } else {
//                         context.push(route);
//                       }
//                     }
//                   },
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ActionGridItem extends StatelessWidget {
//   final String title;
//   final IconData? icon;
//   final String imageUrl;
//   final VoidCallback onTap;

//   const ActionGridItem({
//     super.key,
//     required this.title,
//     this.icon,
//     this.imageUrl = '',
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
    
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         decoration: BoxDecoration(
//           color: theme.colorScheme.surfaceContainer,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Icon/Image container
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: theme.colorScheme.primaryContainer,
//                 shape: BoxShape.circle,
//               ),
//               child: icon != null 
//                 ? Icon(
//                     icon,
//                     size: 36,
//                     color: AppKolors.blackness.withValues(alpha: .7),
//                   )
//                 : ClipOval(
//                     child: imageUrl.isNotEmpty 
//                       ? Image.network(
//                           imageUrl,
//                           width: 36,
//                           height: 36,
//                           fit: BoxFit.cover,
//                         )
//                       : const Icon(
//                           Icons.image_not_supported,
//                           size: 36,
//                           color: Colors.grey,
//                         ),
//                   ),
//             ),
            
//             const SizedBox(height: 12),
            
//             // Title
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: theme.textTheme.bodySmall?.copyWith(
//                 fontWeight: FontWeight.w500,
//                 color: theme.colorScheme.onSurface,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }