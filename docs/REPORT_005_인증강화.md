# 작업 보고서 #005: 인증 시스템 강화

**작업일**: 2026-01-27  
**작업자**: 풀스택 개발자  
**작업 구분**: Week 3 (Day 15-17) - 인증 강화

---

## 📋 요약

이번 작업에서는 **로그인 보안을 강화**하고 **카카오 소셜 로그인**을 추가했습니다.

주요 변경:
1. **Refresh Token 시스템 도입** - 자주 로그인하지 않아도 됨
2. **카카오 로그인** - 카카오 계정으로 간편 로그인
3. **자동 토큰 갱신** - 사용 중 갑자기 로그아웃되는 문제 해결

---

## 🤔 Refresh Token이 뭔가요?

### 기존 방식의 문제점

```
[기존: Access Token만 사용]

로그인 → Access Token 발급 (유효기간 30분)
                ↓
        30분 후 만료
                ↓
        다시 로그인해야 함 😫

문제점:
- 30분마다 로그인? 너무 불편!
- 유효기간을 길게 하면? 보안 위험!
```

### 새로운 방식 (Refresh Token)

```
[신규: Access Token + Refresh Token]

로그인 → Access Token (30분) + Refresh Token (7일) 발급
                ↓
        30분 후 Access Token 만료
                ↓
        Refresh Token으로 자동 갱신! 🎉
                ↓
        7일 후에만 재로그인 필요

장점:
- 7일간 로그인 유지 (편리!)
- Access Token 짧아서 탈취되어도 안전 (보안!)
```

### 비유: 회사 출입증

| 토큰 | 비유 | 유효기간 | 용도 |
|------|------|----------|------|
| **Access Token** | 일일 출입증 | 30분 | API 요청 |
| **Refresh Token** | 사원증 | 7일 | 출입증 재발급 |

```
매일 아침: 사원증 보여주고 → 일일 출입증 받음
하루 종일: 일일 출입증으로 출입
다음 날: 사원증으로 다시 출입증 발급

→ 사원증(Refresh Token)이 있으면 매일 로그인(비밀번호 입력) 안 해도 됨!
```

---

## 🤔 카카오 로그인이 뭔가요?

### 기존 방식

```
앱 설치 → 회원가입 (아이디/비밀번호 입력) → 로그인

귀찮은 점:
- 아이디 뭘로 하지?
- 비밀번호 또 만들어야 하네...
- 이 앱 비밀번호가 뭐였더라?
```

### 카카오 로그인

```
앱 설치 → "카카오로 로그인" 버튼 클릭 → 끝!

장점:
- 새 계정 안 만들어도 됨
- 비밀번호 기억할 필요 없음
- 카카오 계정만 있으면 OK
```

### 동작 원리

```
[사용자]              [우리 앱]              [우리 서버]              [카카오]
   │                     │                      │                      │
   │ 1. 카카오 로그인     │                      │                      │
   │    버튼 클릭        │                      │                      │
   │────────────────────>│                      │                      │
   │                     │                      │                      │
   │ 2. 카카오 앱으로    │                      │                      │
   │    이동            │                      │                      │
   │────────────────────────────────────────────────────────────────────>│
   │                     │                      │                      │
   │ 3. 카카오 로그인 완료│                      │                      │
   │<────────────────────────────────────────────────────────────────────│
   │   (카카오 토큰)     │                      │                      │
   │                     │                      │                      │
   │ 4. 카카오 토큰을    │                      │                      │
   │    우리 서버로 전송 │──────────────────────>│                      │
   │                     │                      │                      │
   │                     │                      │ 5. 카카오에          │
   │                     │                      │    사용자 정보 조회   │
   │                     │                      │─────────────────────>│
   │                     │                      │                      │
   │                     │                      │<─────────────────────│
   │                     │                      │                      │
   │                     │ 6. 우리 서버         │                      │
   │                     │    JWT 토큰 발급     │                      │
   │                     │<─────────────────────│                      │
   │                     │                      │                      │
   │ 7. 로그인 완료!     │                      │                      │
   │<────────────────────│                      │                      │
```

---

## ✅ 완료된 작업

### 생성/수정된 파일 (6개)

