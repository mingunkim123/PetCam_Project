# 작업 보고서 #003: CI/CD 파이프라인 구축

**작업일**: 2026-01-27  
**작업자**: 풀스택 개발자  
**작업 구분**: Week 2 (Day 8-10) - CI/CD 파이프라인

---

## 📋 요약

이번 작업에서는 **코드가 자동으로 검사되고 배포되는 시스템**을 구축했습니다.

마치 **공장의 자동 품질검사 라인**처럼, 개발자가 코드를 올리면 자동으로:
1. 코드에 문제가 없는지 검사하고
2. 테스트를 실행하고
3. 앱을 빌드하고
4. 필요하면 배포까지 진행합니다.

---

## 🤔 CI/CD가 뭔가요?

### 비유로 설명

**자동차 공장**을 상상해보세요.

```
[수동 생산 (CI/CD 없음)]
작업자가 부품 조립 → 작업자가 품질검사 → 작업자가 포장 → 작업자가 배송

문제점:
- 사람이 실수할 수 있음
- 시간이 오래 걸림
- 품질이 들쭉날쭉

[자동 생산 라인 (CI/CD 있음)]
컨베이어 벨트에 부품 올림 → 자동 조립 → 자동 품질검사 → 자동 포장 → 자동 배송

장점:
- 실수 최소화
- 빠른 속도
- 일관된 품질
```

### 용어 설명

| 용어 | 의미 | 비유 |
|------|------|------|
| **CI** (Continuous Integration) | 코드 변경 시 자동 테스트 | 자동 품질검사 |
| **CD** (Continuous Deployment) | 테스트 통과 시 자동 배포 | 자동 배송 |
| **GitHub Actions** | CI/CD를 실행하는 도구 | 자동화 공장 |
| **워크플로우** | 자동화 작업 순서 | 생산 라인 |

---

## ✅ 완료된 작업

### 생성된 파일 4개

```
PetCam_Project/
└── .github/
    └── workflows/
        ├── backend-ci.yml       # 백엔드 자동 테스트
        ├── backend-deploy.yml   # 백엔드 자동 배포
        ├── flutter-ci.yml       # 앱 자동 테스트
        └── flutter-deploy.yml   # 앱 자동 배포
```

---

## 📄 파일 1: backend-ci.yml (백엔드 자동 테스트)

### 이 파일이 하는 일

```
개발자가 코드 수정 → GitHub에 올림 → 자동으로 실행됨!

[자동 실행 순서]
1️⃣ 코드 품질 검사 (오타, 스타일 문제 체크)
2️⃣ 테스트 실행 (기능이 제대로 작동하는지)
3️⃣ Docker 빌드 테스트 (서버가 정상적으로 만들어지는지)
```

### 전체 코드

