#ifndef APP_TYPES_H_
#define APP_TYPES_H_

#include <Arduino.h>

// ==========================================
// 센서 데이터 구조체
// ==========================================

struct MPUData {
    float accelX, accelY, accelZ;   // 가속도 (g)
    float gyroX, gyroY, gyroZ;     // 자이로 (deg/s)
    float accelMagnitude;           // 가속도 벡터 크기
    float gyroMagnitude;            // 자이로 벡터 크기
};

struct HRData {
    uint16_t bpm;          // 심박수
    uint16_t hrv;          // 심박변이도 (ms)
    uint32_t irValue;      // IR 센서 값
    bool     fingerOn;     // 접촉 감지
};

// ==========================================
// 반려견 상태 타입
// ==========================================

enum PetMood : uint8_t {
    MOOD_HAPPY      = 0x01,
    MOOD_ANXIOUS    = 0x02,
    MOOD_ACTIVE     = 0x03,
    MOOD_EXCITED    = 0x04,
    MOOD_CALM       = 0x05,
    MOOD_UNKNOWN    = 0xFF
};

enum SleepStage : uint8_t {
    SLEEP_AWAKE     = 0x00,
    SLEEP_DROWSY    = 0x01,
    SLEEP_LIGHT     = 0x02,
    SLEEP_DEEP      = 0x03
};

struct PetStatus {
    PetMood    mood;
    SleepStage sleepStage;
    uint8_t    sleepQuality;      // 0~100
    uint16_t   bpm;
    uint16_t   hrv;
    uint16_t   activityIndex;     // 0~1000
    uint16_t   tailWagFreq;       // mHz
    float      accelMag;
    float      gyroMag;
};

// ==========================================
// BLE 명령 타입 (Protocol Layer에서 사용)
// ==========================================

enum AppCommandType : uint8_t {
    CMD_CAPTURE_SINGLE  = 0x01,   // 단발 촬영
    CMD_CAPTURE_BURST   = 0x02,   // 연속 촬영 (베스트컷)
    CMD_CAPTURE_PREVIEW = 0x03    // 미리보기
};

// 이벤트 큐에 전달되는 명령 구조체
struct AppCommand {
    AppCommandType type;
    double gpsLat;
    double gpsLng;
    int    burstCount;             // CMD_CAPTURE_BURST일 때만 사용
};

#endif
