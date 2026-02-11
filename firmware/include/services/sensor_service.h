#ifndef SENSOR_SERVICE_H_
#define SENSOR_SERVICE_H_

#include "app/app_types.h"

// ==========================================
// Sensor Service — 데이터 필터링/버퍼링
// ==========================================
// 역할: HAL에서 raw 데이터를 읽고, 이동평균 필터 적용
// 규칙: HAL만 호출, BLE/분석 로직 금지

void sensorServiceInit();

// HAL에서 읽고 내부 버퍼에 축적 (SensorTask에서 호출)
void sensorServiceUpdate();

// 필터링된 데이터 획득 (AnalysisTask에서 호출)
MPUData sensorServiceGetFilteredIMU();
HRData  sensorServiceGetFilteredHR();

#endif
