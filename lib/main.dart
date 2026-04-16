import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'page/main_navigation_page.dart';
import 'services/app_language.dart';
import 'services/firestore_user_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AppLanguage.instance.initialize();

  await FirestoreUserScope.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: AppLanguage.instance.locale,
          home: const MainNavigationPage(),
        );
      },
    );
  }
}
