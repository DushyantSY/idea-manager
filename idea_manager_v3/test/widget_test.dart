// test/widget_test.dart
// Basic smoke test — verifies the app launches without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_manager/app.dart';

void main() {
  testWidgets('App launches and shows splash screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: IdeaManagerApp()),
    );
    // Splash should be visible immediately
    expect(find.text('Idea Manager'), findsOneWidget);
  });
}
