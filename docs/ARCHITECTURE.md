# PetCam 시스템 아키텍처 v3.0

> **프로젝트**: PetCam — 지능형 반려동물 모니터링 시스템  
> **작성일**: 2026-03-04  
> **펌웨어 버전**: v3.0 (Clean Architecture)

---

## 시스템 전체 구성도

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              PetCam System                                 │
│                                                                            │
│  ┌──────────────────┐        ┌──────────────┐        ┌──────────────────┐  │
│  │                  │  BLE   │              │  HTTP  │                  │  │
│  │  ESP32-S3 기기   │◄──────►│  Mobile App  │◄──────►│    AI Server     │  │
│  │  (Firmware v3.0) │        │  (Flutter)   │        │    (FastAPI)     │  │
│  │                  │  WiFi  │              │        │                  │  │
│  └────────┬─────────┘        └──────────────┘        └────────┬─────────┘  │
│           │                                                    │           │
│           │ HTTP Upload                                        │           │
│           └────────────────────────────────────────────────────┘           │
│                                                                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 하드웨어 구성

| 구분 | 부품 | 사양 | 인터페이스 |
|:-----|:-----|:-----|:-----------|
| MCU | ESP32-S3-WROOM-1-N16R8V | 240MHz, 16MB Flash, 8MB PSRAM | — |
| 카메라 | OV3660 | 3MP, UXGA, JPEG | DVP 8-bit (GPIO 6~18) |
| IMU | MPU6050 | 6축, ±4g, ±500°/s | I2C 0x68 (GPIO 1,2) |
| 심박센서 | MAX30102 | 광학 HR/SpO2, IR | I2C 0x57 (GPIO 1,2) |
| 통신 | 내장 | WiFi + BLE 5.0 | — |

---

## 펌웨어 아키텍처 (Clean Architecture / Layered)

### 계층 구조

```
┌──────────────────────────────────────────────────────────────┐
│                      App Layer                               │
│  main.cpp — 초기화 시퀀스                                     │
│  task_manager.cpp — FreeRTOS 4개 태스크 관리                  │
├──────────────────────────────────────────────────────────────┤
│                    Protocol Layer                             │
│  command_handler.cpp — BLE raw bytes → AppCommand 파싱       │
│  ble_protocol.cpp — 패킷 직렬화/역직렬화                      │
├──────────────────────────────────────────────────────────────┤
│                    Services Layer                             │
│  sensor_service.cpp — 이동평균 필터, 링 버퍼                  │
│  camera_service.cpp — 단발/미리보기/베스트컷 촬영              │
│  behavior_service.cpp — 활동·수면·기분·꼬리흔들기 분석         │
├──────────────────────────────────────────────────────────────┤
│                    Drivers Layer                              │
│  ble_driver.cpp — BLE GATT 서버, 청크 전송                    │
├──────────────────────────────────────────────────────────────┤
│                      HAL Layer                               │
│  camera_hal.cpp — esp_camera API 래핑                        │
│  sensor_hal.cpp — MPU6050 + MAX30102 라이브러리 래핑          │
├──────────────────────────────────────────────────────────────┤
│                      Config Layer                            │
│  board_config.h — GPIO 핀맵                                  │
│  ble_config.h — BLE UUID, MTU, 전송 설정                     │
│  app_config.h — 태스크 주기, 임계값, 버퍼 크기                │
│  app_types.h — 공유 구조체/enum 정의                         │
└──────────────────────────────────────────────────────────────┘
```

**의존성 규칙**: 항상 아래로만 참조 (HAL은 Services를 절대 참조하지 않음)

### 디렉터리 구조

