"""
=============================================================================
PetCam AI Server - 테스트 설정 파일 (conftest.py)
=============================================================================

이 파일이 하는 일:
    테스트를 실행하기 전에 필요한 준비물들을 만들어줍니다.
    마치 요리하기 전에 재료를 준비하는 것과 같습니다.

주요 구성요소:
    1. 테스트용 데이터베이스 (실제 DB를 건드리지 않음)
    2. 테스트용 API 클라이언트 (서버에 요청을 보내는 도구)
    3. 테스트용 사용자 계정 (로그인 테스트에 사용)

사용 방법:
    pytest tests/ -v
=============================================================================
"""

import os
import asyncio
from typing import AsyncGenerator, Generator

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# =============================================================================
# 환경 변수 설정 (테스트용)
# =============================================================================
# 테스트가 실행되기 전에 환경 변수를 설정합니다.
# 이렇게 하면 실제 서버 설정과 충돌하지 않습니다.

os.environ["SECRET_KEY"] = "test-secret-key-for-testing-only-do-not-use-in-production"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"  # 메모리 DB (테스트용)
os.environ["ALLOWED_ORIGINS"] = "*"


# =============================================================================
# 이제 앱을 임포트합니다 (환경 변수 설정 후!)
# =============================================================================
from database import Base
from main import app
from app.auth import get_password_hash, create_access_token
from app.models.user import User


# =============================================================================
# 테스트용 데이터베이스 엔진 생성
# =============================================================================
# SQLite 메모리 데이터베이스를 사용합니다.
# - 장점: 빠르고, 테스트가 끝나면 자동으로 사라짐
# - 실제 PostgreSQL과 100% 동일하지는 않지만, 기본 기능 테스트에는 충분

test_engine = create_async_engine(
    "sqlite+aiosqlite:///:memory:",  # 메모리에만 존재하는 임시 DB
    connect_args={"check_same_thread": False},  # SQLite 멀티스레드 허용
    poolclass=StaticPool,  # 연결 풀 설정 (테스트용)
)

# 테스트용 세션 팩토리
TestSessionLocal = sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
)


# =============================================================================
# Fixture: 이벤트 루프 설정
# =============================================================================
# pytest-asyncio가 비동기 테스트를 실행할 수 있도록 이벤트 루프를 설정합니다.

@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """
    테스트 세션 전체에서 사용할 이벤트 루프를 생성합니다.
    
    비유: 
        테스트들이 달릴 수 있는 '운동장'을 만드는 것과 같습니다.
        모든 테스트가 같은 운동장에서 뛰어야 충돌이 없습니다.
    """
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop  # 테스트가 끝날 때까지 이 루프를 사용
    loop.close()  # 테스트가 끝나면 정리


# =============================================================================
# Fixture: 테스트용 데이터베이스 세션
# =============================================================================

@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """
    각 테스트마다 새로운 데이터베이스 세션을 제공합니다.
    
    동작 방식:
        1. 테스트 시작 전: 테이블 생성
        2. 테스트 실행: DB 세션 사용
        3. 테스트 종료 후: 테이블 삭제 (깨끗하게 정리)
    
    비유:
        시험 볼 때마다 새 시험지를 받는 것과 같습니다.
        이전 학생의 답이 남아있으면 안 되니까요!
    """
    # 1. 테이블 생성 (CREATE TABLE)
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # 2. 세션 생성 및 테스트에 제공
    async with TestSessionLocal() as session:
        yield session  # 이 세션을 테스트에서 사용
    
    # 3. 테이블 삭제 (DROP TABLE) - 깨끗하게 정리
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


# =============================================================================
# Fixture: 테스트용 API 클라이언트
# =============================================================================

@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """
    API 요청을 보낼 수 있는 테스트 클라이언트를 생성합니다.
    
    이게 뭔가요?
        실제로 서버를 띄우지 않고도 API를 테스트할 수 있게 해주는 도구입니다.
        마치 비행 시뮬레이터처럼, 진짜 비행기를 띄우지 않고 조종 연습을 할 수 있습니다.
    
    사용 예시:
        response = await client.get("/health")
        response = await client.post("/register", json={"username": "test"})
    """
    
    # 테스트용 DB 세션을 앱에 주입하는 함수
    async def override_get_db():
        yield db_session
    
    # 원래 DB 대신 테스트 DB를 사용하도록 교체
    from app.auth import get_db
    app.dependency_overrides[get_db] = override_get_db
    
    # 테스트 클라이언트 생성
    async with AsyncClient(
        transport=ASGITransport(app=app),  # FastAPI 앱에 직접 연결
        base_url="http://test"  # 테스트용 가짜 URL
    ) as ac:
        yield ac  # 이 클라이언트를 테스트에서 사용
    
    # 테스트 후 원래대로 복구
    app.dependency_overrides.clear()


# =============================================================================
# Fixture: 테스트용 사용자 생성
# =============================================================================

@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession) -> User:
    """
    테스트에 사용할 사용자 계정을 미리 만들어둡니다.
    
    생성되는 계정:
        - 아이디: testuser
        - 비밀번호: testpassword123
    
    왜 필요한가요?
        로그인 테스트, 인증이 필요한 API 테스트 등에서 사용합니다.
        매번 회원가입부터 하면 테스트가 느려지고 복잡해지니까요.
    """
    # 비밀번호를 암호화해서 저장 (실제 서비스와 동일한 방식)
    hashed_password = get_password_hash("testpassword123")
    
    # 사용자 생성
    user = User(
        username="testuser",
        hashed_password=hashed_password,
        is_active=True  # 활성 상태
    )
    
    # DB에 저장
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)  # DB에서 생성된 ID 등을 가져옴
    
    return user


# =============================================================================
# Fixture: 테스트용 인증 토큰
# =============================================================================

@pytest_asyncio.fixture
async def auth_token(test_user: User) -> str:
    """
    테스트용 JWT 인증 토큰을 생성합니다.
    
    이게 뭔가요?
        로그인하면 받는 '출입증' 같은 것입니다.
        이 토큰이 있어야 사진 업로드 같은 기능을 사용할 수 있습니다.
    
    사용 예시:
        headers = {"Authorization": f"Bearer {auth_token}"}
        response = await client.get("/photos", headers=headers)
    """
    # JWT 토큰 생성 (실제 로그인과 동일한 방식)
    token = create_access_token(data={"sub": test_user.username})
    return token


# =============================================================================
# Fixture: 인증된 클라이언트 (토큰 포함)
# =============================================================================

@pytest_asyncio.fixture
async def authenticated_client(
    client: AsyncClient, 
    auth_token: str
) -> AsyncClient:
    """
    이미 로그인된 상태의 클라이언트를 제공합니다.
    
    왜 필요한가요?
        인증이 필요한 API를 테스트할 때마다 
        headers={"Authorization": ...}를 쓰기 귀찮으니까요!
    
    사용 예시:
        # 토큰 없이도 바로 사용 가능!
        response = await authenticated_client.get("/photos")
    """
    # 모든 요청에 인증 헤더 자동 추가
    client.headers["Authorization"] = f"Bearer {auth_token}"
    return client
