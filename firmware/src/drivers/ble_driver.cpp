#include "drivers/ble_driver.h"
#include "config/ble_config.h"

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ==========================================
// 내부 상태
// ==========================================
static BLEServer*         pServer = nullptr;
static BLECharacteristic* pDataChar = nullptr;     // 이미지 전송
static BLECharacteristic* pSensorChar = nullptr;   // 센서 데이터
static bool               connected = false;
static BleCommandCallback commandCallback = nullptr;

// ==========================================
// BLE 콜백 — 연결/해제
// ==========================================
class ServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* server) override {
        connected = true;
        Serial.println("📱 [BLE_DRV] 연결됨");
    }
    void onDisconnect(BLEServer* server) override {
        connected = false;
        Serial.println("📴 [BLE_DRV] 연결 해제");
        delay(500);
        BLEDevice::startAdvertising();
        Serial.println("📡 [BLE_DRV] 재광고 시작");
    }
};

// ==========================================
// BLE 콜백 — 명령 수신 (raw bytes만 전달)
// ==========================================
// 왜 이렇게? → 이전에는 이 콜백 안에서 GPS 파싱, Flag 설정 등
// 비즈니스 로직을 직접 수행했음. 이제는 raw bytes를 콜백으로
// 전달하여 상위 레이어(command_handler)가 처리하도록 위임.
class CmdCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* characteristic) override {
        std::string value = characteristic->getValue();
        if (value.length() > 0 && commandCallback) {
            commandCallback((const uint8_t*)value.data(), value.length());
        }
    }
};

// ==========================================
// 초기화
// ==========================================
void bleDriverInit(BleCommandCallback onCommand) {
    commandCallback = onCommand;

    BLEDevice::init(BLE_DEVICE_NAME);
    BLEDevice::setMTU(BLE_MTU_SIZE);

    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    BLEService* pService = pServer->createService(
        BLEUUID(BLE_SERVICE_UUID), BLE_SERVICE_HANDLES
    );

    // 이미지 전송 Characteristic
    pDataChar = pService->createCharacteristic(
        BLE_DATA_CHAR_UUID,
        BLECharacteristic::PROPERTY_NOTIFY
    );
    pDataChar->addDescriptor(new BLE2902());

    // 명령 수신 Characteristic
    BLECharacteristic* pCmdChar = pService->createCharacteristic(
        BLE_CMD_CHAR_UUID,
        BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
    );
    pCmdChar->setCallbacks(new CmdCallbacks());

    // 센서 데이터 Characteristic
    pSensorChar = pService->createCharacteristic(
        BLE_SENSOR_CHAR_UUID,
        BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
    );
    pSensorChar->addDescriptor(new BLE2902());

    pService->start();

    BLEAdvertising* pAdv = BLEDevice::getAdvertising();
    pAdv->addServiceUUID(BLE_SERVICE_UUID);
    pAdv->setScanResponse(true);
    pAdv->setMinPreferred(0x06);
    pAdv->setMinPreferred(0x12);
    BLEDevice::startAdvertising();

    Serial.println("📡 [BLE_DRV] 서버 준비 완료");
}

// ==========================================
// 이미지 전송 (청크 분할)
// ==========================================
void bleDriverSendImage(uint8_t* data, size_t len) {
    if (!connected || !pDataChar) return;

    String header = "SIZE:" + String(len);
    pDataChar->setValue((uint8_t*)header.c_str(), header.length());
    pDataChar->notify();
    delay(BLE_HEADER_DELAY_MS);

    size_t pos = 0;
    Serial.printf("📤 [BLE_DRV] 이미지 전송 시작 (%d bytes)...\n", len);

    while (pos < len) {
        size_t chunk = (len - pos < BLE_IMAGE_CHUNK_SIZE) ? len - pos : BLE_IMAGE_CHUNK_SIZE;
        pDataChar->setValue(&data[pos], chunk);
        pDataChar->notify();
        pos += chunk;
        delay(BLE_CHUNK_DELAY_MS);
    }

    Serial.println("✅ [BLE_DRV] 이미지 전송 완료");
}

// ==========================================
// 센서 데이터 전송
// ==========================================
void bleDriverSendSensorData(uint8_t* data, size_t len) {
    if (!connected || !pSensorChar) return;
    pSensorChar->setValue(data, len);
    pSensorChar->notify();
}

bool bleDriverIsConnected() {
    return connected;
}
