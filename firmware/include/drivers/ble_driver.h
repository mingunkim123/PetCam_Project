#ifndef BLE_DRIVER_H_
#define BLE_DRIVER_H_

#include <Arduino.h>

// ==========================================
// BLE Driver — 순수 통신만 담당
// ==========================================
// 역할: BLE 서버 초기화, 데이터 전송, 연결 상태 관리
// 규칙: 명령 파싱/비즈니스 로직 금지 — raw bytes만 전달

// 명령 수신 콜백 타입 (Protocol Layer에서 등록)
typedef void (*BleCommandCallback)(const uint8_t* data, size_t len);

// 초기화
void bleDriverInit(BleCommandCallback onCommand);

// 데이터 전송
void bleDriverSendImage(uint8_t* data, size_t len);
void bleDriverSendSensorData(uint8_t* data, size_t len);

// 상태
bool bleDriverIsConnected();

#endif
