enum GameMode {
  standard, // Normal Liar (Liar gets "Liar")
  spy,      // Spy Mode / Alternative Word (Spy gets a different but similar word)
}

enum GameDifficulty {
  easy,
  medium,
  hard,
}

class GameSettings {
  final int playerCount;
  final int liarCount;
  final GameMode mode;
  final GameDifficulty difficulty;
  final String theme;
  final String? apiKey;

  const GameSettings({
    this.playerCount = 4,
    this.liarCount = 1,
    this.mode = GameMode.standard,
    this.difficulty = GameDifficulty.medium,
    this.theme = '',
    this.apiKey,
  });

  GameSettings copyWith({
    int? playerCount,
    int? liarCount,
    GameMode? mode,
    GameDifficulty? difficulty,
    String? theme,
    String? apiKey,
  }) {
    return GameSettings(
      playerCount: playerCount ?? this.playerCount,
      liarCount: liarCount ?? this.liarCount,
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      theme: theme ?? this.theme,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  String get difficultyKorean {
    switch (difficulty) {
      case GameDifficulty.easy:
        return '쉬움';
      case GameDifficulty.medium:
        return '보통';
      case GameDifficulty.hard:
        return '어려움';
    }
  }

  String get modeKorean {
    switch (mode) {
      case GameMode.standard:
        return '일반 라이어';
      case GameMode.spy:
        return '바보(스파이) 모드';
    }
  }
}
