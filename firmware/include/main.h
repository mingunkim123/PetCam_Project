#ifndef MAIN_H_
#define MAIN_H_

#include <Arduino.h>
extern int burstCount;     // ⭐ 이 줄을 추가하세요! (연속 촬영 횟수 저장용)

// ==========================================
// ESP32-S3-WROOM-1 CAM (Freenove/Generic) 표준 핀맵
// ==========================================
#define PWDN_GPIO_NUM     -1
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM     15
#define SIOD_GPIO_NUM      4
#define SIOC_GPIO_NUM      5

// 데이터 핀 (순서가 매우 중요합니다)
#define Y9_GPIO_NUM       16
#define Y8_GPIO_NUM       17
#define Y7_GPIO_NUM       18
#define Y6_GPIO_NUM       12
#define Y5_GPIO_NUM       10
#define Y4_GPIO_NUM        8
#define Y3_GPIO_NUM        9
#define Y2_GPIO_NUM       11

#define VSYNC_GPIO_NUM     6
#define HREF_GPIO_NUM      7
#define PCLK_GPIO_NUM     13

// BLE 설정 (동일하게 유지)
#define DEVICE_NAME       "TEST"
#define SERVICE_UUID      "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define DATA_CHAR_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CMD_CHAR_UUID     "beb5483f-36e1-4688-b7f5-ea07361b26a8" // 명령 수신용 (3f) 👈 추가!

bool initCamera();           // 카메라 초기화 함수
void captureAndSendImage();  // 사진 촬영 및 전송 함수
void capturePreview();       // 📸 미리보기 촬영 함수
void captureBestCut(int count); // 🏆 베스트 컷 촬영 함수 (추가)

extern bool previewFlag;     // 미리보기 깃발 (추가)
extern double currentLat;    // 📍 현재 위도 (추가)
extern double currentLng;    // 📍 현재 경도 (추가)

#endif