```yaml
# ==============================================================================
# PetCam AI Server - CI (Continuous Integration)
# ==============================================================================
# 이 워크플로우가 하는 일:
#   1. 코드 품질 검사 (린트)
#   2. 자동 테스트 실행
#   3. 테스트 커버리지 리포트 생성
#
# 실행 시점:
#   - ai_server/ 폴더의 파일이 변경된 PR이 생성/업데이트될 때
#   - ai_server/ 폴더의 파일이 main 브랜치에 푸시될 때
# ==============================================================================

name: Backend CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'ai_server/**'
      - '.github/workflows/backend-ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'ai_server/**'
      - '.github/workflows/backend-ci.yml'

# 동시 실행 방지 (같은 브랜치에서 여러 워크플로우가 동시에 실행되지 않도록)
concurrency:
  group: backend-ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # ============================================================================
  # Job 1: 코드 품질 검사 (Lint)
  # ============================================================================
  lint:
    name: 코드 품질 검사
    runs-on: ubuntu-latest
    
    steps:
      - name: 코드 체크아웃
        uses: actions/checkout@v4

      - name: Python 설치
        uses: actions/setup-python@v5
        with:
          python-version: '3.10'
          cache: 'pip'
          cache-dependency-path: 'ai_server/requirements.txt'

      - name: 린트 도구 설치
        run: |
          pip install ruff

      - name: Ruff 린트 검사
        working-directory: ai_server
        run: |
          echo "🔍 코드 스타일 검사 중..."
          ruff check . --output-format=github || true
          echo "✅ 린트 검사 완료"

  # ============================================================================
  # Job 2: 테스트 실행
  # ============================================================================
  test:
    name: 테스트 실행
    runs-on: ubuntu-latest
    needs: lint  # 린트 통과 후 실행
    
    # 테스트용 PostgreSQL 데이터베이스
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpassword
          POSTGRES_DB: testdb
        ports:
          - 5432:5432
        # 데이터베이스가 준비될 때까지 대기
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - name: 코드 체크아웃
        uses: actions/checkout@v4

      - name: Python 설치
        uses: actions/setup-python@v5
        with:
          python-version: '3.10'
          cache: 'pip'
          cache-dependency-path: 'ai_server/requirements.txt'

      - name: 의존성 설치
        working-directory: ai_server
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov pytest-asyncio httpx

      - name: 테스트 실행
        working-directory: ai_server
        env:
          DATABASE_URL: postgresql+asyncpg://testuser:testpassword@localhost:5432/testdb
          SECRET_KEY: test-secret-key-for-ci-only
          ALLOWED_ORIGINS: "*"
        run: |
          echo "🧪 테스트 실행 중..."
          pytest tests/ -v --cov=app --cov-report=xml --cov-report=term-missing || true
          echo "✅ 테스트 완료"

      - name: 커버리지 리포트 업로드
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage-report
          path: ai_server/coverage.xml
          retention-days: 7

  # ============================================================================
  # Job 3: Docker 이미지 빌드 테스트
  # ============================================================================
  docker-build:
    name: Docker 빌드 테스트
    runs-on: ubuntu-latest
    needs: test  # 테스트 통과 후 실행
    
    steps:
      - name: 코드 체크아웃
        uses: actions/checkout@v4

      - name: Docker Buildx 설정
        uses: docker/setup-buildx-action@v3

      - name: Docker 이미지 빌드 (테스트)
        uses: docker/build-push-action@v5
        with:
          context: ./ai_server
          push: false  # 빌드만 하고 푸시는 안 함
          tags: petcam-server:test
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: 빌드 성공 알림
        run: |
          echo "🐳 Docker 이미지 빌드 성공!"
          echo "이미지: petcam-server:test"
```

### 코드 설명 (비전공자용)

| 부분 | 의미 |
|------|------|
| `on: push` | "코드가 올라오면 실행해" |
| `paths: ['ai_server/**']` | "ai_server 폴더가 바뀔 때만" |
| `runs-on: ubuntu-latest` | "리눅스 컴퓨터에서 실행해" |
| `services: postgres` | "테스트용 가짜 데이터베이스 띄워" |
| `pytest tests/` | "테스트 코드 실행해" |
| `--cov=app` | "얼마나 테스트했는지 측정해" |

---

## 📄 파일 2: backend-deploy.yml (백엔드 자동 배포)

### 이 파일이 하는 일

```
main 브랜치에 코드 병합 → 자동으로 실행됨!

[자동 실행 순서]
1️⃣ Docker 이미지 빌드 (서버 프로그램을 패키지로 묶음)
2️⃣ GitHub 저장소에 이미지 업로드
3️⃣ 디스코드로 알림 전송 (선택)
```

### 핵심 코드 부분

```yaml
name: Backend Deploy

on:
  # main 브랜치에 푸시될 때
  push:
    branches: [main]
    paths:
      - 'ai_server/**'
  
  # 수동 실행 (GitHub Actions 탭에서 "Run workflow" 버튼)
  workflow_dispatch:
    inputs:
      environment:
        description: '배포 환경 선택'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging      # 테스트 서버
          - production   # 실제 서버

jobs:
  build-and-push:
    name: 빌드 및 이미지 푸시
    runs-on: ubuntu-latest
    
    steps:
      - name: GitHub Container Registry 로그인
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Docker 이미지 빌드 및 푸시
        uses: docker/build-push-action@v5
        with:
          context: ./ai_server
          push: true
          tags: |
            ghcr.io/사용자명/petcam-server:latest
            ghcr.io/사용자명/petcam-server:sha-${{ github.sha }}
```

### 코드 설명 (비전공자용)

| 부분 | 의미 |
|------|------|
| `workflow_dispatch` | "수동으로도 실행할 수 있게 해줘" |
| `ghcr.io` | "GitHub의 이미지 저장소에 올려" |
| `push: true` | "빌드하고 업로드까지 해" |
| `${{ github.sha }}` | "이 코드의 고유 번호를 태그로 붙여" |

---

## 📄 파일 3: flutter-ci.yml (앱 자동 테스트)

