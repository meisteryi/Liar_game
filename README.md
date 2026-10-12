# 🕵️‍♂️ AI 라이어 게임 (AI Liar Game)

<p align="center">
  <b>Google Gemini AI가 만들어내는 무한하고 기발한 제시어로 즐기는 모바일 라이어 게임</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Google%20Gemini%20AI-Generative%20AI-8E75C4?style=for-the-badge&logo=googlegemini&logoColor=white" />
  <img src="https://img.shields.io/badge/State%20Management-Riverpod-blue?style=for-the-badge" />
</p>

---

## 💡 Overview

**AI 라이어 게임 (Liar Game)**은 친구들과 오프라인으로 모여 스마트폰 한 대를 돌려가며 즐길 수 있는 파티 추리 보드게임 애플리케이션입니다.

기존 라이어 게임의 고정된 단어 데이터베이스 한계를 뛰어넘어, **Google Gemini 생성형 AI API**를 연동하여 사용자가 입력한 자유 주제 또는 AI 자동 추론을 통해 매 판마다 신선하고 흥미진진한 제시어 쌍과 힌트를 동적으로 생성합니다.

---

## ✨ Key Features (주요 기능)

### 1. 🤖 Gemini AI 실시간 단어 & 힌트 생성 엔진
* **무한한 카테고리 & 자유 주제 지원**:
  * 음식, 영화, 동물 같은 일반적인 주제는 물론, "우리 동네 맛집", "대학 과목", "최신 밈" 등 어떤 주제를 입력해도 Gemini가 즉시 찰떡같은 제시어를 생성
* **다양한 Gemini 모델 Fallback 대응**:
  * 서비스 안정성을 위해 트래픽 급증 시 `gemini-3.5-flash`, `gemini-2.5-flash`, `gemini-2.0-flash` 등으로 유연하게 자동 폴백(Fallback) 전환

### 2. 🎭 2가지 게임 모드 (Game Modes)
* **스탠다드 모드 (Standard Liar)**:
  * 시민들은 진짜 단어를 확인하고, 라이어에게는 오직 **'라이어'**라는 사실만 전달됩니다.
  * 라이어는 들키지 않기 위해 눈치껏 그럴듯한 설명을 해야 합니다.
* **스파이 모드 (Spy / Alternative Word Mode)**:
  * 라이어(스파이)에게 진짜 단어와 매우 유사하지만 미묘하게 다른 대체 단어(예: '짜장면' vs '짬뽕')를 몰래 부여합니다.
  * 자신이 라이어인지조차 모른 채 자연스럽게 대화하다가 점차 이상함을 감지하게 되는 고도의 심리전 모드입니다.

### 3. ⚖️ 3단계 AI 난이도 조절 (Difficulty)
* **쉬움 (Easy)**: 흔하고 직관적인 단어 쌍으로 초심자나 가벼운 분위기에 적합
* **보통 (Medium)**: 서로 밀접하게 연관되어 있어 헷갈리기 쉬운 단어 쌍
* **어려움 (Hard)**: 미묘한 뉘앙스 차이로 고도의 관찰력과 추리가 필요한 매니아용 단어 쌍

### 4. 📱 스마트폰 1대로 즐기는 완벽한 게임 플로우
* **홈 & 게임 설정 (`HomeScreen`)**: 플레이어 수(3~10인+), 라이어 수(1~3인), 게임 모드, 난이도, 주제 설정
* **비밀 카드 확인 (`CardCheckScreen`)**: 다음 사람에게 폰을 넘기며 한 명씩 터치/홀드로 자신의 단어를 확인 (스포일러 방지)
* **토론 & 발언 타이머 (`DiscussionScreen`)**: 발언 순서 안내 및 남은 토론 시간 카운트다운 타이머 제공
* **투표 시스템 (`VotingScreen`)**: 의심되는 사람을 손쉽게 터치하여 투표 집계
* **결과 & 역전 찬스 (`ResultScreen`)**:
  * 라이어의 정체 공개
  * 라이어가 지목되었을 경우, 진짜 단어를 맞추면 라이어가 승리하는 마지막 역전 퀴즈 기회 제공

### 5. ⚙️ 설정 & API Key 관리 (`SettingsScreen`)
* 사용자의 개인 Google Gemini API 키를 로컬 스토리지(`SharedPreferences`)에 안전하게 저장하여 무료로 이용 가능

---

## 🛠 Tech Stack (기술 스택)

| 영역 | 기술 스택 | 설명 |
| :--- | :--- | :--- |
| **Framework** | **Flutter (Dart)** | iOS / Android 멀티플랫폼 모바일 앱 |
| **State Management** | **Flutter Riverpod (2.5+)** | 게임 세션, 타이머, AI 응답 상태의 불변성 및 반응형 관리 |
| **AI Integration** | **google_generative_ai** | 공식 Google Gemini SDK를 통한 구조화된 JSON 프롬프트 생성 |
| **Local Storage** | **shared_preferences** | 사용자 지정 API Key 및 기본 게임 설정 영속화 |
| **Typography** | **google_fonts** | 세련되고 몰입감 있는 폰트 스타일링 |

---

## 📂 Project Structure (프로젝트 구조)

```text
Liar_game/
├── pubspec.yaml                  # Flutter 의존성 설정
├── lib/
│   ├── main.dart                 # 앱 엔트리포인트 및 테마 설정
│   ├── models/                   # 데이터 모델
│   │   ├── game_settings.dart    # 게임 설정(인원, 모드, 난이도, 주제)
│   │   └── game_state.dart       # 게임 진행 상태(플레이어 역할, 단계, 단어)
│   ├── providers/                # Riverpod 상태 관리
│   │   ├── game_provider.dart    # 전체 게임 흐름(시작, 카드 확인, 투표, 판정) 로직
│   │   └── gemini_provider.dart  # Gemini AI API 호출 및 단어 생성 서비스
│   ├── services/
│   │   └── storage_service.dart  # API 키 및 로컬 설정 저장 서비스
│   └── views/                    # UI 화면
│       ├── home_screen.dart      # 게임 세팅 및 시작 화면
│       ├── card_check_screen.dart# 플레이어별 비밀 카드 확인 화면
│       ├── discussion_screen.dart# 토론 및 타이머 화면
│       ├── voting_screen.dart    # 라이어 지목 투표 화면
│       ├── result_screen.dart    # 최종 결과 및 라이어 역전 정답 화면
│       └── settings_screen.dart  # Gemini API 키 설정 화면
```

---

## 🚀 Getting Started (실행 방법)

### 사전 준비
* Flutter SDK (최신 Stable 버전 권장)
* Dart SDK
* Google AI Studio에서 발급받은 **Gemini API Key** (무료 발급 가능)

### 설치 및 실행

1. **레포지토리 클론**
   ```bash
   git clone https://github.com/meisteryi/Liar_game.git
   cd Liar_game
   ```

2. **의존성 설치**
   ```bash
   flutter pub get
   ```

3. **앱 실행**
   ```bash
   flutter run
   ```

4. **앱 실행 후**: 설정(⚙️) 아이콘을 눌러 본인의 Gemini API 키를 입력하면 바로 AI 생성 단어로 게임을 시작할 수 있습니다.
