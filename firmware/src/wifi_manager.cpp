#include "wifi_manager.h"

bool connectToWiFi(const char* ssid, const char* password) {
    Serial.printf("📡 WiFi 연결 시도: %s\n", ssid);
    
    // 이미 연결되어 있다면 true 반환
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("✅ 이미 WiFi에 연결되어 있습니다.");
        return true;
    }

    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);

    int retry = 0;
    while (WiFi.status() != WL_CONNECTED && retry < 20) { // 10초 대기
        delay(500);
        Serial.print(".");
        retry++;
    }
    Serial.println();

    if (WiFi.status() == WL_CONNECTED) {
        Serial.printf("✅ WiFi 연결 성공! IP: %s\n", WiFi.localIP().toString().c_str());
        return true;
    } else {
        Serial.println("❌ WiFi 연결 실패");
        return false;
    }
}

bool scanForSSID(const char* targetSSID) {
    Serial.println("🔍 주변 WiFi 스캔 중...");
    int n = WiFi.scanNetworks();
    if (n == 0) {
        Serial.println("❌ 발견된 네트워크 없음");
        return false;
    }

    for (int i = 0; i < n; ++i) {
        if (WiFi.SSID(i) == targetSSID) {
            Serial.printf("✅ 타겟 네트워크 발견: %s (RSSI: %d)\n", targetSSID, WiFi.RSSI(i));
            return true;
        }
    }
    Serial.println("❌ 타겟 네트워크를 찾을 수 없음");
    return false;
}

bool uploadFile(const char* filename, const char* serverUrl) {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("❌ WiFi 연결 안됨, 업로드 불가");
        return false;
    }

    File file = LittleFS.open(filename, "r");
    if (!file) {
        Serial.printf("❌ 파일 열기 실패: %s\n", filename);
        return false;
    }

    HTTPClient http;
    http.begin(serverUrl);
    http.setTimeout(10000); // 10초 타임아웃 설정
    
    // Multipart/form-data 헤더 설정은 라이브러리가 자동으로 처리하지 않으므로
    // 간단하게 raw binary로 보내거나, boundary를 직접 만들어야 합니다.
    // 여기서는 가장 확실한 방법인 boundary를 이용한 multipart 전송을 구현합니다.
    
    String boundary = "------------------------Esp32Boundary";
    String contentType = "multipart/form-data; boundary=" + boundary;
    
    // 헤더 생성
    String head = "--" + boundary + "\r\n";
    head += "Content-Disposition: form-data; name=\"file\"; filename=\"" + String(filename) + "\"\r\n";
    head += "Content-Type: image/jpeg\r\n\r\n";
    
    String tail = "\r\n--" + boundary + "--\r\n";
    
    size_t contentLength = head.length() + file.size() + tail.length();
    
    http.addHeader("Content-Type", contentType);
    http.addHeader("Content-Length", String(contentLength));
    
    // 스트리밍 전송을 위해 커스텀 방식 사용이 필요할 수 있으나, 
    // HTTPClient의 sendRequest는 Stream을 직접 지원하지 않는 경우가 많음.
    // 하지만 ESP32 HTTPClient는 stream을 지원함.
    
    // 메모리 부족을 피하기 위해 청크 단위로 보내는 로직이 필요할 수 있지만,
    // HTTPClient 라이브러리가 Stream을 받아주면 편합니다.
    // 여기서는 간단하게 구현하기 위해 전체를 메모리에 올리지 않고,
    // 연결 후 직접 write하는 방식을 쓰거나, 라이브러리 기능을 활용해야 합니다.
    
    // *중요*: 표준 HTTPClient는 복잡한 multipart 스트리밍을 직접 지원하지 않을 수 있음.
    // 따라서 여기서는 가장 단순하게 파일 내용을 body로 쏘는 binary upload를 먼저 시도하거나,
    // 서버가 multipart를 강제한다면 직접 TCP 연결을 쓰는게 나을 수 있음.
    // 하지만 사용자가 "HTTP POST"라고만 했으므로, 일단 가장 쉬운 방법인
    // "image/jpeg" content-type으로 raw body 전송을 시도해봅니다.
    // (서버가 이걸 받아준다면 훨씬 효율적임)
    
    // 만약 서버가 꼭 multipart를 원한다면 아래 코드를 수정해야 함.
    // 일단은 안전하게 Multipart 흉내를 내서 보내봅니다.
    
    // ** 수정된 접근 **: 
    // HTTPClient의 sendRequest는 payload를 한 번에 받기를 원할 수 있음.
    // 5MP 이미지는 500KB가 넘으므로 RAM에 다 올릴 수 없음 (PSRAM 있으면 가능하지만).
    // PSRAM을 믿고 buffer에 다 읽어서 보내는게 가장 쉬운 방법일 수 있음.
    // N16R8은 8MB PSRAM이 있으므로 500KB~1MB 파일은 충분히 메모리에 올릴 수 있음.
    
    size_t fSize = file.size();
    uint8_t * buf = (uint8_t*) ps_malloc(fSize + head.length() + tail.length());
    if (!buf) {
        Serial.println("❌ PSRAM 할당 실패 (업로드용 버퍼) - 파일이 너무 큽니다.");
        file.close();
        http.end();
        return false;
    }
    
    // 버퍼에 데이터 조립
    memcpy(buf, head.c_str(), head.length());
    file.read(buf + head.length(), fSize);
    memcpy(buf + head.length() + fSize, tail.c_str(), tail.length());
    
    file.close();
    
    Serial.printf("📤 업로드 시작: %s (%d bytes)\n", filename, contentLength);
    
    int httpResponseCode = http.POST(buf, contentLength);
    
    free(buf); // 메모리 해제
    
    if (httpResponseCode == 200) {
        Serial.printf("✅ 업로드 성공! 응답 코드: %d\n", httpResponseCode);
        String response = http.getString();
        Serial.println("서버 응답: " + response);
        http.end();
        return true;
    } else {
        Serial.printf("❌ 업로드 실패. 응답 코드: %d\n", httpResponseCode);
        http.end();
        return false;
    }
}

