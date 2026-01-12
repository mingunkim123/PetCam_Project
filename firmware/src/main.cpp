#include <Arduino.h>
#include "esp_camera.h"
#include "main.h"
#include "ble_manager.h"
#include "wifi_manager.h"
#include <LittleFS.h>

// 카메라 매니저 함수 선언
bool initCamera();
String captureAndSave();

// WiFi 설정 (사용자가 수정해야 함)
const char* WIFI_SSID = "ForLinux";
const char* WIFI_PASSWORD = "qzvm2024";
const char* UPLOAD_SERVER_URL = "http://172.24.112.37:8000/upscale"; // AI Server IP


int burstCount = 0;
unsigned long lastBurstTime = 0; // 타이머용 변수
bool previewFlag = false;        // 미리보기 깃발 정의
double currentLat = 0.0;         // 📍 위도 초기화
double currentLng = 0.0;         // 📍 경도 초기화

void captureAndSendImage();

void setup() {
    Serial.begin(115200);
    delay(2000);
    
    // 1. LittleFS 초기화
    if(!LittleFS.begin(true)){
        Serial.println("LittleFS Mount Failed");
        return;
    }
    Serial.println("✅ LittleFS Mounted");

    // 2. 카메라 초기화 (camera_manager.cpp 사용)
    // 2. 카메라 초기화 (camera_manager.cpp 사용)
    if (!initCamera()) {
        Serial.println("❌ 카메라 초기화 실패 (하지만 BLE는 계속 진행합니다)");
        // while(1) delay(1000); // 멈추지 않고 진행
    }

    // 3. BLE 초기화
    initBLE();
}

void loop() {
    // 1. 산책 중 촬영 명령 처리 (명령 받으면 일단 저장만 함)
    // 1. 산책 중 촬영 명령 처리 (명령 받으면 일단 저장만 함)
    if (takePhotoFlag) {
        takePhotoFlag = false;
        captureAndSave(); // 사진 찍고 Flash에 보관
    }

    // 1-1. 미리보기 명령 처리 (추가)
    if (previewFlag) {
        previewFlag = false;
        capturePreview(); // 저화질로 찍어서 바로 전송
    }

    // 1-2. 연속 촬영 처리 (On-Device Best Cut)
    if (burstCount > 0) {
        captureBestCut(burstCount); // 3장 찍고 1장만 저장
        burstCount = 0; // 완료
    }

    // 2. 주기적으로 '집(Wi-Fi)'인지 확인하고, 쌓인 파일이 있으면 한꺼번에 업로드
    static unsigned long lastSyncCheck = 0;
    if (millis() - lastSyncCheck > 30000) { // 30초마다 체크
        if (scanForSSID(WIFI_SSID)) { // 집 Wi-Fi 발견!
            if (connectToWiFi(WIFI_SSID, WIFI_PASSWORD)) {
                // 🚀 Flash에 쌓인 모든 파일을 찾아 서버로 보냅니다.
                syncAllFiles(UPLOAD_SERVER_URL); 
                
                WiFi.disconnect(true);
                WiFi.mode(WIFI_OFF);
            }
        }
        lastSyncCheck = millis();
    }
}