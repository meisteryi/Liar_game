import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _themeController = TextEditingController();

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  void _showWarningDialog({
    required String title,
    required String content,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF6EE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E1E1E), width: 1.5),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
        ),
        content: Text(
          content,
          style: const TextStyle(color: Color(0xFF757575), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onConfirm != null) {
                onConfirm();
              }
            },
            child: const Text(
              '확인',
              style: TextStyle(color: Color(0xFF1E1E1E), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _onStartPressed(String? apiKey, GameSettings currentSettings) async {
    final enteredTheme = _themeController.text.trim();

    // 2. Theme check
    if (enteredTheme.isEmpty) {
      _showWarningDialog(
        title: '주제 입력 필요',
        content: '라이어 게임 진행을 위해 원하는 주제(테마)를 입력해 주세요.\n예: 과일, 음식, 영화, 스포츠 등',
      );
      return;
    }

    // Capture theme from controller
    ref.read(gameProvider.notifier).updateSettings(
      currentSettings.copyWith(theme: enteredTheme),
    );

    try {
      await ref.read(gameProvider.notifier).startGame();
    } catch (e, stack) {
      debugPrint('게임 시작 중 에러 발생: $e');
      debugPrint('상세 스택트레이스: $stack');
      if (mounted) {
        _showWarningDialog(
          title: '에러 발생',
          content: '제미나이 단어 생성 중 오류가 발생했습니다: $e\n\nAPI 키 상태나 네트워크 환경을 확인해 주세요.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final settings = gameState.settings;
    final apiKey = settings.apiKey;

    // Dynamically adjust max liar count. Min 1, max is (players - 2)
    final maxLiars = (settings.playerCount > 4) ? 2 : 1;
    // Adjust liar count if it exceeds the max allowed for the current player count
    if (settings.liarCount > maxLiars) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(gameProvider.notifier).updateSettings(
          settings.copyWith(liarCount: maxLiars),
        );
      });
    }

    final isGenerating = gameState.stage == GameStage.loading;

    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(
        title: const Text('LIAR GAME'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player count slider/buttons
                const Text(
                  '인원 선택',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCounterButton(
                      icon: Icons.remove,
                      onPressed: settings.playerCount > 3
                          ? () {
                              ref.read(gameProvider.notifier).updateSettings(
                                    settings.copyWith(playerCount: settings.playerCount - 1),
                                  );
                            }
                          : null,
                    ),
                    Text(
                      '${settings.playerCount} 명',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    _buildCounterButton(
                      icon: Icons.add,
                      onPressed: settings.playerCount < 10
                          ? () {
                              ref.read(gameProvider.notifier).updateSettings(
                                    settings.copyWith(playerCount: settings.playerCount + 1),
                                  );
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Player Name Configuration List
                const Text(
                  '플레이어 이름 설정',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBF7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5DFD5), width: 1.5),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: settings.playerCount,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final player = index < gameState.players.length ? gameState.players[index] : null;
                      final currentName = player?.name ?? '플레이어 ${index + 1}';
                      final score = player?.score ?? 0;
                      return _PlayerNameInputRow(
                        index: index,
                        initialName: currentName.startsWith('플레이어 ') ? '' : currentName,
                        defaultLabel: '플레이어 ${index + 1}',
                        score: score,
                        onChanged: (val) {
                          ref.read(gameProvider.notifier).updatePlayerName(index, val);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Liar count
                const Text(
                  '라이어 수',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCounterButton(
                      icon: Icons.remove,
                      onPressed: settings.liarCount > 1
                          ? () {
                              ref.read(gameProvider.notifier).updateSettings(
                                    settings.copyWith(liarCount: settings.liarCount - 1),
                                  );
                            }
                          : null,
                    ),
                    Text(
                      '${settings.liarCount} 명',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    _buildCounterButton(
                      icon: Icons.add,
                      onPressed: settings.liarCount < maxLiars
                          ? () {
                              ref.read(gameProvider.notifier).updateSettings(
                                    settings.copyWith(liarCount: settings.liarCount + 1),
                                  );
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Game Mode selector (Standard vs Spy)
                const Text(
                  '게임 모드',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectorTile(
                        title: '일반 라이어',
                        subtitle: '라이어는 제시어를 모름',
                        selected: settings.mode == GameMode.standard,
                        onTap: () {
                          ref.read(gameProvider.notifier).updateSettings(
                                settings.copyWith(mode: GameMode.standard),
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSelectorTile(
                        title: '바보(스파이) 모드',
                        subtitle: '스파이는 다른 단어를 받음',
                        selected: settings.mode == GameMode.spy,
                        onTap: () {
                          ref.read(gameProvider.notifier).updateSettings(
                                settings.copyWith(mode: GameMode.spy),
                              );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Difficulty selector (Easy, Medium, Hard)
                const Text(
                  '제시어 난이도',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDifficultyButton(
                        label: '쉬움',
                        selected: settings.difficulty == GameDifficulty.easy,
                        onTap: () {
                          ref.read(gameProvider.notifier).updateSettings(
                                settings.copyWith(difficulty: GameDifficulty.easy),
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDifficultyButton(
                        label: '보통',
                        selected: settings.difficulty == GameDifficulty.medium,
                        onTap: () {
                          ref.read(gameProvider.notifier).updateSettings(
                                settings.copyWith(difficulty: GameDifficulty.medium),
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDifficultyButton(
                        label: '어려움',
                        selected: settings.difficulty == GameDifficulty.hard,
                        onTap: () {
                          ref.read(gameProvider.notifier).updateSettings(
                                settings.copyWith(difficulty: GameDifficulty.hard),
                              );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Custom Theme/Category input
                const Text(
                  '원하는 주제 (선택)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _themeController,
                  style: const TextStyle(color: Color(0xFF1E1E1E)),
                  decoration: InputDecoration(
                    hintText: '예: 과일, IT 기기, 영화 (비우면 무작위 생성)',
                    hintStyle: const TextStyle(color: Color(0xFFC0B9AF)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF1E1E1E), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF1E1E1E), width: 2.0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Start button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _onStartPressed(apiKey, settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E1E),
                      foregroundColor: const Color(0xFFFAF6EE),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '게임 준비 완료',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      ),
      if (isGenerating)
        Positioned.fill(
          child: Material(
            color: const Color(0xFFFAF6EE).withValues(alpha: 0.75),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E1E1E)),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Gemini가 재미있는 단어를 생각하고 있어요...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterButton({required IconData icon, required VoidCallback? onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed == null ? const Color(0xFFE5DFD5) : const Color(0xFFFDFBF7),
        border: Border.all(
          color: onPressed == null ? const Color(0xFFC0B9AF) : const Color(0xFF1E1E1E),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: onPressed == null ? const Color(0xFF9E9E9E) : const Color(0xFF1E1E1E)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSelectorTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 110,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E1E1E) : const Color(0xFFFDFBF7),
          border: Border.all(
            color: const Color(0xFF1E1E1E),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: selected ? const Color(0xFFFAF6EE) : const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: selected ? const Color(0xFFC0B9AF) : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E1E1E) : const Color(0xFFFDFBF7),
          border: Border.all(
            color: const Color(0xFF1E1E1E),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: selected ? const Color(0xFFFAF6EE) : const Color(0xFF1E1E1E),
          ),
        ),
      ),
    );
  }
}

class _PlayerNameInputRow extends StatefulWidget {
  final int index;
  final String initialName;
  final String defaultLabel;
  final int score;
  final ValueChanged<String> onChanged;

  const _PlayerNameInputRow({
    required this.index,
    required this.initialName,
    required this.defaultLabel,
    required this.score,
    required this.onChanged,
  });

  @override
  State<_PlayerNameInputRow> createState() => _PlayerNameInputRowState();
}

class _PlayerNameInputRowState extends State<_PlayerNameInputRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void didUpdateWidget(covariant _PlayerNameInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialName != oldWidget.initialName && _controller.text != widget.initialName) {
      _controller.text = widget.initialName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${widget.index + 1}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFAF6EE),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E1E1E)),
              decoration: InputDecoration(
                hintText: widget.defaultLabel,
                hintStyle: const TextStyle(color: Color(0xFFC0B9AF), fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFE5DFD5), width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF1E1E1E), width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 16, color: Color(0xFF757575)),
            const SizedBox(width: 4),
            Text(
              '${widget.score}점',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
