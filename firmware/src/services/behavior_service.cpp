#include "services/behavior_service.h"
#include "config/app_config.h"
#include <math.h>

// ==========================================
// 내부 상태
// ==========================================
static unsigned long lowActivityStartTime = 0;
static bool inLowActivity = false;
static SleepStage currentSleepStage = SLEEP_AWAKE;

static float gyroZHistory[SENSOR_BUFFER_SIZE];
static int gyroZHistIdx = 0, gyroZHistCount = 0;

static PetMood moodHistory[MOOD_HISTORY_SIZE];
static int moodHistIdx = 0, moodHistCount = 0;

// ==========================================
// 내부 함수 (static — 외부에 노출되지 않음)
// ==========================================
static uint16_t calculateActivityIndex(const MPUData& mpu) {
    float dynamicAccel = fabsf(mpu.accelMagnitude - 1.0f);
    float gyroContrib = mpu.gyroMagnitude / 500.0f;
    float combined = dynamicAccel * 0.7f + gyroContrib * 0.3f;
    uint16_t index = (uint16_t)(combined * 1000.0f);
    return (index > 1000) ? 1000 : index;
}

static uint16_t detectTailWag(const MPUData& mpu) {
    gyroZHistory[gyroZHistIdx] = mpu.gyroZ;
    gyroZHistIdx = (gyroZHistIdx + 1) % SENSOR_BUFFER_SIZE;
    if (gyroZHistCount < SENSOR_BUFFER_SIZE) gyroZHistCount++;
    if (gyroZHistCount < 10) return 0;

    int zeroCrossings = 0;
    for (int i = 1; i < gyroZHistCount; i++) {
        int prevIdx = (gyroZHistIdx - gyroZHistCount + i - 1 + SENSOR_BUFFER_SIZE) % SENSOR_BUFFER_SIZE;
        int currIdx = (gyroZHistIdx - gyroZHistCount + i + SENSOR_BUFFER_SIZE) % SENSOR_BUFFER_SIZE;
        if ((gyroZHistory[prevIdx] > 0 && gyroZHistory[currIdx] < 0) ||
            (gyroZHistory[prevIdx] < 0 && gyroZHistory[currIdx] > 0)) {
            zeroCrossings++;
        }
    }

    float timeSec = (float)gyroZHistCount * 0.01f;
    float freq = (zeroCrossings / 2.0f) / timeSec;
    uint16_t freqMHz = (uint16_t)(freq * 1000.0f);

    float maxGyroZ = 0;
    for (int i = 0; i < gyroZHistCount; i++) {
        float absVal = fabsf(gyroZHistory[i]);
        if (absVal > maxGyroZ) maxGyroZ = absVal;
    }

    if (maxGyroZ > TAIL_WAG_MIN_AMPLITUDE &&
        freqMHz >= TAIL_WAG_MIN_FREQ && freqMHz <= TAIL_WAG_MAX_FREQ) {
        return freqMHz;
    }
    return 0;
}

static PetMood determineMood(uint16_t activity, uint16_t tailWag, uint16_t bpm, uint16_t hrv) {
    PetMood newMood;

    if (activity < ACTIVITY_THRESHOLD_MED && bpm > BPM_HIGH)
        newMood = MOOD_ANXIOUS;
    else if (activity > ACTIVITY_THRESHOLD_MED && bpm > BPM_ELEVATED)
        newMood = MOOD_EXCITED;
    else if (tailWag > 0 && bpm <= BPM_ELEVATED)
        newMood = MOOD_HAPPY;
    else if (activity > ACTIVITY_THRESHOLD_HIGH)
        newMood = MOOD_ACTIVE;
    else
        newMood = MOOD_CALM;

    // 기분 안정화 (다수결)
    moodHistory[moodHistIdx] = newMood;
    moodHistIdx = (moodHistIdx + 1) % MOOD_HISTORY_SIZE;
    if (moodHistCount < MOOD_HISTORY_SIZE) moodHistCount++;

    if (moodHistCount >= MOOD_MIN_VOTES) {
        int counts[6] = {0};
        for (int i = 0; i < moodHistCount; i++) counts[moodHistory[i]]++;
        int maxCount = 0;
        PetMood majority = newMood;
        for (int i = 1; i <= 5; i++) {
            if (counts[i] > maxCount) { maxCount = counts[i]; majority = (PetMood)i; }
        }
        return majority;
    }
    return newMood;
}

static SleepStage determineSleepStage(uint16_t activity, uint16_t bpm) {
    unsigned long now = millis();

    if (activity <= SLEEP_ACTIVITY_THRESHOLD) {
        if (!inLowActivity) { inLowActivity = true; lowActivityStartTime = now; }
        unsigned long duration = now - lowActivityStartTime;

        if (duration >= SLEEP_DEEP_MS) {
            currentSleepStage = (bpm > 0 && bpm < BPM_RESTING_LOW) ? SLEEP_DEEP : SLEEP_LIGHT;
        } else if (duration >= SLEEP_LIGHT_MS) {
            currentSleepStage = SLEEP_LIGHT;
        } else if (duration >= SLEEP_DROWSY_MS) {
            currentSleepStage = SLEEP_DROWSY;
        }
    } else {
        inLowActivity = false;
        currentSleepStage = SLEEP_AWAKE;
    }
    return currentSleepStage;
}

static uint8_t calculateSleepQuality(SleepStage stage, uint16_t hrv, uint16_t activity) {
    if (stage == SLEEP_AWAKE) return 0;
    float score = 0;

    switch (stage) {
        case SLEEP_DROWSY: score += 10; break;
        case SLEEP_LIGHT:  score += 25; break;
        case SLEEP_DEEP:   score += 40; break;
        default: break;
    }

    float hrvScore = (hrv > 0) ? fminf((float)hrv / 50.0f, 1.0f) * 30.0f : 15.0f;
    score += hrvScore;

    float stillness = fmaxf(0.0f, 1.0f - (float)activity / (float)SLEEP_ACTIVITY_THRESHOLD) * 30.0f;
    score += stillness;

    return (uint8_t)fminf(score, 100.0f);
}

// ==========================================
// Public API
// ==========================================
void behaviorServiceInit() {
    lowActivityStartTime = 0;
    inLowActivity = false;
    currentSleepStage = SLEEP_AWAKE;
    gyroZHistIdx = gyroZHistCount = 0;
    moodHistIdx = moodHistCount = 0;
    memset(gyroZHistory, 0, sizeof(gyroZHistory));
    memset(moodHistory, 0, sizeof(moodHistory));
    Serial.println("🧠 [BHV_SVC] 행동 분석 서비스 초기화 완료");
}

PetStatus behaviorServiceAnalyze(const MPUData& mpu, const HRData& hr) {
    PetStatus s;
    s.activityIndex = calculateActivityIndex(mpu);
    s.tailWagFreq = detectTailWag(mpu);
    s.bpm = hr.bpm;
    s.hrv = hr.hrv;
    s.accelMag = mpu.accelMagnitude;
    s.gyroMag  = mpu.gyroMagnitude;
    s.sleepStage = determineSleepStage(s.activityIndex, s.bpm);
    s.mood = (s.sleepStage >= SLEEP_LIGHT) ? MOOD_CALM
             : determineMood(s.activityIndex, s.tailWagFreq, s.bpm, s.hrv);
    s.sleepQuality = calculateSleepQuality(s.sleepStage, s.hrv, s.activityIndex);
    return s;
}
