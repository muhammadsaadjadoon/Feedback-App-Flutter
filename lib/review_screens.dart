import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'design.dart';
import 'helpers.dart';
import 'model.dart';
import 'store.dart';

class ComposeScreen extends StatefulWidget {
  final AppStore store;
  const ComposeScreen({super.key, required this.store});
  @override State<ComposeScreen> createState() => _ComposeScreenState();
}
class _ComposeScreenState extends State<ComposeScreen> {
  final form = GlobalKey<FormState>();
  final subject = TextEditingController(), message = TextEditingController(), suggestion = TextEditingController();
  String category = 'Task';
  int rating = 0, step = 0;
  bool busy = false, submitted = false, allowLeave = false;
  bool get dirty => rating != 0 || subject.text.isNotEmpty || message.text.isNotEmpty || suggestion.text.isNotEmpty;
  @override void dispose() { subject.dispose(); message.dispose(); suggestion.dispose(); super.dispose(); }
  void next() {
    if (!form.currentState!.validate()) { return; }
    if (step == 0 && rating == 0) { notice(context, 'Choose a rating to continue.'); return; }
    FocusScope.of(context).unfocus();
    setState(() => step++);
  }
  Future<void> leave() async {
    if (busy) { return; }
    if (dirty && !submitted) {
      final discard = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Leave this draft?'), content: const Text('Your unsent feedback will be discarded.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep writing')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Discard draft'))]));
      if (discard != true || !mounted) { return; }
    }
    if (!mounted) { return; }
    setState(() => allowLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) { Navigator.pop(context); } });
  }
  Future<void> submit() async {
    if (busy) { return; }
    setState(() => busy = true);
    try {
      await widget.store.submit(Review(id: 'review-${DateTime.now().microsecondsSinceEpoch}', userId: widget.store.uid, author: widget.store.name, category: category, subject: subject.text.trim(), message: message.text.trim(), suggestion: suggestion.text.trim(), rating: rating, createdAt: DateTime.now()));
      if (mounted) { setState(() => submitted = true); }
    } catch (e) { if (mounted) { notice(context, friendlyError(e)); } }
    finally { if (mounted) { setState(() => busy = false); } }
  }
  @override Widget build(BuildContext context) => PopScope<void>(canPop: allowLeave || (!busy && (!dirty || submitted)), onPopInvokedWithResult: (didPop, _) { if (!didPop) { leave(); } }, child: Scaffold(
    appBar: AppBar(leading: IconButton(tooltip: 'Back', onPressed: busy ? null : leave, icon: const Icon(Icons.arrow_back_rounded)), title: const Text('Give feedback', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18))),
    body: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 660), child: submitted ? success() : Form(key: form, child: ListView(padding: const EdgeInsets.fromLTRB(24, 12, 24, 32), children: [
      Row(children: List.generate(3, (i) => Expanded(child: Padding(padding: EdgeInsets.only(right: i < 2 ? 8 : 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 4, decoration: BoxDecoration(color: i <= step ? Studio.green : Studio.line, borderRadius: BorderRadius.circular(10))), const SizedBox(height: 8), Text(['01 · Experience', '02 · Your thoughts', '03 · Review'][i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: i == step ? Studio.green : Studio.muted))]))))),
      const SizedBox(height: 28), Text(['How did it go?', 'Tell us a little more.', 'Ready to be heard?'][step], style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 10), Text(['Choose what you’re reviewing and rate your experience.', 'Specific details help us make meaningful improvements.', 'Take a moment to check your feedback before sending.'][step], style: const TextStyle(color: Studio.muted)), const SizedBox(height: 26),
      if (step == 0) ...experience(),
      if (step == 1) ...thoughts(),
      if (step == 2) ...preview(),
      const SizedBox(height: 24), Row(children: [if (step > 0) ...[OutlinedButton(onPressed: busy ? null : () => setState(() => step--), child: const Text('Back')), const SizedBox(width: 12)], Expanded(child: FilledButton.icon(key: const ValueKey('review-next'), onPressed: busy ? null : step == 2 ? submit : next, icon: Icon(step == 2 ? Icons.send_outlined : Icons.arrow_forward_rounded, size: 18), label: Text(busy ? 'Sending…' : step == 2 ? 'Submit feedback' : 'Continue')))]),
      const SizedBox(height: 16), const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock_outline, size: 14, color: Studio.muted), SizedBox(width: 6), Flexible(child: Text('Only you and authorized admins can read this.', style: TextStyle(fontSize: 11, color: Studio.muted)))]),
    ])))),
  ));
  List<Widget> experience() => [
    const Eyebrow('What is this about?'), const SizedBox(height: 12),
    Wrap(spacing: 10, runSpacing: 10, children: categories.map((c) => ChoiceChip(key: ValueKey('category-$c'), avatar: Icon(categoryIcon(c), size: 18), label: Text(c), selected: category == c, selectedColor: Studio.mint, onSelected: (_) => setState(() => category = c))).toList()),
    const SizedBox(height: 22), TextFormField(key: const ValueKey('review-subject'), controller: subject, maxLength: 120, validator: (v) => requiredText(v, min: 3), onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: '$category name', hintText: 'e.g. Flutter fundamentals')),
    const SizedBox(height: 20), Surface(child: Column(children: [const Eyebrow('Your overall experience'), const SizedBox(height: 16), Stars(rating: rating, onChange: (n) => setState(() => rating = n)), const SizedBox(height: 14), Text(rating == 0 ? 'Tap a star to rate' : ['Disappointing', 'Could be better', 'It was okay', 'Really good', 'Loved it'][rating - 1], style: const TextStyle(fontWeight: FontWeight.w700, color: Studio.green)), const SizedBox(height: 6), const Text('There’s no wrong answer. Be honest.', style: TextStyle(fontSize: 12, color: Studio.muted))])),
  ];
  List<Widget> thoughts() => [
    TextFormField(key: const ValueKey('review-message'), controller: message, minLines: 5, maxLines: 8, maxLength: 2000, validator: (v) => requiredText(v, min: 10), onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Your experience', alignLabelWithHint: true, hintText: 'What worked well? What could we do better?')),
    const SizedBox(height: 18), TextFormField(key: const ValueKey('review-suggestion'), controller: suggestion, minLines: 3, maxLines: 5, maxLength: 1000, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'An idea for improvement (optional)', alignLabelWithHint: true, hintText: 'What would make this better next time?')),
    const SizedBox(height: 12), const Surface(color: Color(0xFFEDF3E9), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.lightbulb_outline, color: Studio.green), SizedBox(width: 12), Expanded(child: Text('A clear example is more helpful than a general statement. Your suggestions help us take action.', style: TextStyle(color: Studio.muted, fontSize: 13)))])),
  ];
  List<Widget> preview() => [Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(categoryIcon(category), color: Studio.green), const SizedBox(width: 10), Eyebrow(category)]), const SizedBox(height: 20), Text(subject.text.trim(), style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12), Stars(rating: rating), const Divider(height: 32), Text(message.text.trim(), style: const TextStyle(height: 1.6)), if (suggestion.text.trim().isNotEmpty) ...[const SizedBox(height: 22), const Eyebrow('Your suggestion'), const SizedBox(height: 8), Text(suggestion.text.trim())], const Divider(height: 32), Text('Submitted as ${widget.store.name}', style: const TextStyle(fontSize: 12, color: Studio.muted)),
  ]))];
  Widget success() => SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(children: [const SizedBox(height: 40), Container(padding: const EdgeInsets.all(28), decoration: const BoxDecoration(color: Studio.mint, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Studio.green, size: 52)), const SizedBox(height: 30), Text('Heard. And appreciated.', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center), const SizedBox(height: 14), const Text('Your feedback has been submitted. Follow its progress and read responses in your inbox.', textAlign: TextAlign.center, style: TextStyle(color: Studio.muted, height: 1.6)), const SizedBox(height: 28), const Surface(child: Row(children: [Icon(Icons.schedule_rounded, color: Studio.green), SizedBox(width: 12), Expanded(child: Text('Status: New\nReady for the team to review.'))])), const SizedBox(height: 24), SizedBox(width: double.infinity, child: FilledButton(onPressed: leave, child: const Text('Back to workspace')))]));
}

