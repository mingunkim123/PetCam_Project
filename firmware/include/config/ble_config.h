#ifndef BLE_CONFIG_H_
#define BLE_CONFIG_H_

// ==========================================
// BLE 설정 — 유일한 정의 위치 (DRY 원칙)
// ==========================================
#define BLE_DEVICE_NAME        "PetCam"
#define BLE_SERVICE_UUID       "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define BLE_DATA_CHAR_UUID     "beb5483e-36e1-4688-b7f5-ea07361b26a8"  // 이미지 전송
#define BLE_CMD_CHAR_UUID      "beb5483f-36e1-4688-b7f5-ea07361b26a8"  // 명령 수신
#define BLE_SENSOR_CHAR_UUID   "beb54840-36e1-4688-b7f5-ea07361b26a8"  // 센서 데이터

// BLE 전송 설정
#define BLE_MTU_SIZE           512
#define BLE_IMAGE_CHUNK_SIZE   128    // 이미지 분할 전송 단위 (bytes)
#define BLE_CHUNK_DELAY_MS     20     // 전송 간 대기 시간 (ms)
#define BLE_HEADER_DELAY_MS    50     // 헤더 전송 후 대기 시간 (ms)
#define BLE_SERVICE_HANDLES    30     // BLE 서비스 핸들 수

#endif