void syncAllFiles(const char* serverUrl) {
    Serial.println("📂 저장된 파일 동기화 시작...");
    
    File root = LittleFS.open("/");
    if (!root) {
        Serial.println("❌ 디렉토리 열기 실패");
        return;
    }
    if (!root.isDirectory()) {
        Serial.println("❌ 루트가 디렉토리가 아닙니다");
        return;
    }

    File file = root.openNextFile();
    while (file) {
        String fileName = String(file.name());
        
        // 캡처된 이미지 파일인지 확인 (capture_로 시작하고 .jpg로 끝나는지)
        if (fileName.indexOf("capture_") >= 0 && fileName.endsWith(".jpg")) {
            Serial.printf("found file: %s\n", fileName.c_str());
            
            String fullPath = fileName;
            if (!fullPath.startsWith("/")) fullPath = "/" + fullPath;

            // 📍 GPS 정보 파일 확인 (.txt)
            String txtPath = fullPath;
            txtPath.replace(".jpg", ".txt");
            
            String finalUrl = String(serverUrl);
            
            if (LittleFS.exists(txtPath)) {
                File txtFile = LittleFS.open(txtPath, "r");
                if (txtFile) {
                    String gpsData = txtFile.readString();
                    txtFile.close();
                    // URL에 쿼리 파라미터 추가 (?lat=...&lng=...)
                    // gpsData는 "37.123,127.123" 형식임
                    int commaIndex = gpsData.indexOf(',');
                    if (commaIndex > 0) {
                        String lat = gpsData.substring(0, commaIndex);
                        String lng = gpsData.substring(commaIndex + 1);
                        finalUrl += "?lat=" + lat + "&lng=" + lng;
                        Serial.println("📍 GPS 데이터 첨부: " + finalUrl);
                    }
                }
            }

            if (uploadFile(fullPath.c_str(), finalUrl.c_str())) {
                // 업로드 성공 시 삭제
                LittleFS.remove(fullPath);
                if (LittleFS.exists(txtPath)) LittleFS.remove(txtPath); // txt도 삭제
                Serial.printf("🗑️ 삭제 완료: %s\n", fullPath.c_str());
            } else {
                Serial.printf("⚠️ 업로드 실패: %s (다음에 재시도)\n", fullPath.c_str());
            }
        }
        
        file = root.openNextFile();
    }
    Serial.println("✅ 동기화 작업 종료");
}