```
firmware/
├── platformio.ini
├── boards/
│   └── esp32-s3-devkitc-1-n16r8v.json
├── include/
│   ├── config/
│   │   ├── board_config.h         ← GPIO 핀맵
│   │   ├── ble_config.h           ← BLE 설정
│   │   └── app_config.h           ← 태스크/임계값
│   ├── app/
│   │   ├── app_types.h            ← 공유 타입
│   │   └── task_manager.h
│   ├── hal/
│   │   ├── camera_hal.h
│   │   └── sensor_hal.h
│   ├── drivers/
│   │   └── ble_driver.h
│   ├── services/
│   │   ├── sensor_service.h
│   │   ├── camera_service.h
│   │   └── behavior_service.h
│   └── protocol/
│       ├── ble_protocol.h
│       └── command_handler.h
└── src/
    ├── main.cpp                   ← 초기화 시퀀스
    ├── app/
    │   └── task_manager.cpp       ← FreeRTOS 태스크 관리
    ├── hal/
    │   ├── camera_hal.cpp         ← OV3660 하드웨어 추상화
    │   └── sensor_hal.cpp         ← MPU6050/MAX30102 추상화
    ├── drivers/
    │   └── ble_driver.cpp         ← BLE GATT 서버
    ├── services/
    │   ├── sensor_service.cpp     ← 센서 필터링
    │   ├── camera_service.cpp     ← 촬영 로직
    │   └── behavior_service.cpp   ← 행동 분석 엔진
    └── protocol/
        ├── ble_protocol.cpp       ← 패킷 직렬화
        └── command_handler.cpp    ← 명령 파싱
```

---

## FreeRTOS 태스크 구성

### Dual-Core 배치

```
┌────────────────────────────────────────────────────────────────┐
│                        ESP32-S3 Dual Core                      │
│                                                                │
│  ┌─────────────────────────┐  ┌─────────────────────────────┐  │
│  │       Core 0            │  │         Core 1              │  │
│  │                         │  │                             │  │
│  │  ┌───────────────────┐  │  │  ┌───────────────────────┐  │  │
│  │  │ SensorTask 100Hz  │  │  │  │ CameraTask 이벤트기반 │  │  │
│  │  │ 센서 I2C 읽기     │  │  │  │ 촬영 + BLE 이미지전송 │  │  │
│  │  │ Stack: 4KB        │  │  │  │ Stack: 8KB            │  │  │
│  │  │ Priority: 3       │  │  │  │ Priority: 2           │  │  │
│  │  └───────────────────┘  │  │  └───────────────────────┘  │  │
│  │                         │  │                             │  │
│  │  ┌───────────────────┐  │  │  ┌───────────────────────┐  │  │
│  │  │ AnalysisTask 2Hz  │  │  │  │ BLETask 1Hz           │  │  │
│  │  │ 행동/수면/기분    │  │  │  │ 센서 데이터 BLE 전송  │  │  │
│  │  │ Stack: 8KB        │  │  │  │ Stack: 4KB            │  │  │
│  │  │ Priority: 2       │  │  │  │ Priority: 1           │  │  │
│  │  └───────────────────┘  │  │  └───────────────────────┘  │  │
│  └─────────────────────────┘  └─────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

**Core 분리 이유**: 카메라/BLE(Core 1)의 블로킹이 센서 샘플링(Core 0)에 영향을 주지 않도록 격리

### 태스크 상세

| 태스크 | Core | 주기 | Stack | 우선순위 | 역할 |
|:-------|:----:|:-----|:-----:|:--------:|:-----|
| SensorTask | 0 | 10ms (100Hz) | 4KB | 3 (최고) | MPU6050/MAX30102 I2C 읽기 → 링 버퍼 축적 |
| AnalysisTask | 0 | 500ms (2Hz) | 8KB | 2 | 필터링 데이터 기반 행동/수면/기분 분석 |
| CameraTask | 1 | 이벤트 기반 | 8KB | 2 | Queue에서 명령 수신 → 촬영 → BLE 전송 |
| BLETask | 1 | 1000ms (1Hz) | 4KB | 1 | PetStatus → 직렬화 → BLE Notify |

### 태스크 간 통신

```
                    ┌──────────────┐
  BLE 명령 수신 ──►│ cmdQueue     │──► CameraTask (촬영 실행)
                    │ (FreeRTOS    │
                    │  Queue ×8)   │
                    └──────────────┘

                    ┌──────────────┐
  AnalysisTask ───►│ statusMutex  │──► BLETask (센서 데이터 전송)
                    │ (Mutex       │
                    │  보호)       │
                    └──────────────┘
