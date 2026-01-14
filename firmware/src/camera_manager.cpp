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

    // 💡 [표준 설정 복구] OV3660 표준 사용법
    // 1. 해상도: UXGA (1600x1200)
    // 2. 화질: 10 (최고 화질)
    // 3. PSRAM 사용 필수
    config.frame_size = FRAMESIZE_UXGA;
    config.jpeg_quality = 10; 
    config.fb_location = CAMERA_FB_IN_PSRAM;
    config.fb_count = 2; // 더블 버퍼링 유지

    // 카메라 초기화 실행
    esp_err_t err = esp_camera_init(&config);
    if (err != ESP_OK) {
        Serial.printf("❌ 카메라 초기화 실패: 0x%x", err);
        return false;
    }
    
    // 💡 [중요] 센서 수동 설정 제거
    // OV3660은 기본적으로 Auto Exposure / Auto White Balance가 켜져 있습니다.
    // 억지로 건드리지 않고 기본값(Auto)을 신뢰합니다.
    
    Serial.println("✅ 카메라 준비 완료! (Standard OV3660 Mode)");
    return true;
}

// 사진을 찍어서 BLE로 보내는 핵심 함수
void captureAndSendImage() {
    Serial.println("🔄 [Camera] 오래된 프레임 비우기...");
    
    // 💡 [중요] 오래된 프레임 버퍼 비우기 (Stale Frame Flushing)
    // fb_count가 2이므로, 이전에 찍혀서 대기 중인 프레임이 있을 수 있음.
    // 이를 버려야 지금 찍는 '새 사진'을 얻을 수 있음.
    for (int i = 0; i < 2; i++) {
        camera_fb_t * temp_fb = esp_camera_fb_get();
        if (temp_fb) {
            esp_camera_fb_return(temp_fb);
        }
    }

    // 진짜 촬영 (이제 최신 프레임임)
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

// 📸 미리보기 촬영 함수 (저화질 -> 전송 -> 원복)
void capturePreview() {
    sensor_t * s = esp_camera_sensor_get();
    if (!s) {
        Serial.println("❌ 센서 감지 실패");
        return;
    }

    // 1. 해상도 낮추기 (QQVGA: 160x120) - 전송 속도 확보
    Serial.println("📉 미리보기 모드: 해상도 낮춤 (QQVGA)");
    s->set_framesize(s, FRAMESIZE_QQVGA);
    delay(100); // 설정 적용 대기

    // 💡 버퍼 비우기
    camera_fb_t * temp_fb = esp_camera_fb_get();
    if (temp_fb) esp_camera_fb_return(temp_fb);

    // 2. 촬영
    camera_fb_t * fb = esp_camera_fb_get();
    if (!fb) {
        Serial.println("❌ 미리보기 촬영 실패");
        s->set_framesize(s, FRAMESIZE_UXGA); // 2MP 복구
        return;
    }

    Serial.printf("📸 미리보기 촬영 성공! 크기: %d bytes\n", fb->len);

    // 3. BLE로 바로 전송
    sendImageBLE(fb->buf, fb->len);

    // 4. 메모리 해제 및 해상도 원복
    esp_camera_fb_return(fb);
    
    Serial.println("📈 일반 모드: 해상도 복구 (2MP)");
    s->set_framesize(s, FRAMESIZE_UXGA); // 2MP (1600x1200)
    delay(100);
}

// 🏆 베스트 컷 촬영 함수 (On-Device Best Cut)
void captureBestCut(int count) {
    camera_fb_t * bestFb = NULL;
    size_t maxLen = 0;

    Serial.printf("🏁 베스트 컷 촬영 시작 (%d장 중 선별)\n", count);
    
    // 💡 시작 전 버퍼 비우기
    for (int i = 0; i < 2; i++) {
        camera_fb_t * temp_fb = esp_camera_fb_get();
        if (temp_fb) esp_camera_fb_return(temp_fb);
    }

    for (int i = 0; i < count; i++) {
        Serial.printf("📸 촬영 %d/%d (진행중...)\n", i + 1, count);
        
        // 1. 촬영
        camera_fb_t * fb = esp_camera_fb_get();
        if (!fb) {
            Serial.println("실패 ❌");
            continue;
        }

        // 2. 선명도(용량) 비교
        if (fb->len > maxLen) {
            if (bestFb) esp_camera_fb_return(bestFb); // 기존 1등은 반납
            bestFb = fb; // 새로운 1등 등극
            maxLen = fb->len;
            Serial.printf(" (현재 1등: %d bytes) 👑\n", maxLen);
        } else {
            esp_camera_fb_return(fb); // 탈락
            Serial.println(" (탈락) 📉");
        }
        
        delay(100); // 셔터 간격
    }

    // 3. 최종 우승자 전송
    if (bestFb) {
        Serial.printf("🎉 최종 베스트 컷 전송: %d bytes\n", bestFb->len);
        sendImageBLE(bestFb->buf, bestFb->len);
        esp_camera_fb_return(bestFb);
    } else {
        Serial.println("❌ 건질 사진이 없습니다.");
    }
}