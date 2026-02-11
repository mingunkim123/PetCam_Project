#ifndef CAMERA_SERVICE_H_
#define CAMERA_SERVICE_H_

#include <Arduino.h>
#include "esp_camera.h"

// ==========================================
// Camera Service — 촬영 전략 로직
// ==========================================
// 역할: 베스트 컷, 미리보기 등 상위 촬영 로직
// 규칙: HAL을 통해서만 카메라 접근, BLE 직접 호출 금지

// 단발 촬영 — 캡처된 프레임 반환 (호출자가 전송 + 반환 담당)
camera_fb_t* cameraServiceCapture();

// 미리보기 — 저화질 프레임 반환 (호출자가 전송 + 반환 담당)
camera_fb_t* cameraServicePreview();

// 베스트 컷 — N장 중 최고 프레임 반환 (호출자가 전송 + 반환 담당)
camera_fb_t* cameraServiceBestCut(int count);

// 프레임 반환 (HAL에 위임)
void cameraServiceReturn(camera_fb_t* fb);

#endif
