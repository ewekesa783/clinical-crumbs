import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/features/library/presentation/screens/prototype_lesson_renderer.dart';

Widget buildRenderer(Map<String, dynamic> lesson) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: PrototypeLessonRenderer(
        lesson: lesson,
        resourceUuid: 'test-lesson',
        onChooseAnother: () {},
      ),
    ),
  );
}

void main() {
  testWidgets(
    'an unrelated cover uses the generic illustration instead of lungs',
    (tester) async {
      await tester.pumpWidget(
        buildRenderer({
          'title': 'An Unrelated Lesson',
          'pages': [
            {
              'id': 'cover',
              'type': 'cover',
              'title': 'An Unrelated Lesson',
              'subtitle': 'A test lesson',
            },
          ],
        }),
      );

      expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
      expect(find.text('An Unrelated Lesson'), findsWidgets);
      expect(find.byIcon(Icons.air), findsNothing);
    },
  );

  testWidgets(
    'golden minute hero is selected by declared design metadata',
    (tester) async {
      await tester.pumpWidget(
        buildRenderer({
          'title': 'Metadata-Driven Hero Test',
          'pages': [
            {
              'id': 'cover',
              'type': 'cover',
              'hero_design': 'golden_minute',
              'eyebrow': 'PAEDIATRICS · NEONATOLOGY',
              'title': 'Metadata-Driven Hero Test',
              'subtitle': 'A topic-specific hero selected through metadata',
              'chips': ['12 min read', 'Kenyan protocols', 'Interactive'],
              'takeaway':
                  'Start ventilation within 60 seconds: the Golden Minute.',
            },
          ],
        }),
      );

      expect(find.textContaining('VENTILATE'), findsOneWidget);
      expect(find.textContaining('WITHIN 60 s'), findsOneWidget);
      expect(find.text('THE GOLDEN MINUTE'), findsOneWidget);
      expect(find.text('Kenyan protocols'), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_outlined), findsNothing);
    },
  );

  testWidgets(
    'mechanism visuals display the lesson supplied captions',
    (tester) async {
      await tester.pumpWidget(
        buildRenderer({
          'title': 'Test Mechanism',
          'pages': [
            {
              'id': 'mechanism',
              'type': 'mechanism',
              'title': 'Test Mechanism',
              'body': 'Mechanism test body.',
              'visual': {
                'label': 'LESSON-SPECIFIC MODEL',
                'items': [
                  {
                    'shape': 'lungs_fluid',
                    'caption': 'Fluid-filled model',
                  },
                  {
                    'shape': 'lungs_air',
                    'caption': 'Air-filled model',
                  },
                ],
              },
            },
          ],
        }),
      );

      expect(find.text('LESSON-SPECIFIC MODEL'), findsOneWidget);
      expect(find.text('Fluid-filled model'), findsOneWidget);
      expect(find.text('Air-filled model'), findsOneWidget);
      expect(find.text('Airway model'), findsNothing);
    },
  );

  testWidgets(
    'flow diagrams display each branch label and its explanation',
    (tester) async {
      await tester.pumpWidget(
        buildRenderer({
          'title': 'Test Flowchart',
          'pages': [
            {
              'id': 'flow',
              'type': 'flow',
              'title': 'Test Flowchart',
              'diagram': [
                [
                  'Choose the appropriate pathway',
                  'decision',
                  [
                    ['YES', 'Explanation for the yes branch', 'process'],
                    ['NO', 'Explanation for the no branch', 'danger'],
                  ],
                ],
              ],
            },
          ],
        }),
      );

      expect(find.text('Choose the appropriate pathway'), findsOneWidget);
      expect(find.text('YES'), findsOneWidget);
      expect(find.text('NO'), findsOneWidget);
      expect(find.text('Explanation for the yes branch'), findsOneWidget);
      expect(find.text('Explanation for the no branch'), findsOneWidget);
    },
  );
}
