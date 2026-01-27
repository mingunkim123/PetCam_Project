# PetCam Mobile App

Flutter 기반 크로스 플랫폼 반려동물 모니터링 앱입니다.

## 주요 기능

- **사진 갤러리**: AI 업스케일된 고화질 반려동물 사진 무한 스크롤 탐색
- **BLE 제어**: ESP32-CAM과 블루투스 연결하여 근거리 촬영 제어
- **산책 기록**: Naver Map 기반 산책 경로 기록 및 히스토리 관리
- **실시간 심박수**: BLE를 통한 반려동물 심박수 모니터링
- **JWT 인증**: 안전한 토큰 기반 사용자 인증

## 프로젝트 구조

```
lib/
├── main.dart                      # 앱 진입점, 테마 설정
├── models/
│   └── pet_photo.dart             # 사진 모델
└── src/
    ├── core/
    │   ├── constants/
    │   │   └── constants.dart     # 색상, 스타일, 상수 정의
    │   └── widgets/               # 공통 위젯
    │       ├── connection_status_badge.dart
    │       ├── main_drawer.dart
    │       ├── ad_banner.dart
    │       └── section_header.dart
    │
    ├── features/                  # 기능별 모듈 (Feature-First 구조)
    │   ├── auth/                  # 인증
    │   │   └── presentation/
    │   │       └── login_screen.dart
    │   │
    │   ├── home/                  # 홈 화면
    │   │   ├── data/
    │   │   │   └── pet_repository.dart
    │   │   ├── domain/
    │   │   │   └── pet_profile.dart
    │   │   └── presentation/
    │   │       ├── home_controller.dart
    │   │       ├── home_screen.dart
    │   │       └── widgets/
    │   │           ├── ai_comparison_sheet.dart
    │   │           ├── control_panel.dart
    │   │           ├── featured_pet_photo.dart
    │   │           ├── heart_rate_monitor.dart
    │   │           ├── pet_favorites_card.dart
    │   │           ├── pet_profile_card.dart
    │   │           └── summary_card.dart
    │   │
    │   ├── gallery/               # 사진 갤러리
    │   │   ├── data/
    │   │   │   └── gallery_repository.dart
    │   │   ├── domain/
    │   │   │   └── pet_photo.dart
    │   │   └── presentation/
    │   │       ├── gallery_controller.dart
    │   │       ├── gallery_screen.dart
    │   │       └── widgets/
    │   │           ├── empty_photo_state.dart
    │   │           └── image_preview_list.dart
    │   │
    │   ├── map/                   # 산책 지도
    │   │   ├── data/
    │   │   │   └── walk_repository.dart
    │   │   ├── domain/
    │   │   │   ├── walk_point.dart
    │   │   │   └── walk_session.dart
    │   │   └── presentation/
    │   │       ├── map_screen.dart
    │   │       ├── walk_detail_screen.dart
    │   │       └── walk_history_screen.dart
    │   │
    │   └── store/                 # 스토어
    │       ├── data/
    │       │   └── store_repository.dart
    │       ├── domain/
    │       │   └── store_item.dart
    │       └── presentation/
    │           ├── store_controller.dart
    │           └── store_screen.dart
    │
    ├── routing/
    │   └── app_router.dart        # GoRouter 라우팅 설정
    │
    └── services/                  # 공통 서비스
        ├── ai_service.dart        # AI 서버 API 호출
        ├── auth_service.dart      # JWT 인증 관리
        ├── ble_service.dart       # BLE 통신
        ├── heart_rate_service.dart
        └── store_service.dart
```

## 환경 설정

### 1. 사전 요구사항

- Flutter SDK 3.10.4 이상
- Dart SDK 3.0 이상
- Android Studio / Xcode (플랫폼별)

### 2. 환경 변수 설정

프로젝트 루트에 `.env` 파일 생성:

```bash
# AI 서버 URL
API_URL=http://your-server-ip:8000

# Naver Map Client ID (네이버 클라우드 콘솔에서 발급)
NAVER_MAP_CLIENT_ID=your-naver-map-client-id
```

### 3. 의존성 설치

```bash
flutter pub get
```

### 4. 플랫폼별 설정

#### Android

`android/app/src/main/AndroidManifest.xml`에 권한 추가 (이미 설정됨):
- 인터넷, 블루투스, 위치 권한

#### iOS

`ios/Runner/Info.plist`에 권한 설명 추가 (이미 설정됨):
- 블루투스, 위치 사용 권한 설명

## 실행 방법

### 개발 모드

```bash
# 디바이스 확인
flutter devices

# 실행
flutter run

# 특정 디바이스로 실행
flutter run -d <device_id>
```

### 빌드

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store용)
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 주요 의존성

| 패키지 | 용도 |
|--------|------|
| `flutter_riverpod` | 상태 관리 |
| `go_router` | 선언적 라우팅 |
| `flutter_blue_plus` | BLE 통신 |
| `flutter_naver_map` | 지도 표시 |
| `http` | HTTP 클라이언트 |
| `flutter_secure_storage` | 안전한 토큰 저장 |
| `flutter_dotenv` | 환경 변수 관리 |
| `geolocator` | 위치 서비스 |
| `permission_handler` | 권한 관리 |
| `image_picker` | 이미지 선택 |

## 아키텍처

### 상태 관리: Riverpod

```dart
// Provider 정의 예시
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// 사용 예시
Consumer(builder: (context, ref, child) {
  final authState = ref.watch(authProvider);
  // ...
})
```

### 라우팅: GoRouter

```dart
// app_router.dart에서 정의
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/gallery', builder: (_, __) => const GalleryScreen()),
    // ...
  ],
);
```

### API 통신

```dart
// AuthService를 통한 인증된 요청
final headers = await AuthService().getAuthHeaders();
final response = await http.get(
  Uri.parse('$baseUrl/photos'),
  headers: headers,
);
```

## 개발 가이드

### 새 기능 추가 시

1. `lib/src/features/` 아래에 새 폴더 생성
2. Feature-First 구조 따르기:
   - `data/` - Repository, DataSource
   - `domain/` - Model, Entity
   - `presentation/` - Screen, Controller, Widget

### 코드 스타일

```bash
# 린트 검사
flutter analyze

# 포맷팅
dart format lib/
```

## 트러블슈팅

### BLE 연결 실패

1. 블루투스 활성화 확인
2. 위치 권한 허용 확인 (Android에서 BLE 스캔에 필요)
3. ESP32 기기가 광고 중인지 확인

### Naver Map 로드 실패

1. `.env` 파일의 `NAVER_MAP_CLIENT_ID` 확인
2. 네이버 클라우드 콘솔에서 앱 번들 ID 등록 확인

### API 연결 실패

1. `.env` 파일의 `API_URL` 확인
2. 서버가 실행 중인지 확인
3. 네트워크 연결 상태 확인

## 라이선스

이 프로젝트는 내부 사용 목적으로 개발되었습니다.
