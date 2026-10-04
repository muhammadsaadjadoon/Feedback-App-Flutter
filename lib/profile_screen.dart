import 'package:flutter/material.dart';
import 'design.dart';
import 'helpers.dart';
import 'store.dart';
import 'profile_data.dart';

const avatarColors = [Studio.mint, Color(0xFFD9E6F1), Color(0xFFF1E3CD), Color(0xFFE5DDF3), Color(0xFFD8EDE7)];
class ProfileAvatar extends StatelessWidget {
  final AppStore store;
  final double radius;
  const ProfileAvatar({super.key, required this.store, this.radius = 32});
  @override Widget build(BuildContext context) => AvatarPreview(name: store.name, data: store.profile, radius: radius);
}
class AvatarPreview extends StatelessWidget {
  final String name;
  final ProfileData data;
  final double radius;
  const AvatarPreview({super.key, required this.name, required this.data, this.radius = 40});
  @override Widget build(BuildContext context) {
    final fallback = CircleAvatar(radius: radius, backgroundColor: avatarColors[data.avatar.clamp(0, 4).toInt()], child: Text(initials(name), style: TextStyle(fontSize: radius * .6, fontWeight: FontWeight.w800, color: Studio.ink)));
    if (data.photoUrl.trim().isEmpty || !ProfileData.validUrl(data.photoUrl)) { return fallback; }
    return ClipOval(child: Image.network(data.photoUrl.trim(), width: radius * 2, height: radius * 2, fit: BoxFit.cover, cacheWidth: 180, cacheHeight: 180, errorBuilder: (_, error, stack) => fallback, loadingBuilder: (_, child, progress) => progress == null ? child : fallback));
  }
}
class ProfileScreen extends StatefulWidget {
  final AppStore store;
  const ProfileScreen({super.key, required this.store});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), bio = TextEditingController(), phone = TextEditingController(), location = TextEditingController(), website = TextEditingController(), photo = TextEditingController();
  int avatar = 0;
  String previewUrl = '';
  bool loaded = false, dirty = false, busy = false, allowLeave = false;
  @override void dispose() { for (final c in [name, bio, phone, location, website, photo]) { c.dispose(); } super.dispose(); }
  void load() {
    final p = widget.store.profile;
    name.text = widget.store.name; bio.text = p.bio; phone.text = p.phone; location.text = p.location; website.text = p.website; photo.text = p.photoUrl; avatar = p.avatar; previewUrl = p.photoUrl;
    loaded = true;
  }
  ProfileData get draft => ProfileData(bio: bio.text.trim(), phone: phone.text.trim(), location: location.text.trim(), website: website.text.trim(), photoUrl: photo.text.trim(), avatar: avatar);
  void changed(String _) => setState(() => dirty = true);
  Future<void> leave() async {
    if (busy) { return; }
    if (dirty) {
      final discard = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Discard profile changes?'), content: const Text('Your unsaved changes will be lost.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep editing')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Discard'))]));
      if (discard != true || !mounted) { return; }
    }
    if (!mounted) { return; }
    setState(() => allowLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) { Navigator.pop(context); } });
  }
  Future<void> save() async {
    if (busy || !form.currentState!.validate()) { return; }
    setState(() => busy = true);
    try {
      await widget.store.saveProfile(name.text, draft);
      if (mounted) { setState(() { dirty = false; previewUrl = photo.text.trim(); }); notice(context, 'Profile details saved.'); }
    } catch (e) { if (mounted) { notice(context, friendlyError(e)); } }
    finally { if (mounted) { setState(() => busy = false); } }
  }
  Future<void> securityAction(Future<void> Function() operation, String success) async {
    if (busy) { return; }
    setState(() => busy = true);
    try { await operation(); if (mounted) { notice(context, success); } }
    catch (e) { if (mounted) { notice(context, friendlyError(e)); } }
    finally { if (mounted) { setState(() => busy = false); } }
  }
  @override Widget build(BuildContext context) => ListenableBuilder(listenable: widget.store, builder: (context, _) {
    if (!loaded && !widget.store.profileLoading && widget.store.profileError == null) { load(); }
    return PopScope<void>(canPop: allowLeave || (!busy && !dirty), onPopInvokedWithResult: (didPop, _) { if (!didPop) { leave(); } }, child: Scaffold(
      appBar: AppBar(leading: IconButton(tooltip: 'Back', onPressed: busy ? null : leave, icon: const Icon(Icons.arrow_back)), title: const Text('Profile settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18))),
      body: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: widget.store.profileLoading && !loaded ? const Center(child: CircularProgressIndicator()) : widget.store.profileError != null && !loaded ? Padding(padding: const EdgeInsets.all(24), child: EmptyState(title: 'Profile needs attention', message: widget.store.profileError!, action: 'Retry', onTap: widget.store.reloadProfile)) : Form(key: form, child: ListView(padding: const EdgeInsets.fromLTRB(24, 12, 24, 40), children: [
        const Eyebrow('Make it yours'), const SizedBox(height: 10), Text('A profile that feels\nlike you.', style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 22),
        Surface(child: Column(children: [AvatarPreview(name: name.text, data: ProfileData(avatar: avatar, photoUrl: previewUrl), radius: 42), const SizedBox(height: 18), const Text('Choose your avatar colour', style: TextStyle(color: Studio.muted, fontSize: 12)), const SizedBox(height: 12), Wrap(spacing: 12, runSpacing: 12, children: List.generate(5, (i) => Semantics(label: 'Avatar colour ${i + 1}', selected: avatar == i, button: true, child: InkWell(onTap: busy ? null : () => setState(() { avatar = i; dirty = true; }), borderRadius: BorderRadius.circular(30), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: avatarColors[i], shape: BoxShape.circle, border: Border.all(color: avatar == i ? Studio.green : Colors.transparent, width: 2)), child: avatar == i ? const Icon(Icons.check, color: Studio.green, size: 18) : null))))), const SizedBox(height: 12), const Text('Photo URL takes priority. Leave it empty to use initials.', style: TextStyle(fontSize: 11, color: Studio.muted), textAlign: TextAlign.center)])),
        const SectionTitle('Personal details'),
        TextFormField(key: const ValueKey('profile-name'), controller: name, enabled: !busy, maxLength: 80, validator: (v) => requiredText(v, min: 2), onChanged: changed, decoration: const InputDecoration(labelText: 'Display name', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 14),
        TextFormField(controller: bio, enabled: !busy, maxLength: 300, minLines: 3, maxLines: 5, onChanged: changed, decoration: const InputDecoration(labelText: 'About you', alignLabelWithHint: true)), const SizedBox(height: 14),
        LayoutBuilder(builder: (context, c) {
          final width = c.maxWidth >= 600 ? (c.maxWidth - 16) / 2 : c.maxWidth;
          return Wrap(spacing: 16, runSpacing: 16, children: [
            SizedBox(width: width, child: TextFormField(controller: phone, enabled: !busy, maxLength: 30, keyboardType: TextInputType.phone, onChanged: changed, decoration: const InputDecoration(labelText: 'Contact phone (optional)', prefixIcon: Icon(Icons.phone_outlined)))),
            SizedBox(width: width, child: TextFormField(controller: location, enabled: !busy, maxLength: 100, onChanged: changed, decoration: const InputDecoration(labelText: 'City / location (optional)', prefixIcon: Icon(Icons.location_on_outlined)))),
          ]);
        }), const SizedBox(height: 14),
        TextFormField(controller: website, enabled: !busy, maxLength: 250, keyboardType: TextInputType.url, onChanged: changed, validator: (v) => ProfileData.validUrl(v ?? '') ? null : 'Use a full https:// URL.', decoration: const InputDecoration(labelText: 'Website (optional)', prefixIcon: Icon(Icons.link))), const SizedBox(height: 14),
        TextFormField(controller: photo, enabled: !busy, maxLength: 500, keyboardType: TextInputType.url, onChanged: changed, validator: (v) => ProfileData.validUrl(v ?? '') ? null : 'Use a full https:// image URL.', decoration: InputDecoration(labelText: 'Profile photo URL (optional)', prefixIcon: const Icon(Icons.image_outlined), suffixIcon: IconButton(tooltip: 'Preview photo', onPressed: busy ? null : () { if (ProfileData.validUrl(photo.text)) { setState(() => previewUrl = photo.text.trim()); } else { notice(context, 'Enter a valid https:// image URL.'); } }, icon: const Icon(Icons.preview_outlined)))),
        const SizedBox(height: 14), FilledButton.icon(key: const ValueKey('profile-save'), onPressed: busy ? null : save, icon: const Icon(Icons.check), label: Text(busy ? 'Saving…' : 'Save profile')),
        const SectionTitle('Account & security'), Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.store.accountEmail, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text(widget.store.demo ? 'Security changes require a real Firebase account.' : widget.store.emailVerified ? 'Email verified' : 'Email not yet verified', style: const TextStyle(fontSize: 12, color: Studio.muted)), const SizedBox(height: 16),
          if (!widget.store.demo) ...[
            if (!widget.store.emailVerified) OutlinedButton.icon(onPressed: busy ? null : () => securityAction(widget.store.sendVerification, 'Verification email sent. Check your inbox.'), icon: const Icon(Icons.verified_user_outlined), label: const Text('Send verification email')),
            TextButton(onPressed: busy ? null : () => securityAction(widget.store.refreshAccount, 'Account status refreshed.'), child: const Text('Refresh verification status')),
            const Divider(), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.mail_outline, color: Studio.green), title: const Text('Change email'), subtitle: const Text('Verify your new address before it replaces the old one.'), trailing: const Icon(Icons.chevron_right), onTap: busy ? null : () => openSecurity(true)),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.lock_outline, color: Studio.green), title: const Text('Change password'), subtitle: const Text('Confirm your current password to continue.'), trailing: const Icon(Icons.chevron_right), onTap: busy ? null : () => openSecurity(false)),
            OutlinedButton(onPressed: busy ? null : () => securityAction(() => widget.store.resetPassword(widget.store.accountEmail), 'Password reset email sent.'), child: const Text('Send password reset email')),
          ],
        ])),
        const SizedBox(height: 18), const Text('Profile details are private to your account. Your contact phone is a profile field, not a verified sign-in number. Photo links load from the URL you provide.', style: TextStyle(color: Studio.muted, fontSize: 11, height: 1.5)),
      ])))),
    ));
  });
  Future<void> openSecurity(bool email) async {
    await showDialog<void>(context: context, builder: (_) => CredentialDialog(store: widget.store, changeEmail: email));
  }
}
class CredentialDialog extends StatefulWidget {
  final AppStore store;
  final bool changeEmail;
  const CredentialDialog({super.key, required this.store, required this.changeEmail});
  @override State<CredentialDialog> createState() => _CredentialDialogState();
}
class _CredentialDialogState extends State<CredentialDialog> {
  final form = GlobalKey<FormState>();
  final current = TextEditingController(), next = TextEditingController(), confirmation = TextEditingController();
  bool busy = false, show = false;
  String? error;
  @override void dispose() { current.dispose(); next.dispose(); confirmation.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) { return; }
    setState(() { busy = true; error = null; });
    try {
      await widget.store.changeCredentials(currentPassword: current.text, newEmail: widget.changeEmail ? next.text.trim() : null, newPassword: widget.changeEmail ? null : next.text);
      if (mounted) { notice(context, widget.changeEmail ? 'Verification sent to your new address. Complete it there, then sign in with the updated email.' : 'Password updated.'); Navigator.pop(context); }
    } catch (e) { if (mounted) { setState(() => error = friendlyError(e)); } }
    finally { if (mounted) { setState(() => busy = false); } }
  }
  @override Widget build(BuildContext context) => PopScope<void>(canPop: !busy, child: AlertDialog(title: Text(widget.changeEmail ? 'Change email' : 'Change password'), content: SingleChildScrollView(child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
    TextFormField(controller: current, enabled: !busy, obscureText: !show, validator: (v) => (v?.isEmpty ?? true) ? 'Enter your current password.' : null, decoration: const InputDecoration(labelText: 'Current password')), const SizedBox(height: 16),
    TextFormField(controller: next, enabled: !busy, obscureText: !widget.changeEmail && !show, keyboardType: widget.changeEmail ? TextInputType.emailAddress : TextInputType.visiblePassword, validator: widget.changeEmail ? emailCheck : (v) => (v?.length ?? 0) < 8 ? 'Use at least 8 characters.' : null, decoration: InputDecoration(labelText: widget.changeEmail ? 'New email address' : 'New password')),
    if (!widget.changeEmail) ...[const SizedBox(height: 16), TextFormField(controller: confirmation, enabled: !busy, obscureText: !show, validator: (v) => v == next.text ? null : 'Passwords do not match.', decoration: const InputDecoration(labelText: 'Confirm new password'))],
    CheckboxListTile(contentPadding: EdgeInsets.zero, value: show, onChanged: busy ? null : (v) => setState(() => show = v ?? false), title: const Text('Show passwords', style: TextStyle(fontSize: 13))),
    if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
  ]))), actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Updating…' : widget.changeEmail ? 'Send verification' : 'Update password'))]));
}
