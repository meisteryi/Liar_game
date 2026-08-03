import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liar_game/models/game_settings.dart';
import 'package:liar_game/models/game_state.dart';
import 'package:liar_game/providers/game_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be setup with default settings', () {
      final state = container.read(gameProvider);
      expect(state.stage, GameStage.setup);
      expect(state.settings.playerCount, 4);
      expect(state.settings.liarCount, 1);
      expect(state.settings.mode, GameMode.standard);
    });

    test('updateSettings should change the game configuration', () {
      final notifier = container.read(gameProvider.notifier);
      final newSettings = const GameSettings(
        playerCount: 6,
        liarCount: 2,
        mode: GameMode.spy,
        difficulty: GameDifficulty.hard,
        theme: '음식',
      );

      notifier.updateSettings(newSettings);

      final state = container.read(gameProvider);
      expect(state.settings.playerCount, 6);
      expect(state.settings.liarCount, 2);
      expect(state.settings.mode, GameMode.spy);
      expect(state.settings.theme, '음식');
    });

    test('resetGame should return game stage to setup but preserve settings', () {
      final notifier = container.read(gameProvider.notifier);
      
      notifier.updateSettings(const GameSettings(apiKey: 'dummy_key', playerCount: 5));
      notifier.resetGame();

      final state = container.read(gameProvider);
      expect(state.stage, GameStage.setup);
      expect(state.settings.apiKey, 'dummy_key');
      expect(state.settings.playerCount, 5);
    });
  });
}
