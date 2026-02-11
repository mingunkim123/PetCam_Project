#include "services/sensor_service.h"
#include "hal/sensor_hal.h"
#include "config/app_config.h"

// ==========================================
// 내부 링 버퍼
// ==========================================
static MPUData mpuBuffer[SENSOR_BUFFER_SIZE];
static HRData  hrBuffer[HR_BUFFER_SIZE];
static int mpuBufIdx = 0, mpuBufCount = 0;
static int hrBufIdx  = 0, hrBufCount  = 0;

void sensorServiceInit() {
    memset(mpuBuffer, 0, sizeof(mpuBuffer));
    memset(hrBuffer, 0, sizeof(hrBuffer));
    mpuBufIdx = mpuBufCount = 0;
    hrBufIdx  = hrBufCount  = 0;
    Serial.println("🔧 [SENS_SVC] 센서 서비스 초기화 완료");
}

// ==========================================
// HAL에서 읽고 버퍼에 축적
// ==========================================
void sensorServiceUpdate() {
    MPUData mpu;
    if (sensorHalReadIMU(&mpu)) {
        mpuBuffer[mpuBufIdx] = mpu;
        mpuBufIdx = (mpuBufIdx + 1) % SENSOR_BUFFER_SIZE;
        if (mpuBufCount < SENSOR_BUFFER_SIZE) mpuBufCount++;
    }

    HRData hr;
    if (sensorHalReadHR(&hr)) {
        hrBuffer[hrBufIdx] = hr;
        hrBufIdx = (hrBufIdx + 1) % HR_BUFFER_SIZE;
        if (hrBufCount < HR_BUFFER_SIZE) hrBufCount++;
    }
}

// ==========================================
// 이동평균 필터
// ==========================================
MPUData sensorServiceGetFilteredIMU() {
    MPUData avg = {0};
    if (mpuBufCount == 0) return avg;

    for (int i = 0; i < mpuBufCount; i++) {
        avg.accelX += mpuBuffer[i].accelX;
        avg.accelY += mpuBuffer[i].accelY;
        avg.accelZ += mpuBuffer[i].accelZ;
        avg.gyroX  += mpuBuffer[i].gyroX;
        avg.gyroY  += mpuBuffer[i].gyroY;
        avg.gyroZ  += mpuBuffer[i].gyroZ;
        avg.accelMagnitude += mpuBuffer[i].accelMagnitude;
        avg.gyroMagnitude  += mpuBuffer[i].gyroMagnitude;
    }

    float n = (float)mpuBufCount;
    avg.accelX /= n;  avg.accelY /= n;  avg.accelZ /= n;
    avg.gyroX  /= n;  avg.gyroY  /= n;  avg.gyroZ  /= n;
    avg.accelMagnitude /= n;
    avg.gyroMagnitude  /= n;

    return avg;
}

HRData sensorServiceGetFilteredHR() {
    HRData avg = {0};
    if (hrBufCount == 0) return avg;

    uint32_t sumBPM = 0, sumHRV = 0;
    int validCount = 0;

    for (int i = 0; i < hrBufCount; i++) {
        if (hrBuffer[i].bpm > 0) {
            sumBPM += hrBuffer[i].bpm;
            sumHRV += hrBuffer[i].hrv;
            validCount++;
        }
    }

    if (validCount > 0) {
        avg.bpm = sumBPM / validCount;
        avg.hrv = sumHRV / validCount;
    }
    avg.fingerOn = hrBuffer[(hrBufIdx - 1 + HR_BUFFER_SIZE) % HR_BUFFER_SIZE].fingerOn;
    avg.irValue  = hrBuffer[(hrBufIdx - 1 + HR_BUFFER_SIZE) % HR_BUFFER_SIZE].irValue;

    return avg;
}