```
PetCam_Project/
├── ai_server/
│   ├── app/
│   │   ├── models/
│   │   │   └── refresh_token.py    # 🆕 Refresh Token DB 모델
│   │   ├── schemas/
│   │   │   └── user.py             # ✏️ 토큰 스키마 추가
│   │   ├── api/
│   │   │   ├── auth.py             # ✏️ 토큰 갱신 API 추가
│   │   │   └── oauth.py            # 🆕 카카오 로그인 API
│   │   └── auth.py                 # ✏️ Refresh Token 로직 추가
│   └── main.py                     # ✏️ OAuth 라우터 등록
│
└── mobile_app/
    └── lib/src/services/
        └── auth_service.dart       # ✏️ Refresh Token 지원
```

---

## 📄 파일 1: refresh_token.py (DB 모델)

### 이 파일이 하는 일

Refresh Token을 데이터베이스에 저장하는 테이블 구조를 정의합니다.

### 전체 코드

```python
"""
=============================================================================
Refresh Token 모델 정의
=============================================================================

Refresh Token이 뭔가요?
    로그인하면 2개의 토큰을 받습니다:
    
    1. Access Token (출입증)
       - 유효기간: 짧음 (30분)
       - 용도: API 요청할 때 사용
       - 특징: 자주 갱신해야 함
    
    2. Refresh Token (갱신권)
       - 유효기간: 길음 (7일)
       - 용도: Access Token이 만료되면 새로 발급받을 때 사용
       - 특징: DB에 저장됨, 탈취되면 무효화 가능
=============================================================================
"""

import uuid
from datetime import datetime

from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from database import Base


class RefreshToken(Base):
    """
    Refresh Token 저장 테이블
    
    각 필드 설명:
        id: 토큰의 고유 ID (UUID)
        user_id: 이 토큰의 주인 (users 테이블 참조)
        token: 실제 토큰 문자열 (랜덤 생성)
        expires_at: 만료 시간
        revoked: 무효화 여부 (True면 사용 불가)
        created_at: 생성 시간
    """
    
    __tablename__ = "refresh_tokens"
    
    # =========================================================================
    # 기본 키
    # =========================================================================
    id = Column(
        UUID(as_uuid=True),      # UUID 타입 사용
        primary_key=True,        # 기본 키
        default=uuid.uuid4       # 자동으로 UUID 생성
    )
    
    # =========================================================================
    # 사용자 참조 (외래 키)
    # =========================================================================
    # 이 토큰이 누구의 것인지
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),  # 사용자 삭제 시 토큰도 삭제
        nullable=False,
        index=True  # 검색 속도 향상
    )
    
    # =========================================================================
    # 토큰 문자열
    # =========================================================================
    # 실제로 클라이언트에게 전달되는 토큰 값
    token = Column(
        String(255),
        unique=True,   # 중복 불가
        nullable=False,
        index=True     # 검색 속도 향상 (토큰으로 조회하니까)
    )
    
    # =========================================================================
    # 만료 시간
    # =========================================================================
    expires_at = Column(
        DateTime,
        nullable=False
    )
    
    # =========================================================================
    # 무효화 여부
    # =========================================================================
    # True = 이 토큰은 더 이상 사용할 수 없음
    # 로그아웃하거나 보안 문제 발생 시 True로 변경
    revoked = Column(
        Boolean,
        default=False,
        nullable=False
    )
    
    # =========================================================================
    # 생성 시간
    # =========================================================================
    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False
    )
    
    def is_valid(self) -> bool:
        """
        토큰이 유효한지 확인합니다.
        
        유효 조건:
            1. 무효화되지 않음 (revoked == False)
            2. 만료 시간이 지나지 않음
        
        Returns:
            True: 유효함, False: 무효함
        """
        # 무효화되었으면 False
        if self.revoked:
            return False
        
        # 만료되었으면 False
        if datetime.utcnow() > self.expires_at:
            return False
        
        return True
```

### 코드 설명

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | 토큰 고유 ID |
| `user_id` | UUID | 토큰 소유자 |
| `token` | String | 실제 토큰 문자열 |
| `expires_at` | DateTime | 만료 시간 |
| `revoked` | Boolean | 무효화 여부 |
| `created_at` | DateTime | 생성 시간 |

---

## 📄 파일 2: user.py (스키마 추가)

### 추가된 스키마

