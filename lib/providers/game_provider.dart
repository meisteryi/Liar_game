import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../services/storage_service.dart';
import 'gemini_provider.dart';

class GameNotifier extends StateNotifier<GameState> {
  final Ref _ref;

  GameNotifier(this._ref) : super(const GameState()) {
    _loadInitialSettings();
  }

  // Load API Key on startup
  Future<void> _loadInitialSettings() async {
    final apiKey = await StorageService.getApiKey();
    state = state.copyWith(
      settings: state.settings.copyWith(apiKey: apiKey),
    );
  }

  // Update configuration parameters
  void updateSettings(GameSettings settings) {
    state = state.copyWith(settings: settings);
  }

  // Save Gemini API key to storage
  Future<void> saveApiKey(String key) async {
    await StorageService.saveApiKey(key);
    state = state.copyWith(
      settings: state.settings.copyWith(apiKey: key),
    );
  }

  // Delete Gemini API key
  Future<void> deleteApiKey() async {
    await StorageService.deleteApiKey();
    state = state.copyWith(
      settings: state.settings.copyWith(apiKey: null),
    );
  }

  // Reset current game to setup screen
  void resetGame() {
    state = GameState(
      settings: state.settings, // Keep settings & API Key
    );
  }

  // Start the word generation and assign roles
  Future<void> startGame() async {
    final apiKey = state.settings.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API 키가 설정되지 않았습니다. 설정 화면에서 키를 입력해 주세요.');
    }

    state = state.copyWith(stage: GameStage.loading);

    try {
      final geminiService = _ref.read(geminiServiceProvider);
      
      // Request words from Gemini API
      final result = await geminiService.generateWords(
        apiKey: apiKey,
        theme: state.settings.theme,
        difficulty: state.settings.difficulty,
        mode: state.settings.mode,
      );

      final targetWord = result.targetWord.trim();
      // If standard mode, alternative is "라이어". If spy mode, it's the other word.
      final alternativeWord = state.settings.mode == GameMode.standard 
          ? '라이어' 
          : result.alternativeWord.trim();
      final hint = result.hint.trim();

      // Create Players & Assign Roles
      final totalPlayers = state.settings.playerCount;
      final totalLiars = state.settings.liarCount;

      // Randomly choose liar indices
      final random = Random();
      final Set<int> liarIndices = {};
      while (liarIndices.length < totalLiars) {
        liarIndices.add(random.nextInt(totalPlayers));
      }

      final List<Player> players = List.generate(totalPlayers, (index) {
        final isLiar = liarIndices.contains(index);
        final assignedWord = isLiar ? alternativeWord : targetWord;
        return Player(
          id: index + 1,
          name: '플레이어 ${index + 1}',
          isLiar: isLiar,
          assignedWord: assignedWord,
        );
      });

      state = state.copyWith(
        stage: GameStage.cardChecking,
        targetWord: targetWord,
        alternativeWord: alternativeWord,
        wordHint: hint,
        players: players,
        currentCheckPlayerIndex: 0,
        isCardFlipped: false,
      );
    } catch (e) {
      // Return to setup and rethrow
      state = state.copyWith(stage: GameStage.setup);
      rethrow;
    }
  }

  // Flip/reveal the secret card
  void flipCard() {
    state = state.copyWith(isCardFlipped: true);
  }

  // Move to next player or start discussing if all checked
  void nextPlayer() {
    if (state.currentCheckPlayerIndex < state.players.length - 1) {
      state = state.copyWith(
        currentCheckPlayerIndex: state.currentCheckPlayerIndex + 1,
        isCardFlipped: false,
      );
    } else {
      state = state.copyWith(
        stage: GameStage.playing,
        isCardFlipped: false,
      );
    }
  }

  // Advance from discussing to voting screen
  void startVoting() {
    state = state.copyWith(stage: GameStage.voting);
  }

  // Execute voting result
  void votePlayer(int playerId) {
    final votedPlayer = state.players.firstWhere((p) => p.id == playerId);
    final isLiar = votedPlayer.isLiar;

    if (!isLiar) {
      // Citizens voted for an innocent player -> Liar wins immediately
      state = state.copyWith(
        votedPlayerId: playerId,
        isLiarCaught: false,
        isLiarWon: true,
        stage: GameStage.results,
      );
    } else {
      // Citizens successfully caught a liar
      // In multi-liar scenario, check if all liars are caught or just this one.
      // For simplicity, if they catch at least one Liar, we give that Liar the final chance to guess the target word.
      state = state.copyWith(
        votedPlayerId: playerId,
        isLiarCaught: true,
        stage: GameStage.results,
      );
    }
  }

  // Liar guesses the word for a comeback
  void guessWord(String guessedWord) {
    if (state.isLiarCaught == true) {
      final normalizedGuess = guessedWord.trim().replaceAll(' ', '').toLowerCase();
      final normalizedTarget = state.targetWord.trim().replaceAll(' ', '').toLowerCase();

      final correct = normalizedGuess == normalizedTarget;

      state = state.copyWith(
        liarGuessedWord: guessedWord,
        isLiarWon: correct, // If correct, Liar wins. Otherwise, citizens win.
      );
    }
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(ref);
});
