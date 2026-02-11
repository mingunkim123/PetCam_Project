#ifndef APP_CONFIG_H_
#define APP_CONFIG_H_

// ==========================================
// FreeRTOS 태스크 설정
// ==========================================
#define TASK_SENSOR_PERIOD_MS      10     // SensorTask 주기 (100Hz)
#define TASK_ANALYSIS_PERIOD_MS    500    // AnalysisTask 주기 (2Hz)
#define TASK_CAMERA_PERIOD_MS      100    // CameraTask 폴링 주기
#define TASK_BLE_PERIOD_MS         1000   // BLETask 전송 주기 (1Hz)

#define TASK_SENSOR_STACK          4096
#define TASK_ANALYSIS_STACK        8192
#define TASK_CAMERA_STACK          8192
#define TASK_BLE_STACK             4096

#define TASK_SENSOR_PRIORITY       3
#define TASK_ANALYSIS_PRIORITY     2
#define TASK_CAMERA_PRIORITY       2
#define TASK_BLE_PRIORITY          1

// ==========================================
// 센서 버퍼 설정
// ==========================================
#define SENSOR_BUFFER_SIZE     50   // 이동평균 버퍼 (100Hz × 0.5s)
#define HR_BUFFER_SIZE         10   // 심박 측정 버퍼

// ==========================================
// 행동 분석 임계값
// ==========================================

// 활동 판별
#define ACTIVITY_THRESHOLD_LOW     50
#define ACTIVITY_THRESHOLD_MED     300
#define ACTIVITY_THRESHOLD_HIGH    600

// 심박수 (강아지 평균: 60~140 BPM)
#define BPM_RESTING_LOW            60
#define BPM_RESTING_HIGH           100
#define BPM_ELEVATED               130
#define BPM_HIGH                   160

// 꼬리 흔들기 감지
#define TAIL_WAG_MIN_FREQ          500    // 0.5Hz (mHz)
#define TAIL_WAG_MAX_FREQ          5000   // 5.0Hz (mHz)
#define TAIL_WAG_MIN_AMPLITUDE     10.0f  // 최소 진폭 (deg/s)

// 수면 감지
#define SLEEP_ACTIVITY_THRESHOLD   30
#define SLEEP_DROWSY_MS            10000   // 10초 → 졸림
#define SLEEP_LIGHT_MS             30000   // 30초 → 얕은 수면
#define SLEEP_DEEP_MS              120000  // 2분 → 깊은 수면

// 기분 안정화
#define MOOD_HISTORY_SIZE          5
#define MOOD_MIN_VOTES             3

// ==========================================
// 카메라 설정
// ==========================================
#define CAMERA_BURST_COUNT         10    // 베스트컷 기본 촬영 수
#define CAMERA_FLUSH_COUNT         2     // 버퍼 플러시 횟수

// ==========================================
// 이벤트 큐 설정
// ==========================================
#define CMD_QUEUE_SIZE             8     // BLE 명령 큐 깊이

#endif
