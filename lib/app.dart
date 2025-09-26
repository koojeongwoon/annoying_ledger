import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:annoying_ledger/core/api/api_client.dart';
import 'package:annoying_ledger/core/config/app_config.dart';
import 'package:annoying_ledger/core/storage/token_storage.dart';
import 'package:annoying_ledger/features/auth/controllers/auth_controller.dart';
import 'package:annoying_ledger/features/auth/data/auth_repository.dart';
import 'package:annoying_ledger/features/auth/view/login_screen.dart';
import 'package:annoying_ledger/features/home/view/home_screen.dart';
import 'package:annoying_ledger/widgets/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class App extends StatelessWidget {
  const App({super.key, required this.tokenStorage});

  final TokenStorage tokenStorage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => ApiClient(baseUrl: AppConfig.apiBaseUrl),
          dispose: (_, client) => client.close(),
        ),
        ProxyProvider<ApiClient, AuthRepository>(
          update: (_, apiClient, _) =>
              AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) {
            final repository = context.read<AuthRepository>();
            final controller = AuthController(repository);
            controller.initialize();
            return controller;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Annoying Ledger',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          textTheme: GoogleFonts.notoSansKrTextTheme(
            Theme.of(context).textTheme,
          ),
          useMaterial3: true,

        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('ko', 'KR'),
        ],
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        switch (auth.status) {
          case AuthStatus.initializing:
            return const SplashScreen();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          case AuthStatus.authenticated:
            return const HomeScreen();
        }
      },
    );
  }
}
