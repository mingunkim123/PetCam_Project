#ifndef BEHAVIOR_SERVICE_H_
#define BEHAVIOR_SERVICE_H_

#include "app/app_types.h"

// ==========================================
// Behavior Service — 행동/기분/수면 분석
// ==========================================

void behaviorServiceInit();
PetStatus behaviorServiceAnalyze(const MPUData& mpu, const HRData& hr);

#endif
