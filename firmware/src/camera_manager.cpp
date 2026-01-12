#include "esp_camera.h"
#include "main.h"
#include "ble_manager.h"
#include <LittleFS.h>

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
    // OV2640 호환성을 위해 UXGA(1600x1200)로 설정합니다. (OV5640도 지원함)
    config.frame_size = FRAMESIZE_UXGA; // 1600x1200 (2MP)
    config.fb_location = CAMERA_FB_IN_PSRAM;
    config.jpeg_quality = 10; // 낮을수록 화질 좋음 (10~63)
    config.fb_count = 2;

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

// 이미지를 Flash에 저장하는 함수
bool saveImageToFlash(camera_fb_t * fb, String &savedPath) {
    if (!LittleFS.begin(true)) {
        Serial.println("❌ LittleFS 마운트 실패");
        return false;
    }

    // 파일명 생성 (타임스탬프가 없으므로 millis() 사용)
    String filename = "/capture_" + String(millis()) + ".jpg";
    
    File file = LittleFS.open(filename, FILE_WRITE);
    if (!file) {
        Serial.println("❌ 파일 열기 실패");
        return false;
    }

    file.write(fb->buf, fb->len);
    file.close();
    
    // 📍 GPS 정보도 별도 파일로 저장 (.txt)
    String txtFilename = "/capture_" + String(millis()) + ".txt";
    File txtFile = LittleFS.open(txtFilename, FILE_WRITE);
    if (txtFile) {
        txtFile.printf("%f,%f", currentLat, currentLng);
        txtFile.close();
        Serial.printf("📍 GPS 저장 완료: %f, %f\n", currentLat, currentLng);
    }

    Serial.printf("💾 Flash 저장 완료: %s (%d bytes)\n", filename.c_str(), fb->len);
    savedPath = filename;
    return true;
}

// 캡처 후 저장 함수
String captureAndSave() {
    camera_fb_t * fb = esp_camera_fb_get();
    if (!fb) {
        Serial.println("❌ 사진 촬영 실패");
        return "";
    }

    Serial.printf("📸 촬영 성공! 크기: %d bytes\n", fb->len);
    
    String savedPath = "";
    if (saveImageToFlash(fb, savedPath)) {
        // 성공
    } else {
        Serial.println("❌ 저장 실패");
    }

    esp_camera_fb_return(fb);
    return savedPath;
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

    // 2. 촬영
    camera_fb_t * fb = esp_camera_fb_get();
    if (!fb) {
        Serial.println("❌ 미리보기 촬영 실패");
        // 실패해도 해상도는 원복해야 함
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

    for (int i = 0; i < count; i++) {
        Serial.printf("📸 촬영 %d/%d...", i + 1, count);
        
        // 1. 촬영
        camera_fb_t * fb = esp_camera_fb_get();
        if (!fb) {
            Serial.println("실패 ❌");
            continue;
        }

        // 2. 선명도(용량) 비교
        // JPEG는 초점이 잘 맞을수록(고주파 성분 많음) 용량이 커지는 경향이 있음 [cite: 2025-12-23]
        if (fb->len > maxLen) {
            // 더 좋은 사진을 찾았다!
            if (bestFb) esp_camera_fb_return(bestFb); // 기존 1등은 반납
            bestFb = fb; // 새로운 1등 등극
            maxLen = fb->len;
            Serial.printf(" (현재 1등: %d bytes) 👑\n", maxLen);
        } else {
            // 탈락
            esp_camera_fb_return(fb); 
            Serial.println(" (탈락) 📉");
        }
        
        delay(100); // 셔터 간격
    }

    // 3. 최종 우승자 저장
    if (bestFb) {
        Serial.printf("🎉 최종 베스트 컷 저장: %d bytes\n", bestFb->len);
        String savedPath = "";
        if (saveImageToFlash(bestFb, savedPath)) {
            Serial.println("✅ 저장 완료");
        } else {
            Serial.println("❌ 저장 실패");
        }
        esp_camera_fb_return(bestFb);
    } else {
        Serial.println("❌ 건질 사진이 없습니다.");
    }
}