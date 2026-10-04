import 'dart:io';
import 'dart:convert';

Future<void> runFlutter(Directory root, List<String> args) async {
  final process = await Process.start('flutter', args, workingDirectory: root.path, runInShell: Platform.isWindows, mode: ProcessStartMode.inheritStdio);
  final code = await process.exitCode;
  if (code != 0) { throw StateError('Flutter command failed: ${args.join(' ')} (exit $code)'); }
}
void copyTree(Directory source, Directory destination) {
  destination.createSync(recursive: true);
  for (final item in source.listSync(followLinks: false)) {
    final name = item.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (item is File) { item.copySync('${destination.path}/$name'); }
    if (item is Directory) { copyTree(item, Directory('${destination.path}/$name')); }
  }
}
Future<void> main() async {
  final root = File.fromUri(Platform.script).parent.parent;
  final backup = Directory.systemTemp.createTempSync('feedback-source-');
  final lib = Directory('${root.path}/lib'), test = Directory('${root.path}/test');
  copyTree(lib, Directory('${backup.path}/lib'));
  copyTree(test, Directory('${backup.path}/test'));
  final pubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
  try {
    final needsRunners = ['android', 'ios', 'web'].any((name) => !Directory('${root.path}/$name').existsSync());
    if (needsRunners) { await runFlutter(root, ['create', '--project-name', 'feedback_studio', '--org', 'com.feedbackstudio', '--platforms', 'android,ios,web', '--no-pub', '.']); }
  } finally {
    copyTree(Directory('${backup.path}/lib'), lib);
    copyTree(Directory('${backup.path}/test'), test);
    File('${root.path}/pubspec.yaml').writeAsStringSync(pubspec);
    backup.deleteSync(recursive: true);
  }
  final template = File('${root.path}/test/widget_test.dart');
  if (template.existsSync() && template.readAsStringSync().contains('Counter increments smoke test')) { template.deleteSync(); }
  final manifest = File('${root.path}/android/app/src/main/AndroidManifest.xml');
  if (manifest.existsSync()) {
    var text = manifest.readAsStringSync().replaceAll(RegExp(r'android:label="[^"]*"'), 'android:label="Feedback"');
    if (!text.contains('android.permission.INTERNET')) { text = text.replaceFirst('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application'); }
    manifest.writeAsStringSync(text);
  }
  final gradle = File('${root.path}/android/app/build.gradle.kts');
  if (gradle.existsSync()) { gradle.writeAsStringSync(gradle.readAsStringSync().replaceAll('minSdk = flutter.minSdkVersion', 'minSdk = maxOf(23, flutter.minSdkVersion)')); }
  final plist = File('${root.path}/ios/Runner/Info.plist');
  if (plist.existsSync()) {
    plist.writeAsStringSync(plist.readAsStringSync().replaceAll(RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)'), '<key>CFBundleDisplayName</key>\n\t<string>Feedback</string>'));
  }
  final webManifest = File('${root.path}/web/manifest.json');
  if (webManifest.existsSync()) {
    final data = jsonDecode(webManifest.readAsStringSync()) as Map<String, dynamic>;
    data['name'] = 'Feedback'; data['short_name'] = 'Feedback';
    data['theme_color'] = '#182C2A'; data['background_color'] = '#F7F8F3';
    webManifest.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
  }
  await runFlutter(root, ['pub', 'get']);
  final icon = await Process.start('dart', ['run', 'flutter_launcher_icons'], workingDirectory: root.path, runInShell: Platform.isWindows, mode: ProcessStartMode.inheritStdio);
  if (await icon.exitCode != 0) { throw StateError('Launcher icon generation failed. See output above.'); }
  stdout.writeln('Setup complete. Run flutter analyze and flutter test, then launch with your Firebase JSON.');
}
