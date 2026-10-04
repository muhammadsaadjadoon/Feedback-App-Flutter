import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_studio/model.dart';
import 'package:feedback_studio/filters.dart';
import 'package:feedback_studio/store.dart';
Review sample(String id, int rating, int days, {String category = 'Task'}) => Review(id: id, userId: 'demo-user', author: 'Saadi', category: category, subject: 'Flutter $id', message: 'Helpful practical examples', suggestion: 'Add practice exercises', rating: rating, createdAt: DateTime(2026, 10, 4).subtract(Duration(days: days)));
void main() {
  final source = [sample('a', 5, 1), sample('b', 2, 3), sample('c', 4, 20, category: 'Course')];
  test('Combined filters search suggestions and preserve source', () {
    final filtered = const FeedbackFilter(query: 'PRACTICE', category: 'Task', rating: 2).apply(source);
    expect(filtered.map((r) => r.id), ['b']);
    expect(source.map((r) => r.id), ['a', 'b', 'c']);
  });
  test('Time filter and low-rated sorting use real data', () {
    final list = const FeedbackFilter(period: 'Last 7 days', sort: 'Lowest rated').apply(source, now: DateTime(2026, 10, 4));
    expect(list.map((r) => r.id), ['b', 'a']);
  });
  test('Display-name updates are validated and keep ownership', () async {
    final store = AppStore(demo: true)..enterDemo(false);
    await store.updateName('Saad Jadoon');
    expect(store.name, 'Saad Jadoon');
    expect(store.uid, 'demo-user');
    await expectLater(store.updateName(' '), throwsArgumentError);
    store.dispose();
  });
  test('Store rejects invalid reviews and other-user ownership', () async {
    final store = AppStore(demo: true)..enterDemo(false);
    await expectLater(store.submit(sample('bad', 0, 0)), throwsArgumentError);
    store.enterDemo(true);
    await expectLater(store.submit(sample('other-user', 5, 0)), throwsStateError);
    store.dispose();
  });
}
