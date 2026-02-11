#ifndef SENSOR_HAL_H_
#define SENSOR_HAL_H_

#include <Arduino.h>
#include "app/app_types.h"

// ==========================================
// 센서 HAL — 하드웨어 추상화 계층
// ==========================================
// 역할: MPU6050/MAX30102 라이브러리를 완전히 감춤
// 규칙: 헤더에 <MPU6050.h>, <MAX30105.h> 절대 노출하지 않음
//        → 센서 교체 시 이 파일만 수정

bool sensorHalInit();
bool sensorHalReadIMU(MPUData* data);
bool sensorHalReadHR(HRData* data);
bool sensorHalIsIMUReady();
bool sensorHalIsHRReady();

#endif
