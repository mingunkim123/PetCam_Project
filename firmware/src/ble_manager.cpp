#include "ble_manager.h"

// UUID 정의 (Flutter 앱의 UUID와 100% 일치시킴)
#define SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define DATA_CHAR_UUID         "beb5483e-36e1-4688-b7f5-ea07361b26a8" // 데이터 전송용 (3e)
#define CMD_CHAR_UUID          "beb5483f-36e1-4688-b7f5-ea07361b26a8" // 명령 수신용 (3f)


// 전역 변수 설정
BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL; // 데이터 전송용
bool deviceConnected = false;
bool oldDeviceConnected = false;
bool takePhotoFlag = false; // 📸 촬영 명령을 감지할 깃발

// 1. 서버 연결 상태 콜백
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        deviceConnected = true;
        Serial.println("📱 [BLE] 스마트폰 연결 성공");
    };

    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
        Serial.println("📴 [BLE] 스마트폰 연결 해제");
    }
};

// 2. ⭐️ 명령 수신 콜백 (명령 채널 전용)
// 2. ⭐️ 명령 수신 콜백 수정
class MyCmdCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        std::string value = pCharacteristic->getValue();

        if (value.length() > 0) {
            uint8_t receivedCmd = value[0];
            Serial.printf("📥 [BLE] 명령 수신: 0x%02X\n", receivedCmd);

            // 📍 GPS 데이터 파싱 (1byte CMD + 8byte Lat + 8byte Lng = 17bytes)
            if (value.length() >= 17) {
                double lat, lng;
                memcpy(&lat, &value[1], 8);
                memcpy(&lng, &value[9], 8);
                currentLat = lat;
                currentLng = lng;
                Serial.printf("📍 위치 수신: %f, %f\n", currentLat, currentLng);
            } else {
                Serial.println("⚠️ 위치 정보 없음 (기본값 0.0 사용)");
                currentLat = 0.0;
                currentLng = 0.0;
            }

            if (receivedCmd == 0x01) { // 단발 촬영
                takePhotoFlag = true;
                Serial.println("🎯 [FLAG] 단발 촬영 예약됨");
            } 
            else if (receivedCmd == 0x02) { // 💡 연속 촬영
                // 여기에 '몇 장 찍을지' 숫자를 넣어줘야 합니다!
                burstCount = 3; // 예: 3장 연속 촬영
                Serial.println("🎯 [FLAG] 연속 촬영 시작 (3장)");
            }
            else if (receivedCmd == 0x03) { // 📸 미리보기
                previewFlag = true;
                Serial.println("🎯 [FLAG] 미리보기 요청됨");
            }
        }
    }
};

// 3. BLE 초기화 함수
void initBLE() {
    BLEDevice::init(DEVICE_NAME);

    // 서버 생성 및 콜백 설정
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    // 서비스 생성
    BLEService *pService = pServer->createService(SERVICE_UUID);

    // [특성 1] 사진 데이터 전송용 (Notify 권한)
    pCharacteristic = pService->createCharacteristic(
        DATA_CHAR_UUID,
        BLECharacteristic::PROPERTY_NOTIFY
    );
    pCharacteristic->addDescriptor(new BLE2902());

    // [특성 2] ⭐️ 앱 명령 수신용 (Write 권한 추가)
    BLECharacteristic *pCmdChar = pService->createCharacteristic(
        CMD_CHAR_UUID,
        BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
    );
    pCmdChar->setCallbacks(new MyCmdCallbacks()); // 위에서 만든 콜백 연결

    // 서비스 시작
    pService->start();

    // 광고(Advertising) 시작
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);  
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();
    
    Serial.println("📡 [BLE] 서버가 준비되었습니다.");
}

// 4. 사진 전송 함수 (조각내서 전송)
void sendImageBLE(uint8_t* data, size_t len) {
    if (!deviceConnected) return;

    size_t pos = 0;
    const size_t chunkSize = 500; // MTU 512 기준 안정적인 크기 [cite: 2025-08-13]

    Serial.printf("📤 [BLE] 사진 전송 시작 (%d bytes)...\n", len);

    while (pos < len) {
        size_t size = (len - pos < chunkSize) ? len - pos : chunkSize;
        pCharacteristic->setValue(&data[pos], size);
        pCharacteristic->notify();
        pos += size;
        delay(10); // 폰이 처리할 수 있게 아주 짧은 대기 시간 [cite: 2025-12-18]
    }

    Serial.println("✅ [BLE] 전송 완료");
}