```

---

## BLE 통신 사양

### GATT 프로파일

| 항목 | 값 |
|:-----|:---|
| Device Name | `PetCam` |
| Service UUID | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` |
| MTU | 512 bytes |

### Characteristic 목록

| Characteristic | UUID | 속성 | 용도 |
|:---------------|:-----|:-----|:-----|
| Image Data | `beb5483e-...` | Notify | JPEG 이미지 청크 전송 |
| Command | `beb5483f-...` | Write / WriteNR | 촬영 명령 수신 |
| Sensor Data | `beb54840-...` | Notify / Read | PetStatus 실시간 전송 |

### 이미지 전송 프로토콜

```
앱 → ESP32: Write CMD Characteristic (촬영 명령)

ESP32 → 앱: Notify (헤더)  "SIZE:123456"
             ├── 50ms 대기
             ├── Notify (chunk 1)  128 bytes
             ├── 20ms 대기
             ├── Notify (chunk 2)  128 bytes
             ├── 20ms 대기
             └── ... (반복)
```

### BLE 명령 포맷

| 바이트 | 필드 | 값 |
|:------:|:-----|:---|
| 0 | 명령 타입 | 0x01: 단발 / 0x02: 베스트컷 / 0x03: 미리보기 |
| 1~8 | GPS 위도 | double (Little Endian) |
| 9~16 | GPS 경도 | double (Little Endian) |
| 17~20 | 촬영 수 (Burst) | int (베스트컷일 때만 사용) |

---

## 행동 분석 엔진

### 분석 파이프라인

```
MPU6050 + MAX30102
       │
       ▼
  이동평균 필터 (sensor_service)
       │
       ▼
  ┌────┴────────────────────────────────┐
  │         behavior_service             │
  │                                      │
  │  활동지수  ──┐                       │
  │  (0~1000)   │                       │
  │             ├──► 기분 판별          │
  │  꼬리흔들기 ─┤    (다수결 안정화)    │
  │  (주파수)   │                       │
  │             ├──► 수면 단계          │
  │  심박수 ────┘    (시간 기반 판별)    │
  │  (BPM/HRV)                          │
  │             └──► 수면 품질 (0~100)  │
  └──────────────────────────────────────┘
       │
       ▼
  PetStatus 구조체
  → BLE로 앱에 전송 (1Hz)
```

### 기분 판별 로직

| 기분 | 조건 |
|:-----|:-----|
| 😊 좋음 (HAPPY) | 꼬리흔들기 감지 + BPM ≤ 130 |
| 😰 불안 (ANXIOUS) | 활동 낮음 + BPM > 160 |
| 🏃 활발 (ACTIVE) | 활동지수 > 600 |
| 😡 흥분 (EXCITED) | 활동 중간 이상 + BPM > 130 |
| 😌 안정 (CALM) | 기타 (기본값) |

### 수면 단계 판별

| 단계 | 조건 |
|:-----|:-----|
| 깨어남 (AWAKE) | 활동지수 > 30 |
| 🥱 졸림 (DROWSY) | 활동 ≤ 30 유지 10초 이상 |
| 😴 얕은 수면 (LIGHT) | 활동 ≤ 30 유지 30초 이상 |
| 💤 깊은 수면 (DEEP) | 활동 ≤ 30 유지 2분 이상 + BPM < 60 |

---

## 카메라 촬영 모드

| 모드 | 해상도 | 동작 |
|:-----|:-------|:-----|
| 단발 촬영 | UXGA (1600×1200) | 버퍼 플러시 → 1장 촬영 |
| 미리보기 | QQVGA (160×120) | 저해상도 촬영 → 촬영 후 UXGA 복구 |
| 베스트컷 | UXGA (1600×1200) | N장 촬영 → JPEG 파일 크기 기준 최고 선별 |

---

## 초기화 시퀀스

