#include "esp_camera.h"
#include "main.h"
#include "ble_manager.h"

// 카메라 초기화 함수
bool initCamera() {
    camera_config_t config;
    config.ledc_channel = LEDC_CHANNEL_0;
    config.ledc_timer = LEDC_TIMER_0;
    config.pin_d0 = Y2_GPIO_NUM;
    config.pin_d1 = Y3_GPIO_NUM;
    config.pin_d2 = Y4_GPIO_NUM;
    config.pin_d3 = Y5_GPIO_NUM;
    config.pin_d4 = Y6_GPIO_NUM;
    config.pin_d5 = Y7_GPIO_NUM;
    config.pin_d6 = Y8_GPIO_NUM;
    config.pin_d7 = Y9_GPIO_NUM;
    config.pin_xclk = XCLK_GPIO_NUM;
    config.pin_pclk = PCLK_GPIO_NUM;
    config.pin_vsync = VSYNC_GPIO_NUM;
    config.pin_href = HREF_GPIO_NUM;
    config.pin_sscb_sda = SIOD_GPIO_NUM;
    config.pin_sscb_scl = SIOC_GPIO_NUM;
    config.pin_pwdn = PWDN_GPIO_NUM;
    config.pin_reset = RESET_GPIO_NUM;
    config.xclk_freq_hz = 20000000;
    config.pixel_format = PIXFORMAT_JPEG;

    // PSRAM이 없는 경우를 대비해 해상도와 품질을 낮게 잡습니다.
    config.frame_size = FRAMESIZE_QVGA; // 320x240
    config.jpeg_quality = 12;
    config.fb_count = 1;

    // 카메라 초기화 실행
    esp_err_t err = esp_camera_init(&config);
    if (err != ESP_OK) {
        Serial.printf("❌ 카메라 초기화 실패: 0x%x", err);
        return false;
    }
    Serial.println("✅ 카메라 준비 완료!");
    return true;
}

// 사진을 찍어서 BLE로 보내는 핵심 함수
void captureAndSendImage() {
    camera_fb_t * fb = esp_camera_fb_get();
    if (!fb) {
        Serial.println("❌ 사진 촬영 실패");
        return;
    }

    Serial.printf("📸 촬영 성공! 크기: %d bytes\n", fb->len);
    
    // BLE를 통해 이미지 데이터 전송
    sendImageBLE(fb->buf, fb->len);

    // 사용한 프레임 버퍼 반환
    esp_camera_fb_return(fb);
}
// 기존 captureAndSendImage를 수정하여 연속 촬영 지원
void captureBurst(int count) {
    for (int i = 0; i < count; i++) {
        Serial.printf("📸 연속 촬영 중 (%d/%d)...\n", i + 1, count);
        captureAndSendImage(); // 기존에 만든 함수를 재사용
        delay(200); // 전송 후 안정화를 위한 짧은 대기
    }
    Serial.println("✅ 연속 촬영 완료!");
}