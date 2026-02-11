#ifndef CAMERA_HAL_H_
#define CAMERA_HAL_H_

#include <Arduino.h>
#include "esp_camera.h"

// ==========================================
// 카메라 HAL — 하드웨어 추상화 계층
// ==========================================
// 역할: esp_camera API를 래핑하여 상위 계층에 간결한 인터페이스 제공
// 규칙: 이 레이어는 BLE/서비스를 절대 참조하지 않음

bool cameraHalInit();
camera_fb_t* cameraHalCapture();
void cameraHalReturn(camera_fb_t* fb);
void cameraHalSetResolution(framesize_t size);
void cameraHalFlushBuffers(int count);

#endif