```python
class TokenWithRefresh(BaseModel):
    """
    Refresh Token 포함 토큰 응답 스키마
    
    로그인 성공 시 반환 (Access Token + Refresh Token)
    """
    access_token: str           # API 요청용 토큰
    refresh_token: str          # 갱신용 토큰
    token_type: str = "bearer"
    expires_in: int = 1800      # Access Token 만료 시간 (초) - 기본 30분


class TokenRefreshRequest(BaseModel):
    """
    토큰 갱신 요청 스키마
    """
    refresh_token: str = Field(
        ...,
        description="갱신용 Refresh Token"
    )


class KakaoLoginRequest(BaseModel):
    """
    카카오 로그인 요청 스키마
    """
    kakao_access_token: str = Field(
        ...,
        description="카카오에서 받은 Access Token"
    )
```

---

## 📄 파일 3: auth.py (인증 로직)

### 추가된 함수들

```python
# =============================================================================
# Refresh Token 관련 함수
# =============================================================================

def generate_refresh_token() -> str:
    """
    랜덤한 Refresh Token 문자열을 생성합니다.
    
    특징:
        - 64바이트 랜덤 문자열 (암호학적으로 안전)
        - URL-safe 문자만 사용 (특수문자 없음)
    
    예시:
        "aB3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7bC9dE1fG3hI5jK7lM9nO1pQ3r"
    """
    return secrets.token_urlsafe(64)


async def create_refresh_token(db: AsyncSession, user_id: str) -> str:
    """
    Refresh Token을 생성하고 DB에 저장합니다.
    
    동작 과정:
        1. 랜덤 토큰 문자열 생성
        2. 만료 시간 계산 (현재 + 7일)
        3. DB에 저장
        4. 토큰 문자열 반환
    """
    # 1. 랜덤 토큰 생성
    token_str = generate_refresh_token()
    
    # 2. 만료 시간 계산
    expires_at = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    
    # 3. DB에 저장
    refresh_token = RefreshToken(
        user_id=user_id,
        token=token_str,
        expires_at=expires_at,
        revoked=False
    )
    db.add(refresh_token)
    await db.commit()
    
    # 4. 토큰 반환
    return token_str


async def verify_refresh_token(db: AsyncSession, token_str: str) -> Optional[User]:
    """
    Refresh Token을 검증하고 해당 사용자를 반환합니다.
    
    검증 과정:
        1. DB에서 토큰 조회
        2. 토큰 존재 여부 확인
        3. 무효화 여부 확인
        4. 만료 여부 확인
        5. 사용자 조회 및 반환
    """
    # DB에서 토큰 조회
    result = await db.execute(
        select(RefreshToken).filter(RefreshToken.token == token_str)
    )
    token_record = result.scalar_one_or_none()
    
    # 토큰이 없으면 None
    if not token_record:
        return None
    
    # 유효성 검사 (무효화, 만료 체크)
    if not token_record.is_valid():
        return None
    
    # 사용자 조회 및 반환
    # ... (생략)


async def revoke_refresh_token(db: AsyncSession, token_str: str) -> bool:
    """
    Refresh Token을 무효화합니다 (로그아웃 시 사용).
    
    왜 필요한가요?
        사용자가 로그아웃하면 Refresh Token을 더 이상 
        사용할 수 없게 만들어야 합니다.
    """
    # ... (생략)
```

---

## 📄 파일 4: api/auth.py (API 엔드포인트)

### 변경된 로그인 API

```python
@router.post("/token", response_model=TokenWithRefresh)
async def login_for_access_token(...):
    """
    로그인 및 토큰 발급
    
    응답 (변경됨):
        - access_token: API 요청에 사용 (유효기간: 30분)
        - refresh_token: access_token 갱신에 사용 (유효기간: 7일)  # 🆕 추가!
        - token_type: "bearer"
        - expires_in: access_token 만료 시간 (초)  # 🆕 추가!
    """
    # 사용자 인증
    user = await authenticate_user(db, form_data.username, form_data.password)
    
    # Access Token 생성
    access_token = create_access_token(data={"sub": user.username})
    
    # Refresh Token 생성 및 DB 저장  # 🆕 추가!
    refresh_token = await create_refresh_token(db, str(user.id))
    
    return TokenWithRefresh(
        access_token=access_token,
        refresh_token=refresh_token,  # 🆕 추가!
        token_type="bearer",
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )
```

### 추가된 토큰 갱신 API

```python
@router.post("/token/refresh", response_model=Token)
async def refresh_access_token(
    token_request: TokenRefreshRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Access Token 갱신
    
    언제 사용하나요?
        Access Token이 만료되었을 때!
        매번 로그인하지 않고 Refresh Token으로 새 Access Token을 받습니다.
    
    요청 본문:
        - refresh_token: 로그인 시 받은 Refresh Token
    
    응답:
        - access_token: 새로운 Access Token
        - token_type: "bearer"
    """
    # Refresh Token 검증
    user = await verify_refresh_token(db, token_request.refresh_token)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )
    
    # 새 Access Token 발급
    new_access_token = create_access_token(data={"sub": user.username})
    
    return Token(access_token=new_access_token, token_type="bearer")
```

