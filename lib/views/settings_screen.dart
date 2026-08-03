import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyController = TextEditingController();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill if key exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = ref.read(gameProvider).settings.apiKey;
      if (key != null) {
        _keyController.text = key;
      }
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final currentKey = gameState.settings.apiKey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gemini API 설정',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '라이어 게임 제시어 생성을 위해 Gemini API 키가 필요합니다. 입력된 키는 기기에만 안전하게 저장됩니다.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 24),
              
              // API Key Text Field
              TextField(
                controller: _keyController,
                obscureText: _obscureText,
                style: const TextStyle(color: Color(0xFF1E1E1E)),
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  labelStyle: const TextStyle(color: Color(0xFF757575)),
                  hintText: 'AIzaSy...',
                  hintStyle: const TextStyle(color: Color(0xFFC0B9AF)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF1E1E1E), width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF1E1E1E), width: 2.0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF1E1E1E),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  // Save Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        final key = _keyController.text.trim();
                        if (key.isNotEmpty) {
                          await ref.read(gameProvider.notifier).saveApiKey(key);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('API 키가 성공적으로 저장되었습니다.'),
                                backgroundColor: Color(0xFF1E1E1E),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1E1E),
                        foregroundColor: const Color(0xFFFAF6EE),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '저장하기',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Delete Button (only if active key exists)
                  if (currentKey != null && currentKey.isNotEmpty)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () async {
                          await ref.read(gameProvider.notifier).deleteApiKey();
                          _keyController.clear();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('API 키가 삭제되었습니다.'),
                                backgroundColor: Color(0xFF1E1E1E),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E1E1E),
                          side: const BorderSide(color: Color(0xFF1E1E1E), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '삭제',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
              
              const Spacer(),
              
              // Key Guide
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFBF7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5DFD5), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API 키 발급 방법',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        // In real device can use url_launcher, but since we are simple:
                      },
                      child: const Text(
                        'Google AI Studio에서 무료로 API 키를 발급받을 수 있습니다. 발급받은 키를 여기에 붙여넣어 주세요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
