#include "hal/camera_hal.h"
#include "config/board_config.h"

// ==========================================
// 카메라 HAL 구현
// ==========================================
// 왜 HAL로 분리? → 카메라 초기화 코드(핀 설정)와 촬영 로직(베스트컷)을
// 분리하면, 카메라 모듈 교체 시 이 파일만 수정하면 됩니다.

bool cameraHalInit() {
    camera_config_t config;
    config.ledc_channel = LEDC_CHANNEL_0;
    config.ledc_timer   = LEDC_TIMER_0;
    config.pin_d0       = CAM_PIN_Y2;
    config.pin_d1       = CAM_PIN_Y3;
    config.pin_d2       = CAM_PIN_Y4;
    config.pin_d3       = CAM_PIN_Y5;
    config.pin_d4       = CAM_PIN_Y6;
    config.pin_d5       = CAM_PIN_Y7;
    config.pin_d6       = CAM_PIN_Y8;
    config.pin_d7       = CAM_PIN_Y9;
    config.pin_xclk     = CAM_PIN_XCLK;
    config.pin_pclk     = CAM_PIN_PCLK;
    config.pin_vsync    = CAM_PIN_VSYNC;
    config.pin_href     = CAM_PIN_HREF;
    config.pin_sscb_sda = CAM_PIN_SIOD;
    config.pin_sscb_scl = CAM_PIN_SIOC;
    config.pin_pwdn     = CAM_PIN_PWDN;
    config.pin_reset    = CAM_PIN_RESET;
    config.xclk_freq_hz = 20000000;
    config.pixel_format = PIXFORMAT_JPEG;
    config.frame_size   = FRAMESIZE_UXGA;
    config.jpeg_quality = 10;
    config.fb_location  = CAMERA_FB_IN_PSRAM;
    config.fb_count     = 2;

    esp_err_t err = esp_camera_init(&config);
    if (err != ESP_OK) {
        Serial.printf("❌ [CAM_HAL] 초기화 실패: 0x%x\n", err);
        return false;
    }

    Serial.println("✅ [CAM_HAL] 카메라 준비 완료 (UXGA, JPEG Q10)");
    return true;
}

camera_fb_t* cameraHalCapture() {
    return esp_camera_fb_get();
}

void cameraHalReturn(camera_fb_t* fb) {
    if (fb) esp_camera_fb_return(fb);
}

void cameraHalSetResolution(framesize_t size) {
    sensor_t* s = esp_camera_sensor_get();
    if (s) {
        s->set_framesize(s, size);
        delay(100);  // 설정 적용 대기
    }
}

void cameraHalFlushBuffers(int count) {
    for (int i = 0; i < count; i++) {
        camera_fb_t* fb = esp_camera_fb_get();
        if (fb) esp_camera_fb_return(fb);
    }
}
