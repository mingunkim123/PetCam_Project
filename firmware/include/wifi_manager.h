#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <LittleFS.h>

// WiFi 연결 함수
bool connectToWiFi(const char* ssid, const char* password);

// 파일 업로드 함수
bool uploadFile(const char* filename, const char* serverUrl);

// 주변 WiFi 스캔 및 특정 SSID 찾기
bool scanForSSID(const char* targetSSID);

// 저장된 모든 파일 업로드
void syncAllFiles(const char* serverUrl);

#endif
