# PetCam AI Server

FastAPI 기반 AI 이미지 처리 및 백엔드 서버입니다.

## 주요 기능

- **AI 업스케일**: Real-ESRGAN을 사용한 이미지 고화질 변환
- **베스트컷 선택**: 여러 사진 중 가장 선명한 사진 자동 선택
- **JWT 인증**: 안전한 토큰 기반 사용자 인증
- **Rate Limiting**: API 남용 방지

## 빠른 시작

### 1. 환경 설정

`.env.example`을 `.env`로 복사하고 값 설정:

```bash
cp .env.example .env
```

필수 환경 변수:

```bash
# JWT 시크릿 키 (생성: openssl rand -hex 32)
SECRET_KEY=your-super-secret-key-change-this

# PostgreSQL 설정
POSTGRES_USER=petuser
POSTGRES_PASSWORD=your-strong-db-password
POSTGRES_DB=petdb

# 데이터베이스 URL
DATABASE_URL=postgresql://petuser:your-strong-db-password@db:5432/petdb
```

### 2. Docker로 실행

```bash
# 빌드 및 실행
docker-compose up -d --build

# 로그 확인
docker-compose logs -f
```

### 3. 확인

- 서버: http://localhost:8000
- API 문서 (Swagger): http://localhost:8000/docs
- API 문서 (ReDoc): http://localhost:8000/redoc

---

## API 문서

### 인증 (Auth)

#### POST /register - 회원가입

새 사용자를 등록합니다.

**요청:**

```json
{
  "username": "testuser",
  "password": "password123"
}
```

**응답 (200 OK):**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "testuser",
  "is_active": true
}
```

**에러:**

| 코드 | 설명 |
|------|------|
| 400 | Username already registered |
| 422 | Validation Error (username 3~50자, password 6자 이상) |
| 429 | Rate limit exceeded (5/minute) |

---

#### POST /token - 로그인

JWT 토큰을 발급받습니다.

**요청:** (OAuth2 form)

```
Content-Type: application/x-www-form-urlencoded

username=testuser&password=password123
```

**응답 (200 OK):**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer"
}
```

**에러:**

| 코드 | 설명 |
|------|------|
| 401 | Incorrect username or password |
| 429 | Rate limit exceeded (10/minute) |

---

### 사진 (Photos)

> 모든 사진 API는 인증이 필요합니다.  
> Header: `Authorization: Bearer <access_token>`

#### POST /upscale - 이미지 업스케일

사진을 업로드하고 AI 업스케일 처리를 시작합니다.

**요청:** (multipart/form-data)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| file | File | O | JPEG 이미지 파일 |
| lat | float | X | 위도 (기본값: 0.0) |
| lng | float | X | 경도 (기본값: 0.0) |

**응답 (200 OK):**

```json
{
  "message": "Upload successful, processing in background",
  "id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**에러:**

| 코드 | 설명 |
|------|------|
| 401 | Not authenticated |
| 429 | Rate limit exceeded (10/minute) |
| 500 | File save failed |

---

#### POST /bestcut - 베스트컷 선택

여러 사진 중 가장 선명한 사진을 선택하고 업스케일합니다.

**요청:** (multipart/form-data)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| files | File[] | O | 여러 JPEG 이미지 파일 |
| lat | float | X | 위도 (기본값: 0.0) |
| lng | float | X | 경도 (기본값: 0.0) |

**응답 (200 OK):**

```json
{
  "message": "Best cut selected, processing in background",
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "score": 156.78
}
```

---

#### GET /photos - 사진 목록 조회

업로드된 사진 목록을 조회합니다.

**쿼리 파라미터:**

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| skip | int | 0 | 건너뛸 개수 |
| limit | int | 100 | 조회 개수 (최대 1000) |

**응답 (200 OK):**

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "original_path": "storage/originals/550e8400.jpg",
    "upscaled_path": "storage/upscaled/550e8400.jpg",
    "status": "completed",
    "latitude": 37.5665,
    "longitude": 126.9780,
    "created_at": "2026-01-27T10:30:00Z"
  }
]
```

**status 값:**

