import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../models/game_state.dart';

class CardCheckScreen extends ConsumerWidget {
  const CardCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final currentIndex = gameState.currentCheckPlayerIndex;
    final currentPlayer = gameState.players[currentIndex];
    final isFlipped = gameState.isCardFlipped;

    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 확인'),
        automaticallyImplyLeading: false, // Prevent going back mid-game
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _showExitConfirmation(context, ref),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '확인 중: ${currentIndex + 1} / ${gameState.players.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF757575)),
                  ),
                  Text(
                    '남은 인원: ${gameState.players.length - currentIndex - 1}명',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF757575)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (currentIndex + (isFlipped ? 1 : 0.5)) / gameState.players.length,
                  backgroundColor: const Color(0xFFE5DFD5),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E1E1E)),
                  minHeight: 6,
                ),
              ),
              
              const Spacer(),
              
              // Instructions
              Text(
                currentPlayer.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedCrossFade(
                firstChild: const Text(
                  '주변 사람들이 보지 못하게 주의해 주세요.\n준비되면 카드를 터치하여 제시어를 확인하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF757575)),
                ),
                secondChild: const Text(
                  '제시어를 확인한 후,\n하단의 확인 버튼을 누르고 다음 플레이어에게 폰을 넘기세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF757575)),
                ),
                crossFadeState: isFlipped ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
              
              const SizedBox(height: 40),

              // 3D Flippable Card
              GestureDetector(
                onTap: () {
                  if (!isFlipped && !gameState.isTransitioning) {
                    ref.read(gameProvider.notifier).flipCard();
                  }
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: isFlipped ? pi : 0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  builder: (context, double angle, _) {
                    final isCardBack = angle < pi / 2;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // perspective
                        ..rotateY(angle),
                      child: Container(
                        width: 280,
                        height: 380,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          border: Border.all(color: const Color(0xFF1E1E1E), width: 2.0),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E1E1E).withAlpha(20),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: isCardBack 
                            ? _buildCardBack() 
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(pi), // Prevents mirror reflection
                                child: _buildCardFront(currentPlayer),
                              ),
                      ),
                    );
                  },
                ),
              ),

              const Spacer(),

              // Confirm/Next Player button (Only shows when card is flipped)
              AnimatedOpacity(
                opacity: isFlipped ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !isFlipped,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(gameProvider.notifier).nextPlayer();
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
                      child: Text(
                        currentIndex == gameState.players.length - 1 ? '게임 시작' : '확인 완료',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.help_outline_rounded,
          size: 64,
          color: Color(0xFF1E1E1E),
        ),
        SizedBox(height: 16),
        Text(
          '터치하여 확인',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Color(0xFF1E1E1E),
          ),
        ),
      ],
    );
  }

  Widget _buildCardFront(Player player) {
    final isLiar = player.isLiar;
    final word = player.assignedWord;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isLiar ? 'ROLE' : 'WORD',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 20),
          if (isLiar && word == '라이어') ...[
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Color(0xFF1E1E1E),
            ),
            const SizedBox(height: 16),
            const Text(
              '당신은',
              style: TextStyle(fontSize: 20, color: Color(0xFF1E1E1E)),
            ),
            const Text(
              '라이어',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const Text(
              '입니다.',
              style: TextStyle(fontSize: 20, color: Color(0xFF1E1E1E)),
            ),
          ] else ...[
            const Icon(
              Icons.visibility_rounded,
              size: 48,
              color: Color(0xFF1E1E1E),
            ),
            const SizedBox(height: 16),
            const Text(
              '당신의 제시어는',
              style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 8),
            Text(
              word,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE5DFD5), thickness: 1.5),
          const SizedBox(height: 16),
          const Text(
            '주의: 정체가 탄로나지 않도록\n자연스럽게 설명하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF6EE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E1E1E), width: 1.5),
        ),
        title: const Text('게임 종료', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('현재 게임을 중단하고 메인 화면으로 돌아가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Color(0xFF757575))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameProvider.notifier).resetGame();
            },
            child: const Text('종료', style: TextStyle(color: Color(0xFF1E1E1E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
