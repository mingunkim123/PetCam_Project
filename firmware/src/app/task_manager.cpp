#include "app/task_manager.h"
#include "config/app_config.h"
#include "app/app_types.h"
#include "services/sensor_service.h"
#include "services/behavior_service.h"
#include "services/camera_service.h"
#include "drivers/ble_driver.h"
#include "protocol/ble_protocol.h"
#include "protocol/command_handler.h"

// ==========================================
// 내부 상태 — Queue & Mutex
// ==========================================
static QueueHandle_t     cmdQueue = nullptr;
static SemaphoreHandle_t statusMutex = nullptr;
static PetStatus         latestStatus;

// GPS 좌표 (명령에서 수신)
static double currentLat = 0.0;
static double currentLng = 0.0;

// 태스크 핸들
static TaskHandle_t sensorTaskHandle   = nullptr;
static TaskHandle_t analysisTaskHandle = nullptr;
static TaskHandle_t cameraTaskHandle   = nullptr;
static TaskHandle_t bleTaskHandle      = nullptr;

// ==========================================
// Task 1: SensorTask (Core 0, 100Hz)
// ==========================================
// 왜 Core 0? → 카메라/BLE(Core 1)의 블로킹에 영향받지 않도록 격리
static void sensorTask(void* param) {
    Serial.println("🏃 [Task] SensorTask 시작 (Core 0, 100Hz)");
    TickType_t lastWake = xTaskGetTickCount();

    for (;;) {
        sensorServiceUpdate();
        vTaskDelayUntil(&lastWake, pdMS_TO_TICKS(TASK_SENSOR_PERIOD_MS));
    }
}

// ==========================================
// Task 2: AnalysisTask (Core 0, 2Hz)
// ==========================================
// 왜 500ms? → 기분/수면 상태는 급변하지 않으므로 2Hz면 충분
static void analysisTask(void* param) {
    Serial.println("🧠 [Task] AnalysisTask 시작 (Core 0, 2Hz)");

    for (;;) {
        MPUData mpu = sensorServiceGetFilteredIMU();
        HRData  hr  = sensorServiceGetFilteredHR();
        PetStatus status = behaviorServiceAnalyze(mpu, hr);

        if (xSemaphoreTake(statusMutex, pdMS_TO_TICKS(10)) == pdTRUE) {
            latestStatus = status;
            xSemaphoreGive(statusMutex);
        }

        // 디버그 로그 (1초에 1번)
        static int logCnt = 0;
        if (++logCnt >= 2) {
            logCnt = 0;
            const char* moods[]  = {"", "😊좋음", "😰불안", "🏃활발", "😡흥분", "😌안정"};
            const char* sleeps[] = {"깨어남", "🥱졸림", "😴얕은", "💤깊은"};
            Serial.printf("🧠 [분석] 기분:%s | 수면:%s(질:%d) | BPM:%d | 활동:%d\n",
                status.mood <= 5 ? moods[status.mood] : "?",
                status.sleepStage <= 3 ? sleeps[status.sleepStage] : "?",
                status.sleepQuality, status.bpm, status.activityIndex);
        }

        vTaskDelay(pdMS_TO_TICKS(TASK_ANALYSIS_PERIOD_MS));
    }
}

// ==========================================
// Task 3: CameraTask (Core 1, 이벤트 기반)
// ==========================================
// 왜 Queue? → 기존 전역 Flag(takePhotoFlag)는 Race Condition 위험.
// FreeRTOS Queue는 atomic 전달 + 여러 명령 순차 처리 가능.
static void cameraTask(void* param) {
    Serial.println("📷 [Task] CameraTask 시작 (Core 1, 이벤트 기반)");
    AppCommand cmd;

    for (;;) {
        // Queue에서 명령 대기 (100ms 타임아웃)
        if (xQueueReceive(cmdQueue, &cmd, pdMS_TO_TICKS(TASK_CAMERA_PERIOD_MS)) == pdTRUE) {
            // GPS 좌표 업데이트
            currentLat = cmd.gpsLat;
            currentLng = cmd.gpsLng;

            camera_fb_t* fb = nullptr;

            switch (cmd.type) {
                case CMD_CAPTURE_SINGLE:
                    Serial.println("📷 [Camera] 단발 촬영");
                    fb = cameraServiceCapture();
                    break;

                case CMD_CAPTURE_PREVIEW:
                    Serial.println("📷 [Camera] 미리보기");
                    fb = cameraServicePreview();
                    break;

                case CMD_CAPTURE_BURST:
                    Serial.printf("📷 [Camera] 베스트컷 (%d장)\n", cmd.burstCount);
                    fb = cameraServiceBestCut(cmd.burstCount);
                    break;
            }

            // 촬영 성공 시 BLE로 전송
            if (fb) {
                bleDriverSendImage(fb->buf, fb->len);
                cameraServiceReturn(fb);
            }
        }
    }
}

// ==========================================
// Task 4: BLETask (Core 1, 1Hz)
// ==========================================
// 왜 1초? → 앱 UI 업데이트에 1초면 충분
static void bleTask(void* param) {
    Serial.println("📡 [Task] BLETask 시작 (Core 1, 1Hz)");

    for (;;) {
        if (bleDriverIsConnected()) {
            PetStatus status;
            if (xSemaphoreTake(statusMutex, pdMS_TO_TICKS(10)) == pdTRUE) {
                status = latestStatus;
                xSemaphoreGive(statusMutex);
            }

            uint8_t packet[BLE_SENSOR_PACKET_SIZE];
            bleProtocolSerializeStatus(status, packet);
            bleDriverSendSensorData(packet, sizeof(packet));
        }

        vTaskDelay(pdMS_TO_TICKS(TASK_BLE_PERIOD_MS));
    }
}

// ==========================================
// 초기화 — Queue/Mutex 생성 + 태스크 생성
// ==========================================
void taskManagerInit() {
    // Queue & Mutex 생성
    cmdQueue = xQueueCreate(CMD_QUEUE_SIZE, sizeof(AppCommand));
    statusMutex = xSemaphoreCreateMutex();

    // 명령 핸들러 초기화 (BLE → Queue 연결)
    commandHandlerInit(cmdQueue);

    // FreeRTOS 태스크 생성
    xTaskCreatePinnedToCore(sensorTask,   "SensorTask",   TASK_SENSOR_STACK,
                            nullptr, TASK_SENSOR_PRIORITY,   &sensorTaskHandle,   0);
    xTaskCreatePinnedToCore(analysisTask, "AnalysisTask", TASK_ANALYSIS_STACK,
                            nullptr, TASK_ANALYSIS_PRIORITY, &analysisTaskHandle, 0);
    xTaskCreatePinnedToCore(cameraTask,   "CameraTask",   TASK_CAMERA_STACK,
                            nullptr, TASK_CAMERA_PRIORITY,   &cameraTaskHandle,   1);
    xTaskCreatePinnedToCore(bleTask,      "BLETask",      TASK_BLE_STACK,
                            nullptr, TASK_BLE_PRIORITY,      &bleTaskHandle,      1);

    Serial.println("✅ 모든 태스크 시작 완료!");
    Serial.println("📊 Core 0: SensorTask(100Hz) + AnalysisTask(2Hz)");
    Serial.println("📊 Core 1: CameraTask(이벤트) + BLETask(1Hz)");
}
