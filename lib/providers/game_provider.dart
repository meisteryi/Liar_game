import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../services/storage_service.dart';
import 'gemini_provider.dart';

class GameNotifier extends StateNotifier<GameState> {
  final Ref _ref;

  // Cache for customized player names (up to 10 players)
  final List<String> _customNames = List.generate(10, (_) => '');
  // Cache for accumulated player scores (playerId -> score)
  final Map<int, int> _playerScores = {};

  GameNotifier(this._ref) : super(const GameState()) {
    _loadInitialSettings();
  }

  // Load API Key on startup
  Future<void> _loadInitialSettings() async {
    const defaultKey = 'AQ.Ab8RN6JRu-8UChX5etoRBAtZSUchgxwmJWFcirnF-lOu0VdH8g';

    // 1. Try loading from local storage
    var apiKey = await StorageService.getApiKey();

    // 2. If not found, try loading from build-time environment variable or fallback to defaultKey
    if (apiKey == null || apiKey.isEmpty) {
      apiKey = const String.fromEnvironment('GEMINI_API_KEY');
      if (apiKey.isEmpty) {
        apiKey = defaultKey;
      } else {
        // Automatically save to local storage for future runs
        await StorageService.saveApiKey(apiKey);
      }
    }

    state = state.copyWith(settings: state.settings.copyWith(apiKey: apiKey));

    // Initialize player state
    updateSettings(state.settings);
  }

  // Update configuration parameters
  void updateSettings(GameSettings settings) {
    // Generate setup player list with cached names and scores when player count changes
    final List<Player> setupPlayers = List.generate(settings.playerCount, (i) {
      final id = i + 1;
      final customName = _customNames[i];
      final currentScore = _playerScores[id] ?? 0;
      return Player(
        id: id,
        name: customName.isEmpty ? '플레이어 $id' : customName,
        isLiar: false,
        assignedWord: '',
        score: currentScore,
      );
    });

    state = state.copyWith(settings: settings, players: setupPlayers);
  }

  // Update a specific player's name
  void updatePlayerName(int index, String name) {
    if (index >= 0 && index < _customNames.length) {
      _customNames[index] = name;

      // If we are currently in setup screen, update the names in state.players so the UI updates
      if (state.stage == GameStage.setup) {
        final currentCount = state.settings.playerCount;
        final List<Player> updatedPlayers = List.generate(currentCount, (i) {
          final id = i + 1;
          final customName = _customNames[i];
          final currentScore = _playerScores[id] ?? 0;
          return Player(
            id: id,
            name: customName.isEmpty ? '플레이어 $id' : customName,
            isLiar: false,
            assignedWord: '',
            score: currentScore,
          );
        });
        state = state.copyWith(players: updatedPlayers);
      }
    }
  }

  // Save Gemini API key to storage
  Future<void> saveApiKey(String key) async {
    await StorageService.saveApiKey(key);
    state = state.copyWith(settings: state.settings.copyWith(apiKey: key));
  }

  // Delete Gemini API key
  Future<void> deleteApiKey() async {
    await StorageService.deleteApiKey();
    state = state.copyWith(settings: state.settings.copyWith(apiKey: null));
  }

  // Toggles Gemini API connection. Set to false to reconnect to Gemini API.
  // api 연결
  static const bool _useDummyData = false;

  // Start the word generation and assign roles
  Future<void> startGame() async {
    final apiKey = state.settings.apiKey;
    if (!_useDummyData && (apiKey == null || apiKey.isEmpty)) {
      throw Exception('Gemini API 키가 설정되지 않았습니다. 설정 화면에서 키를 입력해 주세요.');
    }

    state = state.copyWith(stage: GameStage.loading);

    try {
      String targetWord;
      String alternativeWord;
      String hint;

      if (_useDummyData) {
        // Simulate Gemini API network loading latency
        await Future.delayed(const Duration(milliseconds: 1500));

        targetWord = '김';
        alternativeWord = state.settings.mode == GameMode.standard
            ? '라이어'
            : '미역';
        hint = '해조류';
      } else {
        final geminiService = _ref.read(geminiServiceProvider);

        // Request words from Gemini API
        final result = await geminiService.generateWords(
          apiKey: apiKey!,
          theme: state.settings.theme,
          difficulty: state.settings.difficulty,
          mode: state.settings.mode,
        );

        targetWord = result.targetWord.trim();
        alternativeWord = state.settings.mode == GameMode.standard
            ? '라이어'
            : result.alternativeWord.trim();
        hint = result.hint.trim();
      }

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
        final id = index + 1;
        final customName = _customNames[index];
        final score = _playerScores[id] ?? 0;

        return Player(
          id: id,
          name: customName.isEmpty ? '플레이어 $id' : customName,
          isLiar: isLiar,
          assignedWord: assignedWord,
          score: score,
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
    } catch (e, stack) {
      debugPrint('Error in startGame: $e');
      debugPrint('Stacktrace: $stack');
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
      state = state.copyWith(stage: GameStage.playing, isCardFlipped: false);
    }
  }

  // Award points based on winner outcome
  void _awardPoints({required bool isLiarWinner}) {
    final updatedPlayers = state.players.map((player) {
      int newScore = player.score;
      if (isLiarWinner && player.isLiar) {
        newScore += 2; // Liar gets 2 points
      } else if (!isLiarWinner && !player.isLiar) {
        newScore += 1; // Citizens get 1 point each
      }
      _playerScores[player.id] = newScore;
      return player.copyWith(score: newScore);
    }).toList();

    state = state.copyWith(players: updatedPlayers);
  }

  // Reset current game to setup screen
  void resetGame() {
    // Generate new setup players with persisted names & current scores
    final currentCount = state.settings.playerCount;
    final List<Player> setupPlayers = List.generate(currentCount, (i) {
      final id = i + 1;
      final customName = _customNames[i];
      final currentScore = _playerScores[id] ?? 0;
      return Player(
        id: id,
        name: customName.isEmpty ? '플레이어 $id' : customName,
        isLiar: false,
        assignedWord: '',
        score: currentScore,
      );
    });

    state = GameState(
      stage: GameStage.setup,
      settings: state.settings,
      players: setupPlayers,
    );
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
      _awardPoints(isLiarWinner: true);
      state = state.copyWith(
        votedPlayerId: playerId,
        isLiarCaught: false,
        isLiarWon: true,
        stage: GameStage.results,
      );
    } else {
      // Citizens successfully caught a liar
      state = state.copyWith(
        votedPlayerId: playerId,
        isLiarCaught: true,
        stage: GameStage.results,
      );
    }
  }

  // Liar guesses the word for a comeback
  void guessWord(String guessedWord) {
    if (state.isLiarCaught == true && state.isLiarWon == null) {
      final normalizedGuess = guessedWord
          .trim()
          .replaceAll(' ', '')
          .toLowerCase();
      final normalizedTarget = state.targetWord
          .trim()
          .replaceAll(' ', '')
          .toLowerCase();

      final correct = normalizedGuess == normalizedTarget;

      _awardPoints(isLiarWinner: correct);

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
