import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'store.dart';
import 'screens.dart';
import 'design.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const demo = bool.fromEnvironment('DEMO_MODE', defaultValue: true);
  String? error;
  if (!demo) {
    try {
      const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
      const appId = String.fromEnvironment('FIREBASE_APP_ID');
      const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
      const sender = String.fromEnvironment('FIREBASE_SENDER_ID');
      if ([apiKey, appId, project, sender].any((value) => value.isEmpty)) {
        throw StateError('Missing Firebase configuration');
      }
      await Firebase.initializeApp(options: const FirebaseOptions(apiKey: apiKey, appId: appId,
        messagingSenderId: sender, projectId: project,
        authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
        iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID')));
    } catch (_) { error = 'We could not connect to your workspace. Check the Firebase configuration and restart the app.'; }
  }
  runApp(FeedbackApp(store: error == null ? AppStore(demo: demo) : null, startupError: error));
}
class FeedbackApp extends StatelessWidget {
  final AppStore? store;
  final String? startupError;
  const FeedbackApp({super.key, required this.store, this.startupError});
  @override Widget build(BuildContext context) => MaterialApp(title: 'Feedback', debugShowCheckedModeBanner: false, theme: Studio.theme(),
    home: startupError != null ? Scaffold(body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: EmptyState(title: 'Connection needs attention', message: startupError!, icon: Icons.cloud_off_rounded))))))
      : ListenableBuilder(listenable: store!, builder: (context, _) => store!.signedIn
        ? HomeScreen(key: ValueKey('${store!.uid}-${store!.admin}'), store: store!) : AuthScreen(store: store!)));
}
