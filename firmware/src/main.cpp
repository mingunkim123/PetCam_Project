#include <Arduino.h>
#include "esp_camera.h"
#include "main.h"
#include "ble_manager.h"
// #include "wifi_manager.h" // Wi-Fi 제거
// #include <LittleFS.h>     // Flash 저장 제거

// 카메라 매니저 함수 선언
bool initCamera();
void captureAndSendImage();
void capturePreview();
void captureBestCut(int count);

int burstCount = 0;
unsigned long lastBurstTime = 0;
bool previewFlag = false;
double currentLat = 0.0;
double currentLng = 0.0;

void setup() {
    Serial.begin(115200);
    delay(2000);
    
    // 1. 카메라 초기화
    if (!initCamera()) {
        Serial.println("❌ 카메라 초기화 실패");
    }

    // 2. BLE 초기화
    initBLE();
    
    Serial.println("✅ 시스템 준비 완료 (BLE Only Mode)");
}

void loop() {
    // 1. 산책 중 촬영 명령 처리
    if (takePhotoFlag) {
        takePhotoFlag = false;
        captureAndSendImage(); // 찍어서 바로 BLE 전송
    }

    // 2. 미리보기 명령 처리
    if (previewFlag) {
        previewFlag = false;
        capturePreview(); // 저화질로 찍어서 바로 전송
    }

    // 3. 연속 촬영 처리 (On-Device Best Cut)
    if (burstCount > 0) {
        captureBestCut(burstCount); // 3장 찍고 1장 골라서 전송
        burstCount = 0;
    }
    
    // Wi-Fi 동기화 로직 제거됨
    delay(100);
}