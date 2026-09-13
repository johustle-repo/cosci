import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/app_providers.dart';
import 'package:pseudocode_apk/core/firebase/firebase_initializer.dart';
import 'package:pseudocode_apk/app/routes/app_router.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/app/theme/app_theme.dart';
import 'package:pseudocode_apk/shared/widgets/loading_view.dart';

class PsuEduCodeApp extends StatefulWidget {
  const PsuEduCodeApp({super.key});

  @override
  State<PsuEduCodeApp> createState() => _PsuEduCodeAppState();
}

class _PsuEduCodeAppState extends State<PsuEduCodeApp> {
  late final Future<void> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await FirebaseInitializer.ensureInitialized();
    } catch (_) {
      // Firebase availability must not replace the application with a fatal
      // startup screen. Feature-level flows provide actionable feedback when
      // a specific service is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            key: const ValueKey('cosci-bootstrap'),
            title: 'CoSci',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            initialRoute: AppRoutes.startup,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const LoadingView(message: 'Starting CoSci...'),
            ),
            home: const LoadingView(message: 'Starting CoSci...'),
          );
        }

        const appRouter = AppRouter();

        return MultiProvider(
          providers: AppProviders.providers,
          child: MaterialApp(
            key: const ValueKey('cosci-ready'),
            title: 'CoSci',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            initialRoute: AppRoutes.startup,
            onGenerateRoute: appRouter.onGenerateRoute,
          ),
        );
      },
    );
  }
}
