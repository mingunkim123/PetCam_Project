#include "services/camera_service.h"
#include "hal/camera_hal.h"
#include "config/app_config.h"
#include <esp_heap_caps.h>

// 메모리 상태 로그 (촬영 전후 비교용)
static void logMemory(const char* label) {
    Serial.printf("📊 [MEM] %s — Heap: %d bytes | PSRAM: %d bytes | 최대블록: %d bytes\n",
        label, ESP.getFreeHeap(), ESP.getFreePsram(),
        heap_caps_get_largest_free_block(MALLOC_CAP_8BIT));
}

// ==========================================
// 단발 촬영
// ==========================================
camera_fb_t* cameraServiceCapture() {
    logMemory("단발촬영 전");
    cameraHalFlushBuffers(CAMERA_FLUSH_COUNT);

    camera_fb_t* fb = cameraHalCapture();
    if (!fb) {
        Serial.println("❌ [CAM_SVC] 촬영 실패");
        return nullptr;
    }

    Serial.printf("📸 [CAM_SVC] 촬영 성공 (%d bytes)\n", fb->len);
    logMemory("단발촬영 후");
    return fb;
}

// ==========================================
// 미리보기 (저화질)
// ==========================================
// 왜 해상도 변경 후 복구? → BLE 전송 속도 확보를 위해 일시적으로
// 해상도를 낮추고, 완료 후 고해상도로 복구합니다.
camera_fb_t* cameraServicePreview() {
    logMemory("미리보기 전");
    cameraHalSetResolution(FRAMESIZE_QQVGA);
    cameraHalFlushBuffers(1);

    camera_fb_t* fb = cameraHalCapture();
    if (!fb) {
        Serial.println("❌ [CAM_SVC] 미리보기 실패");
        cameraHalSetResolution(FRAMESIZE_UXGA);
        return nullptr;
    }

    Serial.printf("📸 [CAM_SVC] 미리보기 성공 (%d bytes)\n", fb->len);
    logMemory("미리보기 후");
    return fb;
}

// ==========================================
// 베스트 컷 (N장 중 최고 선별)
// ==========================================
// 왜 파일 크기 기준? → JPEG에서 디테일이 많은 이미지일수록
// 압축 후에도 용량이 크므로, 크기 = 선명도의 간접 지표입니다.
// 대안: 라플라시안 분산 등 진짜 선명도 측정도 가능하지만, MCU에서는
//       연산 비용이 과도하여 파일 크기 방식이 실용적입니다.
camera_fb_t* cameraServiceBestCut(int count) {
    logMemory("베스트컷 전");
    cameraHalFlushBuffers(CAMERA_FLUSH_COUNT);

    camera_fb_t* bestFb = nullptr;
    size_t maxLen = 0;

    Serial.printf("🏁 [CAM_SVC] 베스트 컷 시작 (%d장)\n", count);

    for (int i = 0; i < count; i++) {
        camera_fb_t* fb = cameraHalCapture();
        if (!fb) {
            Serial.printf("  %d/%d ❌ 실패\n", i + 1, count);
            continue;
        }

        if (fb->len > maxLen) {
            if (bestFb) cameraHalReturn(bestFb);
            bestFb = fb;
            maxLen = fb->len;
            Serial.printf("  %d/%d 👑 신규 1등 (%d bytes)\n", i + 1, count, maxLen);
        } else {
            cameraHalReturn(fb);
            Serial.printf("  %d/%d 📉 탈락\n", i + 1, count);
        }

        delay(100);
    }

    if (bestFb) {
        Serial.printf("🎉 [CAM_SVC] 최종 베스트 (%d bytes)\n", bestFb->len);
        logMemory("베스트컷 후");
    } else {
        Serial.println("❌ [CAM_SVC] 건질 사진 없음");
    }

    return bestFb;
}

// ==========================================
// 프레임 반환 + 미리보기 후 해상도 복구
// ==========================================
void cameraServiceReturn(camera_fb_t* fb) {
    cameraHalReturn(fb);
    cameraHalSetResolution(FRAMESIZE_UXGA);
    logMemory("프레임 반환 후");
}