### 추가된 로그아웃 API

```python
@router.post("/logout")
async def logout(
    token_request: TokenRefreshRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    로그아웃 (Refresh Token 무효화)
    
    왜 필요한가요?
        Refresh Token을 무효화하지 않으면, 
        탈취한 사람이 계속 새 Access Token을 발급받을 수 있습니다.
    """
    await revoke_refresh_token(db, token_request.refresh_token)
    return {"message": "로그아웃 성공"}
```

---

## 📄 파일 5: oauth.py (카카오 로그인)

### 전체 코드 (핵심 부분)

```python
"""
=============================================================================
소셜 로그인 API 라우터 (카카오)
=============================================================================
"""

# 카카오 사용자 정보 조회 API URL
KAKAO_USER_INFO_URL = "https://kapi.kakao.com/v2/user/me"


async def get_kakao_user_info(kakao_access_token: str) -> Optional[KakaoUserInfo]:
    """
    카카오 API를 호출하여 사용자 정보를 가져옵니다.
    """
    async with httpx.AsyncClient() as client:
        # 카카오 API 호출
        response = await client.get(
            KAKAO_USER_INFO_URL,
            headers={
                "Authorization": f"Bearer {kakao_access_token}",
            }
        )
        
        if response.status_code != 200:
            return None
        
        data = response.json()
        
        return KakaoUserInfo(
            id=data.get("id"),
            nickname=data.get("kakao_account", {}).get("profile", {}).get("nickname"),
            email=data.get("kakao_account", {}).get("email"),
        )


@router.post("/oauth/kakao", response_model=TokenWithRefresh)
async def kakao_login(
    login_request: KakaoLoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    카카오 로그인
    
    사용 방법:
        1. 앱에서 카카오 SDK로 로그인
        2. 카카오에서 받은 access_token을 이 API로 전송
        3. 우리 서버의 JWT 토큰 받음
    """
    # 1. 카카오 API로 사용자 정보 조회
    kakao_user = await get_kakao_user_info(login_request.kakao_access_token)
    
    if not kakao_user:
        raise HTTPException(status_code=401, detail="Invalid Kakao access token")
    
    # 2. 우리 DB에서 사용자 조회 또는 생성
    kakao_username = f"kakao_{kakao_user.id}"  # 예: kakao_123456789
    
    result = await db.execute(select(User).filter(User.username == kakao_username))
    user = result.scalar_one_or_none()
    
    if not user:
        # 신규 사용자: 자동 회원가입
        random_password = secrets.token_urlsafe(32)
        user = User(
            username=kakao_username,
            hashed_password=get_password_hash(random_password),
        )
        db.add(user)
        await db.commit()
    
    # 3. JWT 토큰 발급
    access_token = create_access_token(data={"sub": user.username})
    refresh_token = await create_refresh_token(db, str(user.id))
    
    return TokenWithRefresh(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
    )
```

---

## 📄 파일 6: auth_service.dart (Flutter)

### 주요 변경 사항

```dart
// =============================================================================
// 토큰 저장 키
// =============================================================================
static const String _accessTokenKey = 'access_token';     // 🆕 추가
static const String _refreshTokenKey = 'refresh_token';   // 🆕 추가
static const String _tokenExpiryKey = 'token_expiry';     // 🆕 추가


// =============================================================================
// 토큰 저장 (Access + Refresh)
// =============================================================================
Future<void> saveTokens({
  required String accessToken,
  required String refreshToken,
  int? expiresIn,
}) async {
  _cachedAccessToken = accessToken;
  _cachedRefreshToken = refreshToken;
  
  // 만료 시간 계산
  if (expiresIn != null) {
    _cachedTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    await _storage.write(key: _tokenExpiryKey, value: _cachedTokenExpiry!.toIso8601String());
  }
  
  await _storage.write(key: _accessTokenKey, value: accessToken);
  await _storage.write(key: _refreshTokenKey, value: refreshToken);
}


// =============================================================================
// 자동 토큰 갱신
// =============================================================================
Future<String?> getValidToken() async {
  final token = await getToken();
  if (token == null) return null;
  
  // 만료 확인
  final expired = await isTokenExpired();
  if (!expired) return token;  // 아직 유효함
  
  // 갱신 시도
  final refreshed = await refreshAccessToken();
  if (refreshed) return _cachedAccessToken;  // 갱신 성공
  
  return null;  // 갱신 실패 - 재로그인 필요
}


// =============================================================================
// 카카오 로그인
// =============================================================================
Future<bool> loginWithKakao(String kakaoAccessToken) async {
  final response = await http.post(
    Uri.parse("$baseUrl/oauth/kakao"),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'kakao_access_token': kakaoAccessToken}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    await saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
      expiresIn: data['expires_in'],
    );
    return true;
  }
  return false;
}
```