```
main.cpp::setup()
    │
    ├── 1. Serial.begin(115200)
    │
    ├── 2. cameraHalInit()
    │       └── OV3660 DVP 핀 설정, JPEG Q10, PSRAM 프레임버퍼
    │
    ├── 3. bleDriverInit(commandHandlerOnBleData)
    │       └── BLE GATT 서버 생성, 3개 Characteristic 등록
    │
    ├── 4. sensorHalInit()
    │       ├── I2C Bus 1 초기화 (GPIO 1,2 / 400kHz)
    │       ├── MPU6050 설정 (±4g, ±500°/s, DLPF 42Hz)
    │       └── MAX30102 설정 (IR 모드, 400 SPS)
    │
    ├── 5. sensorServiceInit() + behaviorServiceInit()
    │       └── 링 버퍼/상태 변수 초기화
    │
    └── 6. taskManagerInit()
            ├── cmdQueue 생성 (깊이 8)
            ├── statusMutex 생성
            ├── commandHandlerInit(cmdQueue)
            └── 4개 FreeRTOS 태스크 생성 (Core 0/1 분배)
```

---

## Mobile App (Flutter)

### 아키텍처

```
mobile_app/lib/src/
├── core/                    ← 공통 요소
│   ├── constants/
│   └── widgets/
├── features/                ← Feature-First 구조
│   ├── auth/                ← 인증
│   ├── home/                ← 대시보드
│   ├── gallery/             ← 갤러리
│   ├── map/                 ← 산책 지도
│   └── store/               ← 스토어
├── routing/                 ← GoRouter
└── services/
    ├── auth_service.dart    ← JWT 인증
    ├── ai_service.dart      ← API 클라이언트
    └── ble_service.dart     ← BLE 통신
```

| 항목 | 기술 |
|:-----|:-----|
| 프레임워크 | Flutter (Dart) |
| 상태 관리 | Riverpod |
| 라우팅 | GoRouter |
| HTTP | Dio |
| BLE | flutter_blue_plus |

---

## AI Server (FastAPI + Docker)

### 아키텍처

```
ai_server/
├── main.py                 ← FastAPI 앱
├── app/
│   ├── api/                ← REST API 라우터
│   ├── core/               ← 설정, DB, 의존성
│   ├── models/             ← SQLAlchemy 모델
│   ├── schemas/            ← Pydantic 스키마
│   └── services/           ← 비즈니스 로직
├── alembic/                ← DB 마이그레이션
├── storage/                ← 이미지 저장소
└── weights/                ← Real-ESRGAN 가중치
```

| 항목 | 기술 |
|:-----|:-----|
| 프레임워크 | FastAPI (Async) |
| DB | PostgreSQL + SQLAlchemy (Async) |
| AI 모델 | Real-ESRGAN (PyTorch) |
| 인증 | JWT (HS256) + bcrypt |
| 배포 | Docker Compose + Nginx |

### 데이터 플로우

```
ESP32 ─── (BLE) ──► 앱 ─── (HTTP) ──► FastAPI ──► PostgreSQL
                                          │
                                          ▼
                                     Real-ESRGAN
                                     (이미지 업스케일)
```

---

## DB 스키마

### users

| 컬럼 | 타입 | 설명 |
|:-----|:-----|:-----|
| id | UUID | PK |
| username | VARCHAR(50) | 사용자명 (unique) |
| hashed_password | VARCHAR(200) | bcrypt 해시 |
| is_active | BOOLEAN | 활성 상태 |

### photos

| 컬럼 | 타입 | 설명 |
|:-----|:-----|:-----|
| id | UUID | PK |
| original_path | VARCHAR | 원본 이미지 경로 |
| upscaled_path | VARCHAR | 업스케일 이미지 경로 |
| status | ENUM | queued / processing / completed / failed |
| latitude | FLOAT | 위도 |
| longitude | FLOAT | 경도 |
| created_at | TIMESTAMP | 생성 시간 |

---

## 기술 스택 요약

| 분류 | 기술 |
|:-----|:-----|
| MCU | ESP32-S3-WROOM-1 (N16R8V) |
| 펌웨어 | C++ / Arduino / PlatformIO / FreeRTOS |
| 모바일 | Flutter / Dart / Riverpod / GoRouter |
| 백엔드 | FastAPI / Python / SQLAlchemy (Async) |
| AI | Real-ESRGAN / PyTorch |
| DB | PostgreSQL |
| 배포 | Docker / Docker Compose / Nginx |
