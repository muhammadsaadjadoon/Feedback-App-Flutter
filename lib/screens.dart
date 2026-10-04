import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'design.dart';
import 'helpers.dart';
import 'model.dart';
import 'store.dart';
import 'filters.dart';
import 'review_screens.dart';
import 'profile_screen.dart';
export 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppStore store;
  const HomeScreen({super.key, required this.store});
  @override State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  late Stream<List<Review>> stream;
  final search = TextEditingController();
  int page = 0, inboxLimit = 20;
  String category = 'All', status = 'All', sort = 'Newest first', period = 'All time';
  int? rating;
  @override void initState() { super.initState(); stream = widget.store.watch(); }
  @override void dispose() { search.dispose(); super.dispose(); }
  void refresh() => setState(() => stream = widget.store.watch());
  void compose() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ComposeScreen(store: widget.store)));
  void details(Review r) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DetailScreen(store: widget.store, reviewId: r.id)));
  void clearFilters() => setState(() { category = 'All'; status = 'All'; rating = null; period = 'All time'; search.clear(); });
  @override Widget build(BuildContext context) {
    final admin = widget.store.admin;
    final labels = ['Home', admin ? 'Inbox' : 'My feedback', 'Insights', 'Account'];
    return LayoutBuilder(builder: (context, size) {
      final wide = size.maxWidth >= 850;
      return Scaffold(
        appBar: AppBar(toolbarHeight: 72, title: const Brand(), actions: [
          if (widget.store.demo) const Padding(padding: EdgeInsets.only(right: 8), child: Chip(label: Text('DEMO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)), side: BorderSide.none)),
          Padding(padding: const EdgeInsets.only(right: 16), child: IconButton(tooltip: 'Your account', onPressed: () => setState(() => page = 3), icon: ProfileAvatar(store: widget.store, radius: 18))),
        ]),
        body: Row(children: [
          if (wide) NavigationRail(selectedIndex: page, onDestinationSelected: (i) => setState(() => page = i), labelType: NavigationRailLabelType.all, backgroundColor: Studio.paper, indicatorColor: Studio.mint,
            destinations: List.generate(4, (i) => NavigationRailDestination(icon: Icon([Icons.grid_view_rounded, Icons.forum_outlined, Icons.bar_chart_rounded, Icons.person_outline][i]), label: Text(labels[i])))),
          Expanded(child: StreamBuilder<List<Review>>(stream: stream, builder: (context, snapshot) {
            if (snapshot.hasError) { return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyState(title: 'Let’s reconnect', message: friendlyError(snapshot.error!), action: 'Try again', onTap: refresh, icon: Icons.cloud_off_outlined))); }
            if (!snapshot.hasData) { return const Center(child: CircularProgressIndicator()); }
            final reviews = snapshot.data!;
            return Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1080), child: ListView(key: ValueKey('page-$page'), padding: const EdgeInsets.fromLTRB(22, 12, 22, 104), children: [
              if (page == 0) ...overview(reviews),
              if (page == 1) ...inbox(reviews),
              if (page == 2) ...insights(reviews),
              if (page == 3) ...account(reviews),
            ])));
          })),
        ]),
        floatingActionButton: page < 2 ? FloatingActionButton.extended(key: const ValueKey('compose'), backgroundColor: Studio.ink, foregroundColor: Studio.mint, elevation: 2, onPressed: compose, icon: const Icon(Icons.add_rounded), label: const Text('Give feedback')) : null,
        bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: page, onDestinationSelected: (i) => setState(() => page = i), destinations: List.generate(4, (i) => NavigationDestination(key: ValueKey('nav-$i'), icon: Icon([Icons.grid_view_outlined, Icons.forum_outlined, Icons.bar_chart_rounded, Icons.person_outline][i]), selectedIcon: Icon([Icons.grid_view_rounded, Icons.forum_rounded, Icons.bar_chart_rounded, Icons.person_rounded][i]), label: labels[i]))),
      );
    });
  }
  Widget pageTitle(String title, String subtitle) => Padding(padding: const EdgeInsets.only(bottom: 22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 8), Text(subtitle, style: const TextStyle(color: Studio.muted))]));
  List<Widget> overview(List<Review> reviews) {
    final admin = widget.store.admin;
    final open = reviews.where((r) => r.status != 'Resolved').length;
    final replies = reviews.where((r) => r.reply.isNotEmpty).length;
    return [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Eyebrow(admin ? 'Administrator workspace' : 'Your personal workspace'), const SizedBox(height: 8), Text('Hello, ${widget.store.name.split(' ').first} 👋', style: Theme.of(context).textTheme.headlineMedium)])), IconButton(tooltip: 'Refresh feedback', onPressed: refresh, icon: const Icon(Icons.refresh_rounded))]),
      const SizedBox(height: 22),
      Container(padding: const EdgeInsets.all(26), decoration: BoxDecoration(color: Studio.ink, borderRadius: BorderRadius.circular(28)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Flexible(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(30)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.circle, size: 6, color: Studio.mint), const SizedBox(width: 7), Flexible(child: Text(widget.store.demo ? 'Sample workspace' : 'Firebase workspace', style: const TextStyle(color: Studio.mint, fontSize: 11)))]))), const SizedBox(width: 8), const Icon(Icons.north_east_rounded, color: Studio.mint)]),
        const SizedBox(height: 22), Text(admin ? 'Listen closely.\nMake things better.' : 'Your experience.\nOur next improvement.', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -.9, height: 1.15)),
        const SizedBox(height: 12), Text(admin ? '$open open conversations are waiting for your attention.' : 'Share what worked. Tell us what didn’t.\nWe’re here to listen.', style: const TextStyle(color: Color(0xFFC4D3CB), height: 1.6)),
        const SizedBox(height: 22), FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: Studio.mint, foregroundColor: Studio.ink), onPressed: admin ? () => setState(() { page = 1; status = 'All'; }) : compose, icon: const Icon(Icons.arrow_forward_rounded, size: 18), label: Text(admin ? 'Open feedback inbox' : 'Share an experience')),
      ])),
      const SizedBox(height: 18), metricGrid(Insights(reviews)),
      const SectionTitle('Your next step'), Surface(color: const Color(0xFFEDF3E9), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.tips_and_updates_outlined, color: Studio.green), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(admin ? 'Close the loop' : replies > 0 ? 'You’ve heard back' : 'Keep the conversation moving', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 5), Text(admin ? Insights(reviews).recommendation : replies > 0 ? '$replies of your reviews have a response. Open your inbox to read what’s changed.' : 'Your honest feedback helps the team understand what matters.', style: const TextStyle(fontSize: 13, color: Studio.muted))]))])),
      SectionTitle('Recent feedback', action: 'View all →', onTap: () => setState(() => page = 1)),
      if (reviews.isEmpty) EmptyState(title: 'A fresh conversation', message: 'Your first review is the start of something better.', onTap: compose) else ...reviews.take(3).map(reviewCard),
    ];
  }
  Widget metricGrid(Insights stats) => LayoutBuilder(builder: (context, c) {
    final cols = c.maxWidth > 680 ? 4 : 2;
    final width = (c.maxWidth - (cols - 1) * 12) / cols;
    final values = ['${stats.reviews.length}', stats.reviews.isEmpty ? '—' : stats.average.toStringAsFixed(1), '${stats.reviews.length - stats.resolved}', '${stats.resolved}'];
    final names = ['Total reviews', 'Average rating', 'Open feedback', 'Resolved'];
    final icons = [Icons.forum_outlined, Icons.star_outline_rounded, Icons.schedule_rounded, Icons.task_alt_rounded];
    return Wrap(spacing: 12, runSpacing: 12, children: List.generate(4, (i) => SizedBox(width: width, child: Surface(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icons[i], size: 21, color: Studio.green), const SizedBox(height: 16), Text(values[i], style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w800, color: Studio.ink, letterSpacing: -1)), const SizedBox(height: 2), Text(names[i], style: const TextStyle(fontSize: 12, color: Studio.muted))])))));
  });
  Widget reviewCard(Review r) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Material(color: Colors.white, borderRadius: BorderRadius.circular(22), child: InkWell(key: ValueKey('review-${r.id}'), borderRadius: BorderRadius.circular(22), onTap: () => details(r), child: Container(padding: const EdgeInsets.all(19), decoration: BoxDecoration(border: Border.all(color: Studio.line), borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: Studio.paper, borderRadius: BorderRadius.circular(10)), child: Icon(categoryIcon(r.category), size: 18, color: Studio.green)), const SizedBox(width: 10), Expanded(child: Eyebrow(r.category)), StatusPill(status: r.status)]),
    const SizedBox(height: 15), Text(r.subject, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Studio.ink, letterSpacing: -.3)), const SizedBox(height: 7), Text(r.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Studio.muted, fontSize: 13, height: 1.5)),
    const SizedBox(height: 15), Stars(rating: r.rating), const Divider(height: 26), Row(children: [CircleAvatar(radius: 12, backgroundColor: const Color(0xFFE8EEE2), child: Text(initials(r.author), style: const TextStyle(fontSize: 8, color: Studio.green, fontWeight: FontWeight.w800))), const SizedBox(width: 7), Expanded(child: Text(r.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))), Text(DateFormat.MMMd().format(r.createdAt), style: const TextStyle(fontSize: 11, color: Studio.muted)), const SizedBox(width: 8), Icon(r.reply.isEmpty ? Icons.chevron_right_rounded : Icons.reply_rounded, color: Studio.green, size: 17)]),
  ])))));
  List<Widget> inbox(List<Review> reviews) {
    final filtered = FeedbackFilter(query: search.text, category: category, status: status, rating: rating, sort: sort, period: period).apply(reviews);
    final active = category != 'All' || rating != null || period != 'All time';
    return [pageTitle(widget.store.admin ? 'Feedback inbox' : 'My feedback', 'Every conversation, all in one place.'),
      Row(children: [Expanded(child: TextField(controller: search, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: 'Search experiences…', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: search.text.isEmpty ? null : IconButton(tooltip: 'Clear search', onPressed: () => setState(search.clear), icon: const Icon(Icons.close_rounded))))), const SizedBox(width: 10), IconButton.filledTonal(tooltip: 'Filter feedback', onPressed: filterSheet, icon: Icon(active ? Icons.filter_alt : Icons.tune_rounded))]),
      const SizedBox(height: 18), Wrap(spacing: 8, runSpacing: 8, children: ['All', ...statuses].map((s) => ChoiceChip(label: Text(s), selected: status == s, selectedColor: Studio.mint, side: const BorderSide(color: Studio.line), onSelected: (_) => setState(() => status = s))).toList()),
      const SizedBox(height: 12), Row(children: [Expanded(child: Text('${filtered.length} conversation${filtered.length == 1 ? '' : 's'}', style: const TextStyle(color: Studio.muted, fontSize: 12))), PopupMenuButton<String>(tooltip: 'Sort feedback', initialValue: sort, onSelected: (v) => setState(() => sort = v), itemBuilder: (_) => ['Newest first', 'Oldest first', 'Lowest rated', 'Highest rated'].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(), child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(sort, style: const TextStyle(color: Studio.green, fontSize: 12, fontWeight: FontWeight.w700)), const Icon(Icons.expand_more, size: 17)])))]),
      if (active) ...[Wrap(spacing: 8, runSpacing: 8, children: [if (category != 'All') Chip(label: Text(category), onDeleted: () => setState(() => category = 'All')), if (rating != null) Chip(label: Text('$rating stars'), onDeleted: () => setState(() => rating = null)), if (period != 'All time') Chip(label: Text(period), onDeleted: () => setState(() => period = 'All time')), TextButton(onPressed: clearFilters, child: const Text('Reset'))]), const SizedBox(height: 12)],
      if (filtered.isEmpty) EmptyState(title: reviews.isEmpty ? 'Your voice belongs here' : 'No matching conversations', message: reviews.isEmpty ? 'Share your first experience to get started.' : 'Try another search or reset your filters.', action: reviews.isEmpty ? 'Give feedback' : 'Reset filters', onTap: reviews.isEmpty ? compose : clearFilters) else ...filtered.take(inboxLimit).map(reviewCard),
      if (filtered.length > inboxLimit) OutlinedButton(onPressed: () => setState(() => inboxLimit += 20), child: Text('Show more (${filtered.length - inboxLimit} remaining')),
    ];
  }
  Future<void> filterSheet() async {
    var nextCategory = category, nextPeriod = period; int? nextRating = rating;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: Studio.paper, builder: (c) => StatefulBuilder(builder: (c, local) => SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Text('Refine your inbox', style: Theme.of(c).textTheme.titleLarge)), IconButton(tooltip: 'Close filters', onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close))]),
      const SizedBox(height: 20), const Eyebrow('Category'), const SizedBox(height: 10), Wrap(spacing: 8, children: ['All', ...categories].map((v) => ChoiceChip(label: Text(v), selected: nextCategory == v, onSelected: (_) => local(() => nextCategory = v))).toList()),
      const SizedBox(height: 20), const Eyebrow('Rating'), const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: [ChoiceChip(label: const Text('Any'), selected: nextRating == null, onSelected: (_) => local(() => nextRating = null)), ...List.generate(5, (i) => ChoiceChip(label: Text('${i + 1} ★'), selected: nextRating == i + 1, onSelected: (_) => local(() => nextRating = i + 1)))]),
      const SizedBox(height: 20), const Eyebrow('Time period'), const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: ['All time', 'Last 7 days', 'Last 30 days'].map((v) => ChoiceChip(label: Text(v), selected: nextPeriod == v, onSelected: (_) => local(() => nextPeriod = v))).toList()),
      const SizedBox(height: 26), FilledButton(onPressed: () { setState(() { category = nextCategory; rating = nextRating; period = nextPeriod; }); Navigator.pop(c); }, child: const Text('Apply filters')),
    ])))));
  }
  List<Widget> insights(List<Review> source) {
    final reviews = FeedbackFilter(period: period).apply(source);
    final stats = Insights(reviews);
    return [pageTitle('The bigger picture', widget.store.admin ? 'Understand your community. Find your next improvement.' : 'A clearer view of the experiences you’ve shared.'),
      Wrap(spacing: 8, runSpacing: 8, children: ['All time', 'Last 7 days', 'Last 30 days'].map((v) => ChoiceChip(label: Text(v), selected: period == v, onSelected: (_) => setState(() => period = v))).toList()), const SizedBox(height: 18),
      Surface(child: Column(children: [const Eyebrow('Overall experience'), const SizedBox(height: 22), RatingRing(stats: stats), const SizedBox(height: 16), Text('${stats.reviews.length} reviews in this period', style: const TextStyle(color: Studio.muted)), const SizedBox(height: 8), Text(stats.reviews.isEmpty ? 'Waiting for your first review' : '${(stats.positive * 100 / stats.reviews.length).round()}% rated their experience 4 or 5 stars', style: const TextStyle(fontSize: 12, color: Studio.green, fontWeight: FontWeight.w700))])),
      const SectionTitle('How people rated'), Surface(child: Column(children: [for (var n = 5; n >= 1; n--) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [SizedBox(width: 34, child: Text('$n ★', style: const TextStyle(fontWeight: FontWeight.w700))), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: reviews.isEmpty ? 0 : stats.countRating(n) / reviews.length, minHeight: 9, color: Studio.green, backgroundColor: Studio.paper))), SizedBox(width: 35, child: Text('${stats.countRating(n)}', textAlign: TextAlign.right, style: const TextStyle(color: Studio.muted)))]))])),
      const SectionTitle('Conversations by category'), Surface(child: Column(children: categories.map((cat) {
        final list = reviews.where((r) => r.category == cat).toList();
        return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [Icon(categoryIcon(cat), color: Studio.green), const SizedBox(width: 12), Expanded(child: Text(cat, style: const TextStyle(fontWeight: FontWeight.w700))), Text('${list.length} reviews', style: const TextStyle(color: Studio.muted, fontSize: 12)), const SizedBox(width: 12), Text(list.isEmpty ? '—' : '${Insights(list).average.toStringAsFixed(1)} ★', style: const TextStyle(fontWeight: FontWeight.w700))]));
      }).toList())),
      const SizedBox(height: 18), OutlinedButton.icon(onPressed: () => copyReport(reviews), icon: const Icon(Icons.copy_outlined, size: 17), label: const Text('Copy feedback report')),
      const SectionTitle('Closing the loop'), Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${stats.resolved} of ${reviews.length} resolved', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: reviews.isEmpty ? 0 : stats.resolved / reviews.length, minHeight: 10, color: Studio.green, backgroundColor: Studio.paper)), const SizedBox(height: 16), Text(stats.recommendation, style: const TextStyle(color: Studio.muted, fontSize: 13))])),
    ];
  }
  List<Widget> account(List<Review> reviews) => [pageTitle('Your space', 'Account details, responses, and workspace information.'),
    Surface(child: Column(children: [ProfileAvatar(store: widget.store, radius: 34), const SizedBox(height: 14), Text(widget.store.name, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 6), Text(widget.store.accountEmail, style: const TextStyle(color: Studio.muted, fontSize: 12)), const SizedBox(height: 8), StatusPill(status: widget.store.admin ? 'Administrator' : 'Member'), const SizedBox(height: 12), Text(widget.store.demo ? 'Demo account · sample data' : 'Firebase workspace account', style: const TextStyle(fontSize: 12, color: Studio.muted))])),
    const SizedBox(height: 12), OutlinedButton.icon(onPressed: editName, icon: const Icon(Icons.edit_outlined, size: 17), label: const Text('Profile settings')),
    const SectionTitle('Responses & updates'),
    if (reviews.where((r) => r.reply.isNotEmpty).isEmpty) const Surface(child: Text('Replies to your feedback will appear here.', style: TextStyle(color: Studio.muted))) else ...reviews.where((r) => r.reply.isNotEmpty).take(5).map((r) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Surface(child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.mark_chat_read_outlined, color: Studio.green), title: Text(r.subject, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(r.reply, maxLines: 2, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.chevron_right), onTap: () => details(r))))),
    const SectionTitle('Workspace'), Surface(child: Column(children: [const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.lock_outline, color: Studio.green), title: Text('Private by design'), subtitle: Text('Members see their own feedback. Authorized admins manage the workspace.')), const Divider(), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.info_outline, color: Studio.green), title: const Text('Your workspace'), subtitle: Text(widget.store.demo ? 'Demo changes reset when you restart.' : 'Reviews and responses synchronize with your Firebase project.'))])),
    const SizedBox(height: 24), OutlinedButton.icon(onPressed: signOut, icon: const Icon(Icons.logout_rounded), label: const Text('Sign out')),
  ];
  Future<void> copyReport(List<Review> reviews) async {
    String quote(String v) => '"${v.replaceAll('"', '""')}"';
    final rows = [
      ['Category', 'Subject', 'Rating', 'Status', 'Author', 'Created', 'Review', 'Suggestion', 'Response'],
      ...reviews.map((r) => [r.category, r.subject, '${r.rating}', r.status, r.author, r.createdAt.toIso8601String(), r.message, r.suggestion, r.reply]),
    ];
    await Clipboard.setData(ClipboardData(text: rows.map((row) => row.map(quote).join(',')).join('\n')));
    if (mounted) { notice(context, 'Report copied as CSV. Paste it into a file or spreadsheet.'); }
  }
  Future<void> editName() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProfileScreen(store: widget.store)));
  }
  Future<void> signOut() async {
    final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Sign out?'), content: const Text('You can sign back in whenever you’re ready.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Stay here')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sign out'))]));
    if (confirmed != true) { return; }
    try { await widget.store.signOut(); } catch (e) { if (mounted) { notice(context, friendlyError(e)); } }
  }
}
