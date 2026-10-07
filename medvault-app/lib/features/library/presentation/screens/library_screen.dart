import 'package:flutter/material.dart';

/// Library landing screen.
///
/// Content browsing will be wired in a later task once the taxonomy
/// read path is established.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Library'),
      ),
    );
  }
}
