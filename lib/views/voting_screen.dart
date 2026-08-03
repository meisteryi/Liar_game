import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

class VotingScreen extends ConsumerStatefulWidget {
  const VotingScreen({super.key});

  @override
  ConsumerState<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends ConsumerState<VotingScreen> {
  int? _selectedPlayerId;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('투표 및 지목'),
        automaticallyImplyLeading: false,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                '누가 라이어인가요?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '플레이어들이 상의하여 가장 의심스러운 플레이어를 지목해 주세요. 지목된 플레이어를 선택하고 아래 버튼을 누르면 정체가 공개됩니다.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 32),

              // Player Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: gameState.players.length,
                  itemBuilder: (context, index) {
                    final player = gameState.players[index];
                    final isSelected = _selectedPlayerId == player.id;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPlayerId = player.id;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1E1E1E) : const Color(0xFFFDFBF7),
                          border: Border.all(
                            color: const Color(0xFF1E1E1E),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? []
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF1E1E1E).withAlpha(10),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFAF6EE) : const Color(0xFF1E1E1E),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                size: 24,
                                color: isSelected ? const Color(0xFF1E1E1E) : const Color(0xFFFAF6EE),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              player.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFFFAF6EE) : const Color(0xFF1E1E1E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Arrest Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedPlayerId == null
                      ? null
                      : () {
                          ref.read(gameProvider.notifier).votePlayer(_selectedPlayerId!);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    foregroundColor: const Color(0xFFFAF6EE),
                    disabledBackgroundColor: const Color(0xFFE5DFD5),
                    disabledForegroundColor: const Color(0xFF9E9E9E),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '지목한 플레이어 정체 공개',
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
