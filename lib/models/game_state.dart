import 'game_settings.dart';

enum GameStage {
  setup,           // Configuring settings
  loading,         // Fetching words from Gemini
  cardChecking,    // Pass & Play, players check their words
  playing,         // Discussing (without timer)
  voting,          // Voting for the liar
  results,         // Results revelation & final guess
}

class Player {
  final int id;
  final String name;
  final bool isLiar;
  final String assignedWord;

  const Player({
    required this.id,
    required this.name,
    required this.isLiar,
    required this.assignedWord,
  });

  Player copyWith({
    int? id,
    String? name,
    bool? isLiar,
    String? assignedWord,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      isLiar: isLiar ?? this.isLiar,
      assignedWord: assignedWord ?? this.assignedWord,
    );
  }
}

class GameState {
  final GameStage stage;
  final GameSettings settings;
  final String targetWord;
  final String alternativeWord; // Used as alternative in Spy mode, or "라이어" in standard
  final String wordHint;
  final List<Player> players;
  final int currentCheckPlayerIndex; // Index of the player currently checking the card
  final bool isCardFlipped;          // True when word is visible
  final int? votedPlayerId;          // ID of the player who received the most votes
  final bool? isLiarCaught;          // Null before results, True if voted player was a liar
  final String? liarGuessedWord;      // Final guess from the caught liar
  final bool? isLiarWon;             // Final outcome: True if liar won, False if citizens won

  const GameState({
    this.stage = GameStage.setup,
    this.settings = const GameSettings(),
    this.targetWord = '',
    this.alternativeWord = '',
    this.wordHint = '',
    this.players = const [],
    this.currentCheckPlayerIndex = 0,
    this.isCardFlipped = false,
    this.votedPlayerId,
    this.isLiarCaught,
    this.liarGuessedWord,
    this.isLiarWon,
  });

  GameState copyWith({
    GameStage? stage,
    GameSettings? settings,
    String? targetWord,
    String? alternativeWord,
    String? wordHint,
    List<Player>? players,
    int? currentCheckPlayerIndex,
    bool? isCardFlipped,
    int? votedPlayerId,
    bool? isLiarCaught,
    String? liarGuessedWord,
    bool? isLiarWon,
  }) {
    return GameState(
      stage: stage ?? this.stage,
      settings: settings ?? this.settings,
      targetWord: targetWord ?? this.targetWord,
      alternativeWord: alternativeWord ?? this.alternativeWord,
      wordHint: wordHint ?? this.wordHint,
      players: players ?? this.players,
      currentCheckPlayerIndex: currentCheckPlayerIndex ?? this.currentCheckPlayerIndex,
      isCardFlipped: isCardFlipped ?? this.isCardFlipped,
      votedPlayerId: votedPlayerId ?? this.votedPlayerId,
      isLiarCaught: isLiarCaught ?? this.isLiarCaught,
      liarGuessedWord: liarGuessedWord ?? this.liarGuessedWord,
      isLiarWon: isLiarWon ?? this.isLiarWon,
    );
  }
}
