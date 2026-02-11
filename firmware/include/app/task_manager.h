#ifndef TASK_MANAGER_H_
#define TASK_MANAGER_H_

#include <Arduino.h>

// ==========================================
// Task Manager — FreeRTOS 태스크 오케스트레이션
// ==========================================
// 역할: 태스크 생성, Queue/Mutex 관리, 태스크 함수 정의
// 규칙: 모든 서비스를 조율하는 최상위 오케스트레이터

void taskManagerInit();

#endif
