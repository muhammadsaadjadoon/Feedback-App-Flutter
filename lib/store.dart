import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'model.dart';
import 'profile_data.dart';

class AppStore extends ChangeNotifier {
  final bool demo;
  AppStore({required this.demo}) {
    if (demo) { _seed(); } else {
      _authSub = FirebaseAuth.instance.idTokenChanges().listen((user) async {
        if (_creating || _disposed) { return; }
        final generation = ++_generation;
        if (user == null) { uid = ''; name = ''; admin = false; }
        else {
          uid = user.uid;
          final display = user.displayName ?? user.email?.split('@').first ?? 'Member';
          name = display.length > 80 ? display.substring(0, 80) : display;
          try {
            final token = await user.getIdTokenResult();
            if (generation != _generation || _disposed) { return; }
            admin = token.claims?['admin'] == true;
          } catch (_) { if (generation != _generation || _disposed) { return; } admin = false; }
        }
        if (generation == _generation && !_disposed) { _watchProfile(); notifyListeners(); }
      });
    }
  }
  StreamSubscription<User?>? _authSub;
  int _generation = 0;
  bool _creating = false, _disposed = false;
  String uid = '', name = '';
  ProfileData profile = const ProfileData();
  String? profileError;
  bool profileLoading = false;
  String _profileUid = '';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  final Map<String, ProfileData> _demoProfiles = {};
  final Map<String, String> _demoNames = {};
  bool get emailVerified => !demo && FirebaseAuth.instance.currentUser?.emailVerified == true;
  bool admin = false;
  final List<Review> _reviews = [];
  final _changes = StreamController<List<Review>>.broadcast();
  bool get signedIn => uid.isNotEmpty;
  String get accountEmail => demo ? 'Demo account' : FirebaseAuth.instance.currentUser?.email ?? '';
  Future<void> updateName(String value) async {
    final trimmed = value.trim();
    if (!signedIn || trimmed.length < 2 || trimmed.length > 80) { throw ArgumentError('Use a name between 2 and 80 characters.'); }
    if (!demo) { await FirebaseAuth.instance.currentUser!.updateDisplayName(trimmed); }
    name = trimmed;
    if (demo) { _demoNames[uid] = trimmed; }
    if (!_disposed) { notifyListeners(); }
  }
  void _watchProfile({bool force = false}) {
    if (!force && _profileUid == uid) { return; }
    _profileSub?.cancel();
    _profileUid = uid;
    profileError = null;
    profile = demo ? (_demoProfiles[uid] ?? const ProfileData()) : const ProfileData();
    profileLoading = !demo && signedIn;
    if (demo || !signedIn) { return; }
    final watchedUid = uid;
    _profileSub = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((doc) {
      if (_disposed || uid != watchedUid) { return; }
      profile = ProfileData.fromMap(doc.data() ?? {});
      profileLoading = false;
      profileError = null;
      notifyListeners();
    }, onError: (Object error) {
      if (_disposed || uid != watchedUid) { return; }
      profileLoading = false;
      profileError = 'Profile could not load. Check your connection and deploy the new profile rules.';
      notifyListeners();
    });
  }
  void reloadProfile() { _watchProfile(force: true); notifyListeners(); }
  Future<void> saveProfile(String displayName, ProfileData next) async {
    if (!signedIn || !next.valid || displayName.trim().length < 2 || displayName.trim().length > 80) {
      throw ArgumentError('Invalid profile details.');
    }
    if (demo) { _demoProfiles[uid] = next; }
    else { await FirebaseFirestore.instance.collection('users').doc(uid).set(next.toMap()); }
    profile = next;
    profileError = null;
    if (name != displayName.trim()) { await updateName(displayName); }
    if (!_disposed) { notifyListeners(); }
  }
  Future<void> sendVerification() async {
    if (demo || !signedIn) { throw StateError('A real account is required.'); }
    await FirebaseAuth.instance.currentUser!.sendEmailVerification();
  }
  Future<void> refreshAccount() async {
    if (demo || !signedIn) { return; }
    await FirebaseAuth.instance.currentUser!.reload();
    if (!_disposed) { notifyListeners(); }
  }
  Future<void> changeCredentials({required String currentPassword, String? newEmail, String? newPassword}) async {
    if (demo || !signedIn) { throw StateError('A real account is required.'); }
    final user = FirebaseAuth.instance.currentUser!;
    final email = user.email;
    if (email == null) { throw StateError('An email/password account is required.'); }
    await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: email, password: currentPassword));
    if (newEmail != null) { await user.verifyBeforeUpdateEmail(newEmail.trim()); }
    if (newPassword != null) {
      if (newPassword.length < 8) { throw ArgumentError('Password must have at least 8 characters.'); }
      await user.updatePassword(newPassword);
    }
  }
  Future<void> signIn(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.trim(), password: password);
  }
  Future<void> register(String displayName, String email, String password) async {
    _creating = true;
    _generation++;
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.trim(), password: password);
      await result.user!.updateDisplayName(displayName.trim());
    } finally {
      _creating = false;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !_disposed) {
        final token = await user.getIdTokenResult();
        if (!_disposed) {
          uid = user.uid;
          name = user.displayName ?? displayName.trim();
          admin = token.claims?['admin'] == true;
          _watchProfile();
          notifyListeners();
        }
      }
    }
  }
  Future<void> resetPassword(String email) => FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  void enterDemo(bool asAdmin) { uid = asAdmin ? 'demo-admin' : 'demo-user'; name = _demoNames[uid] ?? (asAdmin ? 'Alex Morgan' : 'Saadi'); admin = asAdmin; _watchProfile(); notifyListeners(); }
  Future<void> signOut() async {
    if (!demo) { await FirebaseAuth.instance.signOut(); }
    uid = ''; name = ''; admin = false; _watchProfile(); notifyListeners();
  }
  Stream<List<Review>> watch() {
    if (!signedIn) { return Stream.value(const <Review>[]); }
    if (demo) { return _demoWatch(); }
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('feedback');
    if (!admin) { q = q.where('userId', isEqualTo: uid); }
    return q.snapshots().map((snapshot) {
      final list = snapshot.docs.map(Review.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); return list;
    });
  }
  List<Review> _visible() => _reviews.where((r) => admin || r.userId == uid).toList()..sort((a,b) => b.createdAt.compareTo(a.createdAt));
  Stream<List<Review>> _demoWatch() async* { yield _visible(); yield* _changes.stream.map((_) => _visible()); }
  Future<void> submit(Review review) async {
    if (!signedIn || review.userId != uid) { throw StateError('Sign in to submit your own feedback.'); }
    if (!categories.contains(review.category) || review.rating < 1 || review.rating > 5
        || review.subject.trim().length < 3 || review.subject.length > 120
        || review.message.trim().length < 10 || review.message.length > 2000
        || review.suggestion.length > 1000 || review.author.trim().isEmpty || review.author.length > 80) {
      throw ArgumentError('Feedback does not meet the required limits.');
    }
    if (demo) { _reviews.add(review); _changes.add(_visible()); }
    else { await FirebaseFirestore.instance.collection('feedback').add(review.toMap()); }
  }
  Future<void> moderate(Review review, String status, String reply) async {
    if (!admin) { throw StateError('Administrator access required.'); }
    if (!statuses.contains(status) || reply.trim().length > 2000) { throw ArgumentError('Invalid response or status.'); }
    if (demo) {
      final i = _reviews.indexWhere((r) => r.id == review.id);
      if (i < 0) { throw StateError('Feedback no longer exists.'); }
      _reviews[i] = review.moderated(status, reply.trim()); _changes.add(_visible());
    } else {
      await FirebaseFirestore.instance.collection('feedback').doc(review.id).update({'status': status, 'reply': reply.trim()});
    }
  }
  void _seed() {
    final examples = [
      ('demo-user', 'Saadi', 'Course', 'Flutter essentials', 'The practical examples made state management much easier to understand.', 'Add a short practice exercise after each lesson.', 5, 'Resolved', 'Thanks! Practice exercises are now part of the lesson plan.'),
      ('maria', 'Maria Lewis', 'Service', 'Internship support', 'The team was helpful, but it took two days to hear back.', 'A response-time estimate would help.', 3, 'In progress', 'We are reviewing our support response times.'),
      ('james', 'James Carter', 'Task', 'REST API integration', 'Clear requirements and a useful real-world challenge.', 'Include an example JSON response.', 5, 'New', ''),
      ('demo-user', 'Saadi', 'Task', 'Weekly assignment', 'The submission instructions were hard to find on mobile.', 'Place the deadline next to the submit button.', 2, 'New', ''),
      ('emma', 'Emma Wilson', 'Course', 'Dart fundamentals', 'Good explanations and a friendly pace for beginners.', '', 4, 'New', ''),
    ];
    for (var i = 0; i < examples.length; i++) {
      final e = examples[i];
      _reviews.add(Review(id: 'sample-$i', userId: e.$1, author: e.$2, category: e.$3,
        subject: e.$4, message: e.$5, suggestion: e.$6, rating: e.$7,
        status: e.$8, reply: e.$9, createdAt: DateTime.now().subtract(Duration(hours: i * 9))));
    }
  }
  @override void dispose() { _disposed = true; _generation++; _authSub?.cancel(); _profileSub?.cancel(); _changes.close(); super.dispose(); }
}
