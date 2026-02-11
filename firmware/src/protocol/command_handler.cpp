#include "protocol/command_handler.h"
#include "protocol/ble_protocol.h"

static QueueHandle_t cmdQueueRef = nullptr;

void commandHandlerInit(QueueHandle_t cmdQueue) {
    cmdQueueRef = cmdQueue;
    Serial.println("📋 [CMD_HDL] 명령 핸들러 초기화 완료");
}

// ==========================================
// BLE raw bytes → AppCommand → Queue
// ==========================================
// 왜 Queue? → 기존의 전역 Flag(takePhotoFlag 등)는 Race Condition 위험이 있음.
// FreeRTOS Queue는 atomic하게 데이터를 전달하므로 안전함.
// 또한 Flag는 "최신 1개"만 보관하지만, Queue는 여러 명령을 순차 처리 가능.
void commandHandlerOnBleData(const uint8_t* data, size_t len) {
    if (!cmdQueueRef) return;

    AppCommand cmd;
    if (bleProtocolParseCommand(data, len, &cmd)) {
        const char* cmdNames[] = {"", "단발촬영", "연속촬영", "미리보기"};
        Serial.printf("📥 [CMD_HDL] 명령 수신: %s\n",
            cmd.type <= CMD_CAPTURE_PREVIEW ? cmdNames[cmd.type] : "알 수 없음");

        if (cmd.gpsLat != 0.0 || cmd.gpsLng != 0.0) {
            Serial.printf("📍 [CMD_HDL] 위치: %f, %f\n", cmd.gpsLat, cmd.gpsLng);
        }

        // Queue에 명령 전달 (CameraTask가 수신)
        if (xQueueSend(cmdQueueRef, &cmd, pdMS_TO_TICKS(10)) != pdTRUE) {
            Serial.println("⚠️ [CMD_HDL] 명령 큐 가득 참!");
        }
    } else {
        Serial.printf("⚠️ [CMD_HDL] 알 수 없는 명령: 0x%02X\n", data[0]);
    }
}
