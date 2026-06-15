// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:nrbgymkhana/features/thewall/presentation/screens/reportincidents.dart';

// void main() {
//   group('GymkhanaIssueReportForm - Entity Chips Section', () {
//     late ProviderContainer container;
//     List<Override> overrides;

//     // Helper to build the GymkhanaIssueReportForm widget with necessary providers
//     Future<void> pumpWidgetUnderTest(WidgetTester tester, {List<String>? initialEntities, String? status}) async {
//       overrides = [
//         // Ensure the "Entities" section is visible by providing a status
//         statusProvider.overrideWith((ref) => status ?? 'Staff'),
//         entityListProvider.overrideWith((ref) => initialEntities ?? []),
//         // Provide default states for other providers used by the form
//         entityInputProvider.overrideWith((ref) => ''),
//         descriptionProvider.overrideWith((ref) => ''),
//         attachmentsProvider.overrideWith((ref) => []),
//       ];

//       container = ProviderContainer(overrides: overrides);

//       await tester.pumpWidget(
//         UncontrolledProviderScope(
//           container: container,
//           child: MaterialApp(
//             home: Scaffold(
//               // The form is typically shown in a modal, but for testing this part,
//               // rendering it directly within a Scaffold is sufficient.
//               body: SingleChildScrollView( // In case the form content overflows
//                 child: GymkhanaIssueReportForm(),
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     tearDown(() {
//       container.dispose();
//     });

//     testWidgets('renders no chips and no Wrap when entity list is empty', (WidgetTester tester) async {
//       await pumpWidgetUnderTest(tester, initialEntities: []);

//       expect(find.byType(Chip), findsNothing);
//       // The Wrap widget for chips should not be present if there are no entities
//       // We identify it by checking for a Wrap that would contain Chips.
//       // If no Chips, this specific Wrap shouldn't be there or have children.
//       final wrapFinder = find.byWidgetPredicate((widget) {
//         if (widget is Wrap && widget.children.any((child) => child is Chip)) {
//           return true;
//         }
//         // Check for an empty wrap that might be rendered if logic allows
//         if (widget is Wrap && widget.spacing == 8.0 && widget.children.isEmpty) {
//            // This could be the target Wrap if it's always rendered but empty.
//            // Based on `list.map(...).toList()`, it won't render if list is empty.
//         }
//         return false;
//       });
//       expect(wrapFinder, findsNothing); // Expect no Wrap containing Chips
//       expect(container.read(entityListProvider), isEmpty);
//     });

//     testWidgets('renders chips correctly based on entityListProvider', (WidgetTester tester) async {
//       final initialEntities = ['Entity Alpha', 'Entity Beta'];
//       await pumpWidgetUnderTest(tester, initialEntities: initialEntities);

//       expect(find.byType(Chip), findsNWidgets(2));
//       expect(find.text('Entity Alpha'), findsOneWidget);
//       expect(find.text('Entity Beta'), findsOneWidget);

//       // Verify the Wrap widget properties
//       final wrapFinder = find.ancestor(of: find.byType(Chip), matching: find.byType(Wrap));
//       expect(wrapFinder, findsOneWidget);
//       final wrapWidget = tester.widget<Wrap>(wrapFinder);
//       expect(wrapWidget.spacing, 8.0);
//       expect(wrapWidget.children.length, 2);

//       expect(container.read(entityListProvider), initialEntities);
//     });

//     testWidgets('deleting a chip removes it from UI and updates provider', (WidgetTester tester) async {
//       final initialEntities = ['Entity X', 'Entity Y', 'Entity Z'];
//       await pumpWidgetUnderTest(tester, initialEntities: initialEntities);

//       // Verify initial state
//       expect(find.byType(Chip), findsNWidgets(3));
//       expect(find.text('Entity Y'), findsOneWidget);

//       // Find the Chip for 'Entity Y' and simulate its deletion
//       final chipToDeleteFinder = find.widgetWithText(Chip, 'Entity Y');
//       final chipWidget = tester.widget<Chip>(chipToDeleteFinder);
      
//       expect(chipWidget.onDeleted, isNotNull);
//       chipWidget.onDeleted!(); // Call the onDeleted callback

//       await tester.pump(); // Rebuild the widget tree

//       // Verify UI update
//       expect(find.byType(Chip), findsNWidgets(2));
//       expect(find.text('Entity Y'), findsNothing);
//       expect(find.text('Entity X'), findsOneWidget);
//       expect(find.text('Entity Z'), findsOneWidget);

//       // Verify provider state update
//       expect(container.read(entityListProvider), ['Entity X', 'Entity Z']);
//     });

//     testWidgets('deleting the last chip removes all chips and empties provider', (WidgetTester tester) async {
//       final initialEntities = ['Sole Entity'];
//       await pumpWidgetUnderTest(tester, initialEntities: initialEntities);

//       expect(find.byType(Chip), findsOneWidget);

//       final chipWidget = tester.widget<Chip>(find.widgetWithText(Chip, 'Sole Entity'));
//       chipWidget.onDeleted!();
//       await tester.pump();

//       expect(find.byType(Chip), findsNothing);
//       expect(container.read(entityListProvider), isEmpty);
//     });

//     testWidgets('Wrap widget for chips is not rendered if status is null', (WidgetTester tester) async {
//       // The entity list section, including the Wrap for chips, is conditional on `status != null`
//       await pumpWidgetUnderTest(tester, initialEntities: ['Entity 1'], status: null);

//       // No chips should be rendered because the entire section is hidden
//       expect(find.byType(Chip), findsNothing);
//       // Consequently, the Wrap widget for these chips should also not be found.
//       final wrapContainingChipsFinder = find.ancestor(of: find.byType(Chip), matching: find.byType(Wrap));
//       expect(wrapContainingChipsFinder, findsNothing);
//     });
//   });
// }