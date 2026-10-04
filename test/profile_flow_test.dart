import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_studio/main.dart';
import 'package:feedback_studio/store.dart';

void main() {
  testWidgets(
    'Small-screen profile editor saves details without layout exceptions',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = AppStore(demo: true)..enterDemo(false);
      await tester.pumpWidget(FeedbackApp(store: store));
      await tester.pumpAndSettle();
      expect(find.text('feedback studio.'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('nav-3')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Profile settings'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Profile settings')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile settings'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('profile-name')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-name')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('profile-name')),
        'Saad Jadoon',
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('profile-save')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('profile-save'))),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('profile-save')));
      await tester.pumpAndSettle();
      expect(store.name, 'Saad Jadoon');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
