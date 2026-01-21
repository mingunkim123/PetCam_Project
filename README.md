📸 PetCam Project
PetCam은 ESP32 기반의 저전력 카메라, AI 업스케일링 서버, 그리고 크로스 플랫폼 모바일 앱으로 구성된 지능형 반려동물 모니터링 시스템입니다.

🏗️ System Architecture
AI Server (Backend)
Mobile App (Flutter)
Firmware (ESP32)
Capture
BLE
WiFi/HTTP
Control
View Photos
State Mgmt
Upscale
Store
Deploy
Camera Module
ESP32 Board
Mobile App
AI Server
Riverpod
Real-ESRGAN
PostgreSQL
Docker Compose
🚀 Components & Tech Stack
1. 📱 Mobile App (/mobile_app)
사용자가 반려동물의 사진을 확인하고 카메라를 제어하는 프론트엔드입니다.

Framework: Flutter
State Management: Riverpod (Notifier Pattern)
Routing: GoRouter
Features:
Infinite Scroll: 끊김 없는 갤러리 탐색
BLE Control: 근거리 카메라 제어
Naver Map: 사진 촬영 위치 지도 표시
2. 🧠 AI Server (/ai_server)
이미지를 수신하고 AI로 화질을 개선(Upscaling)하여 저장하는 백엔드입니다.

Framework: FastAPI (Python)
Database: PostgreSQL + Async SQLAlchemy (Asyncpg)
AI Model: Real-ESRGAN (Super Resolution)
Infrastructure: Docker & Docker Compose
Security: Environment Variables (.env), Input Validation
3. 📷 Firmware (/firmware)
ESP32 하드웨어를 제어하여 사진을 촬영하고 전송합니다.

Platform: PlatformIO (C++)
Hardware: ESP32-CAM (OV2640/OV5640)
Features:
Deep Sleep: 배터리 절약 모드
Smart Config: 간편한 Wi-Fi 설정
Buffer Management: 안정적인 이미지 전송
🛠️ Getting Started
Prerequisites
Docker & Docker Compose
Flutter SDK
PlatformIO (VS Code Extension)
1. AI Server Setup
cd ai_server
# .env 파일 설정 (DATABASE_URL 등)
docker-compose up --build -d
서버가 localhost:8000에서 실행됩니다.

2. Mobile App Setup
cd mobile_app
flutter pub get
flutter run
3. Firmware Setup
VS Code에서 /firmware 폴더 열기
PlatformIO 확장에서 Upload 클릭 (ESP32 연결 필요)
✨ Key Features
AI Super Resolution: 저해상도 ESP32 이미지를 고화질로 자동 변환
Async Architecture: 대용량 트래픽 처리를 위한 비동기 서버 구조
Modern UI/UX: 사용자 친화적인 모바일 인터페이스
Developed by Mingun Kim
