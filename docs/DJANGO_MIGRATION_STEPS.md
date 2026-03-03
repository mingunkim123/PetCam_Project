# Django + DRF 백엔드 재구축 - 단계별 가이드 (30 Steps)

> **사용법**: 한 Step을 완료한 뒤, "다음 step"이라고 말하면 다음 단계로 진행합니다.
> Django/DRF를 모르는 분도 따라갈 수 있도록 각 단계를 최대한 작게 나눴습니다.

---

## 📌 Step 1: 기존 FastAPI 코드 백업

**목표**: 나중에 참고할 수 있도록 현재 ai_server를 백업합니다.

**할 일**:
- `ai_server/` 전체를 `ai_server_backup_fastapi/` 로 복사
- 또는 `ai_server/` 내부에 `_backup_fastapi/` 폴더를 만들고 핵심 파일만 복사

**왜?**: Django로 전환하다 문제가 생기면 기존 코드를 참고할 수 있습니다.

**완료 조건**: 백업 폴더가 존재하고, `main.py`, `app/` 등 핵심 파일이 포함되어 있으면 OK.

---

## 📌 Step 2: Python 가상환경 생성

**목표**: Django 프로젝트용 독립 가상환경을 만듭니다.

**할 일**:
```bash
cd /home/mingun/PetCam_Project
python3 -m venv venv_django
source venv_django/bin/activate   # Linux/Mac
# Windows: venv_django\Scripts\activate
```

**완료 조건**: 터미널 프롬프트에 `(venv_django)`가 보이면 OK.

---

## 📌 Step 3: Django + DRF 기본 패키지 설치

**목표**: Django, DRF, DB 관련 패키지를 설치합니다.

**할 일**:
```bash
pip install Django>=4.2,<5 djangorestframework django-cors-headers django-environ psycopg2-binary PyJWT passlib[bcrypt]
```

**완료 조건**: `pip list`에 Django, djangorestframework가 보이면 OK.

---

## 📌 Step 4: Django 프로젝트 스캐폴드 생성

**목표**: Django 프로젝트를 ai_server 안에 생성합니다.

**할 일**:
```bash
cd ai_server
django-admin startproject petcam .
```

**결과**: `manage.py`, `petcam/` 폴더가 생성됩니다.

> **참고**: 시스템에 `config` 모듈이 있으면 `config` 대신 `petcam` 사용 (예: turtlebot3_ws).

**완료 조건**: `python manage.py check` 통과, `runserver` 실행 시 에러 없으면 OK.

---

## 📌 Step 5: settings를 base/dev/prod로 분리

**목표**: 설정 파일을 환경별로 분리합니다.

**할 일**:
- `petcam/settings.py` 를 `petcam/settings/base.py` 로 이름 변경
- `petcam/settings/dev.py`, `petcam/settings/prod.py` 생성
- `petcam/settings/__init__.py`에서 `DJANGO_SETTINGS_MODULE`에 따라 base/dev/prod 선택

**완료 조건**: `python manage.py runserver --settings=petcam.settings.dev` 가 정상 동작하면 OK.

---

## 📌 Step 6: base.py에 공통 설정 정리

**목표**: INSTALLED_APPS, MIDDLEWARE, DRF, CORS 등 공통 설정을 base.py에 정의합니다.

**할 일**:
- `rest_framework`, `corsheaders` 를 INSTALLED_APPS에 추가
- CORS, DRF 기본 설정 추가
- `petcam/__init__.py`에서 `os.environ.get("DJANGO_ENV", "dev")` 로 설정 모듈 선택

**완료 조건**: DRF, CORS 관련 에러 없이 runserver 실행되면 OK.

---

## 📌 Step 7: django-environ으로 환경변수 로드

**목표**: .env 파일에서 SECRET_KEY, DEBUG, DATABASE_URL 등을 읽어옵니다.

**할 일**:
- petcam/settings/base.py에서 `django-environ` 사용
- `SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`, `DATABASE_URL` 환경변수 로드
- `.env.example`에 Django용 항목 추가 (기존과 병합)

**완료 조건**: .env 파일이 있으면 그 값을 읽고, 없으면 기본값으로 동작하면 OK.

---

## 📌 Step 8: PostgreSQL DB 설정

**목표**: Django가 PostgreSQL에 연결되도록 설정합니다.

