#include <Arduino.h>
#include "hal/camera_hal.h"
#include "hal/sensor_hal.h"
#include "drivers/ble_driver.h"
#include "services/sensor_service.h"
#include "services/behavior_service.h"
#include "protocol/command_handler.h"
#include "app/task_manager.h"

// ==========================================
// PetCam v3.0 — 클린 아키텍처 (Layered)
// ==========================================
// 계층 구조:
//   Config   → board_config, ble_config, app_config
//   Types    → app_types (공유 구조체/enum)
//   HAL      → camera_hal, sensor_hal
//   Drivers  → ble_driver
//   Services → camera_service, sensor_service, behavior_service
//   Protocol → ble_protocol, command_handler
//   App      → task_manager, main.cpp (여기)
//
// 의존성 규칙: 항상 아래로만 → HAL은 Services를 절대 참조 안 함

void setup() {
    Serial.begin(115200);
    delay(2000);

    Serial.println("🚀 ========================================");
    Serial.println("🐾 PetCam v3.0 — Clean Architecture");
    Serial.println("🚀 ========================================");

    // 1. 카메라 HAL 초기화
    if (!cameraHalInit()) {
        Serial.println("❌ 카메라 초기화 실패");
    }

    // 2. BLE 드라이버 초기화 (명령 콜백 연결)
    bleDriverInit(commandHandlerOnBleData);

    // 3. 센서 HAL 초기화
    if (!sensorHalInit()) {
        Serial.println("⚠️ 센서 초기화 실패 — 카메라/BLE 모드로 동작합니다.");
    }

    // 4. 서비스 초기화
    sensorServiceInit();
    behaviorServiceInit();

    // 5. 태스크 매니저 시작 (FreeRTOS 태스크 생성)
    taskManagerInit();
}

void loop() {
    // 모든 로직은 FreeRTOS 태스크에서 처리됨
    static unsigned long lastReport = 0;
    if (millis() - lastReport > 30000) {
        lastReport = millis();
        Serial.printf("💚 [System] Uptime: %lus | Free Heap: %d | PSRAM: %d\n",
            millis() / 1000, ESP.getFreeHeap(), ESP.getFreePsram());
    }
    vTaskDelay(pdMS_TO_TICKS(1000));
}