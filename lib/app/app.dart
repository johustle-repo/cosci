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
  late final Future<String?> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _initializeFirebase();
  }

  Future<String?> _initializeFirebase() async {
    try {
      await FirebaseInitializer.ensureInitialized();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
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

        final appRouter = AppRouter(startupError: snapshot.data);

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