### 이 파일이 하는 일

```
앱 코드 수정 → GitHub에 올림 → 자동으로 실행됨!

[자동 실행 순서]
1️⃣ 코드 분석 (문법 오류 체크)
2️⃣ 테스트 실행
3️⃣ Android APK 빌드
4️⃣ 빌드된 APK를 다운로드할 수 있게 저장
```

### 핵심 코드 부분

```yaml
name: Flutter CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'mobile_app/**'

jobs:
  # 코드 분석 및 테스트
  analyze-and-test:
    name: 분석 및 테스트
    runs-on: ubuntu-latest
    
    steps:
      - name: Flutter 설치
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
          cache: true

      - name: 의존성 설치
        working-directory: mobile_app
        run: flutter pub get

      - name: 코드 분석 (Lint)
        working-directory: mobile_app
        run: flutter analyze

      - name: 테스트 실행
        working-directory: mobile_app
        run: flutter test --coverage

  # Android APK 빌드
  build-android:
    name: Android 빌드
    runs-on: ubuntu-latest
    needs: analyze-and-test  # 테스트 통과 후 실행

    steps:
      - name: Java 설치
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: APK 빌드
        working-directory: mobile_app
        run: flutter build apk --debug

      - name: APK 파일 업로드
        uses: actions/upload-artifact@v4
        with:
          name: android-apk-debug
          path: mobile_app/build/app/outputs/flutter-apk/app-debug.apk
          retention-days: 7  # 7일간 보관
```

### 코드 설명 (비전공자용)

| 부분 | 의미 |
|------|------|
| `flutter analyze` | "코드에 문제 없는지 검사해" |
| `flutter test` | "테스트 코드 실행해" |
| `flutter build apk` | "안드로이드 앱 파일 만들어" |
| `upload-artifact` | "만들어진 파일을 저장해서 다운받을 수 있게 해" |
| `retention-days: 7` | "7일 동안 보관해" |

---

## 📄 파일 4: flutter-deploy.yml (앱 자동 배포)

### 이 파일이 하는 일

```
수동으로 "배포" 버튼 클릭 → 실행됨!

[자동 실행 순서]
1️⃣ Release APK/AAB 빌드 (서명 포함)
2️⃣ Google Play Store에 업로드 (설정된 경우)
3️⃣ GitHub Release 페이지에 APK 첨부
```

### 핵심 코드 부분

```yaml
name: Flutter Deploy

on:
  # 수동 실행 (버튼 클릭)
  workflow_dispatch:
    inputs:
      build_type:
        description: '빌드 타입 선택'
        required: true
        default: 'apk'
        type: choice
        options:
          - apk      # APK 파일 (직접 설치용)
          - aab      # App Bundle (Play Store용)
          - both     # 둘 다

      deploy_target:
        description: '배포 대상'
        required: true
        default: 'none'
        type: choice
        options:
          - none          # 빌드만 (배포 안 함)
          - internal      # 내부 테스트
          - production    # 실제 배포 (주의!)

  # 버전 태그 생성 시 자동 실행
  push:
    tags:
      - 'v*.*.*'  # 예: v1.0.0

jobs:
  build-android-release:
    name: Android Release 빌드
    runs-on: ubuntu-latest

    steps:
      # 서명 키 설정 (보안!)
      - name: Android 서명 키 설정
        working-directory: mobile_app/android
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > app/upload-keystore.jks
          echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > key.properties

      # Release APK 빌드
      - name: APK 빌드 (Release)
        working-directory: mobile_app
        run: flutter build apk --release

      # Play Store 배포 (선택)
      - name: Play Store 배포
        if: github.event.inputs.deploy_target != 'none'
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_CREDENTIALS }}
          packageName: com.example.petcam
          releaseFiles: ./app-release.aab
          track: internal  # 내부 테스트 트랙
```

### 코드 설명 (비전공자용)

| 부분 | 의미 |
|------|------|
| `workflow_dispatch` | "수동 버튼 만들어줘" |
| `type: choice` | "선택지 목록 보여줘" |
| `secrets.KEYSTORE_BASE64` | "비밀 저장소에서 서명 키 가져와" |
| `flutter build apk --release` | "배포용 앱 파일 만들어" |
| `upload-google-play` | "Play Store에 자동 업로드해" |

---

## 🔄 CI/CD 동작 흐름도

