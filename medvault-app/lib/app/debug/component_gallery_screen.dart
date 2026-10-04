import 'package:flutter/material.dart';

/// Debug-only screen rendering the application's design-token components
/// (typography scale, buttons, a card, a chip) for visual review, with a
/// light/dark theme toggle.
///
/// Reachable only in debug builds; see the redirect guard on
/// [ComponentGalleryRoute] in app_router.dart.
class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() =>
      _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDark ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Component Gallery'),
          actions: [
            Switch(
              value: _isDark,
              onChanged: (value) => setState(() => _isDark = value),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Headline', style: Theme.of(context).textTheme.headlineMedium),
            Text('Title', style: Theme.of(context).textTheme.titleLarge),
            Text('Body', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Card content'),
              ),
            ),
            const SizedBox(height: 16),
            const Chip(label: Text('Chip')),
          ],
        ),
      ),
    );
  }
}
