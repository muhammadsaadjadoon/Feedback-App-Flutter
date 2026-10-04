import 'package:flutter/material.dart';
import 'store.dart';
import 'design.dart';
import 'helpers.dart';

class AuthScreen extends StatefulWidget {
  final AppStore store;
  const AuthScreen({super.key, required this.store});
  @override State<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController(), name = TextEditingController();
  bool register = false, busy = false, obscure = true;
  String? error;
  @override void dispose() { email.dispose(); password.dispose(); name.dispose(); super.dispose(); }
  Future<void> authenticate() async {
    if (!form.currentState!.validate()) { return; }
    setState(() { busy = true; error = null; });
    try {
      if (register) { await widget.store.register(name.text, email.text, password.text); }
      else { await widget.store.signIn(email.text, password.text); }
    } catch (e) { if (mounted) { setState(() => error = friendlyError(e)); } }
    finally { if (mounted) { setState(() => busy = false); } }
  }
  Future<void> reset() async {
    if (emailCheck(email.text) != null) { notice(context, 'Enter your email address first.'); return; }
    setState(() => busy = true);
    try { await widget.store.resetPassword(email.text); if (mounted) { notice(context, 'If an account exists, a password reset email will arrive shortly.'); } }
    catch (e) { if (mounted) { notice(context, friendlyError(e)); } }
    finally { if (mounted) { setState(() => busy = false); } }
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Brand(), const SizedBox(height: 28),
    Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: Studio.ink, borderRadius: BorderRadius.circular(30)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Eyebrow('A little feedback. A better tomorrow.', color: Studio.mint), const SizedBox(height: 24),
      const Text('Good things\nstart with\nyour voice.', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, height: 1.08, letterSpacing: -1.4, color: Colors.white)),
      const SizedBox(height: 22), const Text('A thoughtful space to share experiences\nand turn feedback into progress.', style: TextStyle(color: Color(0xFFC4D3CB), height: 1.6)),
      const SizedBox(height: 26), Wrap(spacing: 8, runSpacing: 8, children: ['Share honestly', 'Track progress', 'See change'].map((t) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(30)), child: Text(t, style: const TextStyle(fontSize: 11, color: Studio.mint)))).toList()),
    ])), const SizedBox(height: 28),
    Text(widget.store.demo ? 'Take a look around.' : register ? 'Make yourself heard.' : 'Welcome back.', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 8),
    Text(widget.store.demo ? 'Explore both sides of a better feedback experience.' : register ? 'Create your account to join the conversation.' : 'Sign in to pick up the conversation.', style: const TextStyle(color: Studio.muted)), const SizedBox(height: 22),
    if (widget.store.demo) ...[
      FilledButton.icon(key: const ValueKey('demo-member'), onPressed: () => widget.store.enterDemo(false), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Continue as a member')),
      const SizedBox(height: 12), OutlinedButton.icon(key: const ValueKey('demo-admin'), onPressed: () => widget.store.enterDemo(true), icon: const Icon(Icons.admin_panel_settings_outlined), label: const Text('Explore admin workspace')),
      const SizedBox(height: 16), const Text('Demo uses sample data. Changes reset on restart.', style: TextStyle(fontSize: 12, color: Studio.muted), textAlign: TextAlign.center),
    ] else Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (register) ...[TextFormField(controller: name, enabled: !busy, maxLength: 80, validator: (v) => requiredText(v, min: 2), decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 12)],
      TextFormField(controller: email, enabled: !busy, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], validator: emailCheck, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline))), const SizedBox(height: 14),
      TextFormField(controller: password, enabled: !busy, obscureText: obscure, autofillHints: [register ? AutofillHints.newPassword : AutofillHints.password], validator: (v) => (v?.length ?? 0) < (register ? 8 : 1) ? 'Enter ${register ? 'at least 8 characters' : 'your password'}.' : null,
        decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(tooltip: obscure ? 'Show password' : 'Hide password', onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
      if (!register) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: busy ? null : reset, child: const Text('Forgot password?'))),
      if (error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(error!, style: const TextStyle(color: Colors.red))), const SizedBox(height: 14),
      FilledButton(onPressed: busy ? null : authenticate, child: Text(busy ? 'Please wait…' : register ? 'Create account' : 'Sign in')),
      TextButton(onPressed: busy ? null : () => setState(() { register = !register; error = null; }), child: Text(register ? 'Already a member? Sign in' : 'New here? Create an account')),
    ])), const SizedBox(height: 22), const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock_outline, size: 14, color: Studio.muted), SizedBox(width: 6), Flexible(child: Text('Your feedback stays within your workspace.', style: TextStyle(fontSize: 11, color: Studio.muted)))]),
  ]))))));
}
