import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/game_settings.dart';

class GeminiWordResult {
  final String targetWord;
  final String alternativeWord;
  final String hint;

  GeminiWordResult({
    required this.targetWord,
    required this.alternativeWord,
    required this.hint,
  });

  factory GeminiWordResult.fromJson(Map<String, dynamic> json) {
    return GeminiWordResult(
      targetWord: json['target_word'] ?? '',
      alternativeWord: json['alternative_word'] ?? '',
      hint: json['hint'] ?? '',
    );
  }
}

class GeminiService {
  // Priority list of models authorized for the key to rotate on errors (like 503 high demand)
  static const List<String> _fallbackModels = [
    'gemini-3.5-flash',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-flash-latest',
    'gemini-3.5-flash-lite',
    'gemini-2.0-flash-lite',
  ];

  Future<GeminiWordResult> generateWords({
    required String apiKey,
    required String theme,
    required GameDifficulty difficulty,
    required GameMode mode,
  }) async {
    String difficultyDescription = '';
    switch (difficulty) {
      case GameDifficulty.easy:
        difficultyDescription = '쉬움 (아주 흔하고 명확하게 다른 단어 쌍, 대중적인 주제)';
        break;
      case GameDifficulty.medium:
        difficultyDescription = '보통 (대중적이지만 서로 연관도가 높아 혼동하기 쉬운 단어 쌍)';
        break;
      case GameDifficulty.hard:
        difficultyDescription =
            '어려움 (유사도가 매우 높아 구분하기 아주 미묘하거나, 조금 더 구체적이고 매니아틱한 단어 쌍)';
        break;
    }

    final prompt =
        '''
너는 라이어 게임(Liar Game)을 위한 단어 생성기야.
아래 조건에 따라 게임 제시어를 한국어로 생성해 줘.

[게임 조건]
1. 주제/테마: ${theme.isEmpty ? '아무거나 흥미롭고 재미있는 주제 자율 선정' : theme}
2. 난이도: $difficultyDescription
3. 게임 모드: ${mode == GameMode.spy ? '스파이(바보) 모드 - 일반 플레이어가 받는 단어(target_word)와 스파이가 받는 단어(alternative_word)가 서로 매우 비슷하면서도 확실히 달라야 함.' : '일반 라이어 모드 - 제시어와 힌트를 정해주면 됨.'}

[단어 선정 가이드라인]
- 명사 형태의 구체적이고 직관적인 단어여야 함.
- 스파이 모드일 때 두 단어(target_word, alternative_word)는 반드시 동일한 범주에 속해야 함 (예: 짜장면과 짬뽕, 사과와 배, 스마트폰과 태블릿).
- 난이도가 '어려움'일수록 두 단어의 차이가 미세하고 헷갈려야 함 (예: 카페라떼와 카푸치노).
- 난이도가 '쉬움' 에 가까울수록 너무 구체적이지 않은, 일반적인 사람들이라면 거의 모두가 알 수 있는 단어를 제시해야 함.
- 사용자가 입력한 카테고리 안에 포함되는 단어만을 제시해야 함. 예를 들어 입력받은 단어가 '영화' 이면, 영화와 관련된 모든 단어 중에 고르는 게 아니라, 영화 제목 중에 고르는 거임.
- 결과는 JSON 형식으로 반환해야 함.
''';

    Object? lastError;

    for (final modelName in _fallbackModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: Schema.object(
              properties: {
                'target_word': Schema.string(
                  description:
                      'The secret word for standard players (in Korean). e.g., "짜장면". Must be a single specific noun.',
                ),
                'alternative_word': Schema.string(
                  description:
                      'The secret word for the Spy/Fool player in Spy Mode (in Korean). It must be closely related to target_word but different. e.g., "짬뽕" if target is "짜장면". In standard mode, this can be a similar concept too, but will act as a reference.',
                ),
                'hint': Schema.string(
                  description:
                      'A hint or common category that applies to both words (in Korean). e.g., "중식 면 요리".',
                ),
              },
              requiredProperties: ['target_word', 'alternative_word', 'hint'],
            ),
          ),
        );

        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text == null) {
          throw Exception('Model $modelName returned an empty response.');
        }

        final Map<String, dynamic> decoded = jsonDecode(text);
        return GeminiWordResult.fromJson(decoded);
      } catch (e) {
        lastError = e;
        debugPrint(
          'Warning: Model $modelName failed: $e. Retrying with next model...',
        );
      }
    }

    // If we exhausted all fallback models
    throw Exception('모든 제미나이 모델이 일시적으로 사용 불가능합니다. (마지막 오류: $lastError)');
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