**할 일**:
- `DATABASES`를 `django.db.backends.postgresql`로 설정
- `DATABASE_URL` 파싱 (django-environ의 `env.db()` 사용)
- `python manage.py check` 실행 시 DB 관련 에러가 없으면 OK

**완료 조건**: `manage.py check` 통과, (선택) `migrate` 실행 시 DB 연결 성공.

---

## 📌 Step 9: accounts 앱 생성

**목표**: 사용자/인증용 Django 앱을 만듭니다.

**할 일**:
```bash
python manage.py startapp accounts
```
- `petcam/settings/base.py`의 `INSTALLED_APPS`에 `accounts` 추가

**완료 조건**: `accounts/` 폴더가 생기고, `manage.py check` 에러 없음.

---

## 📌 Step 10: 커스텀 User 모델 정의

**목표**: UUID 기반 User 모델을 정의합니다.

**할 일**:
- `accounts/models.py`에 `AbstractUser` 상속 User 모델 작성
- 필드: `id` (UUID, primary_key), `username`, `password` (Django 해시), `is_active`
- `AUTH_USER_MODEL = 'accounts.User'` 를 petcam/settings/base.py에 설정

**완료 조건**: `makemigrations accounts` 실행 시 마이그레이션 파일 생성.

---

## 📌 Step 11: RefreshToken 모델 정의

**목표**: DB 기반 Refresh Token 모델을 만듭니다.

**할 일**:
- `accounts/models.py`에 `RefreshToken` 모델 추가
- 필드: `id` (UUID), `user` (FK → User), `token` (unique), `expires_at`, `revoked`, `created_at`

**완료 조건**: `makemigrations accounts`로 새 마이그레이션이 생성됨.

---

## 📌 Step 12: accounts 마이그레이션 적용

**목표**: User, RefreshToken 테이블을 DB에 생성합니다.

**할 일**:
```bash
python manage.py migrate
```

**완료 조건**: `auth_user`(또는 accounts_user), `accounts_refreshtoken` 테이블이 생성됨.

---

## 📌 Step 13: JWT Access Token 생성/검증 유틸 작성

**목표**: PyJWT로 Access Token을 발급·검증하는 함수를 만듭니다.

**할 일**:
- `accounts/auth_utils.py` (또는 `core/jwt_utils.py`) 생성
- `create_access_token(username)` → JWT 문자열 반환
- `verify_access_token(token)` → username 반환 또는 None

**완료 조건**: 테스트 코드나 Django shell에서 토큰 생성/검증이 동작하면 OK.

---

## 📌 Step 14: Refresh Token CRUD 유틸 작성

**목표**: RefreshToken 생성·검증·무효화 로직을 구현합니다.

**할 일**:
- `create_refresh_token(user_id)` → DB에 저장 후 token 문자열 반환
- `verify_refresh_token(token)` → User 반환 또는 None
- `revoke_refresh_token(token)` → revoked=True 설정

**완료 조건**: Django shell에서 위 함수들이 정상 동작하면 OK.

---

## 📌 Step 15: DRF JWT 인증 클래스 작성

**목표**: `Authorization: Bearer <token>` 헤더를 파싱해 request.user를 설정하는 인증 클래스를 만듭니다.

**할 일**:
- `accounts/authentication.py` 에 `BaseAuthentication` 상속 클래스 작성
- `authenticate(self, request)` 에서 Bearer 토큰 추출 → JWT 검증 → User 조회 → `(user, token)` 반환

**완료 조건**: 인증 클래스를 사용하는 뷰에서 `request.user`가 설정되면 OK.

---

## 📌 Step 16: 비밀번호 해시 유틸 (bcrypt)

**목표**: 회원가입/로그인 시 bcrypt로 비밀번호를 해시합니다.

**할 일**:
- `accounts/utils.py` 에 `get_password_hash(password)` 와 `verify_password(plain, hashed)` 구현
- passlib의 `CryptContext(schemes=["bcrypt"])` 사용 (기존 FastAPI와 동일)

**완료 조건**: 해시된 비밀번호로 `verify_password` 시 True 반환하면 OK.

---

## 📌 Step 17: 회원가입 API (POST /register)

**목표**: JSON `{username, password}`로 회원가입하는 뷰를 만듭니다.

