#ifndef BLE_MANAGER_H_
#define BLE_MANAGER_H_

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "main.h"

// 다른 파일에서도 연결 상태를 알 수 있도록 공유
extern bool deviceConnected;
extern bool takePhotoFlag; // 이 줄 추가! (외부에서 이 깃발을 볼 수 있게 함)

// 함수 선언
void initBLE();
void sendImageBLE(uint8_t* data, size_t len);

#endif