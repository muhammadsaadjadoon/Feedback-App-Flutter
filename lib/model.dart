import 'package:cloud_firestore/cloud_firestore.dart';

const categories = ['Task', 'Course', 'Service'];
const statuses = ['New', 'In progress', 'Resolved'];

class Review {
  final String id, userId, author, category, subject, message, suggestion, status, reply;
  final int rating;
  final DateTime createdAt;
  const Review({required this.id, required this.userId, required this.author,
    required this.category, required this.subject, required this.message,
    required this.suggestion, required this.rating, required this.createdAt,
    this.status = 'New', this.reply = ''});
  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Review(id: doc.id, userId: d['userId'] as String,
      author: d['author'] as String, category: d['category'] as String,
      subject: d['subject'] as String, message: d['message'] as String,
      suggestion: d['suggestion'] as String, rating: (d['rating'] as num).toInt(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: d['status'] as String, reply: d['reply'] as String);
  }
  Map<String, dynamic> toMap() => {'userId': userId, 'author': author,
    'category': category, 'subject': subject, 'message': message,
    'suggestion': suggestion, 'rating': rating, 'createdAt': FieldValue.serverTimestamp(),
    'status': 'New', 'reply': ''};
  Review moderated(String status, String reply) => Review(id: id, userId: userId,
    author: author, category: category, subject: subject, message: message,
    suggestion: suggestion, rating: rating, createdAt: createdAt, status: status, reply: reply);
}

class Insights {
  final List<Review> reviews;
  const Insights(this.reviews);
  double get average => reviews.isEmpty ? 0 : reviews.fold<int>(0, (s, r) => s + r.rating) / reviews.length;
  int get resolved => reviews.where((r) => r.status == 'Resolved').length;
  int get positive => reviews.where((r) => r.rating >= 4).length;
  int countRating(int n) => reviews.where((r) => r.rating == n).length;
  String get recommendation {
    if (reviews.isEmpty) { return 'Collect your first review to start finding improvement opportunities.'; }
    final low = reviews.where((r) => r.rating <= 2 && r.status != 'Resolved').length;
    if (low > 0) { return '$low low-rated open review${low == 1 ? '' : 's'} need attention. Read their suggestions and follow up.'; }
    return 'Keep the conversation going. Respond to open feedback and share what improved.';
  }
}
