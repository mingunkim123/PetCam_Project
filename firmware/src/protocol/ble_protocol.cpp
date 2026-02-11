#include "protocol/ble_protocol.h"
#include "config/app_config.h"
#include <string.h>

// ==========================================
// PetStatus → BLE 20바이트 패킷
// ==========================================
// 왜 별도 함수? → 패킷 형식 변경 시 이 파일만 수정하면 됨.
// 기존에는 main.cpp의 bleTask() 안에 직접 존재했음.
void bleProtocolSerializeStatus(const PetStatus& s, uint8_t* out) {
    memset(out, 0, BLE_SENSOR_PACKET_SIZE);

    out[0] = (uint8_t)s.mood;
    out[1] = (uint8_t)(s.bpm & 0xFF);
    out[2] = (uint8_t)(s.bpm >> 8);
    out[3] = (uint8_t)(s.hrv & 0xFF);
    out[4] = (uint8_t)(s.hrv >> 8);
    out[5] = (uint8_t)(s.activityIndex & 0xFF);
    out[6] = (uint8_t)(s.activityIndex >> 8);
    out[7] = (uint8_t)(s.tailWagFreq & 0xFF);
    out[8] = (uint8_t)(s.tailWagFreq >> 8);
    out[9] = (uint8_t)s.sleepStage;
    out[10] = s.sleepQuality;
    memcpy(&out[11], &s.accelMag, sizeof(float));
    memcpy(&out[15], &s.gyroMag, sizeof(float));
    out[19] = 0xFF;  // 예비
}

// ==========================================
// Raw BLE bytes → AppCommand
// ==========================================
// 왜 별도 함수? → BLE 콜백에서 GPS 파싱·명령 해석을 직접 하면
// 통신 레이어가 앱 로직에 의존하게 됨. 여기서 파싱하고 구조체로 반환.
bool bleProtocolParseCommand(const uint8_t* data, size_t len, AppCommand* cmd) {
    if (len == 0 || !cmd) return false;

    cmd->type = (AppCommandType)data[0];
    cmd->gpsLat = 0.0;
    cmd->gpsLng = 0.0;
    cmd->burstCount = CAMERA_BURST_COUNT;

    // GPS 데이터 파싱 (1byte CMD + 8byte Lat + 8byte Lng = 17bytes)
    if (len >= 17) {
        memcpy(&cmd->gpsLat, &data[1], 8);
        memcpy(&cmd->gpsLng, &data[9], 8);
    }

    // 유효한 명령인지 확인
    return (cmd->type >= CMD_CAPTURE_SINGLE && cmd->type <= CMD_CAPTURE_PREVIEW);
}