**할 일**:
- `accounts/views.py`에 `RegisterView` (APIView)
- 요청: JSON `username`, `password`
- 응답: `{id, username, is_active}` (201)
- 중복 username 시 400

**완료 조건**: Postman/curl로 `/register` 호출 시 사용자 생성되면 OK.

---

## 📌 Step 18: 로그인 API (POST /token)

**목표**: form-data `username`, `password`로 로그인하고 access_token, refresh_token을 반환합니다.

**할 일**:
- `accounts/views.py`에 `LoginView`
- OAuth2 호환 form: `username`, `password`
- 응답: `{access_token, refresh_token, token_type: "bearer", expires_in}`

**완료 조건**: 로그인 성공 시 토큰이 반환되면 OK.

---

## 📌 Step 19: 토큰 갱신 API (POST /token/refresh)

**목표**: JSON `{refresh_token}`으로 새 access_token을 발급합니다.

**할 일**:
- `accounts/views.py`에 `RefreshTokenView`
- 요청: JSON `refresh_token`
- 응답: `{access_token, token_type: "bearer"}`

**완료 조건**: refresh_token으로 새 access_token 발급되면 OK.

---

## 📌 Step 20: 로그아웃 API (POST /logout)

**목표**: Refresh Token을 무효화합니다.

**할 일**:
- `accounts/views.py`에 `LogoutView`
- 요청: JSON `refresh_token`
- 응답: `{message: "로그아웃 성공"}`

**완료 조건**: 로그아웃 후 해당 refresh_token으로 갱신 시도 시 401이면 OK.

---

## 📌 Step 21: accounts URL 라우팅

**목표**: /register, /token, /token/refresh, /logout URL을 연결합니다.

**할 일**:
- `accounts/urls.py` 생성
- `petcam/urls.py`에서 `path("", include("accounts.urls"))` 추가
- 슬래시 없이 `/register`, `/token` 등이 매칭되도록 설정 (APPEND_SLASH=False 또는 명시적 경로)

**완료 조건**: 각 엔드포인트가 의도한 URL로 응답하면 OK.

---

## 📌 Step 22: 헬스체크 API (GET /health)

**목표**: `{status: "ok", version: "1.0.0"}` 를 반환하는 뷰를 만듭니다.

**할 일**:
- `petcam/views.py` 또는 `accounts/views.py`에 `health_view`
- `petcam/urls.py`에 `path("health", health_view)` 등록

**완료 조건**: `GET /health` → 200 + JSON 응답이면 OK.

---

## 📌 Step 23: photos 앱 생성 및 PhotoRecord 모델

**목표**: 사진 업로드/목록용 앱과 모델을 만듭니다.

**할 일**:
- `python manage.py startapp photos`
- `photos/models.py`에 `ProcessingStatus` (TextChoices), `PhotoRecord` 모델 정의
- 필드: id, original_path, upscaled_path, status, error_message, created_at, latitude, longitude

**완료 조건**: `makemigrations photos` → `migrate` 성공.

---

## 📌 Step 24: 업스케일 API (POST /upscale)

**목표**: multipart `file`, `lat`, `lng`로 이미지 업로드 후 PhotoRecord 생성합니다.

**할 일**:
- `photos/views.py`에 `UpscaleView` (인증 필수)
- 파일을 `storage/originals/{uuid}.jpg`에 저장
- PhotoRecord 생성 (status=QUEUED), (AI 처리는 다음 단계)

**완료 조건**: 업로드 시 파일 저장 및 DB 레코드 생성되면 OK.

---

## 📌 Step 25: 베스트컷 API (POST /bestcut)

**목표**: 다중 파일 중 블러 점수 최고 파일만 남기고 PhotoRecord 생성합니다.

**할 일**:
- `photos/views.py`에 `BestCutView`
- OpenCV Laplacian으로 블러 점수 계산
- 최고 점수 파일만 `storage/originals/{uuid}.jpg`로 이동, 나머지 삭제
- PhotoRecord 생성 후 (AI는 다음 단계)

**완료 조건**: bestcut 호출 시 선택된 파일만 저장되고 레코드 생성되면 OK.

---

## 📌 Step 26: 사진 목록/다운로드/삭제 API

**목표**: GET /photos, GET /photos/{id}, DELETE /photos/{id} 를 구현합니다.

