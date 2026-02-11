#include "hal/sensor_hal.h"
#include "config/board_config.h"

// 하드웨어 라이브러리는 .cpp에서만 include (정보 은닉)
#include <Wire.h>
#include <MPU6050.h>
#include <MAX30105.h>

// ==========================================
// 내부 상태 (static — 외부에 노출되지 않음)
// ==========================================
static MPU6050   mpu;
static MAX30105  hrSensor;
static TwoWire   sensorWire(1);
static bool      mpuReady = false;
static bool      hrReady  = false;

// ==========================================
// 초기화
// ==========================================
bool sensorHalInit() {
    Serial.println("🔧 [SENS_HAL] I2C Bus 1 초기화...");
    sensorWire.begin(SENSOR_SDA_PIN, SENSOR_SCL_PIN, 400000);

    // --- MPU6050 ---
    Serial.println("🔧 [SENS_HAL] MPU6050 초기화...");
    mpu = MPU6050(0x68, &sensorWire);
    mpu.initialize();

    if (mpu.testConnection()) {
        mpuReady = true;
        mpu.setFullScaleAccelRange(MPU6050_ACCEL_FS_4);
        mpu.setFullScaleGyroRange(MPU6050_GYRO_FS_500);
        mpu.setDLPFMode(MPU6050_DLPF_BW_42);
        Serial.println("✅ [SENS_HAL] MPU6050 준비 완료 (±4g, ±500°/s)");
    } else {
        Serial.println("❌ [SENS_HAL] MPU6050 연결 실패!");
    }

    // --- MAX30102 ---
    Serial.println("🔧 [SENS_HAL] MAX30102 초기화...");
    if (hrSensor.begin(sensorWire, I2C_SPEED_FAST, 0x57)) {
        hrReady = true;
        hrSensor.setup(0x1F, 4, 2, 400, 411, 4096);
        hrSensor.setPulseAmplitudeRed(0);
        hrSensor.setPulseAmplitudeIR(0x1F);
        Serial.println("✅ [SENS_HAL] MAX30102 준비 완료 (HR Mode)");
    } else {
        Serial.println("❌ [SENS_HAL] MAX30102 연결 실패!");
    }

    return mpuReady || hrReady;
}

// ==========================================
// IMU 읽기 (Raw → 물리 단위 변환)
// ==========================================
bool sensorHalReadIMU(MPUData* data) {
    if (!mpuReady) return false;

    int16_t ax, ay, az, gx, gy, gz;
    mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

    data->accelX = ax / 8192.0f;
    data->accelY = ay / 8192.0f;
    data->accelZ = az / 8192.0f;
    data->gyroX  = gx / 65.5f;
    data->gyroY  = gy / 65.5f;
    data->gyroZ  = gz / 65.5f;

    data->accelMagnitude = sqrtf(
        data->accelX * data->accelX +
        data->accelY * data->accelY +
        data->accelZ * data->accelZ
    );
    data->gyroMagnitude = sqrtf(
        data->gyroX * data->gyroX +
        data->gyroY * data->gyroY +
        data->gyroZ * data->gyroZ
    );

    return true;
}

// ==========================================
// 심박수 읽기 (피크 감지 + BPM/HRV 계산)
// ==========================================
static uint32_t lastBeatTime = 0;
static uint16_t beatIntervals[10];
static int beatIdx = 0;
static int beatCount = 0;

bool sensorHalReadHR(HRData* data) {
    if (!hrReady) return false;

    data->irValue = hrSensor.getIR();
    data->fingerOn = (data->irValue > 50000);

    if (data->fingerOn) {
        static uint32_t prevIR = 0;
        static bool rising = false;
        static uint32_t peakValue = 0;

        if (data->irValue > prevIR && !rising) {
            rising = true;
        } else if (data->irValue < prevIR && rising) {
            rising = false;
            uint32_t now = millis();

            if (peakValue > 0 && (now - lastBeatTime) > 300) {
                uint16_t interval = now - lastBeatTime;
                lastBeatTime = now;

                beatIntervals[beatIdx] = interval;
                beatIdx = (beatIdx + 1) % 10;
                if (beatCount < 10) beatCount++;

                uint32_t avgInterval = 0;
                for (int i = 0; i < beatCount; i++) avgInterval += beatIntervals[i];
                avgInterval /= beatCount;
                data->bpm = (avgInterval > 0) ? (60000 / avgInterval) : 0;

                if (beatCount >= 2) {
                    float sumSqDiff = 0;
                    int cnt = 0;
                    for (int i = 1; i < beatCount; i++) {
                        int diff = (int)beatIntervals[i] - (int)beatIntervals[i-1];
                        sumSqDiff += diff * diff;
                        cnt++;
                    }
                    data->hrv = (uint16_t)sqrtf(sumSqDiff / cnt);
                } else {
                    data->hrv = 0;
                }
            }
            peakValue = data->irValue;
        }
        prevIR = data->irValue;
    } else {
        data->bpm = 0;
        data->hrv = 0;
    }

    return true;
}

bool sensorHalIsIMUReady() { return mpuReady; }
bool sensorHalIsHRReady()  { return hrReady; }
