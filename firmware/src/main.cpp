#include <Arduino.h>
#include "esp_camera.h"
#include "main.h"
#include "ble_manager.h" // 분리한 헤더 추가


int burstCount = 0;
unsigned long lastBurstTime = 0; // 타이머용 변수

void captureAndSendImage();

void setup() {
    Serial.begin(115200);
    delay(2000);
    
    // 1. 카메라 초기화 (사장님이 성공하신 코드)
    camera_config_t config = {};
    // ... (기존에 성공했던 config 설정들 그대로 유지) ...
    config.pin_d0 = Y2_GPIO_NUM; config.pin_d1 = Y3_GPIO_NUM;
    config.pin_d2 = Y4_GPIO_NUM; config.pin_d3 = Y5_GPIO_NUM;
    config.pin_d4 = Y6_GPIO_NUM; config.pin_d5 = Y7_GPIO_NUM;
    config.pin_d6 = Y8_GPIO_NUM; config.pin_d7 = Y9_GPIO_NUM;
    config.pin_xclk = XCLK_GPIO_NUM; config.pin_pclk = PCLK_GPIO_NUM;
    config.pin_vsync = VSYNC_GPIO_NUM; config.pin_href = HREF_GPIO_NUM;
    config.pin_sccb_sda = SIOD_GPIO_NUM; config.pin_sccb_scl = SIOC_GPIO_NUM;
    config.pin_pwdn = PWDN_GPIO_NUM; config.pin_reset = RESET_GPIO_NUM;
    config.xclk_freq_hz = 20000000; config.pixel_format = PIXFORMAT_JPEG;
    config.grab_mode = CAMERA_GRAB_LATEST; config.fb_location = CAMERA_FB_IN_PSRAM;
    config.frame_size = FRAMESIZE_VGA; config.jpeg_quality = 12; config.fb_count = 2;

    if (esp_camera_init(&config) == ESP_OK) {
        Serial.println("✅ 카메라 준비 완료!");
    }

    // 2. BLE 초기화
    initBLE();
}

void loop() {
    // 단발 촬영
    if (takePhotoFlag) {
        captureAndSendImage();
        takePhotoFlag = false;
    }

    // 연속 촬영 (Non-blocking 방식)
    if (burstCount > 0) {
        unsigned long currentTime = millis();
        if (currentTime - lastBurstTime >= 1500) { // 1.5초 간격으로 촬영
            Serial.printf("🚀 연속 촬영 중... (남은 횟수: %d)\n", burstCount);
            captureAndSendImage();
            burstCount--;
            lastBurstTime = currentTime;
        }
    }
    
    delay(1); // 💡 BLE 스택이 일할 수 있게 아주 짧은 틈만 줍니다.
}