**할 일**:
- `GET /photos?skip=0&limit=100` → 목록 JSON
- `GET /photos/{id}?type=upscaled` → 이미지 파일 스트리밍
- `DELETE /photos/{id}` → 파일 및 DB 레코드 삭제

**완료 조건**: 세 API가 기존 응답 형식과 호환되면 OK.

---

## 📌 Step 27: AI 백그라운드 처리 연동

**목표**: 업스케일/베스트컷 후 RealESRGAN으로 이미지 처리합니다.

**할 일**:
- 기존 `ai_service.py`의 `process_image_sync` 로직을 `services/ai_service.py`로 이식
- 뷰에서 레코드 저장 후 `threading.Thread` 또는 Celery로 백그라운드 실행
- 완료 시 DB status, upscaled_path 업데이트

**완료 조건**: 업로드 후 백그라운드에서 AI 처리 완료되면 OK.

---

## 📌 Step 28: OAuth 카카오 로그인 (POST /oauth/kakao)

**목표**: `kakao_access_token`으로 우리 User 조회/생성 후 JWT 발급합니다.

**할 일**:
- `oauth/` 또는 `accounts/` 에 카카오 API 호출 로직
- `POST /oauth/kakao` (JSON: kakao_access_token)
- `GET /oauth/kakao/userinfo?kakao_access_token=...` (디버깅용)

**완료 조건**: 카카오 토큰으로 로그인 시 우리 JWT가 발급되면 OK.

---

## 📌 Step 29: Rate Limiting 및 CORS 마무리

**목표**: 기존과 동일한 요청 제한 및 CORS 설정을 적용합니다.

**할 일**:
- DRF throttling 또는 django-ratelimit 사용
- register 5/min, token 10/min, refresh 30/min, logout 10/min, upscale/bestcut 10/min, photos 60/min
- CORS_ALLOW_CREDENTIALS, CORS_ALLOWED_ORIGINS 확인

**완료 조건**: rate limit 초과 시 429, CORS 관련 에러 없음.

---

## 📌 Step 30: Docker 및 최종 점검

**목표**: Dockerfile, docker-compose를 Django용으로 수정하고 전체 동작을 확인합니다.

**할 일**:
- Dockerfile: `gunicorn petcam.wsgi:application` 등 Django 실행 명령으로 변경
- docker-compose: 환경변수, 볼륨(storage, weights) 유지
- 모바일 앱에서 API_URL만 새 백엔드로 두고 로그인→업로드→목록→다운로드 시나리오 테스트

**완료 조건**: Docker로 빌드·실행 시 모든 API가 정상 동작하면 OK.

---

## 진행 상황 체크리스트

| Step | 완료 |
|------|------|
| 1. 기존 코드 백업 | ☐ |
| 2. 가상환경 생성 | ☐ |
| 3. Django 패키지 설치 | ☐ |
| 4. 프로젝트 스캐폴드 | ☐ |
| 5. settings 분리 | ☐ |
| 6. base.py 공통 설정 | ☐ |
| 7. django-environ | ☐ |
| 8. PostgreSQL 설정 | ☐ |
| 9. accounts 앱 생성 | ☐ |
| 10. User 모델 | ☐ |
| 11. RefreshToken 모델 | ☐ |
| 12. accounts 마이그레이션 | ☐ |
| 13. JWT 유틸 | ☐ |
| 14. Refresh Token CRUD | ☐ |
| 15. DRF 인증 클래스 | ☐ |
| 16. 비밀번호 해시 | ☐ |
| 17. POST /register | ☐ |
| 18. POST /token | ☐ |
| 19. POST /token/refresh | ☐ |
| 20. POST /logout | ☐ |
| 21. accounts URL | ☐ |
| 22. GET /health | ☐ |
| 23. photos 앱 + PhotoRecord | ☐ |
| 24. POST /upscale | ☐ |
| 25. POST /bestcut | ☐ |
| 26. GET/DELETE photos | ☐ |
| 27. AI 백그라운드 | ☐ |
| 28. OAuth 카카오 | ☐ |
| 29. Rate Limit + CORS | ☐ |
| 30. Docker + 최종 점검 | ☐ |

---

**다음 step으로 넘어갈 준비가 되면 "다음 step" 또는 "Step N 진행해줘"라고 말해주세요.**