| 값 | 설명 |
|-----|------|
| queued | 처리 대기 중 |
| processing | 처리 중 |
| completed | 완료 |
| failed | 실패 |

---

#### GET /photos/{photo_id} - 사진 파일 조회

사진 파일을 다운로드합니다.

**쿼리 파라미터:**

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| type | string | upscaled | "upscaled" 또는 "original" |

**응답:**

- `200 OK`: image/jpeg 바이너리
- `404 Not Found`: 사진 없음

---

#### DELETE /photos/{photo_id} - 사진 삭제

사진을 삭제합니다.

**응답 (200 OK):**

```json
{
  "message": "Deleted successfully"
}
```

---

### 헬스체크

#### GET /health - 서버 상태 확인

**응답 (200 OK):**

```json
{
  "status": "ok",
  "version": "1.0.0"
}
```

---

## 에러 응답 형식

모든 에러는 다음 형식으로 반환됩니다:

```json
{
  "detail": "에러 메시지"
}
```

### 공통 HTTP 상태 코드

| 코드 | 설명 |
|------|------|
| 200 | 성공 |
| 400 | 잘못된 요청 |
| 401 | 인증 필요 |
| 403 | 권한 없음 |
| 404 | 리소스 없음 |
| 422 | 유효성 검사 실패 |
| 429 | 요청 한도 초과 |
| 500 | 서버 오류 |

---

## 프로젝트 구조

```
ai_server/
├── main.py                    # FastAPI 앱 진입점
├── database.py                # DB 연결 설정
├── models.py                  # SQLAlchemy 모델 (PhotoRecord)
├── requirements.txt           # Python 의존성
├── Dockerfile                 # 컨테이너 설정
├── docker-compose.yml         # 개발용 Docker Compose
├── .env.example               # 환경변수 예시
│
├── app/
│   ├── api/                   # API 라우터
│   │   ├── auth.py            # 인증 API
│   │   ├── health.py          # 헬스체크
│   │   └── photos.py          # 사진 API
│   │
│   ├── auth.py                # JWT 인증 로직
│   │
│   ├── core/
│   │   ├── config.py          # 설정
│   │   ├── database.py        # DB 세션
│   │   └── deps.py            # 의존성 (DB, Rate Limiter)
│   │
│   ├── models/                # DB 모델
│   │   ├── photo.py
│   │   └── user.py
│   │
│   ├── schemas/               # Pydantic 스키마
│   │   ├── photo.py
│   │   └── user.py
│   │
│   └── services/              # 비즈니스 로직
│       ├── ai_service.py      # AI 처리 (Real-ESRGAN)
│       └── image_service.py
│
├── alembic/                   # DB 마이그레이션
│   └── versions/
│
├── storage/                   # 이미지 저장소 (볼륨 마운트)
│   ├── originals/
│   └── upscaled/
│
├── weights/                   # AI 모델 가중치
│   └── RealESRGAN_x4.pth
│
└── tests/                     # 테스트
    └── concurrency_test.py
```

---

## 개발 환경

### 로컬 실행 (Docker 없이)

```bash
# 가상환경 생성
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# PostgreSQL 실행 필요
# DATABASE_URL 환경변수 설정 필요

# 서버 실행
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### DB 마이그레이션

```bash
# 마이그레이션 생성
alembic revision --autogenerate -m "설명"

# 마이그레이션 적용
alembic upgrade head

# 롤백
alembic downgrade -1
```

---

## 트러블슈팅

### GPU 관련

- **CUDA 오류**: NVIDIA 드라이버 및 NVIDIA Container Toolkit 설치 확인
- **메모리 부족**: 이미지 크기 제한 또는 배치 크기 조정

### 데이터베이스 관련

- **연결 실패**: DATABASE_URL 형식 및 PostgreSQL 실행 상태 확인
- **마이그레이션 오류**: `alembic upgrade head` 실행

### 인증 관련

- **토큰 만료**: 기본 30분, ACCESS_TOKEN_EXPIRE_MINUTES로 조정 가능
- **401 오류**: Authorization 헤더 형식 확인 (`Bearer <token>`)

---

## 라이선스

이 프로젝트는 내부 사용 목적으로 개발되었습니다.
