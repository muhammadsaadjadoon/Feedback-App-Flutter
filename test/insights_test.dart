import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_studio/model.dart';
Review review(int rating, {String status = 'New'}) => Review(id: '$rating', userId: 'u', author: 'User', category: 'Task', subject: 'Example task', message: 'Useful experience', suggestion: '', rating: rating, createdAt: DateTime(2026), status: status);
void main() {
  test('Empty analytics has no division by zero and prompts collection', () {
    const s = Insights([]);
    expect(s.average, 0); expect(s.resolved, 0); expect(s.positive, 0);
    expect(s.recommendation, contains('first review'));
  });
  test('Mixed ratings calculate average, distribution, and unresolved priority', () {
    final s = Insights([review(5), review(4), review(1), review(2, status: 'Resolved')]);
    expect(s.average, 3); expect(s.positive, 2); expect(s.resolved, 1);
    expect(s.countRating(5), 1); expect(s.recommendation, startsWith('1 low-rated open review'));
  });
  test('Resolving a low review removes it from priority advice', () {
    final original = review(1);
    final updated = original.moderated('Resolved', 'We fixed it.');
    expect(original.status, 'New'); expect(updated.rating, 1);
    expect(updated.reply, 'We fixed it.');
    expect(Insights([updated]).recommendation, contains('conversation'));
  });
}
