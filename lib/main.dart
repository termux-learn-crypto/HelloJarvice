import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'screens/permissions_screen.dart';
import 'screens/home_screen.dart';

const String _dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init(
    (options) {
      options.dsn = _dsn.isNotEmpty ? _dsn : '';
      options.tracesSampleRate = 0.2;
    },
    appRunner: () => runApp(const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hello Jarvice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: Builder(
        builder: (ctx) => PermissionsScreen(onComplete: () {
          Navigator.of(ctx).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }),
      ),
    );
  }
}
