import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../models/game_settings.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  final _guessController = TextEditingController();
  bool _submittedGuess = false;

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final votedPlayer = gameState.players.firstWhere((p) => p.id == gameState.votedPlayerId);
    final isLiarCaught = gameState.isLiarCaught ?? false;
    final isLiarWon = gameState.isLiarWon;

    return Scaffold(
      appBar: AppBar(
        title: const Text('게임 결과'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              
              // 1. Arrest Reveal Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFBF7),
                  border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      '${votedPlayer.name} 검거 완료',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isLiarCaught ? '정체 폭로: 라이어!' : '정체 폭로: 시민...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isLiarCaught ? const Color(0xFF1E1E1E) : const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 2. Main content area (Liar's guess input or final winner text)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (isLiarCaught && !_submittedGuess && isLiarWon == null) ...[
                        // Liar gets one last chance to guess the target word
                        const Icon(Icons.psychology_alt_rounded, size: 56, color: Color(0xFF1E1E1E)),
                        const SizedBox(height: 16),
                        const Text(
                          '라이어의 역전 기회',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '라이어는 다른 시민들의 진짜 제시어를 입력하세요.\n맞추면 라이어의 대역전 승리입니다!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Color(0xFF757575), height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        
                        TextField(
                          controller: _guessController,
                          style: const TextStyle(color: Color(0xFF1E1E1E)),
                          decoration: InputDecoration(
                            labelText: '진짜 제시어 추측',
                            labelStyle: const TextStyle(color: Color(0xFF757575)),
                            hintText: '단어를 입력하세요',
                            hintStyle: const TextStyle(color: Color(0xFFC0B9AF)),
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
                        const SizedBox(height: 20),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              final text = _guessController.text.trim();
                              if (text.isNotEmpty) {
                                ref.read(gameProvider.notifier).guessWord(text);
                                setState(() {
                                  _submittedGuess = true;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E1E1E),
                              foregroundColor: const Color(0xFFFAF6EE),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('단어 제출', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ] else ...[
                        // Final Winner Reveal
                        _buildFinalOutcome(isLiarWon ?? false, gameState),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Play again button (only active when the final winner is settled)
              if (!isLiarCaught || isLiarWon != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(gameProvider.notifier).resetGame();
                    },
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
                      '처음으로 돌아가기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalOutcome(bool isLiarWon, dynamic gameState) {
    return Column(
      children: [
        Icon(
          isLiarWon ? Icons.emoji_events_rounded : Icons.people_alt_rounded,
          size: 72,
          color: const Color(0xFF1E1E1E),
        ),
        const SizedBox(height: 16),
        Text(
          isLiarWon ? '라이어 승리!' : '시민 승리!',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isLiarWon
              ? (gameState.isLiarCaught == true
                  ? '라이어가 제시어(${gameState.targetWord})를 정확히 맞추어 대역전극을 펼쳤습니다!'
                  : '시민들이 엉뚱한 플레이어를 지목하여 라이어가 유유히 승리했습니다!')
              : '시민들이 라이어를 안전하게 검거하고, 라이어는 단어를 맞추지 못했습니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF757575), height: 1.5),
        ),
        const SizedBox(height: 32),

        // Secret words details
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5DFD5), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '게임 정보 요약',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E1E1E)),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('시민 제시어', gameState.targetWord),
              const SizedBox(height: 8),
              if (gameState.settings.mode == GameMode.spy)
                _buildInfoRow('스파이 제시어', gameState.alternativeWord)
              else
                _buildInfoRow('라이어 역할', '제시어 없이 정체 숨기기'),
              const SizedBox(height: 8),
              _buildInfoRow('주제 힌트', gameState.wordHint),
              const SizedBox(height: 8),
              _buildInfoRow(
                '진짜 라이어',
                (gameState.players as List)
                    .where((p) => p.isLiar)
                    .map((p) => p.name)
                    .join(', '),
              ),
              if (gameState.isLiarCaught == true && gameState.liarGuessedWord != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow('라이어의 추측', gameState.liarGuessedWord!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF757575), fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E1E1E), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
