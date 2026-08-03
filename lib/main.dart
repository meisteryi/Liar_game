import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/game_state.dart';
import 'providers/game_provider.dart';
import 'views/home_screen.dart';
import 'views/card_check_screen.dart';
import 'views/discussion_screen.dart';
import 'views/voting_screen.dart';
import 'views/result_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: LiarGameApp(),
    ),
  );
}

class LiarGameApp extends StatelessWidget {
  const LiarGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Premium Warm Ivory & Charcoal theme
    final baseTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFAF6EE),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAF6EE),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1E1E1E)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1E1E1E),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E1E1E),
        primary: const Color(0xFF1E1E1E),
        surface: const Color(0xFFFDFBF7),
      ),
    );

    return MaterialApp(
      title: '라이어 게임 (Liar Game)',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme).copyWith(
          // Ensure Korean characters render beautifully if outfit doesn't support them fully
          bodyLarge: GoogleFonts.notoSansKr(
            textStyle: baseTheme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF1E1E1E),
            ),
          ),
          bodyMedium: GoogleFonts.notoSansKr(
            textStyle: baseTheme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF1E1E1E),
            ),
          ),
          titleLarge: GoogleFonts.notoSansKr(
            textStyle: baseTheme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF1E1E1E),
              fontWeight: FontWeight.bold,
            ),
          ),
          headlineMedium: GoogleFonts.notoSansKr(
            textStyle: baseTheme.textTheme.headlineMedium?.copyWith(
              color: const Color(0xFF1E1E1E),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      home: const GameRoot(),
    );
  }
}

class GameRoot extends ConsumerWidget {
  const GameRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    Widget activeScreen;
    switch (gameState.stage) {
      case GameStage.setup:
      case GameStage.loading:
        activeScreen = const HomeScreen();
        break;
      case GameStage.cardChecking:
        activeScreen = const CardCheckScreen();
        break;
      case GameStage.playing:
        activeScreen = const DiscussionScreen();
        break;
      case GameStage.voting:
        activeScreen = const VotingScreen();
        break;
      case GameStage.results:
        activeScreen = const ResultScreen();
        break;
    }

    // Constraint layout for responsive design on web
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6EE),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E1E1E).withAlpha(15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: activeScreen,
          ),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E1E1E)),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Gemini가 재미있는 단어를 생각하고 있어요...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