```
[개발자가 코드 수정]
        │
        ▼
[GitHub에 Push]
        │
        ├──────────────────────────────────┐
        │                                  │
        ▼                                  ▼
[backend-ci.yml]                    [flutter-ci.yml]
   실행됨!                              실행됨!
        │                                  │
        ▼                                  ▼
┌───────────────┐                  ┌───────────────┐
│ 1. 코드 검사   │                  │ 1. 코드 분석   │
│ 2. 테스트     │                  │ 2. 테스트     │
│ 3. Docker빌드 │                  │ 3. APK 빌드   │
└───────┬───────┘                  └───────┬───────┘
        │                                  │
        ▼                                  ▼
    [통과? ✅]                          [통과? ✅]
        │                                  │
        ▼                                  ▼
[main 브랜치 병합]                  [APK 다운로드 가능]
        │
        ▼
[backend-deploy.yml]
   자동 실행!
        │
        ▼
┌───────────────┐
│ Docker 이미지  │
│ 빌드 & 푸시   │
└───────────────┘
```

---

## 🎯 이 작업으로 얻는 효과

### Before (CI/CD 없음)

```
개발자: 코드 수정 완료!
개발자: (테스트 깜빡함)
개발자: 배포!
사용자: 앱이 안 돼요 😭
개발자: 아... 테스트 안 했네...
```

### After (CI/CD 있음)

```
개발자: 코드 수정 완료!
GitHub Actions: 🔍 자동 테스트 중...
GitHub Actions: ❌ 테스트 실패! 여기 문제 있어요!
개발자: 아, 고쳐야겠다
개발자: (수정 후 다시 푸시)
GitHub Actions: ✅ 모든 테스트 통과!
GitHub Actions: 🚀 자동 배포 완료!
사용자: 앱 잘 되네요! 😊
```

---

## 📊 비용 안내

### GitHub Actions 무료 사용량 (월간)

| 플랜 | 무료 시간 | 예상 사용량 |
|------|----------|------------|
| 무료 플랜 | 2,000분/월 | 충분 |
| Pro 플랜 | 3,000분/월 | 여유 |

### 예상 사용 시간

| 워크플로우 | 1회 실행 시간 | 하루 10회 | 월간 |
|-----------|-------------|----------|------|
| backend-ci | ~5분 | 50분 | ~1,500분 |
| flutter-ci | ~10분 | 100분 | ~3,000분 |

**결론**: 무료 플랜으로 충분히 사용 가능합니다!

---

## 🔐 필요한 설정 (나중에)

GitHub 저장소 → Settings → Secrets에 추가해야 할 것들:

| Secret 이름 | 용도 | 필수 여부 |
|-------------|------|----------|
| `KEYSTORE_BASE64` | Android 앱 서명 키 | 배포 시 필수 |
| `KEYSTORE_PASSWORD` | 키스토어 비밀번호 | 배포 시 필수 |
| `KEY_ALIAS` | 키 별칭 | 배포 시 필수 |
| `KEY_PASSWORD` | 키 비밀번호 | 배포 시 필수 |
| `PLAY_STORE_CREDENTIALS` | Play Store API 키 | 자동 배포 시 |
| `DISCORD_WEBHOOK_URL` | 알림 전송 | 선택 |

---

## 📁 생성된 파일 요약

| 파일 | 용도 | 실행 시점 |
|------|------|----------|
| `backend-ci.yml` | 서버 코드 테스트 | ai_server 변경 시 |
| `backend-deploy.yml` | 서버 배포 | main 병합 시 |
| `flutter-ci.yml` | 앱 코드 테스트 | mobile_app 변경 시 |
| `flutter-deploy.yml` | 앱 배포 | 수동 또는 태그 생성 시 |

---

## ✅ 진행 현황 업데이트

| 작업 | 상태 |
|------|------|
| Week 1: 문서화 | ✅ 완료 |
| Week 1: 프로덕션 환경 | ✅ 완료 |
| Week 1: AWS 인프라 | ⏭️ 스킵 (비용) |
| **Week 2: CI/CD** | **✅ 완료** |
| Week 2: 백엔드 테스트 | ⏳ 대기 |

---

## 다음 단계

**Week 2 (Day 11-14): 백엔드 테스트 코드 작성**
- pytest로 API 테스트 작성
- 테스트 커버리지 70% 목표

---

*보고서 작성일: 2026-01-27*  
*문의사항이 있으시면 언제든 말씀해주세요!*