class DetailScreen extends StatefulWidget {
  final AppStore store;
  final String reviewId;
  const DetailScreen({super.key, required this.store, required this.reviewId});
  @override State<DetailScreen> createState() => _DetailScreenState();
}
class _DetailScreenState extends State<DetailScreen> {
  late Stream<List<Review>> stream;
  @override void initState() { super.initState(); stream = widget.store.watch(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('The conversation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18))), body: StreamBuilder<List<Review>>(stream: stream, builder: (context, snap) {
    if (snap.hasError) { return Padding(padding: const EdgeInsets.all(24), child: EmptyState(title: 'Could not load feedback', message: friendlyError(snap.error!), action: 'Retry', onTap: () => setState(() => stream = widget.store.watch()))); }
    if (!snap.hasData) { return const Center(child: CircularProgressIndicator()); }
    final matches = snap.data!.where((r) => r.id == widget.reviewId);
    if (matches.isEmpty) { return const Center(child: Text('This feedback is no longer available.')); }
    final r = matches.first;
    return Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: ListView(padding: const EdgeInsets.all(24), children: [
      Row(children: [Expanded(child: Eyebrow(r.category)), StatusPill(status: r.status)]), const SizedBox(height: 18), Text(r.subject, style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 14), Stars(rating: r.rating), const SizedBox(height: 22),
      Row(children: [CircleAvatar(backgroundColor: Studio.mint, radius: 20, child: Text(initials(r.author), style: const TextStyle(fontSize: 12, color: Studio.green, fontWeight: FontWeight.w800))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.author, style: const TextStyle(fontWeight: FontWeight.w700)), Text(DateFormat('MMM d, yyyy · h:mm a').format(r.createdAt), style: const TextStyle(color: Studio.muted, fontSize: 11))])), IconButton(tooltip: 'Copy feedback', onPressed: () async { await Clipboard.setData(ClipboardData(text: '${r.subject}\n${r.rating}/5 · ${r.category}\n${r.message}\n${r.suggestion}\nStatus: ${r.status}\n${r.reply}')); if (context.mounted) { notice(context, 'Feedback copied.'); } }, icon: const Icon(Icons.copy_outlined, size: 19))]),
      const SizedBox(height: 24), Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Eyebrow('The experience'), const SizedBox(height: 14), SelectableText(r.message, style: const TextStyle(height: 1.7, fontSize: 16)), if (r.suggestion.isNotEmpty) ...[const Divider(height: 36), const Eyebrow('Idea for improvement'), const SizedBox(height: 14), SelectableText(r.suggestion, style: const TextStyle(height: 1.6))]])),
      const SectionTitle('Progress'), Surface(child: Column(children: [progressRow('Submitted', DateFormat.yMMMd().format(r.createdAt), true), const SizedBox(height: 18), progressRow('Team review', r.status == 'New' ? 'Waiting for review' : 'The team has reviewed this feedback', r.status != 'New'), const SizedBox(height: 18), progressRow('Resolved', r.status == 'Resolved' ? 'Marked resolved by the team' : 'We’ll keep you updated here', r.status == 'Resolved')])),
      const SectionTitle('Team response'), Surface(color: r.reply.isEmpty ? Colors.white : const Color(0xFFEDF3E9), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(r.reply.isEmpty ? Icons.chat_bubble_outline : Icons.mark_chat_read_outlined, color: Studio.green), const SizedBox(width: 10), Expanded(child: Text(r.reply.isEmpty ? 'No response yet' : 'From your workspace team', style: const TextStyle(fontWeight: FontWeight.w700)))]), const SizedBox(height: 12), SelectableText(r.reply.isEmpty ? 'You’ll see a reply here when the team responds.' : r.reply, style: const TextStyle(height: 1.6))])),
      if (widget.store.admin) ...[const SectionTitle('Administrator controls'), ModerationForm(key: ValueKey('${r.id}-${r.status}-${r.reply}'), store: widget.store, review: r)],
      const SizedBox(height: 30),
    ])));
  }));
  Widget progressRow(String title, String subtitle, bool done) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: done ? Studio.green : Studio.muted, size: 21), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: Studio.muted, fontSize: 12))]))]);
}
class ModerationForm extends StatefulWidget {
  final AppStore store;
  final Review review;
  const ModerationForm({super.key, required this.store, required this.review});
  @override State<ModerationForm> createState() => _ModerationFormState();
}
class _ModerationFormState extends State<ModerationForm> {
  late String status;
  late TextEditingController reply;
  bool busy = false;
  @override void initState() { super.initState(); status = widget.review.status; reply = TextEditingController(text: widget.review.reply); }
  @override void dispose() { reply.dispose(); super.dispose(); }
  Future<void> save() async {
    if (busy) { return; }
    setState(() => busy = true);
    try { await widget.store.moderate(widget.review, status, reply.text); if (mounted) { notice(context, 'Response and status updated.'); } }
    catch (e) { if (mounted) { notice(context, friendlyError(e)); } }
    finally { if (mounted) { setState(() => busy = false); } }
  }
  @override Widget build(BuildContext context) => Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Eyebrow('Update status'), const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: statuses.map((s) => ChoiceChip(label: Text(s), selected: status == s, onSelected: busy ? null : (_) => setState(() => status = s), selectedColor: Studio.mint)).toList()), const SizedBox(height: 22),
    TextField(key: const ValueKey('admin-reply'), controller: reply, enabled: !busy, minLines: 3, maxLines: 6, maxLength: 2000, decoration: const InputDecoration(labelText: 'Your response', alignLabelWithHint: true, hintText: 'Acknowledge their experience and share next steps.')), const SizedBox(height: 14), FilledButton.icon(key: const ValueKey('admin-save'), onPressed: busy ? null : save, icon: const Icon(Icons.check_rounded), label: Text(busy ? 'Saving…' : 'Save response & status')),
  ]));
}
