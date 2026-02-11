#ifndef COMMAND_HANDLER_H_
#define COMMAND_HANDLER_H_

#include "app/app_types.h"

// ==========================================
// Command Handler — 명령 디스패치
// ==========================================
// 역할: BLE raw bytes → 파싱 → FreeRTOS Queue에 전달
// 규칙: BLE 드라이버의 콜백으로 등록되어 호출됨

// 초기화 (Queue 참조 저장)
void commandHandlerInit(QueueHandle_t cmdQueue);

// BLE 드라이버에서 호출되는 콜백
void commandHandlerOnBleData(const uint8_t* data, size_t len);

#endif
