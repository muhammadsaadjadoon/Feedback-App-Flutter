import 'package:flutter/material.dart';
import 'model.dart';

class Studio {
  static const ink = Color(0xFF182C2A);
  static const green = Color(0xFF216658);
  static const mint = Color(0xFFCDF1D5);
  static const paper = Color(0xFFF7F8F3);
  static const muted = Color(0xFF74807A);
  static const line = Color(0xFFE6EAE2);
  static ThemeData theme() => ThemeData(
    useMaterial3: true, scaffoldBackgroundColor: paper,
    colorScheme: ColorScheme.fromSeed(seedColor: green, primary: green, surface: Colors.white),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 34, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -1.3, color: ink),
      headlineMedium: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -.8, color: ink),
      titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -.4, color: ink),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: ink),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: muted),
    ),
    appBarTheme: const AppBarTheme(backgroundColor: paper, surfaceTintColor: Colors.transparent, foregroundColor: ink, centerTitle: false),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: green, width: 1.5)),
      labelStyle: const TextStyle(color: muted),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 54), textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(48, 50), side: const BorderSide(color: line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: Colors.white, indicatorColor: mint, labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(fontSize: 11, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500, color: ink))),
    dividerTheme: const DividerThemeData(color: line),
  );
}

class Surface extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  const Surface({super.key, required this.child, this.color = Colors.white, this.padding = const EdgeInsets.all(20)});
  @override Widget build(BuildContext context) => SizedBox(width: double.infinity, child: Material(
    color: color, clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Studio.line)),
    child: Padding(padding: padding, child: child)));
}
class Brand extends StatelessWidget {
  final bool light;
  const Brand({super.key, this.light = false});
  @override Widget build(BuildContext context) => Semantics(label: 'App logo', image: true,
    child: Image.asset('assets/branding/logo.png', width: 52, height: 52, fit: BoxFit.contain, cacheWidth: 156));
}
class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const Eyebrow(this.text, {super.key, this.color = Studio.muted});
  @override Widget build(BuildContext context) => Text(text.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.8, color: color));
}
class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 24, bottom: 12), child: Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)), if (action != null) TextButton(onPressed: onTap, child: Text(action!))]));
}
class StatusPill extends StatelessWidget {
  final String status;
  const StatusPill({super.key, required this.status});
  @override Widget build(BuildContext context) {
    final color = status == 'Resolved' ? Studio.green : status == 'In progress' ? const Color(0xFF9A6816) : const Color(0xFF5960A5);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .09), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)));
  }
}
class Stars extends StatelessWidget {
  final int rating;
  final ValueChanged<int>? onChange;
  const Stars({super.key, required this.rating, this.onChange});
  @override Widget build(BuildContext context) => Wrap(spacing: onChange == null ? 1 : 3, children: List.generate(5, (i) => onChange == null
    ? Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 17, color: const Color(0xFFC19039))
    : IconButton(tooltip: '${i + 1} stars', onPressed: () => onChange!(i + 1), icon: Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 36, color: const Color(0xFFC19039)))));
}
class EmptyState extends StatelessWidget {
  final String title, message;
  final VoidCallback? onTap;
  final String action;
  final IconData icon;
  const EmptyState({super.key, required this.title, required this.message, this.onTap, this.action = 'Give feedback', this.icon = Icons.inbox_outlined});
  @override Widget build(BuildContext context) => Surface(child: Column(children: [
    Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Studio.paper, shape: BoxShape.circle), child: Icon(icon, color: Studio.green, size: 36)),
    const SizedBox(height: 18), Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Studio.muted)),
    if (onTap != null) ...[const SizedBox(height: 18), FilledButton(onPressed: onTap, child: Text(action))],
  ]));
}
class RatingRing extends StatelessWidget {
  final Insights stats;
  const RatingRing({super.key, required this.stats});
  @override Widget build(BuildContext context) => SizedBox(width: 142, height: 142, child: Stack(alignment: Alignment.center, children: [
    SizedBox(width: 134, height: 134, child: CircularProgressIndicator(value: stats.reviews.isEmpty ? 0 : stats.average / 5, strokeWidth: 10, backgroundColor: Studio.line, color: Studio.green)),
    Column(mainAxisSize: MainAxisSize.min, children: [Text(stats.reviews.isEmpty ? '—' : stats.average.toStringAsFixed(1), style: const TextStyle(fontSize: 35, fontWeight: FontWeight.w800, color: Studio.ink)), const Text('out of 5', style: TextStyle(color: Studio.muted, fontSize: 12))]),
  ]));
}
IconData categoryIcon(String c) => c == 'Task' ? Icons.assignment_outlined : c == 'Course' ? Icons.school_outlined : Icons.support_agent_rounded;
String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  return parts.isEmpty ? '?' : parts.take(2).map((p) => p[0]).join().toUpperCase();
}