---

## 🔄 새로운 API 엔드포인트

### 기존 API (변경됨)

| 메서드 | 경로 | 설명 | 변경 사항 |
|--------|------|------|----------|
| POST | `/token` | 로그인 | refresh_token 추가 반환 |

### 신규 API

| 메서드 | 경로 | 설명 |
|--------|------|------|
| POST | `/token/refresh` | Access Token 갱신 |
| POST | `/logout` | 로그아웃 (토큰 무효화) |
| POST | `/oauth/kakao` | 카카오 로그인 |
| GET | `/oauth/kakao/userinfo` | 카카오 사용자 정보 조회 |

---

## 📊 로그인 응답 비교

### 기존

```json
{
  "access_token": "eyJhbG...",
  "token_type": "bearer"
}
```

### 변경 후

```json
{
  "access_token": "eyJhbG...",
  "refresh_token": "aB3dE5fG7hI9jK1lM3nO5pQ7r...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

---

## 🎯 이 작업으로 얻는 효과

| 항목 | 이전 | 이후 |
|------|------|------|
| 로그인 유지 | 30분 | **7일** |
| 재로그인 빈도 | 하루 여러 번 | **7일에 1번** |
| 토큰 탈취 위험 | 높음 (긴 유효기간) | **낮음** (짧은 Access Token) |
| 소셜 로그인 | ❌ 없음 | **✅ 카카오** |
| 강제 로그아웃 | ❌ 불가능 | **✅ 서버에서 무효화 가능** |

---

## ⚙️ 카카오 로그인 설정 방법 (나중에)

### 1. 카카오 개발자 등록

1. https://developers.kakao.com 접속
2. 카카오 계정으로 로그인
3. "내 애플리케이션" → "애플리케이션 추가"
4. REST API 키 복사

### 2. 플랫폼 등록

- Android: 패키지명, 키 해시 등록
- iOS: 번들 ID 등록

### 3. 동의항목 설정

- 닉네임: 필수 동의
- 이메일: 선택 동의 (필요시)

### 4. Flutter 카카오 SDK 추가

```yaml
# pubspec.yaml
dependencies:
  kakao_flutter_sdk_user: ^1.6.0
```

---

## 📁 생성/수정된 파일 요약

| 파일 | 작업 | 설명 |
|------|------|------|
| `app/models/refresh_token.py` | 🆕 신규 | Refresh Token DB 모델 |
| `app/schemas/user.py` | ✏️ 수정 | 토큰 스키마 추가 |
| `app/auth.py` | ✏️ 수정 | Refresh Token 로직 |
| `app/api/auth.py` | ✏️ 수정 | 토큰 갱신/로그아웃 API |
| `app/api/oauth.py` | 🆕 신규 | 카카오 로그인 API |
| `main.py` | ✏️ 수정 | OAuth 라우터 등록 |
| `auth_service.dart` | ✏️ 수정 | Refresh Token 지원 |

---

## ✅ 진행 현황 업데이트

| 작업 | 상태 |
|------|------|
| Week 1: 문서화 | ✅ 완료 |
| Week 1: 프로덕션 환경 | ✅ 완료 |
| Week 1: AWS 인프라 | ⏭️ 스킵 |
| Week 2: CI/CD | ✅ 완료 |
| Week 2: 백엔드 테스트 | ✅ 완료 |
| **Week 3: 인증 강화** | **✅ 완료** |
| Week 3: 모니터링 | ⏳ 대기 |

---

## 다음 단계

**Week 3 (Day 18-21): 모니터링 시스템 구축**
- Sentry 에러 트래킹
- CloudWatch 로그/메트릭 (선택)
- Firebase Crashlytics (Flutter)

---

*보고서 작성일: 2026-01-27*  
*문의사항이 있으시면 언제든 말씀해주세요!*
