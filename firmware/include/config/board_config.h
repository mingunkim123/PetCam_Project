#ifndef BOARD_CONFIG_H_
#define BOARD_CONFIG_H_

// ==========================================
// 하드웨어 핀맵 — ESP32-S3-WROOM-1 CAM
// ==========================================

// --- 카메라 (OV3660) SCCB + 데이터 라인 ---
#define CAM_PIN_PWDN      -1
#define CAM_PIN_RESET     -1
#define CAM_PIN_XCLK      15
#define CAM_PIN_SIOD       4
#define CAM_PIN_SIOC       5

#define CAM_PIN_Y9        16
#define CAM_PIN_Y8        17
#define CAM_PIN_Y7        18
#define CAM_PIN_Y6        12
#define CAM_PIN_Y5        10
#define CAM_PIN_Y4         8
#define CAM_PIN_Y3         9
#define CAM_PIN_Y2        11

#define CAM_PIN_VSYNC      6
#define CAM_PIN_HREF       7
#define CAM_PIN_PCLK      13

// --- 센서 I2C Bus 1 (카메라 SCCB와 분리) ---
#define SENSOR_SDA_PIN     1
#define SENSOR_SCL_PIN     2

#endif
