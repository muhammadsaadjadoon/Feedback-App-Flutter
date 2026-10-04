import 'model.dart';
class FeedbackFilter {
  final String query, category, status, sort, period;
  final int? rating;
  const FeedbackFilter({this.query = '', this.category = 'All', this.status = 'All', this.sort = 'Newest first', this.period = 'All time', this.rating});
  List<Review> apply(List<Review> source, {DateTime? now}) {
    final cutoff = period == 'Last 7 days' ? (now ?? DateTime.now()).subtract(const Duration(days: 7)) : period == 'Last 30 days' ? (now ?? DateTime.now()).subtract(const Duration(days: 30)) : null;
    final result = source.where((r) => (category == 'All' || r.category == category) && (status == 'All' || r.status == status)
      && (rating == null || r.rating == rating) && (cutoff == null || !r.createdAt.isBefore(cutoff))
      && '${r.author} ${r.subject} ${r.message} ${r.suggestion}'.toLowerCase().contains(query.trim().toLowerCase())).toList();
    result.sort((a, b) {
      final primary = sort == 'Lowest rated' ? a.rating.compareTo(b.rating) : sort == 'Highest rated' ? b.rating.compareTo(a.rating) : sort == 'Oldest first' ? a.createdAt.compareTo(b.createdAt) : b.createdAt.compareTo(a.createdAt);
      return primary == 0 ? b.createdAt.compareTo(a.createdAt) : primary;
    });
    return result;
  }
}
