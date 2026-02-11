#ifndef BLE_PROTOCOL_H_
#define BLE_PROTOCOL_H_

#include "app/app_types.h"

// ==========================================
// BLE Protocol — 직렬화/역직렬화
// ==========================================
// 역할: PetStatus ↔ byte 배열 변환
// 규칙: 어떤 레이어에도 의존하지 않음 (순수 데이터 변환)

#define BLE_SENSOR_PACKET_SIZE  20

// PetStatus → 20바이트 패킷
void bleProtocolSerializeStatus(const PetStatus& status, uint8_t* out);

// Raw bytes → AppCommand 구조체
bool bleProtocolParseCommand(const uint8_t* data, size_t len, AppCommand* cmd);

#endif
