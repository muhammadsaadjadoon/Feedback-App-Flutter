import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_studio/store.dart';
import 'package:feedback_studio/model.dart';
void main() {
  test('Member sees only own reviews; admin sees all and can respond', () async {
    final store = AppStore(demo: true);
    store.enterDemo(false);
    final initial = await store.watch().first;
    expect(initial.length, 2);
    expect(initial.every((r) => r.userId == 'demo-user'), isTrue);
    final r = Review(id: 'test', userId: store.uid, author: store.name, category: 'Service', subject: 'Support', message: 'Helpful support team', suggestion: '', rating: 4, createdAt: DateTime.now());
    await store.submit(r);
    expect((await store.watch().first).length, 3);
    await expectLater(store.moderate(r, 'Resolved', 'Thanks'), throwsStateError);
    store.enterDemo(true);
    expect((await store.watch().first).length, 6);
    await store.moderate(r, 'Resolved', 'Thank you');
    store.enterDemo(false);
    expect((await store.watch().first).firstWhere((v) => v.id == 'test').reply, 'Thank you');
    await store.signOut(); expect(store.signedIn, isFalse);
    store.dispose();
  });
}
