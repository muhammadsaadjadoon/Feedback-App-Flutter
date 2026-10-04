import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_studio/main.dart';
import 'package:feedback_studio/store.dart';

Future<void> reach(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 160, scrollable: find.byType(Scrollable).first);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}
void main() {
  for (final size in [const Size(320, 640), const Size(390, 844)]) {
    testWidgets('Member submits feedback without overflow at ${size.width}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = AppStore(demo: true);
      await tester.pumpWidget(FeedbackApp(store: store));
      await reach(tester, find.byKey(const ValueKey('demo-member')));
      await tester.tap(find.byKey(const ValueKey('demo-member')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('nav-1')));
      await tester.pumpAndSettle();
      await reach(tester, find.text('Weekly assignment'));
      expect(find.text('Weekly assignment'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('compose')));
      await tester.pumpAndSettle();
      await reach(tester, find.byKey(const ValueKey('review-subject')));
      await tester.enterText(find.byKey(const ValueKey('review-subject')), 'Mobile experience');
      await reach(tester, find.byTooltip('5 stars'));
      await tester.tap(find.byTooltip('5 stars'));
      await reach(tester, find.byKey(const ValueKey('review-next')));
      await tester.tap(find.byKey(const ValueKey('review-next')));
      await tester.pumpAndSettle();
      await reach(tester, find.byKey(const ValueKey('review-message')));
      await tester.enterText(find.byKey(const ValueKey('review-message')), 'The course examples were clear and practical.');
      await reach(tester, find.byKey(const ValueKey('review-next')));
      await tester.tap(find.byKey(const ValueKey('review-next')));
      await tester.pumpAndSettle();
      await reach(tester, find.byKey(const ValueKey('review-next')));
      await tester.tap(find.byKey(const ValueKey('review-next')));
      await tester.pumpAndSettle();
      expect(find.text('Heard. And appreciated.'), findsOneWidget);
      expect((await store.watch().first).any((r) => r.subject == 'Mobile experience' && r.rating == 5), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  }
  testWidgets('Admin resolves a review and saves a response', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = AppStore(demo: true)..enterDemo(true);
    await tester.pumpWidget(FeedbackApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();
    await reach(tester, find.text('Weekly assignment'));
    await tester.tap(find.text('Weekly assignment'));
    await tester.pumpAndSettle();
    await reach(tester, find.byKey(const ValueKey('admin-reply')));
    await tester.enterText(find.byKey(const ValueKey('admin-reply')), 'We have clarified the submission instructions.');
    final resolved = find.widgetWithText(ChoiceChip, 'Resolved');
    await tester.ensureVisible(resolved);
    await tester.tap(resolved);
    await tester.pumpAndSettle();
    await reach(tester, find.byKey(const ValueKey('admin-save')));
    await tester.tap(find.byKey(const ValueKey('admin-save')));
    await tester.pumpAndSettle();
    final review = (await store.watch().first).firstWhere((r) => r.id == 'sample-3');
    expect(review.status, 'Resolved');
    expect(review.reply, 'We have clarified the submission instructions.');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
